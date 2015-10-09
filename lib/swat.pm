package swat;

our $VERSION = '0.1.55';

use base 'Exporter'; 

our @EXPORT = qw{version};

sub version {
    print $VERSION, "\n"
}


1;

package main;

use strict;
use Test::More;
use Data::Dumper;
use File::Temp qw/ tempfile /;
use swat::story;

$| = 1;

sub execute_with_retry {

    my $cmd = shift;
    my $try = shift || 1;

    for my $i (1..$try){
        diag(1, "\nexecute cmd: $cmd\n attempt number: $i") if debug_mod2();
        return $i if system($cmd) == 0;
        sleep $i**2;
    }

    return

}

sub make_http_request {

    return get_prop('http_response') if defined get_prop('http_response');

    my ($fh, $content_file) = tempfile( DIR => get_prop('test_root_dir') );

    if (get_prop('response')){

        ok(1,"response is already set");

        open F, ">", $content_file or die $!;
        print F get_prop('response');
        close F;

        ok(1,"response saved to $content_file");

    }else{

        my $curl_cmd = get_prop('curl_cmd');
        my $hostname = get_prop('hostname');
        my $resource = get_prop('resource');
        my $http_method = get_prop('http_method'); 

        my $st = execute_with_retry("$curl_cmd $hostname$resource > $content_file && test -s $content_file", get_prop('try_num'));
        ok(1,"response saved to $content_file");

        if (get_prop('ignore_http_err')){
            ok(1, "@{[ $st ? 'succ': 'unsucc' ]}sessful response from $http_method $hostname$resource") 
        }else{
            ok($st, "successful response from $http_method  $hostname$resource") 
        }

    }

    open F, $content_file or die $!;
    my $http_response = '';
    $http_response.= $_ while <F>;
    close F;
    set_prop( http_response => $http_response );

    my $debug_bytes = get_prop('debug_bytes');

    diag `head -c $debug_bytes $content_file` if debug_mod2();

    return get_prop('http_response');
}

sub populate_context {

    return if context_populated();

    my $data = shift;
    my $i = 0;

    my $context = [];

    for my $l ( split /\n/, $data ){
        chomp $l;
        $i++;
        $l=":blank_line" unless $l=~/\S/;
        push @$context, [$l, $i];        
    }

    set_prop('context',$context);
    set_prop('context_local',$context);

    diag("context populated") if debug_mod2();

    set_prop(context_populated => 1);

}

sub check_line {
 
    my $pattern = shift;
    my $check_type = shift;
    my $message = shift;
    my $status = 0;


    reset_captures();
    my @captures;

    populate_context( make_http_request() );

    diag("lookup $pattern ...") if debug_mod2();

    my @context         = @{get_prop('context')};
    my @context_local   = @{get_prop('context_local')};
    my @context_new     = ();

    if ($check_type eq 'default'){
        for my $c (@context_local){
            my $ln = $c->[0]; my $next_i = $c->[1];
            if ( index($ln,$pattern) != -1){
                $status = 1;
                push @context_new, $context[$next_i];
            }
        }
    }elsif($check_type eq 'regexp'){
        for my $c (@context_local){
            my $re = qr/$pattern/;
            my $ln = $c->[0]; my $next_i = $c->[1];

            my @foo = ($ln =~ /$re/g);

            if (scalar @foo){
                push @captures, [@foo];
                $status = 1;
                push @context_new, $context[$next_i];
            }
        }
    }else {
        die "unknown check_type: $check_type";
    }

    ok($status,$message);


    if (debug_mod2()){
        my $k=0;
        for my $ce (@captures){
            $k++;
            diag "captured item N $k";
            for  my $c (@{$ce}){
                diag("\tcaptures: $c");
            }
        }
    }

    set_prop( captures => [ @captures ] );

    if (in_block_mode()){
        set_prop( context_local => [@context_new] ); 
    }

    return

}


sub header {

    if (debug_mod12()) {

        my $project = get_prop('project');
        my $hostname = get_prop('hostname');
        my $resource = get_prop('resource');
        my $curl_cmd = get_prop('curl_cmd');
        my $debug = get_prop('debug');
        my $try_num = get_prop('try_num');
        my $ignore_http_err = get_prop('ignore_http_err');

        ok(1, "swat version: $swat::VERSION");
        ok(1, "project: $project");
        ok(1, "hostname: $hostname");
        ok(1, "resource: $resource");
        if ( get_prop('response' )){
            ok(1, 'response is set, so we do not use curl')
        }else{
            ok(1, "curl run: $curl_cmd $hostname$resource");
        }
        ok(1, "debug: $debug");
        ok(1, "try num: $try_num");
        ok(1, "ignore http errors: $ignore_http_err");
    }
}

sub generate_asserts {

    my $filepath_or_array_ref = shift;
    my $write_header = shift;

    header() if $write_header;

    my @ents;
    my @ents_ok;
    my $ent_type;

    if ( ref($filepath_or_array_ref) eq 'ARRAY') {
        @ents = @$filepath_or_array_ref
    }else{
        return unless $filepath_or_array_ref;
        open my $fh, $filepath_or_array_ref or die $!;
        while (my $l = <$fh>){
            push @ents, $l
        }
        close $fh;
    }



  
    ENTRY: for my $l (@ents){

        chomp $l;
        diag $l if $ENV{'swat_debug'};
        
        next ENTRY unless $l =~ /\S/; # skip blank lines

        if ($l=~ /^\s*#(.*)/) { # skip comments
            next ENTRY;
        }

        if ($l=~ /^\s*begin:\s*$/) { # begin: block marker
            diag("begin: block") if debug_mod2();
            set_block_mode();
            next ENTRY;
        }
        if ($l=~ /^\s*end:\s*$/) { # end: block marker
            unset_block_mode();
            populate_context( make_http_request() );
            diag("end: block") if debug_mod2();
            set_prop( context_populated => 0); # flush current context
            next ENTRY;
        }

        if ($l=~/^\s*code:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $code = $1;
            if ($code=~s/\\\s*$//){
                 push @ents_ok, $code;
                 $ent_type = 'code';
                 next ENTRY; # this is multiline, hold this until last line \ found
            }else{
                undef $ent_type;
                handle_code($code);
            }
        }elsif($l=~/^\s*generator:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $code = $1;
            if ($code=~s/\\\s*$//){
                 push @ents_ok, $code;
                 $ent_type = 'generator';
                 next ENTRY; # this is multiline, hold this until last line \ found
            }else{
                undef $ent_type;
                handle_generator($code);
            }
            
        }elsif($l=~/^\s*regexp:\s*(.*)/){
            die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);
            my $re=$1;
            undef $ent_type;
            handle_regexp($re);
        }elsif(defined($ent_type)){
            if ($l=~s/\\\s*$//) {
                push @ents_ok, $l;
                next ENTRY; # this is multiline, hold this until last line \ found
             }else {

                no strict 'refs';
                my $name = "handle_"; $name.=$ent_type;
                push @ents_ok, $l;
                &$name(\@ents_ok);

                undef $ent_type;
                @ents_ok = ();
    
            }
       }else{
            s{#.*}[], s{\s+$}[], s{^\s+}[] for $l;
            undef $ent_type;
            handle_plain($l);
        }
    }

    die "unterminated entity found: $ents_ok[-1]" if defined($ent_type);

}

sub handle_code {

    my $code = shift;

    unless (ref $code){
        eval $code;
        die "code entry eval perl error, code:$code , error: $@" if $@;
        diag "handle_code OK. $code" if $ENV{'swat_debug'};
    } else {
        my $code_to_eval = join "\n", @$code;
        eval $code_to_eval;
        die "code entry eval error, code:$code_to_eval , error: $@" if $@;
        diag "handle_code OK. multiline. $code_to_eval" if $ENV{'swat_debug'};
    }
    
}

sub handle_generator {

    my $code = shift;

    unless (ref $code){
        my $arr_ref = eval $code;
        die "generator entry eval error, code:$code , error: $@" if $@;
        generate_asserts($arr_ref,0);
        diag "handle_code OK. $code" if $ENV{'swat_debug'};
    } else {
        my $code_to_eval = join "\n", @$code;
        my $arr_ref = eval $code_to_eval;
        generate_asserts($arr_ref,0);
        die "code entry eval error, code:$code_to_eval , error: $@" if $@;
        diag "handle_generator OK. multiline. $code_to_eval" if $ENV{'swat_debug'};
    }
    
}

sub handle_regexp {

    my $re = shift;

    my $http_method = get_prop('http_method');
    my $resource = get_prop('resource');

    my $message = in_block_mode() ? "$http_method $resource matches | $re" : "$http_method $resource matches $re";
    check_line($re, 'regexp', $message);
    diag "handle_regexp OK. $re" if $ENV{'swat_debug'};
    
}

sub handle_plain {

    my $l = shift;

    my $http_method = get_prop('http_method');
    my $resource = get_prop('resource');

    my $message = in_block_mode() ? "$http_method $resource returns | $l" : "$http_method $resource returns $l";
    check_line($l, 'default', $message);
    diag "handle_plain OK. $l" if $ENV{'swat_debug'};   
}


1;


__END__

=head1 SYNOPSIS

Web automated testing framework.

=head1 Documentation

Please follow github pages  - https://github.com/melezhik/swat

=head1 AUTHOR

Aleksei Melezhik

=head1 COPYRIGHT

Copyright 2015 Alexey Melezhik.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

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

 
our ($project);
our ($curl_cmd);
our ($http_url, $path, $route_dir, $http_meth); 
our ($debug, $ignore_http_err, $try_num, $debug_bytes);
our ($is_swat_package);
our ($set_server_response);
our ($test_root_dir);
our ($server_response);

our $command_params = {};

$| = 1;

our $context_populated;
our $http_response;
my @context = ();
my @context_local = ();
my $block_mode;
my $captures = [];

for my $p ( keys %$command_params ){
    my $v = $command_params->{$p};
    diag "dynamic cmd parameter set: $p => $v" if debug_mod2();
    my $re = "__".$p."__";
    s{$re}[$v]g for $curl_cmd;
    s{$re}[$v]g for $path;
}

sub execute_with_retry {

    my $cmd = shift;
    my $try = shift || 1;

    for my $p ( keys %$command_params ){
        my $v = $command_params->{$p};
        diag "dynamic cmd parameter set: $p => $v" if debug_mod2();
        my $re = "__".$p."__";
        s{$re}[$v]g for $cmd;
        s{$re}[$v]g for $path;
    }


    for my $i (1..$try){
        diag(1, "\nexecute cmd: $cmd\n attempt number: $i") if debug_mod2();
        return $i if system($cmd) == 0;
        sleep $i**2;
    }

    return

}

sub set_server_response {
    $server_response = shift;
}

sub make_http_request {

    return $http_response if defined $http_response;

    my ($fh, $content_file) = tempfile( DIR => $test_root_dir);

    if ($set_server_response){

        ok(1,"response set somewhere else");

        open F, ">", $content_file or die $!;
        print F $server_response;
        close F;

        ok(1,"response saved to $content_file");

    }else{

        my $st = execute_with_retry("$curl_cmd > $content_file && test -s $content_file", $try_num);
        if ($ignore_http_err){
            ok(1, "@{[ $st ? 'succ': 'unsucc' ]}sessful response from $http_meth $http_url$path") 
        }else{
            ok($st, "successful response from $http_meth $http_url$path") 
        }
        ok(1,"response saved to $content_file");

    }

    open F, $content_file or die $!;
    $http_response = '';
    $http_response.= $_ while <F>;
    close F;
    

    diag `head -c $debug_bytes $content_file` if debug_mod2();

    return $http_response;
}

sub populate_context {

    return if $context_populated;

    my $data = shift;
    my $i = 0;

    @context = ();

    for my $l ( split /\n/, $data ){
        chomp $l;
        $i++;
        $l=":blank_line" unless $l=~/\S/;
        push @context, [$l, $i];        
    }
    @context_local = @context;
    diag("context populated") if debug_mod2();
    $context_populated=1;
}

sub hostname {
    my $a = `hostname`;
    chomp $a;
    return $a;
}

sub captures {

    $captures;
}

sub capture {
    captures()->[0]
}

sub check_line {
 
    my $pattern = shift;
    my $check_type = shift;
    my $message = shift;

    my $status = 0;


    my @context_new = ();
    $captures = [];

    populate_context( make_http_request() );

    diag("lookup $pattern ...") if debug_mod2();
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
                push @{$captures}, [@foo];
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
        for my $ce (@{$captures}){
            $k++;
            diag "captured item N $k";
            for  my $c (@{$ce}){
                diag("\tcaptures: $c");
            }
        }
    }

    if ($block_mode){
        @context_local = @context_new; 
    }

    return

}


sub header {

    if (debug_mod12()) {
        ok(1, "swat version: $swat::VERSION");
        ok(1, "project: $project");
        ok(1, "is swat package: $is_swat_package");
        ok(1, "url: $http_url/$path");
        ok(1, "route: $path ");
        ok(1, "set server response: $set_server_response");
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
            $block_mode=1;
            next ENTRY;
        }
        if ($l=~ /^\s*end:\s*$/) { # end: block marker
            $block_mode=0;
            populate_context( make_http_request() );
            diag("end: block") if debug_mod2();
            $context_populated=0; # flush current context
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
    my $message = $block_mode ? "$http_meth $path matches | $re" : "$http_meth $path matches $re";
    check_line($re, 'regexp', $message);
    diag "handle_regexp OK. $re" if $ENV{'swat_debug'};
    
}

sub handle_plain {

    my $l = shift;
    my $message = $block_mode ? "$http_meth $path returns | $l" : "$http_meth $path returns $l";
    check_line($l, 'default', $message);
    diag "handle_plain OK. $l" if $ENV{'swat_debug'};   
}


sub debug_mod1 {

    $debug == 1
}

sub debug_mod2 {

    $debug == 2
}

sub debug_mod12 {

    debug_mod1() or debug_mod2()
}

sub run_swat_module {

    my $http_method = uc(shift());
    my $path = shift;
    my $params = shift || {};

    undef($context_populated);
    undef($http_response);

    $command_params = $params;

    ok(1,"run swat module: $http_method => $path") if debug_mod12();

    do "$test_root_dir/$path/00.$http_method.m";

    undef($context_populated);
    undef($http_response);

    $command_params = {};

}

1;

__END__



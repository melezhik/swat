package swat;

our $VERSION = '0.1.62';

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


sub execute_with_retry {

    my $cmd = shift;
    my $try = shift || 1;

    for my $i (1..$try){
        diag("\nexecute cmd: $cmd\n attempt number: $i") if debug_mod2();
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

        diag "response saved to $content_file";

    }else{

        my $curl_cmd = get_prop('curl_cmd');
        my $hostname = get_prop('hostname');
        my $resource = get_prop('resource');
        my $http_method = get_prop('http_method'); 

        my $st = execute_with_retry("$curl_cmd '$hostname$resource' > $content_file && test -f $content_file", get_prop('try_num'));

        if ($st) {
            ok(1, "$http_method $hostname$resource succeeded");
        }elsif(ignore_http_err()){
            ok(1, "$http_method $hostname$resource failed, still continue due to ignore_http_err set to 1");
        }else{
            ok(0, "$http_method $hostname$resource succeeded");
            open CNT, $content_file or die $!;
            my $rdata = join "", <CNT>;
            close CNT;
            diag("$curl_cmd $hostname$resource\n===>\n$rdata");
        }

        diag "response saved to $content_file";

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

sub header {

    
    my $project = get_prop('project');
    my $swat_module = get_prop('swat_module');
    my $hostname = get_prop('hostname');
    my $resource = get_prop('resource');
    my $http_method = get_prop('http_method');
    my $curl_cmd = get_prop('curl_cmd');
    my $debug = get_prop('debug');
    my $try_num = get_prop('try_num');
    my $ignore_http_err = get_prop('ignore_http_err');
    
    ok(1, "project: $project");
    ok(1, "hostname: $hostname");
    ok(1, "resource: $resource");
    ok(1, "http method: $http_method");
    if ( get_prop('response' )){
        ok(1, 'response is set, so we do not use curl')
    }
    ok(1,"swat module: $swat_module");
    ok(1, "debug: $debug");
    ok(1, "try num: $try_num");
    ok(1, "ignore http errors: $ignore_http_err");
    
}

sub generate_asserts {

    my $check_file = shift;

    header() if debug_mod12();

    dsl->{debug_mod} = get_prop('debug');

    dsl()->{match_l} = get_prop('match_l');

    dsl()->{output} = make_http_request();

    dsl()->generate_asserts($check_file);

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

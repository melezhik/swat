package swat::story;

use strict;
use base 'Exporter';
use Outthentic::DSL;

our @EXPORT = qw{ 

    new_story end_of_story 

    get_prop set_prop 

    debug_mod1 debug_mod2 debug_mod12

    set_response

    dsl captures capture

    run_swat_module apply_module_variables module_variable

    do_perl_file

    modify_resource

    set_response_processor
    run_response_processor

    hostname ignore_http_err

    project_root_dir

    test_root_dir

    resource resource_dir

    http_method

    body

    headers

};

our @stories = ();

sub new_story {
    
    push @stories, {
        template_variables => {},
        props => { dsl => Outthentic::DSL->new() , response => [] },
    };

}

sub end_of_story {

    if (debug_mod12()){
        Test::More::ok(1,'end of story: '.(get_prop('check_list')));
    }
    delete $stories[-1];

}

sub _story {
    @stories[-1];
}

sub get_prop {

    my $name = shift;

    _story()->{props}->{$name};
    
}

sub set_prop {

    my $name = shift;
    my $value = shift;

    _story()->{props}->{$name} =  $value;
    
}

sub project_root_dir {
    get_prop('project');
}

sub test_root_dir {
    get_prop('test_root_dir');
}

sub hostname {
    get_prop('hostname');
}

sub ignore_http_err {
    get_prop('ignore_http_err');
}

sub resource {
    get_prop('resource');
}

sub resource_dir {
    get_prop('resource_dir');
}

sub http_method {
    get_prop('http_method');
}

sub body {
    get_prop('body');
}

sub headers {
    get_prop('headers');
}



sub context_populated {
    get_prop('context_populated')
}

sub debug_mod1 {

    get_prop('debug') == 1
}

sub debug_mod2 {

    get_prop('debug') == 2
}

sub debug_mod12 {

    debug_mod1() or debug_mod2()
}

sub set_response {
    my $cv = get_prop('response');
    push @$cv, shift();
    set_prop('response', $cv);
}

sub dsl {
    get_prop('dsl')
}

sub captures {

    dsl()->{captures}
}

sub capture {
    dsl()->{captures}->[0]
}

sub run_swat_module {

    my $http_method = uc(shift());
    my $resource = shift;
    my $module_variables = shift || {};

    $main::module_variables = $module_variables;

    my $test_root_dir = get_prop('test_root_dir');

    my $module_file = "$test_root_dir/$resource/00.$http_method.m";

    if (debug_mod12()){
        Test::More::ok(1,"run swat module: $http_method => $resource"); 
        Test::More::ok(1,"load module file: $module_file");
    }

    my $test_root_dir = get_prop('test_root_dir');

    do_perl_file($module_file);
    
}

sub do_perl_file {

    my $file = shift;

    {
        package main;
        do $file;
        die "couldn't parse $file: $@" if $@;
    }

    return 1;
}


sub apply_module_variables {

    set_prop( module_variables => $main::module_variables );

    for my $name ( keys %{ get_prop( 'module_variables' ) } ){

        my $v = module_variable($name);

        my $re = "%".$name."%";

        my $curl_cmd = get_prop('curl_cmd');
        my $resource = get_prop('resource');

        s{$re}[$v]g for $curl_cmd;
        s{$re}[$v]g for $resource;

        if (debug_mod2()){
            Test::More::ok(1,"apply module variable: $name => $v");
        }

        set_prop( curl_cmd => $curl_cmd );
        set_prop( resource => $resource );
    }
    
}

sub module_variable {

    my $name = shift;

    get_prop( 'module_variables' )->{$name};

}

sub modify_resource {

    my $sub = shift;

    my $resource = get_prop('resource');

    Test::More::ok(1,"try to modify_resource: $resource ") if debug_mod12();

    my $new_resource = $sub->($resource);

    Test::More::ok(1,"modify_resource ok: $resource => $new_resource") if debug_mod12();

    set_prop( resource => $new_resource );

}

sub set_response_processor {

    my $sub = shift;

    Test::More::ok(1,"setting response processor") if debug_mod12();

    set_prop( response_processor => $sub );

}

sub run_response_processor {

    return unless get_prop( 'response_processor' );

    my $body = body();

    my $headers = headers();

    Test::More::ok(1,"running response processor") if debug_mod12();

    my $sub = get_prop( 'response_processor' );

    my $retval = $sub->($headers,$body);

    if (debug_mod12()){
        my $debug_bytes = get_prop('debug_bytes');
        my $rshort = substr( $retval, 0, $debug_bytes );
        if (length($rshort) < length($retval)) {
             Test::More::diag("modified response:\n$rshort ... ( output truncated to $debug_bytes bytes )");
        } else{
             Test::More::diag("modified response:\n$retval");
        }
    }

    dsl()->{output} = $retval;
}


1;

__END__


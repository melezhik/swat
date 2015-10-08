package swat::story;

use strict;
use base 'Exporter';

our @EXPORT = qw{ 

    new_story end_of_story 
    get_prop set_prop 

    debug_mod1 debug_mod2 debug_mod12

    set_response

    context_populated

    captures capture reset_captures

    set_block_mode unset_block_mode in_block_mode

    run_swat_module 

    insert_template_variables get_template_variable

    modify_resource

};

our @stories = ();

sub new_story {
    
    push @stories, {
        context_populated => 0,
        captures => [],
        block_mode => 0,
        template_variables => {}
    };

}

sub end_of_story {

    shift @stories;
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
    set_prop('response', shift());
}

sub captures {

    get_prop('captures');
}

sub capture {
    captures()->[0]
}


sub reset_captures {
    set_prop(captures => []);
}

sub set_block_mode {
    set_prop(block_mode => 1);
    
}

sub unset_block_mode {
    set_prop(block_mode => 0);
    
}

sub in_block_mode {
    get_prop(block_mode());
}


sub run_swat_module {

    my $http_method = uc(shift());
    my $resource = shift;
    my $test_root_dir = get_prop('test_root_dir');

    $main::template_variables = shift || {};

    my $module_file = "$test_root_dir/$resource/00.$http_method.m";

    if (debug_mod12()){
        Test::More::ok(1,"run swat module: $http_method => $resource"); 
        Test::More::ok(1,"load module file: $module_file");
    }

    my $test_root_dir = get_prop('test_root_dir');

    do $module_file;

}


sub insert_template_variables {

    for my $name ( keys %main::template_variables ){

        my $v = get_prop('template_variables')->{$name};

        my $re = "%".$name."%";

        my $curl_cmd = get_prop('curl_cmd');
        my $resource = get_prop('resource');

        s{$re}[$v]g for $curl_cmd;
        s{$re}[$v]g for $resource;

        set_prop( curl_cmd => $curl_cmd );
        set_prop( resource => $resource );
    }
    
}

sub get_template_variable {

    my $name = shift;
    %main::template_variables{$name};

}

sub modify_resource {

    my $sub = shift;

    my $resource = get_prop('resource');
    my $new_resource = $sub->($resource);
    Test::More::ok(1,"modify_resource: $resource => $new_resource") if debug12();
    set_prop( resource => $new_resource );

}

sub _story {
    @stories[-1];
}

1;

__END__

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


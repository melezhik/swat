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

    run_swat_module apply_module_variables module_variable

    modify_resource


    hostname

    project_root_dir
    test_root_dir

    resource resource_dir

    http_method
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

    if (debug_mod12()){
        Test::More::ok(1,"end of story: ".(get_prop('check_list')));
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
    get_prop('project_root_dir');
}

sub test_root_dir {
    get_prop('test_root_dir');
}

sub hostname {
    get_prop('hostname');
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
    get_prop('block_mode');
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

    require $module_file;

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

        if (debug_mod12()){
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
    my $new_resource = $sub->($resource);
    Test::More::ok(1,"modify_resource: $resource => $new_resource") if debug_mod12();
    set_prop( resource => $new_resource );

}


1;

__END__


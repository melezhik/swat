package swat::story;

use base 'Exporter';

our @EXPORT = qw{ 
    new_story end_story 
    get_prop set_prop 
    debug_mod1 debug_mod2 debug_mod12
    set_response
    context_populated
    captures capture reset_captures
    set_block_mode unset_block_mode in_block_mode
    insert_template_variables
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

sub end_story {

    shift @stories;
}


sub get_prop {

    my $name = shift;

    _story->{props}->{$name};
    
}

sub set_prop {

    my $name = shift;
    my $value = shift;

    _story->{props}->{$name} =  $value;
    
}



sub context_populated {
    _get_prop('context_populated')
}

sub debug_mod1 {

    _get_prop('debug') == 1
}

sub debug_mod2 {

    _get_prop('debug') == 2
}

sub debug_mod12 {

    debug_mod1() or debug_mod2()
}

sub set_response {
    _set_prop('response', shift());
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
    get_prop(block_mode);
}


sub insert_template_variables {

    for my $name ( keys %{get_prop('template_variables')} ){

        my $v = get_prop('template_variables')->{$name};

        my $re = "%".$p."%";

        my $curl_cmd = get_prop('curl_cmd');
        my $resource = get_prop('resource');

        s{$re}[$v]g for $curl_cmd;
        s{$re}[$v]g for $resource;

        set_prop( curl_cmd => $curl_cmd );
        set_prop( resource => $resource );
    }
    
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


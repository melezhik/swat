package swat::story;

use base 'Exporter';

our @EXPORT = qw{ 
    new_story end_story 
    get_prop set_prop 
    debug_mod1 debug_mod2 debug_mod12
    set_response
    context_populated
    captures capture reset_captures
    set_block_mode unset_block_mode block_mode
};

our @stories = ();

sub new_story {
    
    push @stories, {
        context_populated => 0,
        captures => [],
        block_mode => 0,
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

sub block_mode {
    get_prop(block_mode);
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


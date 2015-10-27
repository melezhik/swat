run_swat_module( 'GET' => '/wife' , { path => '/data.txt' } );
run_swat_module( 'GET' => '/son', { path => '/data.txt' });

set_response(<<HERE);
alex
hello
world
julia
alex

HERE

1;



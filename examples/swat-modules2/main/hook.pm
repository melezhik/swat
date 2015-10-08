run_swat_module( 'GET' => '/foo' , { message => 'foo' } );
run_swat_module( 'GET' => '/bar', { message => 'bar' });

set_response('DONE');

1;



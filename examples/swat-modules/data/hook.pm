run_swat_module( 'GET' => '/wife' , { path => '/data.txt' } );
run_swat_module( 'GET' => '/son', { path => '/data.txt' });

modify_resource( sub {
    '/data.txt'
});

1;



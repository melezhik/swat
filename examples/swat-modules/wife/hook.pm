modify_resource( sub {
    my $r = shift;
    my $path = module_variable('path');
    $r = $path;
    $r;
});
1;



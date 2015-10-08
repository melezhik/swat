modify_resource( sub {
    my $r = shift;
    my $path = get_template_variable('path');
    $r = $path;
    $r;
});
1;



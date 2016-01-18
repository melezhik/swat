my $foo = config()->{main}{foo};
my $bar = config()->{main}{bar};

set_response("foo: $foo");
set_response("bar: $bar");



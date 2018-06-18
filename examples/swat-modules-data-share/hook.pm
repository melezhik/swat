use strict;
set_response('done');
our @foo = ('OK');
run_swat_module( GET => 'foo' );

use Data::Dumper;

print Dumper(\@foo);

1;


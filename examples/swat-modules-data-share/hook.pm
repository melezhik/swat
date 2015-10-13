use strict;
set_response('done');
our @foo = ('OK');
run_swat_module( GET => 'foo' );

use Data::Dumper;

diag Dumper(\@foo);

1;


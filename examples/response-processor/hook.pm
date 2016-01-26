set_response('hello');

set_response_processor( sub { 
      my $headers   = shift;
      my $body      = shift;
      $body=~s/hello/hello swat!/;
      return $body;
});


#!/usr/bin/env perl
use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  $c->render(template => 'index');
};

get '/login' => sub {
  my $c = shift;
  $c->render(template => 'login');
};

post '/login' => sub {

  my $c = shift;

  my $login    = $c->param('login');
  my $password = $c->param('password');

  if ( $login eq 'admin' and $password eq '123456' ){
      $c->render(text => 'LOGIN OK');
      $c->cookie( logged => 'OK');  
  }else{
      $c->render(text => 'BAD LOGIN', status => 401);
  }  


};

get '/restricted/zone' => sub {

  my $c = shift;
  use Data::Dumper;

  if ( $c->cookie('logged')){
      $c->render(text => 'welcome to restricted area');
  }else{
      $c->render(text => 'Oops.', status => 403);
  }

};

app->start;
__DATA__

@@ index.html.ep
hello world

@@ login.html.ep
<form action="/login" method="POST">


#!/usr/bin/env perl

use Catmandu::Sane;
use Plack::Request;
use Plack::Response;
use Plack::Builder;
use JSON;

# Builder
my $builder = Plack::Builder->new();

# Create our PSGI app.
my $api = sub {
  my $env = shift;
  my $req = Plack::Request->new($env);
  my $err;
  my $json;

  eval {
    $json = decode_json( $req->content );
  } or do {
    $err = @$;
  };

  return [
    '200',
    [ 'Content-Type' => 'application/json' ],
    [ $json ]
  ];
};

# Mount our app.
$api = $builder->mount('/' => $api);


# curl
#   -v -H "Accept: application/json" -H "Content-type: application/json"
#   -X POST -d
#   '{ "quote": { "author": "wouter willaert", "quote": "helo world" } }'
#   http://0.0.0.0:5000/

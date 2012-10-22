#!/usr/bin/env perl

# Dependecies.

use Test::More;
use Plack::Test;
use Catmandu;
use Catmandu::Sane;
use HTTP::Request::Common;

# App.

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Plack::Restify';
    use_ok $pkg;
}
require_ok $pkg;

Catmandu->load;

my $app = Catmandu::Plack::Restify->new(
  strict => 1,
  resources => [ 'quotes', 'authors' ]
);

# Tests.

my $get = sub {
   my $cb  = shift;
   my $res = $cb->( GET "/quotes" );
   is $res->code, '200';
};

test_psgi app => $app, client => $get;

my $post = sub {
  my $cb  = shift;
  my $res = $cb->(
    POST '/quotes',
    Content_Type => 'application/json',
   Content => '{ "quote" : "testing", "author" : "testmore" }'
  );
  is $res->code, '201';
};

test_psgi app => $app, client => $post;

# Done.

done_testing 4;

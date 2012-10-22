#!/usr/bin/env perl

# Dependecies.

use Test::More;
use Plack::Test;
use Catmandu;
use Catmandu::Sane;
use HTTP::Request::Common;

# Configuration.

Catmandu->load;

# App.

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Plack::Restify';
    use_ok $pkg;
}

require_ok $pkg;

my $app = Catmandu::Plack::Restify->new(
  strict => 1,
  resources => [ 'quotes', 'authors' ],
  readonly => 1
);

# Client.

my $client = sub {
   my $cb  = shift;
   my $res = $cb->( GET "/" );
   is $res->content, '{"200":"OK"}';
};

# Test.

test_psgi app => $app, client => $client;

done_testing 3;

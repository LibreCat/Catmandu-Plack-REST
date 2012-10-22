#!/usr/bin/env perl

use Catmandu;
use Catmandu::Sane;
use Catmandu::Plack::Restify;
use Plack::Builder;

# Load config.
Catmandu->load;

# Builder
my $builder = Plack::Builder->new();

# Create our PSGI app.
my $api = Catmandu::Plack::Restify->new(
  strict => 1,
  resources => [ 'quotes', 'authors' ],
  readonly => 0
);

# Mount our app.
$api = $builder->mount('/catmandu' => $api);

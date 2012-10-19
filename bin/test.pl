#!/usr/bin/env perl

use Scalar::Util qw( looks_like_number );
use Data::Dumper;

my $string = "/collection/1/search";
$string = substr($string, 1);
my @array = split(/\//, $string);

my $col = $array[0];
my $id = $array[1]; # will be a number or the string search

my $mode = 'collection';

if (looks_like_number $id && $id ne 'search') {
    $mode = 'resource';
} elsif ($id eq 'search') {
    $mode = 'search';
}

print Dumper($mode);

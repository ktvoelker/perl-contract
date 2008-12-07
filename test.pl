#!/usr/bin/perl

use strict;
use warnings;

use lib './';
use Contract;
use Contract::Predicate;

sub foo {
	my ($x, $y) = @_;
	my $z = $x + $y;
	return "$x + $y == $z";
}

contract "foo", two_of integer, integer;

my $x = foo 3, 4;


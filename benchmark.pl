#!/usr/bin/perl

use strict;
use Benchmark qw(cmpthese);

BEGIN { system("make"); push @INC, "blib/arch", "blib/lib" }

my $body  = new Body;
my $sword = new Sword;

cmpthese(500_000, {
    pl => sub { $sword->cut_body_pl( $body ) eq "ouch" or die },
    xs => sub { $sword->cut_body_xs( $body ) eq "ouch" or die },
});


package Body;
use Object::Previous;

sub new { return bless {}, "Body" }
sub hurt_us_pl { my $po = Object::Previous::previous_object_pl(); $po->hurt_us }
sub hurt_us_xs { my $po = Object::Previous::previous_object_xs(); $po->hurt_us }

package Sword;

sub new { return bless {}, "Sword" }
sub cut_body_pl { my $this = shift; my $target = shift; $target->hurt_us_pl }
sub cut_body_xs { my $this = shift; my $target = shift; $target->hurt_us_xs }
sub hurt_us { "ouch" }

package Object::Previous;

use strict;
use warnings;
use Carp;

require Exporter;
use base 'Exporter';

our $VERSION = 1.1005;
our @EXPORT = qw(previous_object);

sub previous_object {};
sub import {
    if( @_==1 or $_[1] !~ m/(:?pure|perl|pl)/ ) {
        eval {
            require XSLoader;
            XSLoader::load('Object::Previous', $VERSION);
        };

        if( $@ ) {
            warn "couldn't load _xs version: $@";
            *previous_object = *previous_object_pl;

        } else {
            *previous_object = *previous_object_xs;
        }

    } else {
        splice @_, 1, 1;
        *previous_object = *previous_object_pl;
    }

    goto &Exporter::import;
}

sub previous_object_pl {
    my @foo = do { package DB; @DB::args=(); caller(2) };

    # NOTE: this doesn't work if, in that previous object, you were to do this:
    #
    #   unshift @_, "borked".
    #
    # The result is that you'd get "borked" instead of the blessed ref of the caller object

    # NOTE: I call this pure-perl vesion The Chromatic Way, but it's really the Devel::StackTrace way see:
    #  - http://perlmonks.org/?node_id=690713
    #  - http://perlmonks.org/?node_id=690795

    $DB::args[0];
}

1;

__END__

=head1 NAME

Object::Previous - find the instance of the object that called your function

=head1 SYNOPSIS

    package Human;
    use Object::Previous;

    sub new { bless {hit_points=>(7+int rand 6)} }
    sub hurt_us {
        my $body = shift;
           $body->{hit_points} -= shift;

        if( (int rand 10) == 0 ) {
            # every once in a while, damaging bodies hurts the sword:

            my $sword = previous_object();
               $sword->hurt_us(1+int rand 4);
        }
    }

    package Sword;
    sub new { bless {hit_points=>2} }
    sub hurt_human {
        my $sword = shift;
        my $target = shift;

        $target->hurt_us( 1+int rand 8 );
    }
    sub hurt_us {
        my $sword = shift;
           $sword->{hit_points} -= shift;

        if( $sword->{hit_points} <= 0 ) {
            warn "the attacker's sword broke!";
        }
    }

=head1 previous_object()

previous_object() either returns the blessed ref of the caller or
undef if it is not possible to find it.

=head1 CAVEATS

If you tinker with the @_ in the caller object, previous_object()
won't work.  Curiously, certain ways of tinkinkering don't hurt
and others do.

    my $self = shift; # doesn't hurt previous_object()
    shift while @_;   # doesn't hurt previous_object()
    splice @_, 0, 30; # doesn't hurt previous_object()

    unshift @_, "borked"; # breaks previous_object();
    @_ = ();              # breaks previous_object();

=head1 AUTHOR(S)

Most of the code was ripped from Perl and from perlmonks.org, but
it was glued together by me.

Paul Miller <paul@cpan.org>

I am using this software in my own projects...  If you find bugs,
please please please let me know. :) Actually, let me know if you
find it handy at all.  Half the fun of releasing this stuff is
knowing that people use it.

=head1 COPYRIGHT

Copyright (c) 2007 Paul Miller

Licensed under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Devel::Stacktrace, perlmonks.org, cop.h, pp_ctl.c

=cut

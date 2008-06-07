package Object::PreviousObject;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
use base 'Exporter';
use version; our $VERSION = qv('1.0.0');

our @EXPORT = qw(previous_object);

sub previous_object {};
sub import {
    if( not(@_) or $_[1] !~ m/(:?pure|perl)/ ) {
        eval {
            require XSLoader;
            XSLoader::load('Object::PreviousObject', $VERSION);
        };

        if( $@ ) {
            warn "couldn't load _xs version: $@";
            *previous_object = *previous_object_perl;

        } else {
            *previous_object = *previous_object_xs;
        }

    } else {
        splice @_, 1, 1;
        *previous_object = *previous_object_perl;
    }

    goto &Exporter::import;
}

sub previous_object_perl {
    my @foo = do { package DB; @DB::args=(); caller(2) };

    # NOTE: this doesn't work if, in that previous object, you were to do this:
    #
    #   unshift @_, "borked".
    #
    # The result is that you'd get "borked" instead of the blessed ref of the caller object

    $DB::args[0];
}

1;

__END__

=head1 NAME

Object::PreviousObject - find the instance of the object that called your function

=head1 SYNOPSIS

    package Human;
    sub hurt_us {
        my $body = shift;
           $body->{hit_points} -= shift;

        if( (int rand 10) == 0 ) {
            # every once in a while, damaging bodies hurts the sword:

            my $sword = previous_object();
               $sword->hurt_us(1+int rand4);
        }
    }

    package Sword;
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

=head1 AUTHOR

Paul Miller <paul@cpan.org>

I am using this software in my own projects...  If you find bugs, please
please please let me know. :) Actually, let me know if you find it handy at
all.  Half the fun of releasing this stuff is knowing that people use it.

=head1 COPYRIGHT

Copyright (c) 2007 Paul Miller -- LGPL [attached]

=head1 SEE ALSO

perl(1)

=cut

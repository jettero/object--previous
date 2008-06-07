package Object::PreviousObject;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
use base 'Exporter';

our %EXPORT_TAGS = ( all => [qw( previous_object )]);
our @EXPORT_OK   = ( @{$EXPORT_TAGS{all}} );

use version; our $VERSION = qv('1.0.0');

require XSLoader;
XSLoader::load('Object::PreviousObject', $VERSION);

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

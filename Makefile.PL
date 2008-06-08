use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Object::Previous',
    VERSION_FROM => 'Previous.pm',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',
    PREREQ_PM    => { version => 0, },
);

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Object::PreviousObject',
    VERSION_FROM => 'PreviousObject.pm',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',
    PREREQ_PM    => { version => 0, },
);

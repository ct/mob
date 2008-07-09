use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mob',
    AUTHOR              => 'Chris Thompson <cthom@cpan.org>',
    VERSION_FROM        => 'lib/Mob.pm',
    ABSTRACT_FROM       => 'lib/Mob.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mob-*' },
);

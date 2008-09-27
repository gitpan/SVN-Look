use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SVN::Look',
    AUTHOR              => 'Gustavo Chaves <gustavo+perl@gnustavo.org>',
    VERSION_FROM        => 'lib/SVN/Look.pm',
    ABSTRACT_FROM       => 'lib/SVN/Look.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
	'Switch'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SVN-Look-*' },
);

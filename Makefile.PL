
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A caching wrapper around the svnlook command.",
  "AUTHOR" => "Gustavo L. de M. Chaves <gnustavo\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Cwd" => 0,
    "English" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "URI::file" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SVN-Look",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "SVN::Look",
  "PREREQ_PM" => {
    "Carp" => 0,
    "File::Spec::Functions" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.31",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);




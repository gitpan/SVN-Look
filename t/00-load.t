#!/usr/bin/perl

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (has_svn()) {
    plan tests => 1;
}
else {
    plan skip_all => 'Need svn commands in the PATH.';
}

my $t = reset_repo();

set_hook(<<'EOS');
use SVN::Look;
EOS

work_ok('commit' => <<"EOS");
touch $t/wc/file
svn add -q --no-auto-props $t/wc/file
svn ci -q -mx $t/wc/file
EOS

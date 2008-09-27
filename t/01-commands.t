#!/usr/bin/perl

use strict;
use warnings;
use lib 't';
use SVN::Look;
use Test::More;

require "test-functions.pl";

if (has_svn()) {
    plan tests => 4;
}
else {
    plan skip_all => 'Need svn commands in the PATH.';
}

my $t = reset_repo();

system(<<"EOS");
touch $t/wc/file
svn add -q --no-auto-props $t/wc/file
svn ps -q svn:mime-type text/plain $t/wc/file
svn ci -q -mlog $t/wc/file
EOS

my $look = SVN::Look->new("$t/repo", -r => 1);

ok(defined $look, 'constructor');

cmp_ok($look->author(), 'eq', $ENV{USER}, 'author');

cmp_ok($look->log_msg(), 'eq', "log\n", 'log_msg');

cmp_ok(($look->added())[0], 'eq', 'file', 'added');


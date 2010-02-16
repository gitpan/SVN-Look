use strict;
use warnings;
use lib 't';
use SVN::Look;
use Test::More;

require "test-functions.pl";

my $nof_tests = 12;
my $login = getlogin || getpwuid($<) || $ENV{USER};
--$nof_tests unless $login;

if (has_svn()) {
    plan tests => $nof_tests;
}
else {
    plan skip_all => 'Need svn commands in the PATH.';
}

my $t = reset_repo();

system(<<"EOS");
echo first >$t/wc/file
svn add -q --no-auto-props $t/wc/file
svn ps -q svn:mime-type text/plain $t/wc/file
svn ci -q -mlog $t/wc/file
EOS

my $look = SVN::Look->new("$t/repo", -r => 1);

ok(defined $look, 'constructor');

cmp_ok($look->author(), 'eq', $login, 'author')
    if $login;

cmp_ok($look->log_msg(), 'eq', "log\n", 'log_msg');

cmp_ok(($look->added())[0], 'eq', 'file', 'added');

system(<<"EOS");
echo second >>$t/wc/file
svn ci -q -mlog $t/wc/file
EOS

$look = SVN::Look->new("$t/repo", -r => 2);

cmp_ok($look->diff(), '=~', qr/\+second/, 'diff');

system(<<"EOS");
echo space in name >$t/wc/'a b.txt'
svn add -q --no-auto-props $t/wc/'a b.txt'
svn ps -q svn:mime-type text/plain $t/wc/'a b.txt'
svn ci -q -mlog $t/wc/'a b.txt'
EOS

$look = SVN::Look->new("$t/repo", -r => 3);

my $pl = eval { $look->proplist('a b.txt') };

ok(defined $pl, 'can call proplist in a file with spaces in the name');

ok(exists $pl->{'svn:mime-type'}, 'proplist finds the expected property');

is($pl->{'svn:mime-type'}, 'text/plain', 'proplist finds the correct property value');

my $youngest = eval { $look->youngest() };

cmp_ok($youngest, '=~', qr/^\d+$/, 'youngest');

my $uuid = eval { $look->uuid() };

cmp_ok($uuid, '=~', qr/^[0-9a-f-]+$/, 'uuid');

my $lock = eval { $look->lock('file') };

ok(! defined $lock, 'no lock');

system(<<"EOS");
svn lock -m'lock comment' $t/wc/file >/dev/null
EOS

$lock = eval { $look->lock('file') };

ok(defined $lock && ref $lock eq 'HASH', 'lock');

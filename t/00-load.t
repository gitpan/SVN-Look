#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SVN::Look' );
}

diag( "Testing SVN::Look $SVN::Look::VERSION, Perl $], $^X" );

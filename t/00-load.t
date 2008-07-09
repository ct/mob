#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Mob' );
	use_ok( 'Mob::Protocol' );
	use_ok( 'Mob::Protocol::Packet' );
}

diag( "Testing Mob $Mob::VERSION, Perl $], $^X" );

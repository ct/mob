############################################################
#### Mob::Protocol
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Protocol;
our $VERSION = '1.00';

use strict;
use Moose;

has foo => (
	isa => 'Str',
	is  => 'ro',	
	default =>  sub { carp "Inside, setting foo"; "value" }, 
);



1; # End of Mob::Protocol

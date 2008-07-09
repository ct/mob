############################################################
#### Mob::Service::Core::Config
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Core::Config;
our $VERSION = '1.00';

use strict;
use Moose;

has foo => (
	isa => 'Str',
	is  => 'ro',	
	default =>  sub { warn "Inside Mob::Service::Core::Config, setting foo"; 
					"value" }, 
);



1; # End of Mob::Service::Core::Config

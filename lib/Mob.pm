############################################################
#### Mob.pm
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob;
our $VERSION = '1.00';

use strict;
use MooseX::POE;
use MooseX::AttributeHelpers;
use POSIX qw(uname);

use Mob::Service::Core::Config;
use Mob::Service::Core::Backchannel::XMPP;

has hostname => (
		isa     => "Str",
		is      => 'rw',
		default => sub { (uname)[1] }
	);

has _pid => (
		isa     => "Int",
		is      => 'ro',
		default => sub { $$ }, # PID
	);

has name => (
		isa     => "Str",
		is      => 'rw',
		default => sub { "Unruly" }
	);

has _identifier => (
		isa     => 'Str',
		is      => 'ro',
#		default =>  sub { $self->hostname . "-" .
#						$self->_pid . "-" .
#						$self->name }, 
	);

has _description => (
		isa     => "Str",
		is      => 'rw',
#		default => sub { "Mob: " . $self->role . 
#						 " [" . $self->hostname . "] " .
#						 $VERSION 
#						}
	);

has services => (
    metaclass  => 'Collection::Hash',
    isa        => 'HashRef',
    is         => 'ro',
    default    => sub { { 
							"core_conf" => Mob::Service::Core::Config->new(),
							"core_backchannel" => Mob::Service::Core::Backchannel::XMPP->new(),
						} },
						
	provides  => {
	    'set'    => 'set_option',
	    'get'    => 'get_option',            
	    'empty'  => 'has_options',
	    'count'  => 'num_options',
	    'delete' => 'delete_option',
	}

);

no MooseX::POE;
1; # End of Mob

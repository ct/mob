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

has pid => (
		isa     => "Int",
		is      => 'ro',
		default => sub { $$ }, # PID
	);

has name => (
		isa     => "Str",
		is      => 'rw',
		default => sub { "Unruly" }
	);

has identifier => (
		isa     => 'Str',
		is      => 'ro',
		lazy_build => 1,
	);

sub _build_identifier { 
	my ($self) = shift;
	
	$self->hostname . "-" .
	$self->pid . "-" .
	$self->name 
} 


has description => (
		isa        => "Str",
		is         => 'rw',
		lazy_build => 1,
	);

sub _build_description { 
	my ($self) = shift;
	
	"Mob: " . $self->role . " [" . $self->hostname . "] " . $self::VERSION; 
}


has backchannel_auth => (
	isa => 'HashRef',
	is  => 'ro',	
	required => 1,
);

has registry_file => (
	isa => 'Str',
	is  => 'ro',	
	default =>  sub { "" }, 
);

has services => (
    metaclass  => 'Collection::Hash',
    isa        => 'HashRef',
    is         => 'ro',
	lazy_build => 1,
	provides  => {
	    'set'    => 'add_service',
	    'get'    => 'get_service',            
	    'delete' => 'delete_service',
	}

);

sub _build_services { 
	my ($self) = shift;
	
	$self->add_service("core_conf", 
						Mob::Service::Core::Config
						->new({
							"name"          => $self->name,
							"registry_file" => $self->registry_file,
							"mob_object"    => $self,
							})
					   );
	
	$self->add_service("core_backchannel", 
						Mob::Service::Core::Backchannel::XMPP
						->new({
							"resource" => $self->identifier,
							"auth"    => $self->backchannel_auth,
							"mob_object"    => $self,
							})
						);
}

no MooseX::POE;
1; # End of Mob

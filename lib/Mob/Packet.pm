############################################################
#### Mob::Packet
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Packet;
our $VERSION = '1.00';

use Moose;
use Data::UUID;
use Time::HiRes;

has packetID => (
    isa     => 'Str',
    is      => 'ro',
    default => sub { lc( Data::UUID->new->create_str() ); },
);

has created => (
    isa     => 'Num',
    is      => 'ro',
    default => sub { Time::HiRes::time; }
);

has sender => (
    isa => 'Str',
    is  => 'rw',
);

has recipient => (
    isa => 'Maybe[Str]',
    is  => 'ro',
);

has senderStore => (
    isa => 'HashRef',
    is  => 'rw',
);

has payload => (
    isa => 'HashRef',
    is  => 'rw',
);

has event_name => (
    isa => 'Str',
    is  => 'ro',
);

has routing_constraint => (
    isa       => 'Maybe[Bool]',
    is        => 'rw',
    predicate => 'route_locally',
    reader    => 'only_route_locally',
    default   => sub { 0 },
    clearer   => 'skip_local_routing',
);

sub dump {
	my ($self) = @_;
	
	my $hashref = {};
	foreach (keys %{$self}){
		$hashref->{$_} =  $self->{$_}
	}
	
	return $hashref;
}


1;

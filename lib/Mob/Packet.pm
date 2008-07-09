############################################################
#### Mob::Packet
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Packet;
our $VERSION = '1.00';

use strict;
use Moose;

use JSON::Any;

has packetID => (
	isa => 'Int',
	is=> 'rw',
);

has URI => (
	isa => 'Str',
	is=> 'rw',
);

has created => (
	isa => 'Str',
	is=> 'rw',
);

has packetType => (
	isa => 'Int',
	is=> 'rw',
);

has sender => (
	isa => 'Str',
	is=> 'rw',
);

has recipient => (
	isa => 'Str',
	is=> 'rw',
);

has senderStore => (
	isa => 'HashRef',
	is=> 'rw',
);

has payload => (
	isa => 'HashRef',
	is => 'rw',
);

has cdata => (
	isa => 'Bool',
	is=> 'rw',
	default => 0,
);

has packetFields => (
        isa => 'ArrayRef',
        is => 'ro',
        default => qw(packetID URI created packetType sender
                        recipient senderStore payload),
);

sub create {
	my $self = shift;
	my $json = JSON::Any->new;
	
	my $packet = ();
	no strict "subs";
	
	foreach my $field ($self->packetFields) {
			$packet->{$field} =  $self->$field;
		}

        my $response = $json->objToJson($packet);
        if ($self->{cdata}) {
		$response = "<![CDATA[" . $response . "]]>";
	}
        return $response;
}

sub decode {
	my $self = shift;
	my $jsonpacket = shift;

	my $json = JSON::Any->new;

   # Always try to strip off CDATA
	$jsonpacket =~ s/^<![CDATA[(.*?)]]>$/$1/;

	my $packet = $json->jsonToObj($jsonpacket);

   ### if $self is a ref, this is an object call, use the packet to populate
	### the existing object, overwriting

	if (ref $self) {
		foreach my $field ($self->packetFields) {
			$self->$field($packet->{$field});
  		}
	} 
	### if it's not a ref, this is a class method call, use the packet to
	### create a new object.
	else 
	{
      $self = Mob::Packet->new($packet);
   }

	### Either way, we're returning a Mob::Packet object
   return $self;
}
1;

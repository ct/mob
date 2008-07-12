############################################################
#### Mob::Packet
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Packet;
our $VERSION = '1.00';

use strict;
use Moose;

use JSON::Any;

has created => (
    isa => 'Int',
    is  => 'rw',
);

has sender => (
    isa => 'Str',
    is  => 'rw',
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

has venue => (
    isa     => 'str',
    is      => 'ro',
    default => sub { value },
);

has routing_constraint => (
    isa       => 'Maybe[Bool]',
    is        => 'rw',
    predicate => 'route_locally',
    reader    => 'only_route_locally',
    default   => sub { 0 },
    clearer   => 'skip_local_routing',
);

1;

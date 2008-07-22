############################################################
#### Mob::Service
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service;
our $VERSION = '1.00';

use strict;
use Moose::Role;

use Mob::Packet;
use Data::Dumper;

use constant {
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

has mob_object => (
    isa      => 'Mob',
    is       => 'ro',
    required => 1,
    weaken   => 1,
);

sub dispatch_request {
    my ( $self, $args ) = @_;

    my $skip_local = delete $args->{_skip_local};
    my $reply      = delete $args->{reply};
    my $reply_to      = delete $args->{reply_to};

    my $packet = Mob::Packet->new(
        sender => $self->mob_object->mobID,
        %{$args},
    );

    if ( ($reply) and ( $reply_to ) ) {
        $packet->recipient( $reply_to );
    }

    if ($skip_local) {
        $packet->skip_local_routing;
    }

    $self->mob_object->handle_event($packet);

}

sub process_packet {
    my ( $self, $packet ) = @_;

    if ( my $method = $self->can( $packet->event_name ) ) {
        return $self->$method($packet);
    }
    return MOB_REQ_NOT_HANDLED;

}

no Moose::Role;
1;

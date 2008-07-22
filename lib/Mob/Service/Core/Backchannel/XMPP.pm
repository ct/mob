############################################################
#### Mob::Service::Core::Backchannel::XMPP
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Core::Backchannel::XMPP;
our $VERSION = '1.00';

use strict;
use MooseX::POE;

with qw(MooseX::POE::Aliased);
with 'Mob::Service';

use POE::Component::Jabber;
use POE::Component::Jabber::Error;
use POE::Component::Jabber::Status;
use POE::Component::Jabber::ProtocolFactory;
use POE::Filter::XML::Node;
use POE::Filter::XML::NS qw/ :JABBER :IQ /;
use JSON::Any;
use Data::Dumper;

use constant {
    DEBUG                => $ENV{MOB_DEBUG},
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

has xmpp => (
    isa        => 'POE::Component::Jabber',
    is         => 'ro',
    lazy_build => 1,
    handles    => {
        output_handler   => 'output_handler',
        return_to_sender => 'return_to_sender',
        shutdown         => 'shutdown',
        connect          => 'connect',
        reconnect        => 'reconnect',
        purge_queue      => 'purge_queue',
    }
);

has auth => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
);

has resource => (
    isa => 'Str',
    is  => 'ro',
);

has jid => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_jid {
    my ($self) = @_;
    $self->auth->{'USERNAME'} . "@" . $self->auth->{'HOSTNAME'};
}

sub _build_xmpp {
    my ($self) = @_;

    POE::Component::Jabber->new(
        IP             => $self->auth->{'IP'},
        Port           => $self->auth->{'PORT'},
        Hostname       => $self->auth->{'HOSTNAME'},
        Username       => $self->auth->{'USERNAME'},
        Password       => $self->auth->{'PASSWORD'},
        Resource       => $self->resource,
        Alias          => 'MOBPCJ',
        ConnectionType => XMPP,
        Debug          => +DEBUG,
        Stateparent    => $self->get_session_id,
        States         => {
            StatusEvent => 'status_event',
            InputEvent  => 'input_event',
            ErrorEvent  => 'error_event',
        }
    );
}

sub BUILD {
    my ($self) = @_;
    $self->mob_object->mobID( $self->jid . "/" . $self->resource );
}

sub START {
    my ( $self, $heap ) = @_[ OBJECT, HEAP ];
    $self->xmpp;
    $poe_kernel->post( "MOBPCJ", "connect" );
}

sub send_node {
    my ( $self, $node ) = @_;

    $poe_kernel->post( "MOBPCJ", "output_handler", $node );
}

event set_presence => sub {
    my ( $self, $type, $status, $heap ) = @_[ OBJECT, ARG0, ARG1, HEAP ];

    my $n = POE::Filter::XML::Node->new('presence');

    if ( $type ne "present" ) {
        $n->insert_tag('show')->data($type);
    }
    if ($status) {
        $n->insert_tag('status')->data($status);
    }
    $self->send_node($n);

};

event status_event => sub {
    my ( $self, $state ) = @_[ OBJECT, ARG0 ];

    if ( $state == PCJ_INIT_FINISHED ) {

        $poe_kernel->post( $self->get_session_id, 'purge_queue' );
        $self->yield( "set_presence", "present" );

        $self->mob_object->handle_event(
            Mob::Packet->new(
                {
                    routing_constraint => 1,
                    event_name         => 'startup_events',
                }
            )
        );
    }
};

event input_event => sub {
    my ( $self, $heap, $node ) = @_[ OBJECT, HEAP, ARG0 ];

    if (    ( $node->name() eq 'message' )
        and ( my $body = $node->get_tag('body')->data )
        and ( $node->attr('from') ne $self->mob_object->mobID ) )
    {
        $body =~ s/^<!\[CDATA\[(.*)]]>$/$1/;

        my $packet = Mob::Packet->new( %{ JSON::Any->jsonToObj($body) }, );

        $packet->routing_constraint(1);

		warn Dumper $packet;

        $self->mob_object->handle_event($packet);
    }

};

sub dispatch_request {
    my ( $self, $packet ) = @_;

    my $to = ( defined $packet->recipient ) ? $packet->recipient : $self->jid;

    my $n = POE::Filter::XML::Node->new('message');
    $n->attr( 'to',   $to );
    $n->attr( 'from', $self->jid . "/" . $self->resource );
    $n->attr( 'type', 'chat' );
    $n->insert_tag('body')
      ->rawdata( "<![CDATA[" . JSON::Any->objToJson( $packet->dump ) . "]]>" );

    $self->send_node($n);

}

event error_event => sub {
    my ( $self, $heap, $node ) = @_[ OBJECT, HEAP, ARG0 ];
    print "XMPP: ErrorEvent\n";
    print $node->to_str() . "\n";
};

sub startup_events {
    my ($self) = @_;

    return MOB_REQ_HANDLED;
}

no MooseX::POE;
1;    # End of Mob::Service::Core::Backchannel::XMPP

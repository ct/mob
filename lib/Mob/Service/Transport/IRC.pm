############################################################
#### Mob::Service::Transport::IRC
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Transport::IRC;
our $VERSION = '1.00';

use strict;
use MooseX::POE::Role;

use POE::Component::IRC::Common qw( :ALL );
use POE::Component::IRC::Plugin qw( :ALL );
use POE::Component::IRC::State;

with 'Mob::Service';

use constant {
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

has nick => (
    metaclass => 'MooseX::Getopt::Meta::Attribute',
    cmd_flag  => 'nickname',
    isa       => 'Str',
    is        => 'rw',
    default   => sub { 'Mob' . int( rand(1000) ) },
);

has server => (
    metaclass => 'MooseX::Getopt::Meta::Attribute',
    cmd_flag  => 'server',
    isa       => 'Str',
    is        => 'ro',
    default   => 'irc.perl.org',
);

has port => (
    metaclass => 'MooseX::Getopt::Meta::Attribute',
    cmd_flag  => 'port',
    isa       => 'Int',
    is        => 'rw',
    default   => '6667',
);

has channels => (
    metaclass => 'MooseX::Getopt::Meta::Attribute',
    cmd_flag  => 'channels',
    isa       => 'ArrayRef',
    is        => 'rw',
    default   => sub { [qw(#mobbots)] },
);

has _owner => (
    accessor  => 'owner',
    metaclass => 'MooseX::Getopt::Meta::Attribute',
    cmd_flag  => 'owner',
    isa       => 'Str',
    is        => 'rw',
    default   => 'mob!mob@mob.x4.net',
);

has _irc => (
    isa        => 'POE::Component::IRC',
    is         => 'rw',
    accessor   => 'irc',
    lazy_build => 1,
    handles    => {
        irc_session_id => 'session_id',
        server_name    => 'server_name',
        plugin_add     => 'plugin_add',
    }
);

sub _build__irc {
    my ($self) = @_;
    POE::Component::IRC::State->spawn(
        Nick    => $_[0]->nick,
        Server  => $_[0]->server,
        Port    => $_[0]->port,
        Ircname => $_[0]->nick,
        Options => { trace => 0 }
    );
}

sub test_channel {
    my ( $self, $channel ) = @_;

    foreach ( @{ $self->channels } ) {
        if ( $_ eq $channel ) {
            return 1;
        }
    }
    return 0;
}

sub test_user {
    my ( $self, $user ) = @_;

    return 1;
}

sub privmsg {
    my $self = shift;
    POE::Kernel->post( $self->irc_session_id => privmsg => @_ );
}

sub START {
    my ( $self, $heap ) = @_[ OBJECT, HEAP ];

    $poe_kernel->post( $self->irc_session_id => register => 'all' );
    $poe_kernel->post( $self->irc_session_id => connect  => {} );

    return;
}

event irc_connected => sub {
    my ( $self, $sender ) = @_[ OBJECT, SENDER ];

    # In any irc_* events SENDER will be the PoCo-IRC session
    for ( @{ $self->channels } ) {
        POE::Kernel->post( $sender => join => $_ );
    }
    return;
};

sub mob_irc_say_public {
    my ( $self, $packet ) = @_;
    if (    ( $packet->sender_store->{server} eq $self->server )
        and ( $self->test_channel( $packet->sender_store->{channel} ) ) )
    {
        $self->privmsg(
            $packet->sender_store->{channel},
            $packet->payload->{line},
        );
        return MOB_REQ_HANDLED_LAST;
    }

    return MOB_REQ_NOT_HANDLED;
}

sub mob_irc_privmsg {
    my ( $self, $packet ) = @_;

    if (    ( $packet->sender_store->{server} eq $self->server )
        and ( $self->test_user( $packet->sender_store->{nick} ) ) )
    {
        $self->privmsg(
            $packet->sender_store->{nick},
            $packet->payload->{line},
        );
        return MOB_REQ_HANDLED_LAST;
    }

}

sub startup_events {
    my ($self) = @_;

    return MOB_REQ_HANDLED;
}

1;    # End of Mob::Service::Transport::IRC

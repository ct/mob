############################################################
#### Mob::Service::Transport::AIM
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Transport::AIM;
our $VERSION = '1.00';

use strict;
use MooseX::POE;
use Data::Dumper;

use POE::Component::OSCAR;
with 'Mob::Service';

use constant {
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

has screen_name => (
    metaclass => 'MooseX::Getopt::Meta::Attribute',
    isa       => 'Str',
    is        => 'ro',
);

has password => (
    metaclass => 'MooseX::Getopt::Meta::Attribute',
    isa       => 'Str',
    is        => 'ro',
);

has owner => (
    accessor  => 'owner',
    metaclass => 'MooseX::Getopt::Meta::Attribute',
    cmd_flag  => 'owner',
    isa       => 'Str',
    is        => 'rw',
    default   => 'cthompsondotcom',
);

has aim => (
    isa     => 'POE::Component::OSCAR',
    is      => 'rw',
    default => sub { POE::Component::OSCAR->new( throttle => 4 ) },
);

sub START {
    my ( $self, $heap ) = @_[ OBJECT, HEAP ];

    $self->aim->set_callback( signon_done => 'signon_complete' );
    $self->aim->set_callback( im_in       => 'mesg_received' );
    $self->aim->set_callback( error       => 'error' );
    $self->aim->set_callback( admin_error => 'admin_error' );
    $self->aim->set_callback( rate_alert  => 'rate_alert' );

    $self->aim->loglevel(5);

    return;
}

event signon_complete => sub {
    my ( $self, $sender ) = @_[ OBJECT, SENDER ];

    warn "AIM: signon_complete";

    return;
};

event error => sub {
    my $args = $_[ARG1];
    my ( $object, $connection, $error, $description, $fatal ) = @$args;
    warn("AIM: ERROR $error / $description / $fatal");

};

event admin_error => sub {
    my $args = $_[ARG1];
    my ( $object, $reqtype, $error, $errval ) = @$args;
    warn("ADMIN ERROR: $reqtype / $error / $errval");
};

event rate_alert => sub {
    my $args = $_[ARG1];
    my ( $object, $level, $clear, $window, $worrisome ) = @$args;
    warn("RATE ALERT: $level / $clear / $window / $worrisome");
};

event mesg_received => sub {
    my ( $self, $args ) = @_[ OBJECT, ARG1 ];
    my ( $object, $who, $what, $away ) = @$args;

    $what =~ s|^<html>||i;
    $what =~ s|</html>$||i;

    warn "AIM: mesg_received\nReceived from $who: $what";

    $self->dispatch_request(
        {
            sender_store => {
                nick    => $who->stringify,
                channel => "",
            },
            reply_event => "aim_send_message",
            reply_to    => $self->mob_object->mobID,
            event_name  => 'mob_irc_bot_addressed',
            payload     => { line => $what, },
        }
    );

};

sub aim_send_message {
    my ( $self, $packet ) = @_;

    $self->aim->send_im(
        $packet->sender_store->{nick},
        $packet->sender_store->{payload}->{line},
    );

    return MOB_REQ_HANDLED_LAST;

}

sub startup_events {
    my ($self) = @_;

    warn "AIM send_startup_events";

    $self->aim->signon(
        screenname => $self->screen_name,
        password   => $self->password,
    );

    return MOB_REQ_HANDLED;
}

1;    # End of Mob::Service::Transport::IRC

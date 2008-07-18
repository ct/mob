############################################################
#### MyIRC
#### v1.00
#### (C)2008 Christopher A. Thompson

package MyIRC;
our $VERSION = '1.00';

use strict;
use Moose;
with 'Mob::Service';
use Data::Dumper;

use constant {
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

sub mob_irc_bot_addressed {
    my ( $self, $packet ) = @_;

    #print Dumper $packet;

    my $event_name = 'mob_irc_say_public';

    if ( $packet->sender_store->{channel} eq "PRIVMSG" ) {
        $event_name = 'mob_irc_privmsg';
    }

    my $line = $packet->payload->{line};
    my $response;

    if ( $line =~ /^time/ ) {
        $response =
          $packet->sender_store->{nick} . ", the time is " . localtime;
    }
    elsif ( $line =~ /^foo/ ) {
        $response = $packet->sender_store->{nick} . ", bar";
    }

    warn "MyIRC: mob_irc_bot_addressed - " . $event_name;

    if ($response) {
        $self->dispatch_request(
            {
                sender_store => $packet->sender_store,
                event_name   => $event_name,
                payload      => { line => $response, },
            }
        );
    }
    return MOB_REQ_HANDLED;

}

sub startup_events {
    my ($self) = @_;

    warn "MyIRC: startup_events";

    return MOB_REQ_HANDLED;
}

1;    # End of Mob::Service::Core::Config

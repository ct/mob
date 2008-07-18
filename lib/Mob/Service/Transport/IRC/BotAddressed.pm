############################################################
#### Mob::Service::Transport::IRC::BotAddressed
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Transport::IRC::BotAddressed;
our $VERSION = '1.00';

use strict;
use MooseX::POE;
use POE::Component::IRC::Common qw( :ALL );
use POE::Component::IRC::Plugin qw( :ALL );

with 'Mob::Service';
with "Mob::Service::Transport::IRC";

use constant {
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

has command_chars => (
    isa     => 'ArrayRef',
    is      => 'ro',
    default => sub { [qw( ! . )] },
);

event irc_msg => sub {
	my ( $self, $who, $recipient, $what ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
    my $me = $self->nick;

    $self->yield( irc_bot_addressed => $who => [qw(PRIVMSG)] => $what );
    
};

event irc_public => sub {
    my ( $self, $who, $channels, $what ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
    my $me = $self->nick;

    warn "BotAddressed: $who, $channels, $what, $me";

	$what =~ m/^\s*\Q$me\E[:,;.!?]?\s*(.*)$/i;
	my $cmd = $1;
	
    if ( ! $cmd ) {
        foreach ( @{ $self->command_chars } ) {
			warn "BotAddressed checking command_chars: $_";
            $what =~ m/^\Q$_\E(.*)$/i;
			$cmd = $1;
        }
    }

    warn "BotAddressed: CMD - $cmd";

    return PCI_EAT_NONE if !defined $cmd && $what !~ /$me/i;

    for my $channel ( @{$channels} ) {
        if ( defined $cmd ) {
            $self->yield( irc_bot_addressed => $who => [$channel] => $cmd );
        }
        else {
            $self->yield( irc_bot_mentioned => $who => [$channel] => $what );
        }
    }
};

event irc_bot_addressed => sub {
    my ($self) = $_[0];
    warn "bot addressed, dispatching";
    $self->dispatch_request(
        {
            sender_store => {
                nick    => ( split /!/, $_[ARG0] )[0],
                channel => $_[ARG1]->[0],
                server  => $self->server,
            },
            event_name => 'mob_irc_bot_addressed',
            payload    => { line => $_[ARG2], },
        }
    );

};

event irc_bot_mentioned => sub {
    my ($nick)    = ( split /!/, $_[ARG0] )[0];
    my ($channel) = $_[ARG1]->[0];
    my ($what)    = $_[ARG2];

    print
      "$nick mentioned my name in channel $channel with the message '$what'\n";
};

sub startup_events {
    my ($self) = @_;
    warn "BotAddressed: startup_events";

 ##   $self->plugin_add( 'BotAddressed',
  #      POE::Component::IRC::Plugin::BotAddressed->new() );

    return MOB_REQ_HANDLED;
}

1;    # End of Mob::Service::Transport::IRC

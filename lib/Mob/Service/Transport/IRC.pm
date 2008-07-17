############################################################
#### Mob::Service::Transport::IRC
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Transport::IRC;
our $VERSION = '1.00';

use strict;
use MooseX::POE;
use POE::Component::IRC;

with 'Mob::Service';

use Data::Dumper;

use constant {
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

sub send_startup_events {
    my ($self) = @_;

    return MOB_REQ_HANDLED;
}

1;    # End of Mob::Service::Transport::IRC

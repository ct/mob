############################################################
#### Mob.pm
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob;
our $VERSION = '1.00';

use strict;
use MooseX::POE;
use MooseX::AttributeHelpers;
use POSIX qw(uname);
use constant {
    DEBUG                => $ENV{MOB_DEBUG},
    NO_BACKCHANNEL       => $ENV{MOB_SKIP_BACKCHANNEL},
    FORCE_BACKCHANNEL    => $ENV{MOB_FORCE_BACKCHANNEL},
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

use File::HomeDir;
use JSON::Any;
use Data::Dumper;

use Mob::Packet;
use Mob::Service::Core::Backchannel::XMPP;

has hostname => (
    isa     => "Str",
    is      => 'rw',
    default => sub { (uname)[1] }
);

has pid => (
    isa     => "Int",
    is      => 'ro',
    default => sub { $$ },    # PID
);

has heap => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
);

has name => (
    isa     => "Str",
    is      => 'rw',
    default => sub { "Unruly" }
);

has identifier => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_identifier {
    my ($self) = shift;

    $self->hostname . "-" . $self->pid . "-" . $self->name;
}

has mobID => (
    isa        => 'Str',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_mobID {
    my ($self) = @_;

    if ( ( !NO_BACKCHANNEL ) and ( !$self->no_backchannel ) ) {
        $self->services->{core_backchannel}->jid . "/" . $self->identifier;
    }
    else {
        $self->identifier;
    }

}

has no_backchannel => (
    isa     => 'Bool',
    is      => 'ro',
    default => 0,
);

has description => (
    isa        => "Str",
    is         => 'rw',
    lazy_build => 1,
);

sub _build_description {
    my ($self) = shift;

    "Mob: " . $self->name . " [" . $self->hostname . "] " . $VERSION;
}

has no_backchannel => (
    isa     => 'Str',
    is      => 'ro',
    default => sub { 0 },
);

has backchannel_auth => (
    isa => 'HashRef',
    is  => 'ro',
);

has registry_file => (
    isa     => 'Str',
    is      => 'ro',
    default => sub { "registry" },
);

has services => (
    metaclass  => 'Collection::Hash',
    isa        => 'HashRef',
    is         => 'ro',
    lazy_build => 1,
    provides   => {
        'set'    => 'add_service',
        'get'    => 'get_service',
        'delete' => 'delete_service',
      }

);

sub _build_services { {}; }

has registry => (
    isa        => 'HashRef',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_registry {
    my ($self) = @_;

    my $homedir  = File::HomeDir->my_home;
    my $mobdir   = $homedir . "/.mob/";
    my $filename = $mobdir . $self->registry_file;

    if ( -e $filename ) {
        open( FH, $filename );
        local $/;
        $self->registry( JSON::Any->jsonToObj(<FH>) );
        close FH;

    }

}

sub BUILD {
    my ($self) = shift;

    $0 = $self->description;

    if (   (FORCE_BACKCHANNEL)
        or ( ( !NO_BACKCHANNEL ) and ( !$self->no_backchannel ) ) )
    {
        $self->add_service(
            "core_backchannel",
            Mob::Service::Core::Backchannel::XMPP->new(
                {
                    "resource"   => $self->identifier,
                    "auth"       => $self->backchannel_auth,
                    "mob_object" => $self,
                }
            )
        );
    }
    else {
        $self->handle_event(
            Mob::Packet->new(
                {
                    routing_constraint => 1,
                    event_name         => 'startup_events',
                }
            )
        );
    }
}

sub handle_event {
    my ( $self, $packet ) = @_;
    my $found_local = 0;

    if ( $packet->route_locally ) {
        foreach my $svc ( keys %{ $self->services } ) {
            my $result = $self->services->{$svc}->process_packet($packet);
            if ( $result == MOB_REQ_HANDLED ) {
                $found_local++;
                next;
            }
            elsif ( $result == MOB_REQ_NOT_HANDLED ) {
                next;
            }
            elsif ( $result == MOB_REQ_HANDLED_LAST ) {
                $found_local++;
                last;
            }
        }

    }

    #print "Mob.pm: handle_event\n" . Dumper $packet;

    if (   ( !$packet->only_route_locally )
        && ( !$found_local )
        && ( !NO_BACKCHANNEL )
        && ( $self->mobID eq $packet->sender ) )
    {
        $self->services->{'core_backchannel'}->dispatch_request($packet);
    }

}

no MooseX::POE;
1;    # End of Mob

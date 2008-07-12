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
    DEBUG             => $ENV{MOB_DEBUG},
    NO_BACKCHANNEL    => $ENV{MOB_SKIP_BACKCHANNEL},
    FORCE_BACKCHANNEL => $ENV{MOB_FORCE_BACKCHANNEL},
};

use Mob::Packet;
use Mob::Service::Core::Config;
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

    "Mob: " . $self->role . " [" . $self->hostname . "] " . $self::VERSION;
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
    default => sub { "" },
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

sub BUILD {
    my ($self) = shift;

    $self->add_service(
        "core_conf",
        Mob::Service::Core::Config->new(
            {
                "name"          => $self->name,
                "registry_file" => $self->registry_file,
                "mob_object"    => $self,
            }
        )
    );

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
}

sub handle_event {
    my ( $self, $packet ) = @_;
    my $found_local = 0;

    if ( $packet->route_locally ) {
        foreach my $svc ( keys %{ $self->services } ) {
            if ( my $method =
                $self->services->{$svc}->can( $packet->event_name ) )
            {
				$found_local++;
                $self->services->{$svc}->$method($packet);
            }
        }
    }

	if ((!$packet->only_route_locally) && (!$found_local)) {
		# body...
	}
	
}

no MooseX::POE;
1;    # End of Mob

############################################################
#### Mob::Service::Core::Config
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Core::Config;
our $VERSION = '1.00';

use strict;
use Moose;
with 'Mob::Service';

use File::HomeDir;
use JSON::Any;
use Data::Dumper;

use constant {
    MOB_REQ_HANDLED      => 0,
    MOB_REQ_NOT_HANDLED  => 1,
    MOB_REQ_HANDLED_LAST => 2,
};

has registry => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
);

has registry_file => (
    isa     => 'Str',
    is      => 'rw',
    default => sub { },
);

sub BUILD {
    my ($self) = @_;

    $self->registry_file( $self->mob_object->registry_file );

    my $homedir  = File::HomeDir->my_home;
    my $mobdir   = $homedir . "/.mob/";
    my $filename = $mobdir . $self->registry_file;

    if ( -e $filename ) {
        $self->load_from_file($filename);
    }
    else {
        warn "No config saved locally.";
        if ( !-d $mobdir ) {
            mkdir $mobdir;
        }
        $self->save_to_file($filename);
    }
}

sub load_from_file {
    my ( $self, $filename ) = @_;

    open( FH, $filename );
    local $/;
    $self->registry( JSON::Any->jsonToObj(<FH>) );
    close FH;
}

sub save_to_file {
    my ( $self, $filename ) = @_;
    open( FH, ">$filename" );
    print FH JSON::Any->objToJson( $self->registry );
    close FH;
}

sub announce_config_version {
    my ( $self, $packet ) = @_;

    print $packet->sender
      . ' has config version '
      . $packet->payload->{version} . "\n";
    print "I have config version " . $self->registry->{_confver} . "\n";
    if ( $packet->payload->{version} > $self->registry->{_confver} ) {
        print "I would totally hit that\n";
    }
    else {
        print "I'm cool\n";
    }
}

sub send_startup_events {
    my ($self) = @_;

    $self->dispatch_request(
        {
            _skip_local => 1,
            event_name  => "announce_config_version",
            payload     => { version => $self->registry->{_confver}, },
        }
    );

    return MOB_REQ_HANDLED;
}

1;    # End of Mob::Service::Core::Config

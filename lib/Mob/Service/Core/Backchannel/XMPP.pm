############################################################
#### Mob::Service::Core::Backchannel::XMPP
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Core::Backchannel::XMPP;
our $VERSION = '1.00';

use strict;
use MooseX::POE;
use Data::Dumper;

use POE::Component::Jabber;
use POE::Component::Jabber::Error;
use POE::Component::Jabber::Status;
use POE::Component::Jabber::ProtocolFactory;
use POE::Filter::XML::Node;
use POE::Filter::XML::NS qw/ :JABBER :IQ /;


has xmpp => (
    isa        => 'POE::Component::Jabber',
    is         => 'ro',
	lazy_build => 1,
	handles    => {
		output_handler => 'output_handler',
		return_to_sender    => 'return_to_sender',
		shutdown => 'shutdown',
		connect => 'connect',
		reconnect => 'reconnect',
		purge_queue => 'purge_queue',
	}
);

sub _build_xmpp {
POE::Component::Jabber->new(
		IP => 'orb.x4.net',
		Port => '5222',
		Hostname => 'x4.net',
		Username => 'backchannel',
		Password => 'XXXXX',
		Alias => 'PCJ',
		ConnectionType => XMPP,                                                
		Debug => '1',
		Stateparent => $_[0]->get_session_id,
		States => {
			StatusEvent => 'status_event',
			InputEvent => 'input_event',
			ErrorEvent => 'error_event',
		}                                        
);
}

sub START {
    my ( $self, $heap ) = @_[ OBJECT, HEAP ];
	warn "START";
	$poe_kernel->post("PCJ", "connect");
}

event set_presence => sub {
	my ( $self, $type, $status, $heap) = @_[ OBJECT, ARG0, ARG1, HEAP ];

	my $n = POE::Filter::XML::Node->new('presence');

	if ($type ne "present") {
	        $n->insert_tag('show')->data($type);
	}
    if ($status) {
		$n->insert_tag('status')->data($status);
	}
	
    $poe_kernel->post( $self->get_session_id, "output_handler", $n );
};

event status_event => sub {
    my ( $self, $state) = @_[ OBJECT, ARG0 ];
	warn "XMPP: status_event $state";
	
	if($state == PCJ_INIT_FINISHED)
    {
		$poe_kernel->post($self->get_session_id, 'purge_queue');
		$self->yield("set_presence", "present");
	}
};

event input_event => sub {
    my ( $self, $heap, $node ) = @_[ OBJECT, HEAP, ARG0 ];
	print "XMPP: InputEvent\n";
	print $node->to_str() .  "\n";
};

event error_event => sub {
    my ( $self, $heap, $node ) = @_[ OBJECT, HEAP, ARG0 ];
	print "XMPP: ErrorEvent\n";
	print $node->to_str() .  "\n";
};


no MooseX::POE;
1; # End of Mob::Service::Core::Backchannel::XMPP

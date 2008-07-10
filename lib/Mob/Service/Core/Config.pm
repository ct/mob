############################################################
#### Mob::Service::Core::Config
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service::Core::Config;
our $VERSION = '1.00';

use strict;
use Moose;
with 'Mob::Service';

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

use File::HomeDir;

has registry => (
	isa => 'HashRef',
	is  => 'ro',	
	lazy_build => 1,
);

sub _build_registry {
	my $filename = File::HomeDir->my_home . "/.mob/config";

	my $c;
	
	if (-e $filename) {
		$c = $_[0]->load($filename);
	} else {
		warn "No config saved locally.";
		$c = undef;
	}
	
	return $c;
}

1; # End of Mob::Service::Core::Config

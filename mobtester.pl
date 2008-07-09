use lib "./lib";

use Mob;
use Data::Dumper;

my $mob = Mob->new();
my $xmpp = $mob->services->{'core_backchannel'}->xmpp;
#print Dumper $mob;

POE::Kernel->run();

############################################################
#### Mob::Service
#### v1.00
#### (C)2008 Christopher A. Thompson

package Mob::Service;
our $VERSION = '1.00';

use strict;
use Moose::Role;

has mob_object => (
    isa      => 'Mob',
    is       => 'ro',
    required => 1,
    weaken   => 1,
);

no Moose::Role;
1;

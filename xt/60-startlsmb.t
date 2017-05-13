#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

system("utils/test/Is_LSMB_running.sh");
ok( $? == 0, "LSMB started");

done_testing;

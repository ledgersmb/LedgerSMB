#!/usr/bin/perl
#
# t/97-pod.t
#
# Checks POD syntax.
#

use strict;
use warnings;

use Test::More;
plan skip_all => "POD_TESTING missing" if ! $ENV{POD_TESTING};

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok(all_pod_files('lib'));

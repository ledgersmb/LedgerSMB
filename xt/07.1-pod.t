#!/usr/bin/perl
#
# xt/07-pod.t
#
# Checks POD syntax.
#

use strict;
use warnings;

use Test2::Require::Module 'Test::Pod' => '1.00';
use Test::Pod;

all_pod_files_ok(all_pod_files('old', 'lib', 't', 'xt'));

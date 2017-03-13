#!/usr/bin/perl

no lib '.';
use FindBin;
BEGIN {
  unshift @INC, $FindBin::Bin
      unless grep(@INC, $FindBin::Bin) || $ENV{mod_perl}
}
require 'lsmb-request.pl';

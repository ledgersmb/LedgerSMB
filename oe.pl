#!/usr/bin/perl

no lib '.';
use FindBin;
BEGIN {
  unshift @INC, $FindBin::Bin
      unless grep($_ eq $FindBin::Bin, @INC) || $ENV{mod_perl}
}
require "old-handler.pl";

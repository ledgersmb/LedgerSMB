#!/usr/bin/perl

use FindBin;
BEGIN {
  lib->import($FindBin::Bin) unless $ENV{mod_perl}
}
require "old-handler.pl";

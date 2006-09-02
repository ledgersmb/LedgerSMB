#!/usr/bin/perl

# Simple script.  Right now, all that needs to be done is that the SL directory
# needs to be deleted and the sql-ledger.conf needs to be renamed.

open (SL, "< sql-ledger.conf");
open (LS, "> ledger-smb.conf");

while ($line = <SL>){
  print LS $line;
}

unlink sql-ledger.conf;

#TODO:  Move/Delete the SL directory

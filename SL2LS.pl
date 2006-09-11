#!/usr/bin/perl

# Simple script.  Right now, all that needs to be done is that the SL directory
# needs to be deleted and the sql-ledger.conf needs to be renamed.

$filedie = "To install manually:
rename the sql-ledger.conf to ledger-smb.conf
Delete the SL directory (optional but HIGHLY recommended)\n";
open (SL, "< sql-ledger.conf") || die (
"Could not open ledger-smb.conf: $! \n $filedie");
open (LS, "> ledger-smb.conf") || die (
"Could not open ledger-smb.conf: $! \n $filedie");

while ($line = <SL>){
  print LS $line;
}

unlink "sql-ledger.conf";

#TODO:  Move/Delete the SL directory

&recursive_unlink("SL");

sub recursive_unlink {
	($dir) = shift @_;
	print "Recursively deleting $dir\n";
	opendir (DIR, $dir);
	while ($file = readdir DIR){
		if ($file !~ /^\.+$/){
			$file = "$dir/$file";
			if (-f $file){
				unlink $file;
			} elsif (-d $file){
				&recursive_unlink("$file");
			}
		}
	}
	closedir(DIR);
	print "Removing $dir\n"; 
	rmdir $dir;
}

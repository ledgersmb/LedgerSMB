#!/usr/bin/perl
#
######################################################################
# LedgerSMB Small Medium Business Accounting Software Installer

# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed 
# under the GNU General Public License version 2 or, at your option, any later 
# version.  For a full list including contact information of contributors, 
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (c) 2002, Dieter Simader
#
#     Web: http://www.sql-ledger.org
#
#######################################################################

# Next bunch of lines are to check to see if they have the cpan module installed.
my $cpan=0;
eval {
  use CPAN;
};
if (!$@){
  $cpan = 1;
}

$| = 1;

if ($ENV{HTTP_USER_AGENT}) {
  print "
This does not work yet!
use $0 from the command line";
  exit;
}

# Make sure they have the required perl modules installed.
my @req_modules=(qw(DBI 
	DBD::Pg 
));
foreach my $module(@req_modules){
  print "Checking for: $module ...\t";
  my @results=&check_module($module);
  print "$results[1]\n";
  next if($results[0]); # Passed, no need to continue..
  if ($cpan == 1){
    # Can try to install the module..
    print "\n\nWould you like to try and install this package ($module) through CPAN? (Y/N) [Y]:";
    $response=<STDIN>;
    if(($response=~/y/i) or ($response eq "\n")){
      my $inst_obj = CPAN::Shell->install($module);
      @results=&check_module($module);
      if(!$results[0]){
	      print "\n\nCould not install $module using CPAN.\n";
	      die "Please try to install this module manually\n";
      }	
    } else {
      die "Please install the $module perl module and retry the setup.\n";
    }
  } else {
    # Can't try to install the module..
    die "Please install the $module perl module and retry the setup.\n";
  }
}

$lynx = `lynx -version`;      # if LWP is not installed use lynx
$gzip = `gzip -V 2>&1`;            # gz decompression utility
$tar = `tar --version 2>&1`;       # tar archiver
$latex = `latex -version`;

%checkversion = ( www => 3, abacus => 4, pluto => 5, neptune => 8 );

%source = (
	    1 => { url => "http://voxel.dl.sourceforge.net/sourceforge/ledger-smb", site => "New York, U.S.A", locale => 'us' },
            2 => { url => "http://easynews.dl.sourceforge.net/sourceforge/ledger-smb", site => "Arizona, U.S.A", locale => 'us' },
	    3 => { url => "http://ufpr.dl.sourceforge.net/sourceforge/ledger-smb", site =>"Brazil", locale => 'br' },
	    4 => { url => "http://surfnet.dl.sourceforge.net/sourceforge/ledger-smb", site => "The Netherlands", locale => 'nl' },
	    5 => { url => "http://http://kent.dl.sourceforge.net/sourceforge/ledger-smb", site => "U.K", locale => 'uk' },
	    6 => { url => "http://ovh.dl.sourceforge.net/sourceforge/ledger-smb", site => "France", locale => 'fr' },
	    7 => { url => "http://mesh.dl.sourceforge.net/sourceforge/ledger-smb", site => "Germany", locale => 'de' },
	    8 => { url => "http://citkit.dl.sourceforge.net/sourceforge/ledger-smb", site => "Russia", locale => 'ru' },
	    9 => { url => "http://optusnet.dl.sourceforge.net/sourceforge/ledger-smb", site => "Sydney, Australia", locale => 'au' },
	    10 => { url => "http://nchc.dl.sourceforge.net/sourceforge/ledger-smb", site => "Taiwan", locale => 'tw' },
	    11 => { url => "http://jaist.dl.sourceforge.net/sourceforge/ledger-smb", site => "Japan", locale => 'jp' },
	    12 => { url => "http://heanet.dl.sourceforge.net/sourceforge/ledger-smb", site => "Ireland", locale => 'ie' }
	  );

$userspath = "users";         # default for new installation

eval { require "ledger-smb.conf"; };

$filename = shift;
chomp $filename;

$newinstall = 1;

# is LWP installed
eval { require LWP::Simple; };
$lwp = !($@);

unless ($lwp || $lynx || $filename) {
  die "You must have either lynx or LWP installed or specify a filename.
perl $0 <filename>\n";
}

if ($filename) {
  # extract version
  die "Not a Ledger-SMB archive\n" if ($filename !~ /^ledger-smb/);
  
  $version = $filename;
  $version =~ s/ledger-smb-(\d+\.\d+\.\d+).*$/$1/;

}
  
if (-f "VERSION") {
  # get installed version from VERSION file
  open(FH, "VERSION");
  @a = <FH>;
  close(FH);
  $version = $a[0];
  chomp $version;

  $newinstall = !$version;

  if (! -f "ledger-smb.conf") {
    $newinstall = 1;
  }
}

$webowner = "nobody";
$webgroup = "nogroup";

if ($httpd = `find /etc /usr/local/etc -type f -name 'httpd.conf'`) {
  chomp $httpd;
  $webowner = `grep "^User " $httpd`;
  $webgroup = `grep "^Group " $httpd`;

  chomp $webowner;
  chomp $webgroup;
  
  ($null, $webowner) = split / /, $webowner;
  ($null, $webgroup) = split / /, $webgroup;

}

if ($confd = `find /etc /usr/local/etc -type d -name 'apache*/conf.d'`) {
  chomp $confd;
}

system("tput clear");

if ($filename) {
  $install = "\ninstall $version from (f)ile\n";
}

# check for latest version
&get_latest_version;
chomp $latest_version;

if (!$newinstall) {

  $install .= "\n(r)einstall $version\n";
  
}

if ($version && $latest_version) {
  if ($version lt $latest_version) {
    $install .= "\n(u)pgrade to $latest_version\n";
  }
}


$install .= "\n(i)nstall $latest_version (from Internet)\n" if $latest_version;

$install .= "\n(d)ownload $latest_version (no installation)" unless $filename;

  print qq|


               LedgerSMB Accounting and ERP Installation



$install


Enter: |;

$a = <STDIN>;
chomp $a;

exit unless $a;
$a = lc $a;

if ($a !~ /d/) {

  print qq|\nEnter httpd owner [$webowner] : |;
  $web = <STDIN>;
  chomp $web;
  $webowner = $web if $web;

  print qq|\nEnter httpd group [$webgroup] : |;
  $web = <STDIN>;
  chomp $web;
  $webgroup = $web if $web;
  
}

if ($a ne 'f') {
  system("tput clear");

  # choose site
  foreach $item (sort { $a <=> $b } keys %source) {
    $i++;
    print qq|$i. $source{$item}{site}\n|;
  }

  $site = "1";

  print qq|\nChoose Location [$site] : |;
  $b = <STDIN>;
  chomp $b;
  $site = $b if $b;
}

if ($a eq 'd') {
  &download;
}
if ($a =~ /(i|u)/) {
  &install_smb;
}
if ($a eq 'r') {
  $latest_version = $version;
  &install_smb;
}
if ($a eq 'f') {
  &install_smb;
}

exit;
# end main

sub check_module{
  my($module)=@_;
  eval "use $module";
  if(!$@){
	  return 1, "Ok";
  }else{
	  return 0, "FAILED",$@;
  }
}

sub download {

  &get_source_code;

}


sub get_latest_version {
  
  print "Checking for latest version number .... ";

  if ($filename) {
    print "skipping, filename supplied\n";
    return;
  }

  if ($lwp) {
    foreach $source (qw(pluto www abacus neptune)) {
      $url = $source{$checkversion{$source}}{url};
      print "\n$source{$checkversion{$source}}{site} ... ";

      $latest_version = LWP::Simple::get("$url/latest_version");
      
      if ($latest_version) {
	last;
      } else {
	print "not found";
      }
    }
  } else {
    if (!$lynx) {
      print "\nYou must have either lynx or LWP installed";
      exit 1;
    }

    foreach $source (qw(pluto www abacus neptune)) {
      $url = $source{$checkversion{$source}}{url};
      print "\n$source{$checkversion{$source}}{site} ... ";
      $ok = `lynx -dump -head $url/latest_version`;
      if ($ok = ($ok =~ s/HTTP.*?200 //)) {
	$latest_version = `lynx -dump $url/latest_version`;
	last;
      } else {
	print "not found";
      }
    }
    die unless $ok;
  }

  if ($latest_version) {
    print "ok\n";
    1;
  }

}


sub get_source_code {

  $err = 0;

  @order = ();
  push @order, $site;
  
  for (sort { $a <=> $b } keys %source) {
    push @order, $_;
  }

  if ($latest_version) {
    # download it
    chomp $latest_version;
    $latest_version = "ledger-smb-${latest_version}.tar.gz";

    print "\nStatus\n";
    print "Downloading $latest_version .... ";

    foreach $key (@order) {
      print "\n$source{$key}{site} .... ";

      if ($lwp) {
	$err = LWP::Simple::getstore("$source{$key}{url}/$latest_version", "$latest_version");
	$err -= 200;
      } else {
	$ok = `lynx -dump -head $source{$key}{url}/$latest_version`;
	$err = !($ok =~ s/HTTP.*?200 //);

	if (!$err) {
	  $err = system("lynx -dump $source{$key}{url}/$latest_version > $latest_version");
	}
      }

      if ($err) {
	print "failed!";
      } else {
	last;
      }

    }
    
  } else {
    $err = -1;
  }
  
  if ($err) {
    die "Cannot get $latest_version";
  } else {
    print "ok!\n";
  }

  $latest_version;

}


sub install_smb {

  if ($filename) {
    $latest_version = $filename;
  } else {
    $latest_version = &get_source_code;
  }

  &decompress;

  if ($newinstall) {
    open(FH, "ledger-smb.conf.default");
    @f = <FH>;
    close(FH);
    unless ($latex) {
      grep { s/^\$latex.*/\$latex = 0;/ } @f;
    }
    open(FH, ">ledger-smb.conf");
    print FH @f;
    close(FH);

    $alias = $absolutealias = $ENV{'PWD'};
    $alias =~ s/.*\///g;
    
    $httpddir = `dirname $httpd`;
    if ($confd) {
      $httpddir = $confd;
    }
    chomp $httpddir;
    $filename = "ledger-smb-httpd.conf";

    # do we have write permission?
    if (!open(FH, ">>$httpddir/$filename")) {
      open(FH, ">$filename");
      $norw = 1;
    }

    $directives = qq|
Alias /$alias $absolutealias/
<Directory $absolutealias>
  AllowOverride All
  AddHandler cgi-script .pl
  Options ExecCGI Includes FollowSymlinks
  Order Allow,Deny
  Allow from All
</Directory>

<Directory $absolutealias/users>
  Order Deny,Allow
  Deny from All
</Directory>
  
|;

    print FH $directives;
    close(FH);
    
    print qq|
This is a new installation.

|;

    if ($norw) {
      print qq|
Webserver directives were written to $filename
      
Copy $filename to $httpddir
|;

      if (!$confd) {
	print qq| and add
# Ledger-SMB
Include $httpddir/$filename

to $httpd
|;
      }

      print qq| and restart your webserver!\n|;

      if (!$permset) {
	print qq|
WARNING: permissions for templates, users, css and spool directory
could not be set. Login as root and set permissions

# chown -hR :$webgroup users templates css spool
# chmod 771 users templates css spool

|;
      }

    } else {
      
       print qq|
Webserver directives were written to

  $httpddir/$filename
|;
     
      if (!$confd) {
	if (!(`grep "^# LedgerSMB" $httpd`)) {

	  open(FH, ">>$httpd");

	  print FH qq|

# LedgerSMB
Include $httpddir/$filename
|;
	  close(FH);
	  
	}
      }

      if (!$>) {
	# send SIGHUP to httpd
	if ($f = `find /var -type f -name 'httpd.pid'`) {
	  $pid = `cat $f`;
	  chomp $pid;
	  if ($pid) {
	    system("kill -s HUP $pid");
	  }
	}
      }
    }
  }
  
  # if this is not root, check if user is part of $webgroup
  if ($>) {
    if ($permset = ($) =~ getgrnam $webgroup)) {
      `chown -hR :$webgroup users templates css spool`;
      chmod 0771, 'users', 'templates', 'css', 'spool';
      `chown :$webgroup ledger-smb.conf`;
    }
  } else {
    # root
    `chown -hR 0:0 *`;
    `chown -hR $webowner:$webgroup users templates css spool`;
    chmod 0771, 'users', 'templates', 'css', 'spool';
    `chown $webowner:$webgroup ledger-smb.conf`;
  }
  
  chmod 0644, 'ledger-smb.conf';
  unlink "ledger-smb.conf.default";

  &cleanup;

  while ($a !~ /(Y|N)/) {
    print qq|\nDisplay README (Y/n) : |;
    $a = <STDIN>;
    chomp $a;
    $a = ($a) ? uc $a : 'Y';
    
    if ($a eq 'Y') {
      @args = ("more", "doc/README");
      system(@args);
    }
  }
  
}


sub decompress {
  
  die "Error: gzip not installed\n" unless ($gzip);
  die "Error: tar not installed\n" unless ($tar);
  
  &create_lockfile;

  # ungzip and extract source code
  print "Decompressing $latest_version ... ";
    
  if (system("gzip -df $latest_version")) {
    print "Error: Could not decompress $latest_version\n";
    &remove_lockfile;
    exit;
  } else {
    print "done\n";
  }

  # strip gz from latest_version
  $latest_version =~ s/\.gz//;
  
  # now untar it
  print "Unpacking $latest_version ... ";
  if (system("tar -xf $latest_version")) {
    print "Error: Could not unpack $latest_version\n";
    &remove_lockfile;
    exit;
  } else {
    # now we have a copy in ledger-smb
    if (system("tar -cf $latest_version -C ledger-smb .")) {
      print "Error: Could not create archive for $latest_version\n";
      &remove_lockfile;
      exit;
    } else {
      if (system("tar -xf $latest_version")) {
        print "Error: Could not unpack $latest_version\n";
	&remove_lockfile;
	exit;
      } else {
        print "done\n";
        print "cleaning up ... ";
        `rm -rf ledger-smb`;
        print "done\n";
      }
    }
  }
}


sub create_lockfile {

  if (-d "$userspath") {
    open(FH, ">$userspath/nologin");
    close(FH);
  }
  
}


sub cleanup {

  unlink "$latest_version";
  unlink "$userspath/members.default" if (-f "$userspath/members.default");

  &remove_lockfile;
  
}


sub remove_lockfile { unlink "$userspath/nologin" if (-f "$userspath/nologin") };



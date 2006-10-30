#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# 
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
# Copyright (C) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
# 
#  Contributors: Jim Rawlings <jim@your-dba.com>
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# user related functions
#
#=====================================================================

package LedgerSMB::User;
use LedgerSMB::Sysconfig;


sub new {
	my ($type, $memfile, $login) = @_;
	my $self = {};

	if ($login ne "") {
		&error("", "$memfile locked!") if (-f "${memfile}.LCK");
    
		open(MEMBER, "$memfile") or &error("", "$memfile : $!");
    
		while (<MEMBER>) {
			if (/^\[$login\]/) {
				while (<MEMBER>) {
					last if /^\[/;
					next if /^(#|\s)/;
	  
					# remove comments
	  
					s/^\s*#.*//g;

					# remove any trailing whitespace
					s/^\s*(.*?)\s*$/$1/;

					($key, $value) = split /=/, $_, 2;
	  
					$self->{$key} = $value;
				}
	
				$self->{login} = $login;

				last;
			}
		}
		close MEMBER;
	}
  
	bless $self, $type;
}


sub country_codes {
	use Locale::Country;
	use Locale::Language;

	my %cc = ();
	
	# scan the locale directory and read in the LANGUAGE files
	opendir DIR, "${LedgerSMB::Sysconfig::localepath}";

	my @dir = grep !/^\..*$/, readdir DIR;

	foreach my $dir (@dir) {
		$dir = substr($dir, 0, -3);
		$cc{$dir} = code2language(substr($dir, 0, 2));
		$cc{$dir} .= ("/" . code2country(substr($dir, 3, 2)))
			if length($dir) > 2;
		$cc{$dir} .= (" " . substr($dir, 6)) if length($dir) > 5;
	}

	closedir(DIR);

	%cc;

}


sub login {
	my ($self, $form) = @_;

	my $rc = -1;
  
	if ($self->{login} ne "") {

		if ($self->{password} ne "") {
			my $password = 
				crypt $form->{password}, 
					substr($self->{login}, 0, 2);
			if ($self->{password} ne $password) {
				return -1;
			}
		}
    
		#there shouldn't be any harm in always doing this. 
		#It might even un-bork things.
  		$self->create_config(
			"${LedgerSMB::Sysconfig::userspath}/$self->{login}.conf");
    
		do "${LedgerSMB::Sysconfig::userspath}/$self->{login}.conf";
		$myconfig{dbpasswd} = unpack 'u', $myconfig{dbpasswd};
  
		# check if database is down
		my $dbh = DBI->connect(
			$myconfig{dbconnect}, $myconfig{dbuser}, 
			$myconfig{dbpasswd}) 
				or $self->error($DBI::errstr);

		# we got a connection, check the version
		my $query = qq|SELECT version FROM defaults|;
		my $sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		my ($dbversion) = $sth->fetchrow_array;
		$sth->finish;

		# add login to employee table if it does not exist
		# no error check for employee table, ignore if it does not exist
		my $login = $self->{login};
		$login =~ s/@.*//;
		$query = qq|SELECT id FROM employee WHERE login = ?|;
		$sth = $dbh->prepare($query);
		$sth->execute($login);

		my ($id) = $sth->fetchrow_array;
		$sth->finish;

		if (! $id) {
			my ($employeenumber) = 
				$form->update_defaults(
					\%myconfig, "employeenumber", $dbh);
      
			$query = qq|
				INSERT INTO employee 
				            (login, employeenumber, name, 
				            workphone, role)
				     VALUES (?, ?, ?, ?, ?)|;
			$sth = $dbh->prepare($query);
			$sth->execute(
				$login, $employeenumber, $myconfig{name},
				$myconfig{tel}, $myconfig{role});
		}
		$dbh->disconnect;

		$rc = 0;

    
		if ($form->{dbversion} ne $dbversion) {
			$rc = -3;
			$dbupdate = (calc_version($dbversion) 
				< calc_version($form->{dbversion}));
		}

		if ($dbupdate) {
			$rc = -4;

			# if DB2 bale out
			if ($myconfig{dbdriver} eq 'DB2') {
				$rc = -2;
			}
		}
	}

	$rc;
  
}


sub check_recurring {
	my ($self, $form) = @_;

	$self->{dbpasswd} = unpack 'u', $self->{dbpasswd};

	my $dbh = DBI->connect(
		$self->{dbconnect}, $self->{dbuser}, $self->{dbpasswd}) 
			or $form->dberror;

	my $query = qq|
		SELECT count(*) FROM recurring
		 WHERE enddate >= current_date AND nextdate <= current_date|;
	($_) = $dbh->selectrow_array($query);
  
	$dbh->disconnect;

	$_;

}


sub dbconnect_vars {
	my ($form, $db) = @_;
  
	my %dboptions = (
		'Pg' => {
			'yy-mm-dd' => 'set DateStyle to \'ISO\'',
			'mm/dd/yy' => 'set DateStyle to \'SQL, US\'',
			'mm-dd-yy' => 'set DateStyle to \'POSTGRES, US\'',
			'dd/mm/yy' => 'set DateStyle to \'SQL, EUROPEAN\'',
			'dd-mm-yy' => 'set DateStyle to \'POSTGRES, EUROPEAN\'',
			'dd.mm.yy' => 'set DateStyle to \'GERMAN\''
			}
		);


	$form->{dboptions} = $dboptions{$form->{dbdriver}}{$form->{dateformat}};

	if ($form->{dbdriver} =~ /Pg/) {
		$form->{dbconnect} = "dbi:$form->{dbdriver}:dbname=$db";
	}

	if ($form->{dbdriver} eq 'Oracle') {
		$form->{dbconnect} = "dbi:Oracle:sid=$form->{sid}";
	}

	if ($form->{dbhost}) {
		$form->{dbconnect} .= ";host=$form->{dbhost}";
	}
	if ($form->{dbport}) {
		$form->{dbconnect} .= ";port=$form->{dbport}";
	}
  
}


sub dbdrivers {

	my @drivers = DBI->available_drivers();

		#  return (grep { /(Pg|Oracle|DB2)/ } @drivers);
	return (grep { /Pg$/ } @drivers);

}


sub dbsources {
	my ($self, $form) = @_;

	my @dbsources = ();
	my ($sth, $query);
  
	$form->{dbdefault} = $form->{dbuser} unless $form->{dbdefault};
	$form->{sid} = $form->{dbdefault};
	&dbconnect_vars($form, $form->{dbdefault});

	my $dbh = DBI->connect(
		$form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) 
			or $form->dberror;


	if ($form->{dbdriver} eq 'Pg') {

		$query = qq|SELECT datname FROM pg_database|;
		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);
    
		while (my ($db) = $sth->fetchrow_array) {

			if ($form->{only_acc_db}) {

				next if ($db =~ /^template/);

				&dbconnect_vars($form, $db);
				my $dbh = DBI->connect(
					$form->{dbconnect}, $form->{dbuser}, 
					$form->{dbpasswd}) 
						or $form->dberror;

				$query = qq|
					SELECT tablename FROM pg_tables
					 WHERE tablename = 'defaults'
					   AND tableowner = ?|;
				my $sth = $dbh->prepare($query);
				$sth->execute($form->{dbuser}) 
					|| $form->dberror($query);

				if ($sth->fetchrow_array) {
					push @dbsources, $db;
				}
				$sth->finish;
				$dbh->disconnect;
				next;
			}
			push @dbsources, $db;
		}
	}

	$sth->finish;
	$dbh->disconnect;
  
	return @dbsources;

}


sub dbcreate {
	my ($self, $form) = @_;

	my %dbcreate = ( 'Pg' => qq|CREATE DATABASE "$form->{db}"| );

	$dbcreate{Pg} .= " WITH ENCODING = '$form->{encoding}'" 
		if $form->{encoding};
  
	$form->{sid} = $form->{dbdefault};
	&dbconnect_vars($form, $form->{dbdefault});
	# The below line connects to Template1 or another template file in order
	# to create the db.  One must disconnect and reconnect later.
	if ($form->{dbsuperuser}){
		my $superdbh = DBI->connect(
 			$form->{dbconnect}, 
			$form->{dbsuperuser}, 
			$form->{dbsuperpasswd}) 
				or $form->dberror;
		my $query = qq|$dbcreate{$form->{dbdriver}}|;
		$superdbh->do($query) || $form->dberror($query);
    
		$superdbh->disconnect;  
	}
	#Reassign for the work below

	&dbconnect_vars($form, $form->{db});
  
	my $dbh = DBI->connect(
		$form->{dbconnect}, 
		$form->{dbuser}, 
		$form->{dbpasswd}) 
			or $form->dberror;
	if ($form->{dbsuperuser}){
		my $superdbh = DBI->connect(
			$form->{dbconnect}, 
			$form->{dbsuperuser}, 
			$form->{dbsuperpasswd}) 
				or $form->dberror;
		# JD: We need to check for plpgsql, 
		# if it isn't there create it, if we can't error
		# Good chance I will have to do this twice as I get 
		# used to the way the code is structured

		my %langcreate = ( 'Pg' => qq|CREATE LANGUAGE plpgsql|);
		my $query = qq|$langcreate{$form->{dbdriver}}|;
		$superdbh->do($query);
		$superdbh->disconnect;
	}
	# create the tables
	my $dbdriver = 
		($form->{dbdriver} =~ /Pg/) 
		? 'Pg' 
		: $form->{dbdriver};
  
	my $filename = qq|sql/${dbdriver}-tables.sql|;
	$self->process_query($form, $dbh, $filename);
  
	# create functions
	$filename = qq|sql/${dbdriver}-functions.sql|;
	$self->process_query($form, $dbh, $filename);

	# load gifi
	($filename) = split /_/, $form->{chart};
	$filename =~ s/_//;
	$self->process_query($form, $dbh, "sql/${filename}-gifi.sql");
 
	# load chart of accounts
	$filename = qq|sql/$form->{chart}-chart.sql|;
	$self->process_query($form, $dbh, $filename);

	# create indices
	$filename = qq|sql/${dbdriver}-indices.sql|;
	$self->process_query($form, $dbh, $filename);
 
	# create custom tables and functions
	my $item;
	foreach $item (qw(tables functions)) {
		$filename = "sql/${dbdriver}-custom_${item}.sql";
		if (-f "$filename") {
			$self->process_query($form, $dbh, $filename);
		}
	}
  
	$dbh->disconnect;

}



sub process_query {
	my ($self, $form, $dbh, $filename) = @_;
  
	return unless (-f $filename);
  
	open(FH, "$filename") or $form->error("$filename : $!\n");
	open(PSQL, "| psql") or $form->error("psql : $! \n");
	while (<FH>){
		print PSQL $_;
	}
	close FH;
 
}
  


sub dbdelete {
	my ($self, $form) = @_;

	$form->{sid} = $form->{dbdefault};
	&dbconnect_vars($form, $form->{dbdefault});
	my $dbh = DBI->connect(
		$form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) 
			or $form->dberror;
	my $query = qq|DROP DATABASE "$form->{db}"|;
	$dbh->do($query) || $form->dberror($query);

	$dbh->disconnect;

}
  


sub dbsources_unused {
	my ($self, $form, $memfile) = @_;

	my @dbexcl = ();
	my @dbsources = ();
  
	$form->error("$memfile locked!") if (-f "${memfile}.LCK");
  
	# open members file
	open(FH, "$memfile") or $form->error("$memfile : $!");

	while (<FH>) {
		if (/^dbname=/) {
			my ($null,$item) = split /=/;
			push @dbexcl, $item;
		}
	}

	close FH;

	$form->{only_acc_db} = 1;
	my @db = &dbsources("", $form);

	push @dbexcl, $form->{dbdefault};

	foreach $item (@db) {
		unless (grep /$item$/, @dbexcl) {
			push @dbsources, $item;
		}
	}

	return @dbsources;

}


sub dbneedsupdate {
	my ($self, $form) = @_;

	my %dbsources = ();
	my $query;
  
	$form->{sid} = $form->{dbdefault};
	&dbconnect_vars($form, $form->{dbdefault});

	my $dbh = DBI->connect(
		$form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) 
			or $form->dberror;

	if ($form->{dbdriver} =~ /Pg/) {

		$query = qq|
			SELECT d.datname 
			  FROM pg_database d, pg_user u
			 WHERE d.datdba = u.usesysid
			       AND u.usename = ?|;
		my $sth = $dbh->prepare($query);
		$sth->execute($form->{dbuser}) || $form->dberror($query);
    
		while (my ($db) = $sth->fetchrow_array) {

			next if ($db =~ /^template/);

			&dbconnect_vars($form, $db);
      
			my $dbh = DBI->connect(
				$form->{dbconnect}, $form->{dbuser}, 
				$form->{dbpasswd}) 
					or $form->dberror;

			$query = qq|
				SELECT tablename 
				  FROM pg_tables
				 WHERE tablename = 'defaults'|;
			my $sth = $dbh->prepare($query);
			$sth->execute || $form->dberror($query);

			if ($sth->fetchrow_array) {
				$query = qq|SELECT version FROM defaults|;
				my $sth = $dbh->prepare($query);
				$sth->execute;
	
				if (my ($version) = $sth->fetchrow_array) {
					$dbsources{$db} = $version;
				}
				$sth->finish;
			}
			$sth->finish;
			$dbh->disconnect;
		}
		$sth->finish;
	}



	$dbh->disconnect;
  
	%dbsources;

}


sub dbupdate {
	my ($self, $form) = @_;

	$form->{sid} = $form->{dbdefault};
  
	my @upgradescripts = ();
	my $query;
	my $rc = -2;
  
	if ($form->{dbupdate}) {
		# read update scripts into memory
		opendir SQLDIR, "sql/." or $form->error($!);
		@upgradescripts = 
			sort script_version 
				grep /$form->{dbdriver}-upgrade-.*?\.sql$/, 
					readdir SQLDIR;
		closedir SQLDIR;
	}


	foreach my $db (split / /, $form->{dbupdate}) {

		next unless $form->{$db};

		# strip db from dataset
		$db =~ s/^db//;
		&dbconnect_vars($form, $db);
    
		my $dbh = DBI->connect(
			$form->{dbconnect}, $form->{dbuser}, 
			$form->{dbpasswd}, {AutoCommit => 0}) 
				or $form->dberror;

		# check version
		$query = qq|SELECT version FROM defaults|;
		my $sth = $dbh->prepare($query);
		# no error check, let it fall through
		$sth->execute;

		my $version = $sth->fetchrow_array;
		$sth->finish;
    
		next unless $version;

		$version = calc_version($version);
		my $dbversion = calc_version($form->{dbversion});

		foreach my $upgradescript (@upgradescripts) {
			my $a = $upgradescript;
			$a =~ s/(^$form->{dbdriver}-upgrade-|\.sql$)//g;
      
			my ($mindb, $maxdb) = split /-/, $a;
			$mindb = calc_version($mindb);
			$maxdb = calc_version($maxdb);

			next if ($version >= $maxdb);

			# exit if there is no upgrade script or version == mindb
			last if ($version < $mindb || $version >= $dbversion);

			# apply upgrade
			$self->process_query($form, $dbh, "sql/$upgradescript");
			$dbh->commit;
			$version = $maxdb;
 
		}
    
		$rc = 0;
 		$dbh->disconnect;
    
	}

	$rc;

}
  

sub calc_version {
  
	my @v = split /\./, $_[0];
	my $version = 0;
	my $i;
  
	for ($i = 0; $i <= $#v; $i++) {
		$version *= 1000;
		$version += $v[$i];
	}

	return $version;
  
}

  
sub script_version {
	my ($my_a, $my_b) = ($a, $b);
  
	my ($a_from, $a_to, $b_from, $b_to);
	my ($res_a, $res_b, $i);

	$my_a =~ s/.*-upgrade-//;
	$my_a =~ s/.sql$//;
	$my_b =~ s/.*-upgrade-//;
	$my_b =~ s/.sql$//;
	($a_from, $a_to) = split(/-/, $my_a);
	($b_from, $b_to) = split(/-/, $my_b);

	$res_a = calc_version($a_from);
	$res_b = calc_version($b_from);

	if ($res_a == $res_b) {
		$res_a = calc_version($a_to);
		$res_b = calc_version($b_to);
	}

	return $res_a <=> $res_b;
  
}


sub create_config {
	my ($self, $filename) = @_;


	@config = &config_vars;

	open(CONF, ">$filename") or $self->error("$filename : $!");
  
	# create the config file
	print CONF qq|# configuration file for $self->{login}

\%myconfig = (
|;

	foreach $key (sort @config) {
		$self->{$key} =~ s/\\/\\\\/g;
		$self->{$key} =~ s/'/\\'/g;

		#remaining conversion from SL
		$self->{$key} =~ s/sql-ledger([^.]*)\.css/ledger-smb$1.css/g;
		print CONF qq|  $key => '$self->{$key}',\n|;
	}

   
	print CONF qq|);\n\n|;

	close CONF;

}


sub save_member {
	my ($self) = @_;

	# format dbconnect and dboptions string
	&dbconnect_vars($self, $self->{dbname});

	$self->error("${LedgerSMB::Sysconfig::memberfile} locked!") 
		if (-f "${LedgerSMB::Sysconfig::memberfile}.LCK");
	open(FH, ">${LedgerSMB::Sysconfig::memberfile}.LCK") 
		or $self->error("${LedgerSMB::Sysconfig::memberfile}.LCK : $!");
	close(FH);

	if (! open(CONF, "+<${LedgerSMB::Sysconfig::memberfile}")) {
		unlink "${LedgerSMB::Sysconfig::memberfile}.LCK";
		$self->error("${LedgerSMB::Sysconfig::memberfile} : $!");
	}

	@config = <CONF>;

	seek(CONF, 0, 0);
	truncate(CONF, 0);

	while ($line = shift @config) {
		last if ($line =~ /^\[$self->{login}\]/);
		#remaining conversion from SL
		$line =~ s/sql-ledger([^.]*)\.css/ledger-smb$1.css/g;
		print CONF $line;
	}

	# remove everything up to next login or EOF
	while ($line = shift @config) {
		last if ($line =~ /^\[/);
	}

	# this one is either the next login or EOF
	print CONF $line;

	while ($line = shift @config) {
		print CONF $line;
	}

	print CONF qq|[$self->{login}]\n|;

	if ($self->{packpw}) {
		$self->{dbpasswd} = pack 'u', $self->{dbpasswd};
		chop $self->{dbpasswd};
	}
	if ($self->{password} ne $self->{old_password}) {
		$self->{password} = crypt $self->{password}, 
			substr($self->{login}, 0, 2) if $self->{password};
	}

	if ($self->{'root login'}) {
		@config = qw(password);
	} else {
		@config = &config_vars;
	}

	# replace \r\n with \n
	for (qw(address signature)) { $self->{$_} =~ s/\r?\n/\\n/g }

	for (sort @config) {
		print CONF qq|$_=$self->{$_}\n| 
	}

	print CONF "\n";
	close CONF;
	unlink "${LedgerSMB::Sysconfig::memberfile}.LCK";
	# create conf file
	if (! $self->{'root login'}) {

		$self->create_config("${LedgerSMB::Sysconfig::userspath}/$self->{login}.conf");

		$self->{dbpasswd} =~ s/\\'/'/g;
		$self->{dbpasswd} =~ s/\\\\/\\/g;
		$self->{dbpasswd} = unpack 'u', $self->{dbpasswd};

		# check if login is in database
		my $dbh = DBI->connect(
			$self->{dbconnect}, $self->{dbuser}, $self->{dbpasswd}, 
			{AutoCommit => 0}) 
				or $self->error($DBI::errstr);

		# add login to employee table if it does not exist
		my $login = $self->{login};
		$login =~ s/@.*//;
		my $query = qq|SELECT id FROM employee WHERE login = '$login'|;
		my $sth = $dbh->prepare($query);
		$sth->execute;

		my ($id) = $sth->fetchrow_array;
		$sth->finish;
		my $employeenumber;
		my @values;
		if ($id) {

			$query = qq|UPDATE employee SET
			role = ?,
			email = ?, 
			name = ?
			WHERE login = ?|;

			@values = ($self->{role}, $self->{email}, $self->{name}, $login);

		} else {

			my ($employeenumber) = Form::update_defaults(
				"", \%$self, "employeenumber", $dbh);
			$query = qq|
				INSERT INTO employee 
				            (login, employeenumber, name, 
				            workphone, role, email, sales)
				    VALUES (?, ?, ?, ?, ?, ?, '1')|;
			
			@values = ($login, $employeenumber, $self->{name}, $self->{tel},
			$self->{role}, $self->{email})
		}

		$sth = $dbh->prepare($query);
		$sth->execute(@values);
		$dbh->commit;
		$dbh->disconnect;

	}

}


sub delete_login {
	my ($self, $form) = @_;

	my $dbh = DBI->connect(
		$form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}, 
		{AutoCommit => 0}) 
			or $form->dberror;
  
	my $login = $form->{login};
	$login =~ s/@.*//;
	my $query = qq|SELECT id FROM employee WHERE login = ?|; 
	my $sth = $dbh->prepare($query);
	$sth->execute($login) || $form->dberror($query);
  
	my ($id) = $sth->fetchrow_array;
	$sth->finish;
	
	my $query = qq|
		UPDATE employee 
		   SET login = NULL,
		       enddate = current_date
		 WHERE login = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($login); 
	$dbh->commit;
	$dbh->disconnect;

}


sub config_vars {
  
	my @conf = 
		qw(acs address businessnumber company countrycode
		currency dateformat dbconnect dbdriver dbhost dbname dboptions
		dbpasswd dbport dbuser email fax menuwidth name numberformat
		password printer role sid signature stylesheet tel templates 
		timeout vclimit);

	@conf;

}


sub error {
	my ($self, $msg) = @_;

	if ($ENV{HTTP_USER_AGENT}) {
		print qq|Content-Type: text/html\n\n|.
			qq|<body bgcolor=ffffff>\n\n|.
			qq|<h2><font color=red>Error!</font></h2>\n|.
			qq|<p><b>$msg</b>|;

	}
  
	die "Error: $msg\n";
  
}


1;


#!/usr/bin/perl
#####################################################################
# Data import script to migrate from version 1.1's flat file based
# users to version 1.2's central database.
#
# NOTE: This script will die if the user it tries to import is
# tied to a bogus or non-existing dataset/database. The fix
# is to edit the members file and either manually set the right
# database configuration for that user, or delete the user entirely.
#
# If the script makes it through all users it will print:
#
# 'SUCCESS! It seems that every user in the members file was imported!'
#
# If you don't get that output at the end of the script, something
# went wrong in the import.
#
# For help/troubleshooting please join the LedgerSMB users mailing
# list. Info on how to subscribe can be found here:
#
# http://lists.sourceforge.net/mailman/listinfo/ledger-smb-users
#
# Other info on how to get help, including commercial support
# can be found at:
#
# http://www.ledgersmb.org/help/
#
use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;

if ( $ENV{HTTP_HOST} ) {
    print "Content-type: text/html\n\n";
    print "<html>\n";
    print
"<strong>This script cannot be executed via http. You must run it via the command line.</strong>\n";
    print "</html>\n";
    exit;
}

my $membersfile = $ARGV[0];

if ( length($membersfile) < 2 ) {

    print "\nUsage: import_members.pl path/to/members\n\n";
    print "You must supply the path to the members file. Default location\n";
    print "is users/members. In this case do this:\n\n";
    print "  ./import_members.pl users/members\n\n";
    exit;
}

my @users = ();

open( FH, '<', "$membersfile" ) || die("Couldn't open members file!");

while (<FH>) {

    chop;

    if (/^\[.*\]/) {
        $login = $_;
        $login =~ s/(\[|\])//g;

        if ( $login eq 'admin' ) {

            print "\nIMPORT FAILED: User 'admin' was found.\n\n";
            print
"Please change this user's name to something else. In LedgerSMB version 1.2, \n";
            print
"'admin' is a reserved user for the administration of the entire system.\n";
            print
"To change the user's name, find the line in the members file that looks \n";
            print
"like [admin] and change 'admin' to something else (keep the '[' and ']').\n";
            print "Save the file and run this script again.\n\n";
            exit;

        }
        elsif ( $login ne 'root login' ) {
            push @users, $login;
            $member{$login}{'login'} = $login;
        }
        next;
    }

    if ( $login ne 'root login' ) {
        if ( ( $key, $value ) = split /=/, $_, 2 ) {
            if ( $key eq 'dbpasswd' ) {
                $member{$login}{$key} = unpack 'u', $value;
            }
            elsif ( $key eq 'password' ) {
                $member{$login}{'crypted_password'} = $value;
            }
            else {
                $member{$login}{$key} = $value;
            }
        }
    }
}

close(FH);

print "\n\nParsing members file completed. Now trying to import user data.\n\n";

foreach (@users) {

    $myUser = $member{$_};
    &save_member($myUser);
    print "Import of user '$_' seems to have succeeded.\n";

}

print
  "\nSUCCESS! It seems that every user in the members file was imported!\n\n";

sub save_member {

    # a slightly modified version of LegerSBM::User::save_member
    # with special handling of the password -> crypted_password

    my ($self) = @_;

    # replace \r\n with \n
    for (qw(address signature)) { $self->{$_} =~ s/\r?\n/\\n/g }

    # use central db
    my $dbh = ${LedgerSMB::Sysconfig::GLOBALDBH};

    #check to see if the user exists already
    my $userCheck = $dbh->prepare("SELECT id FROM users WHERE username = ?");
    $userCheck->execute( $self->{login} );
    my ($userID) = $userCheck->fetchrow_array;

    if ($userID) {

        #got an id, check to see if it's in the users_conf table
        my $userConfCheck =
          $dbh->prepare("SELECT count(*) FROM users_conf WHERE id = ?");
        $userConfCheck->execute($userID);

        ($userConfExists) = $userConfCheck->fetchrow_array;
    }
    else {
        my $userConfAdd = $dbh->prepare("SELECT create_user(?);");
        $userConfAdd->execute( $self->{login} );
        ($userID) = $userConfAdd->fetchrow_array;
    }

    if ($userConfExists) {

        my $userConfUpdate = $dbh->prepare(
            "UPDATE users_conf
    		   SET acs = ?, address = ?, businessnumber = ?,
    			   company = ?, countrycode = ?, currency = ?,
    			   dateformat = ?, dbdriver = ?,
    			   dbhost = ?, dbname = ?, dboptions = ?, 
    			   dbpasswd = ?, dbport = ?, dbuser = ?,
    			   email = ?, fax = ?, menuwidth = ?,
    			   name = ?, numberformat = ?, crypted_password = ?,
    			   print = ?, printer = ?, role = ?,
    			   sid = ?, signature = ?, stylesheet = ?,
    			   tel = ?, templates = ?, timeout = ?,
    			   vclimit = ?
    		 WHERE id = ?;"
        );

        $userConfUpdate->execute(
            $self->{acs},            $self->{address},
            $self->{businessnumber}, $self->{company},
            $self->{countrycode},    $self->{currency},
            $self->{dateformat},     $self->{dbdriver},
            $self->{dbhost},         $self->{dbname},
            $self->{dboptions},      $self->{dbpasswd},
            $self->{dbport},         $self->{dbuser},
            $self->{email},          $self->{fax},
            $self->{menuwidth},      $self->{name},
            $self->{numberformat},   $self->{crypted_password},
            $self->{print},          $self->{printer},
            $self->{role},           $self->{sid},
            $self->{signature},      $self->{stylesheet},
            $self->{tel},            $self->{templates},
            $self->{timeout},        $self->{vclimit},
            $userID
        );

    }
    else {

        my $userConfInsert = $dbh->prepare(
            "INSERT INTO users_conf(acs, address, businessnumber,
    		 					   company, countrycode, currency,
    		 					   dateformat, dbdriver,
    		 					   dbhost, dbname, dboptions, dbpasswd,
    		 					   dbport, dbuser, email, fax, menuwidth,
    		 					   name, numberformat, print, printer, role, 
    		 					   sid, signature, stylesheet, tel, templates, 
    		 					   timeout, vclimit, id, crypted_password)
    		 VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
    		 	   ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
    		 	   ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
        );

        $userConfInsert->execute(
            $self->{acs},            $self->{address},
            $self->{businessnumber}, $self->{company},
            $self->{countrycode},    $self->{currency},
            $self->{dateformat},     $self->{dbdriver},
            $self->{dbhost},         $self->{dbname},
            $self->{dboptions},      $self->{dbpasswd},
            $self->{dbport},         $self->{dbuser},
            $self->{email},          $self->{fax},
            $self->{menuwidth},      $self->{name},
            $self->{numberformat},   $self->{print},
            $self->{printer},        $self->{role},
            $self->{sid},            $self->{signature},
            $self->{stylesheet},     $self->{tel},
            $self->{templates},      $self->{timeout},
            $self->{vclimit},        $userID,
            $self->{crypted_password}
        );

    }

    if ( !$self->{'admin'} ) {

        $self->{dbpasswd} =~ s/\\'/'/g;
        $self->{dbpasswd} =~ s/\\\\/\\/g;

        # format dbconnect and dboptions string
        LedgerSMB::User::dbconnect_vars( $self, $self->{dbname} );

        # check if login is in database
        my $dbh = DBI->connect(
            $self->{dbconnect}, $self->{dbuser},
            $self->{dbpasswd}, { AutoCommit => 0 }
        ) or $self->error($DBI::errstr);
        $dbh->{pg_enable_utf8} = 1;

        # add login to employee table if it does not exist
        my $login = $self->{login};
        $login =~ s/@.*//;
        my $sth = $dbh->prepare("SELECT entity_id FROM employee WHERE login = ?;");
        $sth->execute($login);

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

            @values = ( $self->{role}, $self->{email}, $self->{name}, $login );

        }
        else {

            my ($employeenumber) =
              Form::update_defaults( "", \%$self, "employeenumber", $dbh );
            $query = qq|
				INSERT INTO employee 
				            (login, employeenumber, name, 
				            workphone, role, email, sales)
				    VALUES (?, ?, ?, ?, ?, ?, '1')|;

            @values = (
                $login,       $employeenumber, $self->{name},
                $self->{tel}, $self->{role},   $self->{email}
            );
        }

        $sth = $dbh->prepare($query);
        $sth->execute(@values);
        $dbh->commit;
        $dbh->disconnect;

    }
}

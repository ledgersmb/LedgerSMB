

# inline documentation

package LedgerSMB::Initiate;
use LedgerSMB::Sysconfig;
use LedgerSMB::Auth;
use LedgerSMB::Locale;
use Data::Dumper;
use DBI;
use Locale::Language;
use Locale::Country;
use LedgerSMB::Log;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Initiate');

=over

=item LedgerSMB::User->new($login);

Create a LedgerSMB::User object.  If the user $login exists, set the fields
with values retrieved from the database.

=back

=cut


sub new
{

  my $class=shift;

  my $form = shift;

  my $self={};
  
  bless $self,$class;

  $self->initialize($form);

  return $self;

}


sub initialize
{

      my $self=shift;	
      my $form=shift;

      # In future if required use this function to initialize the attributes of the class "Initiate"
 
      $self->{initiateon}=$form->{initiateon};

      if(scalar($self->{initiateon})==1)
      {
          $form->{company}= 'template1';
	  $form->{port}=${LedgerSMB::Sysconfig::port};
          $form->{host}=${LedgerSMB::Sysconfig::host};

      }
      


}




sub getdbh
{

 my($self,$form)=@_;

 my($database,$host,$port,$username,$password);

 if($form->{initiateon}==1)
 {
   $ENV{PGDATABASE} = $form->{company};
   $ENV{PGHOST}=$form->{host};
   $ENV{PGPORT}=$form->{port};
   $username=$form->{username};
   $password=$form->{password};
   $ENV{PGUSER} = $form->{username};
   $ENV{PGPASSWORD} = $form->{password};
 }
 else
 {

    $ENV{PGDATABASE}=$form->{database};
    $ENV{PGHOST}=$form->{dbhost};
    $ENV{PGPORT}=$form->{dbport};
    $username=$form->{username};
    $password=$form->{password};

 }
  

   my $dbconnect = "dbi:Pg:user=$username password=$password";    # for easier debugging

   my $dbh = DBI->connect($dbconnect) or return "no999";

   return($dbh);

}



sub checksuperuser
{

     my($self,$form)=@_;

     my $dbh=$form->{dbh};

     my $sth=$dbh->prepare("select rolsuper from pg_roles where rolname = session_user;") || $form->dberror(
                __FILE__ . ':' . __LINE__ . ': Finding Superuser Prepare failed : ' );; 

     $sth->execute() or $form->dberror(
                __FILE__ . ':' . __LINE__ . ': Finding Superuser : execution failed' );

     my $super=0;

     $super=$sth->fetchrow_array;


     return($super);


}





sub get_countrys
{

       my $dir=$ENV{SCRIPT_FILENAME};

       $dir =~s/\/[\w\d\.]*$/\/sql\/coa\//;   # 2nd way is store path of coa in sysconfig file


	my @dir= sort LedgerSMB::Initiate->read_directory($form,$dir);

        my @allcodes = grep !/\.+/,@dir;

  
	my $returnvalue=qq|<option value="">null</option>|;

	for my $code(@allcodes)
        {
                $returnvalue.=qq|<option value="$code">$code</option>|;
        }

       	
       return $returnvalue;

       
}





sub validateform
{
    $logger->debug("Begin LedgerSMB::Initiate::validateform");

    ($self,$form,$locale)=@_;

    
#    print STDERR "DF database => $form->{database} dbhost= $form->{dbhost} $form->{dbport} $form->{contribpath} ";



    $form->{database}=~s/ //g;

    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $form->{locale}->text('Database Missing!') )
      unless $form->{database};

     
    $form->{dbhost}=~s/ //g;

   

    $form->{contribpath}=~s/ //g;

    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $locale->text('Contribution File Path Missing!') )
      unless $form->{contribpath};


    $form->{countrycode}=~s/ //g;

    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $locale->text('Country Code Missing!') )
      unless $form->{countrycode};



      $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $locale->text('Chart Account Missing!') )
      unless $form->{chartaccount};



    # check for duplicates

    if ( !$form->{edit} ) {

        # If we can connect to the database, then it already exists
        my $tempdbh = DBI->connect(
            "dbi:Pg:db=$form->{database};host=$form->{dbhost};port=$form->{dbport}",
            $form->{username},
            $form->{password},
            { PrintError => 0 },
        );


        if ( defined($tempdbh)) {
            $tempdbh->disconnect;
            $form->error( __FILE__ . ':' . __LINE__ . ': '
                  . $locale->text( '[_1] is already a database!', $form->{database} )
            );
        }
    }
    $logger->debug("End LedgerSMB::Initiate::validateform");
}


sub save_database
{
    $logger->debug("Begin LedgerSMB::Initiate::save_database");

	my($self,$form)=@_;
	# check all files exist and valids (contrib files , pgdabase.sql and modules and chart accounts etc)

	my @contrib=LedgerSMB::Initiate->check_contrib_valid_exist($form);   #check contrib files

	my @postsql=LedgerSMB::Initiate->check_Pg_database_valid_exist($form); #check sql/Pg-databse.sql files

	my @sqlmodules=LedgerSMB::Initiate->check_sql_modules_valid_exist($form);  #check sql/modules/readme file content exist or not

	my @chartgififiles=LedgerSMB::Initiate->merge_chart_gifi_valid_exist($form);   # check sql/coa/charts and sql/coa/gifi files

	my @totalexecutable_files;
	push(@totalexecutable_files,@contrib);
	push(@totalexecutable_files,@postsql);
	push(@totalexecutable_files,@sqlmodules);
	push(@totalexecutable_files,@chartgififiles);

		# Now all the files are found now start execution process(Stages)

    # Initial setup operations are performed while connected to the postgres
    # database as the currently authenticated user. This database should be
    # present even on a fresh install of PostgreSQL. The authenticated user
    # must have superuser rights to complete this stage of the setup.
    $form->{dbh} = DBI->connect(
        "dbi:Pg:db=postgres;host=$form->{dbhost};port=$form->{dbport}",
        $form->{username},
        $form->{password},
    ) or $form->error( __FILE__ . ':' . __LINE__ . ': ' .
        $locale->text( 'unable to connect to postgres database on [_1]:[_2]',
            $form->{dbhost},$form->{dbport}));

		#Stage 1 -   Create the databse $form->{database}

    # Initial setup operations are performed while connected to the postgres
    # database as the currently authenticated user. This database should be
    # present even on a fresh install of PostgreSQL. The authenticated user
    # must have superuser rights to complete this stage of the setup.
    $form->{dbh} = DBI->connect(
        "dbi:Pg:db=postgres;host=$form->{dbhost};port=$form->{dbport}",
        $form->{username},
        $form->{password},
    ) or $form->error( __FILE__ . ':' . __LINE__ . ': ' .
        $locale->text( 'unable to connect to postgres database on [_1]:[_2]',
            $form->{dbhost},$form->{dbport}));

	LedgerSMB::Initiate->create_database($form); 

    # Now connect to the newly created database as the admin user
    # This connection is used for all subsequent operations
    $form->{dbh} = DBI->connect(
        "dbi:Pg:db=$form->{database};host=$form->{dbhost};port=$form->{dbport}",
        $form->{admin_username},
        $form->{admin_password},
    ) or $form->error( __FILE__ . ':' . __LINE__ . ': ' .
        $locale->text( 'unable to connect to postgres database on [_1]:[_2]',
            $form->{dbhost},$form->{dbport}));

		#Stage 2 -  CReate the language plpgsql
	
	LedgerSMB::Initiate->handle_create_language($form);
		
		#stage 3 -  Execute series of files which are located in array @totalexecutable_files

	LedgerSMB::Initiate->run_all_sql_scripts($form,\@totalexecutable_files);

		#Stage -  Wind up completed the task
	process_roles($form);

        #Stage 5 - Load languages
    load_languages($form);

    $logger->debug("End LedgerSMB::Initiate::save_database");
}

sub load_languages {
    $logger->debug("Beging LedgerSMB::Initiate::load_languages");
    my ($form) = @_;

    opendir DIR, $LedgerSMB::Sysconfig::localepath;
    foreach my $dir (grep !/^\.\.?$/, readdir DIR) {
        my $code = substr( $dir, 0, -3);
        $logger->debug("add language $code");
        my $description = code2language( substr( $code, 0, 2) );
        $description .= '/' . code2country( substr( $code, 3, 2) ) if(length($code) > 4);
        $description .= ' ' . substr( $code, 5 ) if(length($code) > 5);
        $form->{dbh}->do("insert into language ( code, description ) values ( " .
			$form->{dbh}->quote( $code ) . ', ' .
            $form->{dbh}->quote( $description ) . ')'
        ) || $form->error( __FILE__ . ':' . __LINE__ . ': '
                  . $locale->text( 'language [_1]/[_2] creation failed',
                      $code, $description));
    }
    closedir(DIR);
    $logger->debug("End LedgerSMB::Initiate::load_languages");
}



sub process_roles {

    $logger->debug("Begin LedgerSMB::Initiate::process_roles");

	my ($form) = @_;

    $ENV{PGDATABASE} = $form->{database};
    $ENV{PGHOST}     = $form->{dbhost};
    $ENV{PGPORT}     = $form->{dbport};
    $ENV{PGUSER}     = $form->{username};
    $ENV{PGPASSWORD} = $form->{password};

	open (PSQL, '|-', 'psql') ||
        $form->error($locale->text("Couldn't open psql"));

	my $company = $form->{company};
    $logger->debug("LedgerSMB::Initiate::process_roles: company = $company");

	open (ROLEFILE, '<', 'sql/modules/Roles.sql') || $form->error($locale->text("Couldn't open Roles.sql"));

	while ($roleline = <ROLEFILE>){
		$roleline =~ s/<\?lsmb dbname \?>/$company/;
		print PSQL $roleline;
	}


	#create admin user 

    my $dbh = $form->{dbh}; # used only for quote and quote_identifier

    print PSQL "GRANT " .
        $dbh->quote_identifier("lsmb_${company}__users_manage")  . 
        " TO " .
        $dbh->quote_identifier($form->{admin_username}) . ";\n";

    print PSQL "INSERT INTO entity " .
        " (name, entity_class, created, country_id) " .
        " VALUES ( '" . $form->{admin_username} . "', 3, NOW(), " .
        " (SELECT id FROM country WHERE short_name = '" .
        uc($form->{countrycode}) .  "' ));\n";

    print PSQL "INSERT INTO person " .
        " (entity_id, first_name, last_name, created)".
        " VALUES ( (SELECT id FROM entity WHERE name = '" .
        $form->{admin_username} . "'), 'database', 'creator', NOW());\n";

    print PSQL "INSERT INTO users " .
        " (username, entity_id) " .
        " VALUES ( '" . $form->{admin_username} . "', " .
        " (SELECT id FROM entity WHERE name = '" .
        $form->{admin_username} . "'));\n";

    print PSQL "INSERT INTO user_preference (id) " .
        " VALUES ((SELECT id FROM users WHERE entity_id = " .
        "   (SELECT id FROM entity " .
        "     WHERE name = '" . $form->{admin_username} . "')));\n";

    $logger->debug("End LedgerSMB::Initiate::process_roles");
}

sub run_all_sql_scripts
{

	my ($self,$form,$totalexcfiles)=@_;

	foreach $dbfile(@$totalexcfiles)
	{
		print STDERR "Loading $dbfile\n";

		LedgerSMB::Initiate->run_db_file($form,$dbfile);

	}


}


sub run_db_file
{

 	my($self,$form,$dbfile)=@_;
        if ($ENV{PGDATABASE} eq 'template1'){
           $form->error('No database specified!');
        }
        $ENV{PGDATABASE} = $form->{database};
        $ENV{PGHOST}     = $form->{dbhost};
        $ENV{PGPORT}     = $form->{dbport};
        $ENV{PGUSER}     = $form->{username};
        $ENV{PGPASSWORD} = $form->{password};
	system("psql < $dbfile");
}





sub create_database
{
    my ($self,$form)=@_;

    # Create the admin user first, so it can be the owner of the new database
	if ($form->{createuser}){
        # Note: LedgerSMB setup for this user is done in process_roles()
		$form->{dbh}->do(
            "CREATE ROLE " . 
			$form->{dbh}->quote_identifier($form->{admin_username}) .
            " CREATEROLE LOGIN" .
			" PASSWORD " .  $form->{dbh}->quote($form->{admin_password}) .
            ";\n"
        ) || $logger->error(__FILE__ . ':' . __LINE__ . ': ',
            "create role $form->{admin_username} failed");
    }

    $form->{dbh}->do(
        "create database $form->{database} " .
        "  with owner $form->{admin_username}"
    ) || $form->error( __FILE__ . ':' . __LINE__ . ': '
            . $locale->text( 'database [_1] creation failed',$database));

}

sub handle_create_language
{

	my($self,$form)=@_;

    eval {
        local $form->{dbh}->{RaiseError} = 1;
        $form->{dbh}->do("create language plpgsql");
    };
    if($@) {
        $form->error( __FILE__ . ':' . __LINE__ . ': '
            . $locale->text( 'create language plpgsql failed on database [_1]!', $form->{database} )
        );
    }
}






sub check_contrib_valid_exist
{

	my ($self,$form)=@_;

	$locale=$form->{locale};

	#Check contrib files exist at particular directory else through an error

	$dir = $form->{contribpath};
        if ($dir !~ /\/$/){
		$dir = "$dir/";
	}

        $locale=$form->{locale};
 
	my @dir=LedgerSMB::Initiate->read_directory($form,$dir);readdir(IMD);

	@dest=("pg_trgm.sql","tablefunc.sql","tsearch2.sql");  #just expand array if contrib files increases
	
	
	if(!LedgerSMB::Initiate->all_files_found(\@dest,\@dir))
	{
		$form->error( __FILE__ . ':' . __LINE__ . ': '
                  . $locale->text( 'Required contrib files not exist under [_1]',$dir));
		exit;
	}
	
	for(my $i=0;$i<=$#dest;$i++)
	{
	  
		$dest[$i]=$dir.$dest[$i];
	
	}	

	return(@dest);


}



sub check_Pg_database_valid_exist
{


	#check sql/Pg-databas
	my ($self,$form)=@_;
        
	$locale=$form->{locale};

	my $dir=$ENV{SCRIPT_FILENAME};

	my @dest=("Pg-database.sql");  # extend the array if files increase

	$dir =~s/\/[\w\d\.]*$/\/sql\//;   

	my @dir=LedgerSMB::Initiate->read_directory($form,$dir);

        if(!LedgerSMB::Initiate->all_files_found(\@dest,\@dir))
	{
		$form->error( __FILE__ . ':' . __LINE__ . ': '
                  . $locale->text( 'Required Pg-database files Missing under [_1]',$dir));
		exit;
	}
	
	
	for(my $i=0;$i<=$#dest;$i++)
	{
	  
		$dest[$i]=$dir.$dest[$i];
	
	}
	
	return(@dest);

}


sub check_sql_modules_valid_exist
{

	my ($self,$form)=@_;

	$locale=$form->{locale};
       	my @dest; 
	my $dir=$ENV{SCRIPT_FILENAME};

	my $dir = "sql/modules/";


        #now dilemma with search files($dest)
	
	#1.List from README file 
	#2.Read all sql files from sql/modules/ -- Sadashiva
	#
	# I moved the info out of README into LOADORDER to be more friendly to
	# programmers.  --Chris
	
	open(ORD, '<', $dir . "LOADORDER");
	while (my $line = <ORD>){
		$line =~ s/\#.*$//; # ignore comments
		next if $line =~ /^\s*$/;
		$line =~ s/^\s*//;
		$line =~ s/\s*$//;
		push @dest, $dir.$line;
	}
	
	
	
	return(@dest);
	
	
}



sub merge_chart_gifi_valid_exist
{

	my ($self,$form)=@_;

    my @files;

    my $coa = $form->{coa} || 'General';
    $coa = "$coa.sql" unless $coa =~ /\.sql$/;
        
    my $dir = ($ENV{SCRIPT_FILENAME} =~ m/^(.*\/)/) ? $1 : './';

    $dir .= "/sql/coa/$form->{countrycode}/";

    if($form->{chartaccount}) {
        my $file = $dir . 'chart/' . $coa;
        if(-e $file) {
            push(@files, $file);
        } else {
            $logger->error("$file: not found");
        }
    }

    if($form->{gifiaccount}) {
        my $file = $dir . 'gifi/' . $coa;
        if(-e $file) {
            push(@files, $file);
        } else {
            $logger->error("$file: not found");
        }
    }

    return(@files);
}









sub read_directory
{

	my($self,$form,$dir)=@_;
	
	$locale=$form->{locale};
	
	opendir(DIR,$dir) || $form->error( __FILE__ . ':' . __LINE__ . ': '
                  . $locale->text( '[_1] directory Missing!', $dir));

        my @dircontent=readdir(DIR);
	
	closedir(DIR);

	return(@dircontent);

}


sub get_fullpath
{

	my($self,$dir,$files)=@_;

	for(my $i=0;$i<=@$files;$i++)
	{
	  
		$files->[$i]=$dir.$files->[$i];
	
	}


	return(@$files);


}





sub all_files_found
{


 my ($self,$search,$source)=@_;
 
 for my $file(@$search)
 {
       	$allfiles = grep /^$file$/,@$source;

	return 0 unless($allfiles);
 	
 }
 
 return 1;
 
 
}


1;



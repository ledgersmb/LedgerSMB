

# inline documentation

package LedgerSMB::Initiate;
use LedgerSMB::Sysconfig;
use LedgerSMB::Auth::DB;
use LedgerSMB::Locale;
use Data::Dumper;
use DBI;

=item LedgerSMB::User->new($login);

Create a LedgerSMB::User object.  If the user $login exists, set the fields
with values retrieved from the database.

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
          $form->{company}=${LedgerSMB::Sysconfig::default_db};
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
   $database = $form->{company};
   $host=$form->{host};
   $port=$form->{port};
   $username=$form->{username};
   $password=$form->{password};
 }
 else
 {

    $database=$form->{database};
    $host=$form->{dbhost};
    $port=$form->{dbport};
    $username=$form->{username};
    $password=$form->{password};

 }
  

   my $dbconnect = "dbi:Pg:dbname=$database host=$host
		port=$port user=$username password=$password";    # for easier debugging

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


	my @dir=LedgerSMB::Initiate->read_directory($form,$dir);

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

    ($self,$form,$locale)=@_;

    
#    print STDERR "DF database => $form->{database} dbhost= $form->{dbhost} $form->{dbport} $form->{contribpath} ";



    $form->{database}=~s/ //g;

    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $form->{locale}->text('Database Missing!') )
      unless $form->{database};

     
    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $locale->text('Database Driver Missing!') )
      unless $form->{driver};

    
    $form->{dbhost}=~s/ //g;

   

    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $locale->text('Database Host Missing!') )

      unless $form->{dbhost};

    $form->{dbport}=~s/ //g;
    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $locale->text('Database Port Number Missing!') )
      unless $form->{dbport};
   

   
    $invalid=($form->{dbport}=~m/^\d{4}$/);

   
    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $locale->text('Invalid Database Port Number!') )
      unless $invalid;



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

	$form->{initiateon}=0;	

        $tempdbh = LedgerSMB::Initiate->getdbh($form);

	$form->{initiateon}=1;	

 	$form->{tempdbh}=$tempdbh;        

	if ( lc($tempdbh) ne "no999" ) {
            $form->error( __FILE__ . ':' . __LINE__ . ': '
                  . $locale->text( '[_1] is already a database!', $form->{database} )
            );
        }
    }




}


sub save_database
{

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


		#Stage 1 -   Create the databse $form->{database}

		LedgerSMB::Initiate->create_database($form,$form->{dbh},$form->{database},$form->{username}); 
		
		#Stage 2 -  CReate the language plpgsql
	
		$form->{newdbh}=LedgerSMB::Initiate->handle_create_language($form);
		
		#stage 3 -  Execute series of files which are located in array @totalexecutable_files in the database $form->{newdbh}

		LedgerSMB::Initiate->run_all_sql_scripts($form,\@totalexecutable_files);

		#Stage -  Wind up completed the task

		$form->error( __FILE__ . ':' . __LINE__ . ': '
				  . $locale->text("under construction database/language created successfully"));

		exit;

						

}


sub run_all_sql_scripts
{

	my ($self,$form,$totalexcfiles)=@_;

	foreach $dbfile(@$totalexcfiles)
	{

		LedgerSMB::Initiate->run_db_file($form,$dbfile);

	}


}


sub run_db_file
{

 	my($self,$form,$dbfile)=@_;
	
	my $newdbh=$form->{newdbh};

         system("");
}





sub create_database
{


	my ($self,$form,$dbh,$database,$owner)=@_;

	my $locale=$form->{locale};

	$dbh->do("create database $database with owner $owner") || $form->error( __FILE__ . ':' . __LINE__ . ': '
                  . $locale->text( 'database [_1] creation failed',$database));

	

}

sub handle_create_language
{

	my($self,$form)=@_;

	$form->{initiateon}=0;
		
	my $newdbh=LedgerSMB::Initiate->getdbh($form);	
		
	$form->{initiateon}=1;
		

	if(lc($newdbh) eq 'no999')
	{
		
 		$form->{dbh}->do("drop database $form->{database}");

		$form->error( __FILE__ . ':' . __LINE__ . ': '
		        . $locale->text( 'connection failed to database [_1] might be port/localhost problem!', $form->{database} )
		            );		

	}

	

	if(!LedgerSMB::Initiate->create_language($newdbh))
	{
		$form->{dbh}->do("drop database $form->{database}");

		$form->error( __FILE__ . ':' . __LINE__ . ': '
	        . $locale->text( 'connection failed to database [_1] might be port/localhost problem!', $form->{database} )
		            );		

	}


	return($newdbh);
	
}


sub create_language
{

	my ($self,$newdbh)=@_;
	$newdbh->do("create language plpgsql") || return 0;
	return 1;

}





sub check_contrib_valid_exist
{

	my ($self,$form)=@_;

	$locale=$form->{locale};

	#Check contrib files exist at particular directory else through an error

	$dir = $form->{contribpath};

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
        
	my $dir=$ENV{SCRIPT_FILENAME};

	my $location="/sql/modules/";

	$dir =~s/\/[\w\d\.]*$/$location/;

       	my @dir=LedgerSMB::Initiate->read_directory($form,$dir);

=pod 
        now dilemma with search files($dest)
	
	1.List from README file 
	2.Read all sql files from sql/modules/

	Now implementing 2 one .Chris can you suggest me whether to go with 1 or 2

=cut
	my @dest = grep /\.sql$/,@dir;
	
	
	for(my $i=0;$i<=$#dest;$i++)
	{
	  
		$dest[$i]=$dir.$dest[$i];
	
	}
	
	return(@dest);
	
	
}



sub merge_chart_gifi_valid_exist
{

	my ($self,$form)=@_;
        
	$locale=$form->{locale};

	my $dir=$ENV{SCRIPT_FILENAME};

	my $location="/sql/coa/$form->{countrycode}/";

	$dir =~s/\/[\w\d\.]*$/$location/;

	my $chartdir=$dir."chart/";
	
	my $gifidir=$dir."gifi/";


	my @chartdir=LedgerSMB::Initiate->read_directory($form,$chartdir);

	@chartdir=grep /\.sql$/,@chartdir;
	


	my @gifidir;

	if($form->{gifiaccount}==2)
	{
	    @gifidir=LedgerSMB::Initiate->read_directory($form,$gifidir);
	    @gifidir=grep /\.sql$/,@gifidir;
	   	
        }   


        my @dest;	

        my $i;

	for($i=0;$i<=$#chartdir;$i++)
	{
	  
		$dest[$i]=$chartdir.$chartdir[$i];
	
	}

	for(my $j=0;$j<=$#gifidir;$j++,$i++)
	{
	  
		$dest[$i]=$gifidir.$gifidir[$j];
	
	}

	
	return(@dest);


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



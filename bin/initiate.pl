
use LedgerSMB::Form;
use LedgerSMB::Locale;
use LedgerSMB::User;
use LedgerSMB::Initiate;
use LedgerSMB::Auth;

#use LedgerSMB::Session;

$root="";

$form = new Form;

$locale = LedgerSMB::Locale->get_handle( ${LedgerSMB::Sysconfig::language} )  or  $form->error( __FILE__ . ':' . __LINE__ . ': ' . "Locale not loaded: $!\n" );

$locale->encoding('UTF-8');

$form->{locale}=$locale;

$form->{charset} = 'UTF-8';

eval { require DBI; };

$form->error(
    __FILE__ . ':' . __LINE__ . ': ' . $locale->text('DBI not installed!') )
  if ($@);

$form->{stylesheet} = "ledgersmb.css";
$form->{favicon}    = "favicon.ico";
$form->{timeout}    = 600;

require "bin/pw.pl";

# customization
if ( -f "bin/custom/$form->{script}" ) {
    eval { require "bin/custom/$form->{script}"; };
    $form->error( __FILE__ . ':' . __LINE__ . ': ' . $@ ) if ($@);
}

# because iniate.pl called only at admin for initializtion everything at default_db

if ( $form->{action} ) {

    &check_password unless $form->{action} eq 'logout';
   
    &{ $form->{action} };

}
else {

     # if there are no drivers bail out
     $form->error( __FILE__ . ':' . __LINE__ . ':' . $locale->text('No Database Drivers available!') )
     unless ( LedgerSMB::User->dbdrivers );

     &check_password;
     
     $form->{'action'}='login';

     &{ $form->{action} };
    
     
     

}

1;

# end

sub check_password {


	my $auth_temp=LedgerSMB::Auth->get_credentials();

        LedgerSMB::Auth->credential_prompt unless($auth_temp);

        $form->{'login'}=$auth_temp->{'login'};

        $form->{'username'}=$auth_temp->{'login'};

        $form->{'password'}=$auth_temp->{'password'};

	$form->{'initiateon'}=1;
    
        $root=LedgerSMB::Initiate->new($form);

	$form->{dbh}=$root->getdbh($form);   # get the connection if user exist as superuser

	if ( lc($form->{dbh}) eq "no999" or !$root->checksuperuser($form)) {
            LedgerSMB::Auth->credential_prompt;
            exit;
        }
    
        
}


sub login {

    &prepare_initiate($form);

}


sub prepare_initiate {


    # use the dynamic database handle  (self = form )

    my ($self)=@_;

    #get the username and password from cookie for time being it would holds

    my $dbh = $self->{dbh};        


    $self->{title} =
        "LedgerSMB Initial Database Set Up Vizard";   

    $self->header;

   
    print qq|
		<body class="initiate">
		<form method="post" action="$self->{script}">
		<table width="100%">
			<tr class="listheading">
				<th>$self->{title}</th>
			</tr>
			<tr size="5"></tr>
			</tr>|;
    

    print qq|		
			<tr>
				<td><hr size="3" noshade /></td>
			</tr>
		</table>
		<input type="hidden" name="path" value="$self->{path}" />
		<br />
		<button type="submit" class="submit" name="action" value="initiate_database">|
      . $locale->text('Initiate Database')
      . qq|</button>
		<button type="submit" class="submit" name="action" value="logout">|
      . $locale->text('Logout')
      . qq|</button>
		</form>

	| . qq|

	</body>
	</html>|;


}





sub logout {
   
   #$form->redirect( $locale->text('successfully logged Out') );
   
   LedgerSMB::Auth->credential_prompt;

}

sub initiate_database {

    $form->{title} =
        "LedgerSMB "
      . $locale->text('Administration') . " / "
      . $locale->text('Initial database Setup');

    if ( -f "css/ledgersmb.css" ) {
        $myconfig->{stylesheet} = "ledgersmb.css";
    }

    $myconfig->{vclimit}   = 1000;
    $myconfig->{menuwidth} = 155;
    $myconfig->{timeout}   = 3600;

    &form_header;
    &form_footer;
}


sub view_database {

    $form->{title} =
        "LedgerSMB "
      . $locale->text('Administration') . " / "
      . $locale->text('Initial database Setup');


    if ( -f "css/ledgersmb.css" ) {
        $myconfig->{stylesheet} = "ledgersmb.css";
    }

    $myconfig->{vclimit}   = 1000;
    $myconfig->{menuwidth} = 155;
    $myconfig->{timeout}   = 3600;
    $form->header;
    $form->redirect( $locale->text('Under Construction!') );

}



sub form_footer {

    if ( $form->{edit} ) {
        $delete =
          qq|<button type="submit" class="submit" name="action" value="delete">|
          . $locale->text('Delete')
          . qq|</button>
					 <input type="hidden" name="edit" value="1" />|;
    }

    print qq|
	<input name="callback" type="hidden" value="$form->{script}?action=initiate_database&amp;path=$form->{path}" />
	<input type="hidden" name="path" value="$form->{path}" />
	<button type="submit" class="submit" name="action" value="save">|
      . $locale->text('Save')
      . qq|</button>
	<button type="reset" class="reset" name="action" value="reset">|
      . $locale->text('Reset').
	qq|</button>
	$delete
	</form>
	</body>
	</html>
	|;
}



sub form_header
{

$form->header;


print qq|
	<body class="admin">
	<form method="post" action="initiate.pl">
	<table width="100%">
		<tr class="listheading"><th colspan="2">$form->{title}</th></tr>
		<tr size="5"></tr>
		<tr valign="top">
			<td>
				<table>
					<tr>
						<th align="right">| . $locale->text('Database') . qq|</th>
						<td><input name="database" value="$myconfig->{database}" /></td>
					</tr>
					<tr>
						<th align="right">| . $locale->text('Host') . qq|</th>
						<td><input name="dbhost" value="$myconfig->{host}" /></td>
					</tr>
					<tr>
						<th align="right">| . $locale->text('Port') . qq|</th>
						<td><input name="dbport" size="5" value="$myconfig->{port}" /></td>
					</tr>
					
				</table>
			</td>
			
		</tr>
		<tr></tr>
		<tr class="listheading">
			<th colspan="2">| . $locale->text('Contrib Files') . qq|</th>
		</tr>		
		<tr size="5"></tr>
		<tr valign="top">
			<td>
				<table>
					<tr>
						<th align="right">| . $locale->text('Path of Contrib Files') . qq|</th>
						<td><input name="contribpath" value="$myconfig->{contribpath}" /></td>
					</tr>
				</table>
			</td>
		</tr>


		<tr></tr>
		<tr class="listheading">
			<th colspan="2">| . $locale->text('Chart Accounts') . qq|</th>
		</tr>		
		<tr size="5"></tr>
		<tr valign="top">
			<td>
				<table>
					<tr>
						<th align="right">| . $locale->text('Country Code');
					        my $country=LedgerSMB::Initiate->get_countrys();
						# just testing manually      $myconfig->{countrycode}="uk";
		  			        $country=~s/<option value="$myconfig->{countrycode}">/<option value="$myconfig->{countrycode}" selected="selected">/;
print  qq|					</th>
						<td><select name="countrycode">$country</select></td>
					</tr>
					<tr>
						<th align="right">| . $locale->text('Charts Account') . qq|</th>
						<td><input name="chartaccount" class="checkbox" type="checkbox" value="1">$myconfig->{chartaccount}</td>
					</tr>

					<tr>
						<th align="right">| . $locale->text('Gifi Account') . qq|</th>
						<td><input name="gifiaccount" class="checkbox" type="checkbox" value="2">$myconfig->{gifiaccount}</td>
					</tr>
					<tr><th align="right">|. $locale->text('Chart Name') .qq|</th>
						<td><input name="coa" type="text" size="32"></td>
				</table>
					<tr class="listheading">
						<th colspan="2">|.
						$locale->text('Admin User').
						qq|</th></tr><table>
					<tr> <th aligh="right">|.$locale->text('Admin User') . qq| </th>
						<td><input name="admin_username" type="text" size="32" /></td>
					</tr>
					<tr> <td colspan="2"> | . $locale->text('Create database user') . qq| <input name="createuser" class="checkbox" type="checkbox" value="1"></tr>
					<tr> <th align="right"> | . $locale->text('Password') . qq| </th>
						<td><input name="admin_password" type="password" size="32"></td>
				</table>
			</td>
		</tr>



	</table>|;




}




sub save {

    $form->{callback} = "initiate.pl?action=login";
    $form->header;
    print "<pre>";

    LedgerSMB::Initiate->validateform($form,$locale);

    LedgerSMB::Initiate->save_database($form);
    print "</pre>";
    # create user template directory and copy master files
   
}


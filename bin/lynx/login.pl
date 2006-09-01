######################################################################
# LedgerSMB Small Medium Business Accounting
# Copyright (c) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://sourceforge.net/projects/ledger-smb/
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
######################################################################
#
# login frontend
#
#######################################################################


use DBI;
use SL::User;
use SL::Form;


$form = new Form;


$locale = new Locale $language, "login";
$form->{charset} = $locale->{charset};

# customization
if (-f "$form->{path}/custom_$form->{script}") {
  eval { require "$form->{path}/custom_$form->{script}"; };
  $form->error($@) if ($@);
}

# per login customization
if (-f "$form->{path}/$form->{login}_$form->{script}") {
  eval { require "$form->{path}/$form->{login}_$form->{script}"; };
  $form->error($@) if ($@);
}

# window title bar, user info
$form->{titlebar} = "LedgerSMB ".$locale->text('Version'). " $form->{version}";

if ($form->{action}) {
  $form->{titlebar} .= " - $myconfig{name} - $myconfig{dbname}";
  &{ $locale->findsub($form->{action}) };
} else {
  &login_screen;
}


1;


sub login_screen {

  $form->{stylesheet} = "sql-ledger.css";
  $form->{favicon} = "sql-ledger.ico";

  $form->{endsession} = 1;
  $form->header(1);

  if ($form->{login}) {
   $sf = qq|function sf() { document.login.password.focus(); }|;
  } else {
   $sf = qq|function sf() { document.login.login.focus(); }|;
  }

  print qq|
<script language="JavaScript" type="text/javascript">
<!--
var agt = navigator.userAgent.toLowerCase();
var is_major = parseInt(navigator.appVersion);
var is_nav = ((agt.indexOf('mozilla') != -1) && (agt.indexOf('spoofer') == -1)
           && (agt.indexOf('compatible') == -1) && (agt.indexOf('opera') == -1)
	   && (agt.indexOf('webtv') == -1));
var is_nav4lo = (is_nav && (is_major <= 4));

function jsp() {
  if (is_nav4lo)
    document.login.js.value = "0"
  else
    document.login.js.value = "1"
}
$sf
// End -->
</script>
|;

  print qq|

<body class=login onload="jsp(); sf()">

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="http://sourceforge.net/projects/ledger-smb/" target=_top><img src=ledger-smb.png border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}
</h1>

<p>

<form method=post action=$form->{script} name=login>

      <table width=100%>
	<tr>
	  <td align=center>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td><input class=login name=login size=30 value=$form->{login}></td>
	      </tr> 
	      <tr>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input class=login type=password name=password size=30></td>
	      </tr>
	      <input type=hidden name=path value=$form->{path}>
	      <input type=hidden name=js value=$form->{js}>
	    </table>

	    <br>
	    <input type=submit name=action value="|.$locale->text('Login').qq|">
	  </td>
	</tr>
      </table>

</form>

    </td>
  </tr>
</table>
  
</body>
</html>
|;

}


sub selectdataset {
  my ($login) = @_;
  
  if (-f "css/sql-ledger.css") {
    $form->{stylesheet} = "sql-ledger.css";
  }

  $form->header(1);

  print qq|
<body class=login onload="document.forms[0].password.focus()" />

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="http://sourceforge.net/projects/ledger-smb/" target=_top><img src=ledger-smb.png border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}
</h1>

<p>

<form method=post action=$form->{script}>

<input type=hidden name=beenthere value=1>

      <table width=100%>
	<tr>
	  <td align=center>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td>$form->{login}</td>
	      </tr> 
	      <tr>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input class=login type=password name=password size=30 value=$form->{password}></td>
	      </tr>
	      <input type=hidden name=js value=$form->{js}>
	      <input type=hidden name=path value=$form->{path}>
	      <tr>
		<th align=right>|.$locale->text('Company').qq|</th>
		<td>|;
		
		$checked = "checked";
		foreach $login (sort { $login{$a} cmp $login{$b} } keys %{ $login }) {
		  print qq|
		  <br><input class=login type=radio name=login value=$login $checked>$login{$login}
		  |;
		  $checked = "";
		}

		print qq|
		  </td>
	      </tr>
	    </table>
	    <br>
	    <input type=submit name=action value="|.$locale->text('Login').qq|">
	  </td>
	</tr>
      </table>

</form>

    </td>
  </tr>
</table>
  
</body>
</html>
|;


}


sub login {

  $form->{stylesheet} = "sql-ledger.css";
  $form->{favicon} = "sql-ledger.ico";
  
  $form->error($locale->text('You did not enter a name!')) unless ($form->{login});

  if (! $form->{beenthere}) {
    open(FH, "$memberfile") or $form->error("$memberfile : $!");
    @a = <FH>;
    close(FH);
    
    foreach $item (@a) {

      if ($item =~ /^\[(.*?)\]/) {
	$login = $1;
	$found = 1;
      }

      if ($item =~ /^company=/) {
	if ($login =~ /$form->{login}\@/ && $found) {
	  ($null, $name) = split /=/, $item, 2;
	  $login{$login} = $name;
	}
	$found = 0;
      }
  
    }

    if (keys %login > 1) {
      &selectdataset(\%login);
      exit;
    }
  }


  $user = new User $memberfile, $form->{login};

  # if we get an error back, bale out
  if (($errno = $user->login(\%$form, $userspath)) <= -1) {

    $errno *= -1;
    $err[1] = $locale->text('Access Denied!');
    $err[2] = $locale->text('Incorrect Dataset version!');
    $err[3] = $locale->text('Dataset is newer than version!');
    
    if ($errno == 4) {
      # upgrade dataset and log in again
      open FH, ">$userspath/nologin" or $form->error($!);

      for (qw(dbname dbhost dbport dbdriver dbuser dbpasswd)) { $form->{$_} = $user->{$_} }

      $form->{dbpasswd} = unpack 'u', $form->{dbpasswd};
      
      $form->{dbupdate} = "db$user->{dbname}";
      $form->{$form->{dbupdate}} = 1;

      $form->header;
      print $locale->text('Upgrading to Version')." $form->{version} ... ";

      # required for Oracle
      $form->{dbdefault} = $sid;

      $user->dbupdate(\%$form);

      # remove lock file
      unlink "$userspath/nologin";

      print $locale->text('done');

      print "<p><a href=menu.pl?login=$form->{login}&sessionid=$form->{sessionid}&path=$form->{path}&action=display&main=company_logo&js=$form->{js}>".$locale->text('Continue')."</a>";

      exit;
    }
    
    $form->error($err[$errno]);
  }

  # made it this far, setup callback for the menu
  $form->{callback} = "menu.pl?action=display";
  for (qw(login path js)) { $form->{callback} .= "&$_=$form->{$_}" }
  
  # check for recurring transactions
  if ($user->{acs} !~ /Recurring Transactions/) {
    if ($user->check_recurring(\%$form)) {
      $form->{callback} .= "&main=recurring_transactions";
    } else {
      $form->{callback} .= "&main=company_logo";
    }
  } else {
    if ($user->{role} eq 'user') {
      $form->{callback} .= "&main=company_logo";
    } else {
      if ($user->check_recurring(\%$form)) {
	$form->{callback} .= "&main=recurring_transactions";
      } else {
	$form->{callback} .= "&main=company_logo";
      }
    }
  }

  $form->redirect;
  
}



sub logout {

  $form->{callback} = "$form->{script}?path=$form->{path}&login=$form->{login}";

  $form->{endsession} = 1;
  
  $form->redirect;

}



#=====================================================================
# LedgerSMB Small Medium Business Accounting
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
# Copyright (c) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
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
#======================================================================


1;
use DBI;
use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Locale;

## will need this later when session_destroy will be used
#use LedgerSMB::Session;


$form = new Form;

$locale = LedgerSMB::Locale->get_handle(${LedgerSMB::Sysconfig::language}) or 
	$form->error("Locale not loaded: $!\n");
$locale->encoding('UTF-8');
$form->{charset} = 'UTF-8';
#$form->{charset} = $locale->encoding;

# customization
if (-f "bin/custom/$form->{script}") {
	eval { require "bin/custom/$form->{script}"; };
	$form->error($@) if ($@);
}

# per login customization
if (-f "bin/custom/$form->{login}_$form->{script}") {
	eval { require "bin/custom/$form->{login}_$form->{script}"; };
	$form->error($@) if ($@);
}

# window title bar, user info
$form->{titlebar} = "LedgerSMB ".$locale->text('Version'). " $form->{version}";

if ($form->{action}) {
	$form->{titlebar} .= " - $myconfig{name} - $myconfig{dbname}";
	&{ $form->{action} };

} else {
	&login_screen;
}


1;


sub login_screen {

	$form->{stylesheet} = "ledger-smb.css";
	$form->{favicon} = "favicon.ico";

	$form->{endsession} = 1;

	if ($form->{login}) {
		$sf = q|function sf() { document.login.password.focus(); }|;
	} else {
		$sf = q|function sf() { document.login.login.focus(); }|;
	}

	my $headeradd = qq|
	<script language="JavaScript" type="text/javascript">
	<!--
		var agt = navigator.userAgent.toLowerCase();
		var is_major = parseInt(navigator.appVersion);
		var is_nav = ((agt.indexOf('mozilla') != -1) && (agt.indexOf('spoofer') == -1)
					 && (agt.indexOf('compatible') == -1) && (agt.indexOf('opera') == -1)
					 && (agt.indexOf('webtv') == -1));
		var is_nav4lo = (is_nav && (is_major <= 4));

		function jsp() {
			if (is_nav4lo){
				document.login.js.value = "0";
			} else {
				document.login.js.value = "1";
			}
		}

		$sf
	// End -->
	</script>|;

	$form->header(1, $headeradd);

	print qq|

<body class="login" onload="jsp(); sf();">
	<br /><br />
	<center>
		<table class="login" border="3" cellpadding="20">
			<tr>
				<td class="login" align="center">
					<a href="http://www.ledgersmb.org/" target="_top"><img src="ledger-smb.png" width="200" heith="100" border="0" alt="LedgerSMB Logo" /></a>
					<h1 class="login" align="center">|.$locale->text('Version').qq| $form->{version}</h1>
					<p>
					<form method="post" action="$form->{script}" name="login">
					<table width="100%">
						<tr>
							<td align="center">
								<table>
									<tr>
										<th align="right">|.$locale->text('Name').qq|</th>
											<td><input class="login" name="login" size="30" value="$form->{login}" /></td>
									</tr> 
									<tr>
										<th align="right">|.$locale->text('Password').qq|</th>
										<td><input class="login" type="password" name="password" size="30" /></td>
									</tr>
								</table>
								<br />
							</td>
						</tr>
					</table>
						<input type="hidden" name="path" value="$form->{path}" />
						<input type="hidden" name="js" value="$form->{js}" />
						<button type="submit" name="action" value="login">|.$locale->text('Login').qq|</button>
					</form>
					</p>
				</td>
			</tr>
		</table>
	<p><a href="admin.pl"
		>|.$locale->text("Administrative login").qq|</a></p>
	</center>
</body>
</html>|;

}


sub selectdataset {
	my ($login) = @_;

	if (-f "css/ledger-smb.css") {
		$form->{stylesheet} = "ledger-smb.css";
	}

	$form->header(1);

	print qq|
<body class="login" onload="document.forms[0].password.focus()" />
	<br /><br />
	<center>
	<table class="login" border="3" cellpadding="20">
		<tr>
			<td class="login" align="center">
				<a href="http://www.ledgersmb.org/" target="_top"><img src="ledger-smb.png" width="100" heith="100" border="0" alt="LedgerSMB Logo" /></a>
				<h1 class="login" align="center">|.$locale->text('Version').qq| $form->{version}</h1>
				<p>
				<form method="post" action="$form->{script}">
					<input type="hidden" name="beenthere" value="1" />
					<input type="hidden" name="js" value="$form->{js}" />
					<input type="hidden" name="path" value="$form->{path}" />
					<table width="100%">
						<tr>
							<td align="center">
								<table>
									<tr>
										<th align="right">|.$locale->text('Name').qq|</th>
										<td>$form->{login}</td>
									</tr> 
									<tr>
										<th align="right">|.$locale->text('Password').qq|</th>
										<td><input class="login" type="password" name="password" size="30" value="$form->{password}" /></td>
									</tr>
									<tr>
										<th align="right">|.$locale->text('Company').qq|</th>
										<td>|;

		$checked = "checked";
		foreach $login (sort { $login{$a} cmp $login{$b} } keys %{ $login }) {
			print qq| <br /><input class="login" type="radio" name="login" value="$login" $checked>$login{$login} |;
			$checked = "";
		}

	print qq|
										</td>
									</tr>
								</table>
								<br />
								<button type="submit" name="action" value="login">|.$locale->text('Login').qq|</button>
							</td>
						</tr>
					</table>
				</form>
			</td>
		</tr>
	</table>
	</center>
</body>
</html>|;

}


sub login {

	$form->{stylesheet} = "ledger-smb.css";
	$form->{favicon} = "favicon.ico";

	$form->error($locale->text('You did not enter a name!')) unless ($form->{login});

	if (! $form->{beenthere}) {
		open(FH, "${LedgerSMB::Sysconfig::memberfile}") or $form->error("$memberfile : $!");
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


	$user = LedgerSMB::User->new(${LedgerSMB::Sysconfig::memberfile}, $form->{login});

	# if we get an error back, bale out
	if (($errno = $user->login(\%$form, ${LedgerSMB::Sysconfig::userspath})) <= -1) {

		$errno *= -1;
		$err[1] = $locale->text('Access Denied!');
		$err[2] = $locale->text('Incorrect Dataset version!');
		$err[3] = $locale->text('Dataset is newer than version!');

		if ($errno == 4) {
			# upgrade dataset and log in again
			open FH, ">${LedgerSMB::Sysconfig::userspath}/nologin" or $form->error($!);

			for (qw(dbname dbhost dbport dbdriver dbuser dbpasswd)) { $form->{$_} = $user->{$_} }

			$form->{dbpasswd} = unpack 'u', $form->{dbpasswd};

			$form->{dbupdate} = "db$user->{dbname}";
			$form->{$form->{dbupdate}} = 1;

			$form->header;
			print qq|<body>|;
			print $locale->text('Upgrading to Version [_1] ...', $form->{version});

			# required for Oracle
			$form->{dbdefault} = $sid;

			$user->dbupdate(\%$form);

			# remove lock file
			unlink "${LedgerSMB::Sysconfig::userspath}/nologin";

			print $locale->text('done');

			print "<p><a href=\"menu.pl?login=$form->{login}&amp;sessionid=$form->{sessionid}&amp;path=$form->{path}&amp;action=display&amp;main=company_logo&amp;js=$form->{js}>\">".$locale->text('Continue')."</a>";
			print qq|</body>|;
			exit;
		}

		$form->error($err[$errno]);
	}

	# made it this far, setup callback for the menu
	$form->{callback} = "menu.pl?action=display&password=$form->{password}";
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
	#delete the cookie in the browser manually (can't use session_destroy here unfortunately)
	print qq|Set-Cookie: LedgerSMB=; path=/;\n|;
	$form->redirect;
}



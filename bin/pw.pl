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
# Copyright (c) 2004
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
# end of main


sub getpassword {
  my ($s) = @_;

  $form->{endsession} = 1;

  $sessionexpired = qq|<p><span style="font-weight:bold; color:red;">|.$locale->text('Session expired!').qq|</span></p>| if $s;
  
  my $headeradd = qq|
<script language="JavaScript" type="text/javascript">
<!--
function sf(){
    document.pw.password.focus();
}
// End -->
</script>|;

  $form->header(undef, $headeradd);
  print qq|
<body onload="sf()">

  $sessionexpired

<form method=post action=$form->{script} name=pw>

<table>
  <tr>
    <th align=right>|.$locale->text('Password').qq|</th>
    <td><input type="password" name="password" size="30"></td>
    <td><button type="submit" value="continue">|.$locale->text('Continue').qq|</button></td>
  </tr>
</table>

|;

  for (qw(script endsession password)) { delete $form->{$_} }
  $form->hide_form;
  
  print qq|
</form>

</body>
</html>
|;

}



#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# 
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================


1;
# end of main


sub getpassword {
  my ($s) = @_;

  $form->{endsession} = 1;
  $form->header;

  $sessionexpired = qq|<b><font color=red><blink>|.$locale->text('Session expired!').qq|</blink></font></b><p>| if $s;
  
  print qq|
<script language="JavaScript" type="text/javascript">
<!--
function sf(){
    document.pw.password.focus();
}
// End -->
</script>

<body onload="sf()">

  $sessionexpired

<form method=post action=$form->{script} name=pw>

<table>
  <tr>
    <th align=right>|.$locale->text('Password').qq|</th>
    <td><input type=password name=password size=30></td>
    <td><input type=submit value="|.$locale->text('Continue').qq|"></td>
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



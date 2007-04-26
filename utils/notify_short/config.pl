#!/usr/bin/perl

use vars qw($email_to $cc_to $email_from $sendmail $database $db_user
  $db_passwd $template_head $template_foot);

# The address to send the mail to.  On UNIX systems, multiple addresses can be
# separated by a space.
$email_to = 'manager@example';

# The email address this email is from:
$email_from = 'noreply@example';

# The comamnd for sending the email:
$sendmail = "sendmail -f$email_from $email_to";

# The database containing SQL-Ledger
$database = "ledger-smb";

# The user to connect with.  This user only requires select permission to the
# parts table.

$db_user = "ls-short";

# How long between checking for Notify events?  In seconds
$cycle_delay = 60;

# The password for the db user:
$db_passwd = "mypasswd";

$template_top = "From: $email_from
Subject: Parts Short Notice

Hi.  This is the SL-Short listener.  You are receiving this message because
a recently issued invoice has reduced the number of onhand items to a level 
below its re-order point (ROP).  Please see the below report for items currently
at or below their ROP.

Partnumber         Description                          Onhand    ROP
---------------------------------------------------------------------
";

$template_foot = "
Thank you for your attention.";

format MAIL_TOP =
Partnumber         Description                          Onhand    ROP
---------------------------------------------------------------------
.
format MAIL =
@<<<<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>  @>>>>>
$partnumber,      $description,                         $avail,$rop
.
1;


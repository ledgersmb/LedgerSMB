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
# Contributors: Thomas Bayen <bayen@gmx.de>
#               Antti Kaihola <akaihola@siba.fi>
#               Moritz Bunkus (tex)
#               Jim Rawlings <jim@your-dba.com> (DB2)
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# main package
#
#======================================================================

use Math::BigFloat lib=>'GMP';
use LedgerSMB::Sysconfig;

package Form;


sub new {

	my $type = shift;

	my $argstr = shift;

	read(STDIN, $_, $ENV{CONTENT_LENGTH});

	if ($argstr){
		 $_ = $argstr;
	}
	elsif ($ENV{QUERY_STRING}) {
		$_ = $ENV{QUERY_STRING};
	}

	elsif ($ARGV[0]) {
		$_ = $ARGV[0];
	}
	
	my $self = {};
	%$self = split /[&=]/;
	for (keys %$self) { $self->{$_} = unescape("", $self->{$_}) }

	if (substr($self->{action}, 0, 1) !~ /( |\.)/) {
		$self->{action} = lc $self->{action};
		$self->{action} =~ s/( |-|,|\#|\/|\.$)/_/g;
	}

	$self->{menubar} = 1 if $self->{path} =~ /lynx/i;
	#menubar will be deprecated, replaced with below
	$self->{lynx} = 1 if $self->{path} =~ /lynx/i;

	$self->{version} = "1.2.0 Beta 3";
	$self->{dbversion} = "1.2.0";

	bless $self, $type;

}


sub debug {

	my ($self, $file) = @_;

	if ($file) {
		open(FH, '>', "$file") or die $!;
		for (sort keys %$self) { print FH "$_ = $self->{$_}\n" }
		close(FH);
	} else {
		print "\n";
		for (sort keys %$self) { print "$_ = $self->{$_}\n" }
	}

} 

sub encode_all {
	# TODO;
}

sub decode_all {
	# TODO
}

sub escape {
	my ($self, $str, $beenthere) = @_;

	# for Apache 2 we escape strings twice
	if (($ENV{SERVER_SIGNATURE} =~ /Apache\/2\.(\d+)\.(\d+)/) && !$beenthere) {
		$str = $self->escape($str, 1) if $1 == 0 && $2 < 44;
	}

	$str =~ s/([^a-zA-Z0-9_.-])/sprintf("%%%02x", ord($1))/ge;
	$str;

}


sub unescape {
	my ($self, $str) = @_;


	$str =~ tr/+/ /;
	$str =~ s/\\$//;

	$str =~ s/%([0-9a-fA-Z]{2})/pack("c",hex($1))/eg;
	$str =~ s/\r?\n/\n/g;

	$str;

}


sub quote {
	my ($self, $str) = @_;

	if ($str && ! ref($str)) {
		$str =~ s/"/&quot;/g;
	}

	$str;

}


sub unquote {
	my ($self, $str) = @_;

	if ($str && ! ref($str)) {
		$str =~ s/&quot;/"/g;
	}

	$str;

}


sub hide_form {
	my $self = shift;

	if (@_) {

		for (@_) { 
			print qq|<input type="hidden" name="$_" value="|.$self->quote($self->{$_}).qq|" />\n| 
		}

	} else {
		delete $self->{header};

		for (sort keys %$self) { 
			print qq|<input type="hidden" name="$_" value="|.$self->quote($self->{$_}).qq|" />\n| 
		}
	}
}


sub error {

	my ($self, $msg) = @_;

	if ($ENV{HTTP_USER_AGENT}) {

		$self->{msg} = $msg;
		$self->{format} = "html";
		$self->format_string('msg');

		delete $self->{pre};

		if (!$self->{header}) {
			$self->header;
		}

		print qq|<body><h2 class="error">Error!</h2> <p><b>$self->{msg}</b></body>|;

		exit;

	} else {

		if ($ENV{error_function}) {
			&{ $ENV{error_function} }($msg);
		} else {
			die "Error: $msg\n";
		}
	}
}


sub info {
	my ($self, $msg) = @_;

	if ($ENV{HTTP_USER_AGENT}) {
		$msg =~ s/\n/<br>/g;

		delete $self->{pre};

		if (!$self->{header}) {
			$self->header;
			print qq| <body>|;
			$self->{header} = 1;
		}

		print "<b>$msg</b>";

	} else {

		if ($ENV{info_function}) {
			&{ $ENV{info_function} }($msg);
		} else {
			print "$msg\n";
		}
	}
}


sub numtextrows {

	my ($self, $str, $cols, $maxrows) = @_;

	my $rows = 0;

	for (split /\n/, $str) { 
		$rows += int (((length) - 2)/$cols) + 1 
	}

	$maxrows = $rows unless defined $maxrows;

	return ($rows > $maxrows) ? $maxrows : $rows;

}


sub dberror {
	my ($self, $msg) = @_;
	$self->error("$msg\n".$DBI::errstr);
}


sub isblank {
	my ($self, $name, $msg) = @_;
	$self->error($msg) if $self->{$name} =~ /^\s*$/;
}


sub header {

	my ($self, $init, $headeradd) = @_;

	return if $self->{header};

	my ($stylesheet, $favicon, $charset);

	if ($ENV{HTTP_USER_AGENT}) {

		if ($self->{stylesheet} && (-f "css/$self->{stylesheet}")) {
			$stylesheet = qq|<link rel="stylesheet" href="css/$self->{stylesheet}" type="text/css" title="LedgerSMB stylesheet" />\n|;
		}

		if ($self->{charset}) {
			$charset = qq|<meta http-equiv="content-type" content="text/html; charset=$self->{charset}" />\n|;
		}

		$self->{titlebar} = ($self->{title}) ? "$self->{title} - $self->{titlebar}" : $self->{titlebar};

		print qq|Content-Type: text/html\n\n
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
		"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>$self->{titlebar}</title>
	<meta http-equiv="Pragma" content="no-cache" />
	<meta http-equiv="Expires" content="-1" />
	<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
	$stylesheet
	$charset
	<meta name="robots" content="noindex,nofollow" />
        $headeradd
</head>

		$self->{pre} \n|;
	}

	$self->{header} = 1;
}

sub redirect {

	my ($self, $msg) = @_;
	use List::Util qw(first);

	if ($self->{callback} || !$msg){

		main::redirect();
	} else {

		$self->info($msg);
	}
}


sub sort_columns {

	my ($self, @columns) = @_;

	if ($self->{sort}) {
		if (@columns) {
			@columns = grep !/^$self->{sort}$/, @columns;
			splice @columns, 0, 0, $self->{sort};
		}
	}

	@columns;
}


sub sort_order {

	my ($self, $columns, $ordinal) = @_;

	# setup direction
	if ($self->{direction}) {

		if ($self->{sort} eq $self->{oldsort}) {

			if ($self->{direction} eq 'ASC') {
				$self->{direction} = "DESC";
			} else {
				$self->{direction} = "ASC";
			}
		}

	} else {

		$self->{direction} = "ASC";
	}

	$self->{oldsort} = $self->{sort};

	my @a = $self->sort_columns(@{$columns});

	if (%$ordinal) {
		$a[0] = ($ordinal->{$a[$_]}) ? "$ordinal->{$a[0]} $self->{direction}" : "$a[0] $self->{direction}";

		for (1 .. $#a) { 
			$a[$_] = $ordinal->{$a[$_]} if $ordinal->{$a[$_]} 
		}

	} else {
		$a[0] .= " $self->{direction}";
	}

	$sortorder = join ',', @a;
	$sortorder;
}


sub format_amount {

	my ($self, $myconfig, $amount, $places, $dash) = @_;

	my $negative ;
	if ($amount){
		$amount = $self->parse_amount($myconfig, $amount);
		$negative = ($amount < 0);
		$amount =~ s/-//;
	}

	if ($places =~ /\d+/) {
		#$places = 4 if $places == 2;
		$amount = $self->round_amount($amount, $places);
	}

	# is the amount negative

	# Parse $myconfig->{numberformat}



	my ($ts, $ds) = ($1, $2);

	if ($amount) {

		if ($myconfig->{numberformat}) {

			my ($whole, $dec) = split /\./, "$amount";
			$amount = join '', reverse split //, $whole;

			if ($places) {
				$dec .= "0" x $places;
				$dec = substr($dec, 0, $places);
			}

			if ($myconfig->{numberformat} eq '1,000.00') {
				$amount =~ s/\d{3,}?/$&,/g;
				$amount =~ s/,$//;
				$amount = join '', reverse split //, $amount;
				$amount .= "\.$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq '1 000.00') {
				$amount =~ s/\d{3,}?/$& /g;
				$amount =~ s/\s$//;
				$amount = join '', reverse split //, $amount;
				$amount .= "\.$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq "1'000.00") {
				$amount =~ s/\d{3,}?/$&'/g;
				$amount =~ s/'$//;
				$amount = join '', reverse split //, $amount;
				$amount .= "\.$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq '1.000,00') {
				$amount =~ s/\d{3,}?/$&./g;
				$amount =~ s/\.$//;
				$amount = join '', reverse split //, $amount;
				$amount .= ",$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq '1000,00') {
				$amount = "$whole";
				$amount .= ",$dec" if ($dec ne "");
			}

			if ($myconfig->{numberformat} eq '1000.00') {
				$amount = "$whole";
				$amount .= ".$dec" if ($dec ne "");
			}

			if ($dash =~ /-/) {
				$amount = ($negative) ? "($amount)" : "$amount";
			} elsif ($dash =~ /DRCR/) {
				$amount = ($negative) ? "$amount DR" : "$amount CR";
			} else {
				$amount = ($negative) ? "-$amount" : "$amount";
			}
		}

	} else {

		if ($dash eq "0" && $places) {

			if ($myconfig->{numberformat} eq '1.000,00') {
				$amount = "0".","."0" x $places;
			} else {
				$amount = "0"."."."0" x $places;
			}

		} else {
			$amount = ($dash ne "") ? "$dash" : "";
		}
	}

	$amount;
}


sub parse_amount {

	my ($self, $myconfig, $amount) = @_;

	if (($amount eq '') or ($amount eq undef)) {
		return undef;
	}

	if (UNIVERSAL::isa($amount, 'Math::BigFloat')){ # Amount may not be an object	
		return $amount;
	}
	my $numberformat = $myconfig->{numberformat};


	if (($numberformat eq '1.000,00') ||
		($numberformat eq '1000,00')) {

		$amount =~ s/\.//g;
		$amount =~ s/,/./;
	}
	if ($numberformat eq '1 000.00'){
		$amount =~ s/\s//g;
	}

	if ($numberformat eq "1'000.00") {
		$amount =~ s/'//g;
	}


	$amount =~ s/,//g;
	if ($amount =~ s/\((\d*\.?\d*)\)/$1/){
		$amount = $1 * -1;
	}
	if ($amount =~ s/(\d*\.?\d*)\s?DR/$1/){
		$amount = $1 * -1;
	}
	$amount =~ s/\s?CR//;
	$amount = new Math::BigFloat($amount);
	return ($amount * 1);
}


sub round_amount {

	my ($self, $amount, $places) = @_;

	# These rounding rules follow from the previous implementation.
	# They should be changed to allow different rules for different accounts.
	Math::BigFloat->round_mode('+inf') if $amount >= 0;
	Math::BigFloat->round_mode('-inf') if $amount < 0;

	$amount = Math::BigFloat->new($amount)->ffround(-$places) if $places >= 0;
	$amount = Math::BigFloat->new($amount)->ffround(-($places-1)) if $places < 0;

	return $amount;
}

sub callproc {
	my $procname = shift @_;
	my $argstr = "";
	my @results;
	for (1 .. $#_){
		$argstr .= "?, ";
	}
	$argstr =~ s/\, $//;
	$query = "SELECT $procname";
	$query =~ s/\(\)/$argstr/;
	my $sth = $self->{dbh}->prepare($query);
	while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
		push @results, $ref;
	}
	@results;
}

sub get_my_emp_num {
	my ($self, $myconfig, $form) = @_;
	%myconfig = %{$myconfig};
	my $dbh = $form->{dbh};
	# we got a connection, check the version
	my $query = qq|
		SELECT employeenumber FROM employee 
		 WHERE login = ?|;
	my $sth = $dbh->prepare($query);
	$sth->execute($form->{login}) || $form->dberror($query);
	$sth->execute;

	my ($id) = $sth->fetchrow_array;
	$sth->finish;
	$form->{'emp_num'} = $id;
}

sub parse_template {

	my ($self, $myconfig) = @_;

	my ($chars_per_line, $lines_on_first_page, $lines_on_second_page) = (0, 0, 0);
	my ($current_page, $current_line) = (1, 1);
	my $pagebreak = "";
	my $sum = 0;

	my $subdir = "";
	my $err = "";

	my %include = ();
	my $ok;

	if ($self->{language_code}) {

		if (-f "$self->{templates}/$self->{language_code}/$self->{IN}") {
			open(IN, '<', "$self->{templates}/$self->{language_code}/$self->{IN}") or $self->error("$self->{IN} : $!");
		} else {
			open(IN, '<', "$self->{templates}/$self->{IN}") or $self->error("$self->{IN} : $!");
		}

	} else {
		open(IN, "$self->{templates}/$self->{IN}") or $self->error("$self->{IN} : $!");
	}

	@_ = <IN>;
	close(IN);

	$self->{copies} = 1 if (($self->{copies} *= 1) <= 0);

	# OUT is used for the media, screen, printer, email
	# for postscript we store a copy in a temporary file
	my $fileid = time;
	my $tmpfile = $self->{IN};
	$tmpfile =~ s/\./_$self->{fileid}./ if $self->{fileid};
	$self->{tmpfile} = "${LedgerSMB::Sysconfig::userspath}/${fileid}_${tmpfile}";

    my $temphash;
	if ($self->{format} =~ /(postscript|pdf)/ || $self->{media} eq 'email') {
		$temphash{out} = $self->{OUT};
		$self->{OUT} = "$self->{tmpfile}";
        $temphash{printmode} = $self->{printmode};
        $self->{printmode} = '>';
	}

	if ($self->{OUT}) {
		open(OUT, $self->{printmode}, "$self->{OUT}") or $self->error("$self->{OUT} : $!");

	} else {
		open(OUT, ">-") or $self->error("STDOUT : $!");
		$self->header;
	}

	# first we generate a tmpfile
	# read file and replace <?lsmb variable ?>
	while ($_ = shift) {

		$par = "";
		$var = $_;

		# detect pagebreak block and its parameters
		if (/<\?lsmb pagebreak ([0-9]+) ([0-9]+) ([0-9]+) \?>/) {
			$chars_per_line = $1;
			$lines_on_first_page = $2;
			$lines_on_second_page = $3;

			while ($_ = shift) {
				last if (/<\?lsmb end pagebreak \?>/);
				$pagebreak .= $_;
			}
		}

		if (/<\?lsmb foreach /) {

			# this one we need for the count
			chomp $var;
			$var =~ s/.*?<\?lsmb foreach (.+?) \?>/$1/;
			while ($_ = shift) {
				last if (/<\?lsmb end $var \?>/);

				# store line in $par
				$par .= $_;
			}

			# display contents of $self->{number}[] array
			for $i (0 .. $#{ $self->{$var} }) {

				if ($var =~ /^(part|service)$/) {
					next if $self->{$var}[$i] eq 'NULL';
				}

				# Try to detect whether a manual page break is necessary
				# but only if there was a <?lsmb pagebreak ... ?> block before

				if ($var eq 'number' || $var eq 'part' || $var eq 'service') {

					if ($chars_per_line && defined $self->{$var}) {

						my $line;
						my $lines = 0;
						my @d = qw(description);
						push @d, "itemnotes" if $self->{countitemnotes};

						foreach my $item (@d) {

							if ($self->{$item}[$i]) {

								foreach $line (split /\r?\n/, $self->{$item}[$i]) {
									$lines++;
									$lines += int(length($line) / $chars_per_line);
								}
							}
						}

						my $lpp;

						if ($current_page == 1) {
							$lpp = $lines_on_first_page;
						} else {
							$lpp = $lines_on_second_page;
						}

						# Yes we need a manual page break
						if (($current_line + $lines) > $lpp) {
							my $pb = $pagebreak;

							# replace the special variables <?lsmb sumcarriedforward ?>
							# and <?lsmb lastpage ?>
							my $psum = $self->format_amount($myconfig, $sum, 2);
							$pb =~ s/<\?lsmb sumcarriedforward \?>/$psum/g;
							$pb =~ s/<\?lsmb lastpage \?>/$current_page/g;

							# only "normal" variables are supported here
							# (no <?lsmb if, no <?lsmb foreach, no <?lsmb include)
							$pb =~ s/<\?lsmb (.+?) \?>/$self->{$1}/g;

							# page break block is ready to rock
							print(OUT $pb);
							$current_page++;
							$current_line = 1;
							$lines = 0;
						}

						$current_line += $lines;
					}

					$sum += $self->parse_amount($myconfig, $self->{linetotal}[$i]);
				}

				# don't parse par, we need it for each line
				print OUT $self->format_line($par, $i);
			}
			next;
		}

		# if not comes before if!
		if (/<\?lsmb if not /) {

			# check if it is not set and display
			chop;
			s/.*?<\?lsmb if not (.+?) \?>/$1/;

			if (! $self->{$_}) {

				while ($_ = shift) {
					last if (/<\?lsmb end /);

					# store line in $par
					$par .= $_;
				}

				$_ = $par;

			} else {

				while ($_ = shift) {
					last if (/<\?lsmb end /);
				}

				next;
			}
		}

		if (/<\?lsmb if /) {

			# check if it is set and display
			chop;
			s/.*?<\?lsmb if (.+?) \?>/$1/;

			if (/\s/) {
				@a = split;
				$ok = eval "$self->{$a[0]} $a[1] $a[2]";
			} else {
				$ok = $self->{$_};
			}

			if ($ok) {
				while ($_ = shift) {
					last if (/<\?lsmb end /);
					# store line in $par
					$par .= $_;
				}

				$_ = $par;

			} else {

				while ($_ = shift) {
					last if (/<\?lsmb end /);
				}

				next;
			}
		}

		# check for <?lsmb include filename ?>
		if (/<\?lsmb include /) {

			# get the filename
			chomp $var;
			$var =~ s/.*?<\?lsmb include (.+?) \?>/$1/;

			# remove / .. for security reasons
			$var =~ s/(\/|\.\.)//g;

			# assume loop after 10 includes of the same file
			next if ($include{$var} > 10);

			unless (open(INC, '<', "$self->{templates}/$self->{language_code}/$var")) {
				$err = $!;
				$self->cleanup;
				$self->error("$self->{templates}/$self->{language_code}/$var : $err");
			}

			unshift(@_, <INC>);
			close(INC);

			$include{$var}++;

			next;
		}

		print OUT $self->format_line($_);

	}

	close(OUT);

	delete $self->{countitemnotes};

	# Convert the tex file to postscript
	if ($self->{format} =~ /(postscript|pdf)/) {

		use Cwd;
		$self->{cwd} = cwd();
		$self->{tmpdir} = "$self->{cwd}/${LedgerSMB::Sysconfig::userspath}";
		$self->{tmpdir} = "${LedgerSMB::Sysconfig::userspath}" if
			${LedgerSMB::Sysconfig::userspath} =~ /^\//;

		unless (chdir("${LedgerSMB::Sysconfig::userspath}")) {
			$err = $!;
			$self->cleanup;
			$self->error("chdir : $err");
		}

		$self->{tmpfile} =~ s/${LedgerSMB::Sysconfig::userspath}\///g;

		$self->{errfile} = $self->{tmpfile};
		$self->{errfile} =~ s/tex$/err/;

		my $r = 1;
		if ($self->{format} eq 'postscript') {

		system("latex --interaction=nonstopmode $self->{tmpfile} > $self->{errfile}");

		while ($self->rerun_latex) {
			system("latex --interaction=nonstopmode $self->{tmpfile} > $self->{errfile}");
			last if ++$r > 4;
		}

		$self->{tmpfile} =~ s/tex$/dvi/;
		$self->error($self->cleanup) if ! (-f $self->{tmpfile});

		system("dvips $self->{tmpfile} -o -q");
			$self->error($self->cleanup."dvips : $!") if ($?);
			$self->{tmpfile} =~ s/dvi$/ps/;
		}

		if ($self->{format} eq 'pdf') {
			system("pdflatex --interaction=nonstopmode $self->{tmpfile} > $self->{errfile}");

			while ($self->rerun_latex) {
				system("pdflatex --interaction=nonstopmode $self->{tmpfile} > $self->{errfile}");
				last if ++$r > 4;
			}

			$self->{tmpfile} =~ s/tex$/pdf/;
			$self->error($self->cleanup) if ! (-f $self->{tmpfile});
		}
	}


	if ($self->{format} =~ /(postscript|pdf)/ || $self->{media} eq 'email') {

		if ($self->{media} eq 'email') {

			use LedgerSMB::Mailer;

			my $mail = new Mailer;

			for (qw(cc bcc subject message version format charset)) { 
				$mail->{$_} = $self->{$_} 
			}

			$mail->{to} = qq|$self->{email}|;
			$mail->{from} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
			$mail->{notify} = $self->{notify};
			$mail->{fileid} = "$fileid.";

			# if we send html or plain text inline
			if (($self->{format} =~ /(html|txt)/) && 
				($self->{sendmode} eq 'inline')) {

				my $br = "";
				$br = "<br>" if $self->{format} eq 'html';

				$mail->{contenttype} = "text/$self->{format}";

				$mail->{message} =~ s/\r?\n/$br\n/g;
				$myconfig->{signature} =~ s/\\n/$br\n/g;
				$mail->{message} .= "$br\n-- $br\n$myconfig->{signature}\n$br" if $myconfig->{signature};

				unless (open(IN, '<', $self->{tmpfile})) {
					$err = $!;
					$self->cleanup;
					$self->error("$self->{tmpfile} : $err");
				}

				while (<IN>) {
					$mail->{message} .= $_;
				}

				close(IN);

			} else {

				@{ $mail->{attachments} } = ($self->{tmpfile});

				$myconfig->{signature} =~ s/\\n/\n/g;
				$mail->{message} .= "\n-- \n$myconfig->{signature}" if $myconfig->{signature};

			}

			if ($err = $mail->send) {
				$self->cleanup;
				$self->error($err);
			}

		} else {

			$self->{OUT} = $temphash{out};
            $self->{printmode} = $temphash{printmode} if $temphash{printmode};

			unless (open(IN, '<', $self->{tmpfile})) {
				$err = $!;
				$self->cleanup;
				$self->error("$self->{tmpfile} : $err");
			}

			binmode(IN);

			$self->{copies} = 1 if $self->{media} =~ /(screen|email|queue)/;

			chdir("$self->{cwd}");

			for my $i (1 .. $self->{copies}) {
				if ($self->{OUT}) {

					unless (open(OUT, $self->{printmode}, $self->{OUT})) {
						$err = $!;
						$self->cleanup;
						$self->error("$self->{OUT} : $err");
					}

				} else {

					# launch application
					print qq|Content-Type: application/$self->{format}\n|.
						  qq|Content-Disposition: attachment; filename="$self->{tmpfile}"\n\n|;

					unless (open(OUT, ">-")) {
						$err = $!;
						$self->cleanup;
						$self->error("STDOUT : $err");
					}
				}

				binmode(OUT);

				while (<IN>) {
					print OUT $_;
				}

				close(OUT);
				seek IN, 0, 0;
			}

			close(IN);
		}

		$self->cleanup;
	}
}


sub format_line {

	my $self = shift;

	$_ = shift;
	my $i = shift;

	my $str;
	my $newstr;
	my $pos;
	my $l;
	my $lf;
	my $line;
	my $var = "";
	my %a;
	my $offset;
	my $pad;
	my $item;

	while (/<\?lsmb (.+?) \?>/) {

		%a = ();

		foreach $item (split / /, $1) {
			my ($key, $value) = split /=/, $item;

			if ($value ne "") {
				$a{$key} = $value;
			} else {
				$var = $item;
			}
		}

		$str = (defined $i) ? $self->{$var}[$i] : $self->{$var};
		$newstr = $str;

		$self->{countitemnotes} = 1 if $var eq 'itemnotes';

		$var = $1;
		if ($var =~ /^if\s+not\s+/) {

			if ($str) {

				$var =~ s/if\s+not\s+//;
				s/<\?lsmb if\s+not\s+$var \?>.*?(<\?lsmb end\s+$var \?>|$)//s;

			} else {
				s/<\?lsmb $var \?>//;
			}

			next;
		}

		if ($var =~ /^if\s+/) {

			if ($str) {
				s/<\?lsmb $var \?>//;
			} else {
				$var =~ s/if\s+//;
				s/<\?lsmb if\s+$var \?>.*?(<\?lsmb end\s+$var \?>|$)//s;
			}

			next;
		}

		if ($var =~ /^end\s+/) {
			s/<\?lsmb $var \?>//;
			next;
		}

		if ($a{align} || $a{width} || $a{offset}) {

			$newstr = "";
			$offset = 0;
			$lf = "";

			foreach $str (split /\n/, $str) {

				$line = $str;
				$l = length $str;

				do {

					if (($pos = length $str) > $a{width}) {

						if (($pos = rindex $str, " ", $a{width}) > 0) {
							$line = substr($str, 0, $pos);
						}

						$pos = length $str if $pos == -1;
					}

					$l = length $line;

					# pad left, right or center
					$l = ($a{width} - $l);

					$pad = " " x $l;

					if ($a{align} =~ /right/i) {
						$line = " " x $offset . $pad . $line;
					}

					if ($a{align} =~ /left/i) {
						$line = " " x $offset . $line . $pad;
					}

					if ($a{align} =~ /center/i) {
						$pad = " " x ($l/2);
						$line = " " x $offset . $pad . $line;
						$pad = " " x ($l/2);
						$line .= $pad;
					}

					$newstr .= "$lf$line";

					$str = substr($str, $pos + 1);
					$line = $str;
					$lf = "\n";

					$offset = $a{offset};

				} while ($str);
			}
		}

		s/<\?lsmb (.+?) \?>/$newstr/;

	}

	$_;
}


sub cleanup {

	my $self = shift;

	chdir("$self->{tmpdir}");

	my @err = ();

	if (-f "$self->{errfile}") {
		open(FH, '<', "$self->{errfile}");
		@err = <FH>;
		close(FH);
	}

	if ($self->{tmpfile}) {
		# strip extension
		$self->{tmpfile} =~ s/\.\w+$//g;
		my $tmpfile = $self->{tmpfile};
		unlink(<$tmpfile.*>);
	}

	chdir("$self->{cwd}");

	"@err";
}


sub rerun_latex {

	my $self = shift;

	my $a = 0;

	if (-f "$self->{errfile}") {
		open(FH, '<', "$self->{errfile}");
		$a = grep /(longtable Warning:|Warning:.*?LastPage)/, <FH>;
		close(FH);
	}

	$a;
}


sub format_string {

	my ($self, @fields) = @_;

	my $format = $self->{format};

	if ($self->{format} =~ /(postscript|pdf)/) {
		$format = 'tex';
	}

	my %replace = ( 
		'order' => { 
			html => [ '<', '>', '\n', '\r' ],
			txt  => [ '\n', '\r' ],
			tex  => [ quotemeta('\\'), '&', '\n','\r', 
				'\$', '%', '_', '#',
				quotemeta('^'), '{', '}', '<', '>', '£' 
				] },
		html => { '<'  => '&lt;', '>' => '&gt;','\n' => '<br />', 
			'\r' => '<br />' },
		txt  => { '\n' => "\n", '\r' => "\r" },
		tex  => {'&' => '\&', '$' => '\$', '%' => '\%', '_' => '\_',
			'#' => '\#', quotemeta('^') => '\^\\', '{' => '\{', 
			'}' => '\}', '<' => '$<$', '>' => '$>$',
			'\n' => '\newline ', '\r' => '\newline ', 
			'£' => '\pounds ', quotemeta('\\') => '/'} 
	);

	my $key;

	foreach $key (@{ $replace{order}{$format} }) {
		for (@fields) { $self->{$_} =~ s/$key/$replace{$format}{$key}/g }
	}

}


sub datetonum {

	my ($self, $myconfig, $date, $picture) = @_;

	if ($date && $date =~ /\D/) {

		if ($myconfig->{dateformat} =~ /^yy/) {
			($yy, $mm, $dd) = split /\D/, $date;
		}

		if ($myconfig->{dateformat} =~ /^mm/) {
			($mm, $dd, $yy) = split /\D/, $date;
		}

		if ($myconfig->{dateformat} =~ /^dd/) {
			($dd, $mm, $yy) = split /\D/, $date;
		}

		$dd *= 1;
		$mm *= 1;
		$yy += 2000 if length $yy == 2;

		$dd = substr("0$dd", -2);
		$mm = substr("0$mm", -2);

		$date = "$yy$mm$dd";
	}

	$date;
}


sub add_date {

	my ($self, $myconfig, $date, $repeat, $unit) = @_;

	use Time::Local;

	my $diff = 0;
	my $spc = $myconfig->{dateformat};
	$spc =~ s/\w//g;
	$spc = substr($spc, 0, 1);

	if ($date) {

		if ($date =~ /\D/) {

			if ($myconfig->{dateformat} =~ /^yy/) {
				($yy, $mm, $dd) = split /\D/, $date;
			}

			if ($myconfig->{dateformat} =~ /^mm/) {
				($mm, $dd, $yy) = split /\D/, $date;
			}

			if ($myconfig->{dateformat} =~ /^dd/) {
				($dd, $mm, $yy) = split /\D/, $date;
			}

		} else {
			# ISO
			($yy, $mm, $dd) =~ /(....)(..)(..)/;
		}

		if ($unit eq 'days') {
			$diff = $repeat * 86400;
		}

		if ($unit eq 'weeks') {
			$diff = $repeat * 604800;
		}

		if ($unit eq 'months') {
			$diff = $mm + $repeat;

			my $whole = int($diff / 12);
			$yy += $whole;

			$mm = ($diff % 12) + 1;
			$diff = 0;
		}

		if ($unit eq 'years') {
			$yy++;
		}

		$mm--;

		@t = localtime(timelocal(0,0,0,$dd,$mm,$yy) + $diff);

		$t[4]++;
		$mm = substr("0$t[4]",-2);
		$dd = substr("0$t[3]",-2);
		$yy = $t[5] + 1900;

		if ($date =~ /\D/) {

			if ($myconfig->{dateformat} =~ /^yy/) {
				$date = "$yy$spc$mm$spc$dd";
			}

			if ($myconfig->{dateformat} =~ /^mm/) {
				$date = "$mm$spc$dd$spc$yy";
			}

			if ($myconfig->{dateformat} =~ /^dd/) {
				$date = "$dd$spc$mm$spc$yy";
			}

		} else {
			$date = "$yy$mm$dd";
		}
	}

	$date;
}


sub print_button {
	my ($self, $button, $name) = @_;

	print qq|<button class="submit" type="submit" name="action" value="$name" accesskey="$button->{$name}{key}" title="$button->{$name}{value} [Alt-$button->{$name}{key}]">$button->{$name}{value}</button>\n|;
}          


# Database routines used throughout

sub db_init {
	my ($self, $myconfig) = @_;
	$self->{dbh} = $self->dbconnect_noauto($myconfig) || $self->dberror();

	my $query = 
		"SELECT t.extends, 
			coalesce (t.table_name, 'custom_' || extends) 
			|| ':' || f.field_name as field_def
		FROM custom_table_catalog t
		JOIN custom_field_catalog f USING (table_id)";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute;
	my $ref;
	while ($ref = $sth->fetchrow_hashref(NAME_lc)){
		push @{$self->{custom_db_fields}{$ref->{extends}}},
			$ref->{field_def};
	}
}

sub run_custom_queries {
	my ($self, $tablename, $query_type, $linenum) = @_;
	my $dbh = $self->{dbh};
	if ($query_type !~ /^(select|insert|update)$/i){
		$self->error($locale->text(
			"Passed incorrect query type to run_custom_queries."
		));
	}
	my @rc;
	my %temphash;
	my @templist;
	my @elements;
	my $query;
	my $ins_values;
	if ($linenum){
		$linenum = "_$linenum";
	}

	$query_type = uc($query_type);
	for (@{$self->{custom_db_fields}{$tablename}}){
		@elements = split (/:/, $_);
		push @{$temphash{$elements[0]}}, $elements[1];
	}
	for (keys %temphash){
		my @data;
		my $ins_values;
		$query = "$query_type ";
		if ($query_type eq 'UPDATE'){
			$query = "DELETE FROM $_ WHERE row_id = ?";
			my $sth = $dbh->prepare($query);
			$sth->execute->($self->{"id"."$linenum"})
				|| $self->dberror($query);
		} elsif ($query_type eq 'INSERT'){
			$query .= " INTO $_ (";
		}
		my $first = 1;
		for (@{$temphash{$_}}){
			$query .= "$_";
			if ($query_type eq 'UPDATE'){
				$query .= '= ?';
			}	
			$ins_values .= "?, ";
			$query .= ", ";
			$first = 0;
			if ($query_type eq 'UPDATE' or $query_type eq 'INSERT'){
				push @data, $self->{"$_$linenum"}; 
			}
		}
		if ($query_type ne 'INSERT'){
			$query =~ s/, $//;
		}
		if ($query_type eq 'SELECT'){
			$query .= " FROM $_";
		}
		if ($query_type eq 'SELECT' or $query_type eq 'UPDATE'){
			$query .= " WHERE row_id = ?";
		}
		if ($query_type eq 'INSERT'){
			$query .= " row_id) VALUES ($ins_values ?)";
		}
		if ($query_type eq 'SELECT'){
			push @rc, [ $query ];
		} else {
			unshift (@data, $query);
			push @rc, [ @data ];
		}
	}
	if ($query_type eq 'INSERT'){
		for (@rc){
			$query = shift (@{$_});
			$sth = $dbh->prepare($query) 
				|| $self->db_error($query);
			$sth->execute(@{$_}, $self->{id})
				|| $self->dberror($query);;
			$sth->finish;
			$did_insert = 1;
		}
	} elsif ($query_type eq 'UPDATE'){
		@rc = $self->run_custom_queries(
			$tablename, 'INSERT', $linenum);
	} elsif ($query_type eq 'SELECT'){
		for (@rc){
			$query = shift @{$_};
			$sth = $self->{dbh}->prepare($query);
			$sth->execute($self->{id});
			$ref = $sth->fetchrow_hashref(NAME_lc);
			for (keys %{$ref}){
				$self->{$_} = $ref->{$_};
			}
		}
	}
	@rc;
}


sub dbconnect {

	my ($self, $myconfig) = @_;

	# connect to database
	my $dbh = DBI->connect($myconfig->{dbconnect}, $myconfig->{dbuser}, $myconfig->{dbpasswd}) or $self->dberror;

	# set db options
	if ($myconfig->{dboptions}) {
		$dbh->do($myconfig->{dboptions}) || $self->dberror($myconfig->{dboptions});
	}

	$dbh;
}


sub dbconnect_noauto {

	my ($self, $myconfig) = @_;

	# connect to database
	$dbh = DBI->connect($myconfig->{dbconnect}, $myconfig->{dbuser}, $myconfig->{dbpasswd}, {AutoCommit => 0}) or $self->dberror;

	# set db options
	if ($myconfig->{dboptions}) {
		$dbh->do($myconfig->{dboptions});
	}

	$dbh;
}


sub dbquote {

	my ($self, $var) = @_;

	if ($var eq ''){
		$_ = "NULL";
	} else {
		$_ = $self->{dbh}->quote($var);
	}
	$_;
}


sub update_balance {
	# This is a dangerous private function.  All apps calling it must
	# be careful to avoid SQL injection issues

	my ($self, $dbh, $table, $field, $where, $value) = @_;

	# if we have a value, go do it
	if ($value) {
		# retrieve balance from table
		my $query = "SELECT $field FROM $table WHERE $where FOR UPDATE";
		my ($balance) = $dbh->selectrow_array($query);

		$balance += $value;
		# update balance
		$query = "UPDATE $table SET $field = $balance WHERE $where";
		$dbh->do($query) || $self->dberror($query);
	}
}


sub update_exchangerate {

	my ($self, $dbh, $curr, $transdate, $buy, $sell) = @_;

	# some sanity check for currency
	return if ($curr eq "");

	my $query = qq|
		SELECT curr 
		FROM exchangerate
		WHERE curr = ?
		AND transdate = ?
		FOR UPDATE|;

	my $sth = $self->{dbh}->prepare($query);
	$sth->execute($curr, $transdate) || $self->dberror($query);

	my $set;
	my @queryargs;

	if ($buy && $sell) {
		$set = "buy = ?, sell = ?";
		@queryargs = ($buy, $sell);
	} elsif ($buy) {
		$set = "buy = ?";
		@queryargs = ($buy);
	} elsif ($sell) {
		$set = "sell = ?";
		@queryargs = ($sell);
	}

	if ($sth->fetchrow_array) {
		$query = qq|UPDATE exchangerate
					   SET $set
					 WHERE curr = ?
					   AND transdate = ?|;
		push (@queryargs, $curr, $transdate);

	} else {
		$query = qq|
			INSERT INTO exchangerate (
			curr, buy, sell, transdate)
			VALUES (?, ?, ?, ?)|;
		@queryargs = ($curr, $buy, $sell, $transdate);
	}
	$sth->finish;
	$sth = $self->{dbh}->prepare($query);

	$sth->execute(@queryargs) || $self->dberror($query);

}


sub save_exchangerate {

	my ($self, $myconfig, $currency, $transdate, $rate, $fld) = @_;

	my ($buy, $sell) = (0, 0);
	$buy = $rate if $fld eq 'buy';
	$sell = $rate if $fld eq 'sell';

	$self->update_exchangerate(
			$self->{dbh}, 
			$currency, 
			$transdate, 
			$buy, 
			$sell);

	$dbh->commit;
}


sub get_exchangerate {

	my ($self, $dbh, $curr, $transdate, $fld) = @_;

	my $exchangerate = 1;

	if ($transdate) {
		my $query = qq|
			SELECT $fld FROM exchangerate
			WHERE curr = ? AND transdate = ?|;
		$sth = $self->{dbh}->prepare($query);
		$sth->execute($curr, $transdate);

		($exchangerate) = $sth->fetchrow_array;
	}

	$exchangerate;
	$sth->finish;
	$self->{dbh}->commit;
}


sub check_exchangerate {

	my ($self, $myconfig, $currency, $transdate, $fld) = @_;

	return "" unless $transdate;


	my $query = qq|
		SELECT $fld 
		FROM exchangerate
		WHERE curr = ? AND transdate = ?|;

	my $sth = $self->{dbh}->prepare($query);
	$sth->execute($currenct, $transdate);
	my ($exchangerate) = $sth->fetchrow_array;

	$sth->finish;
	$self->{dbh}->commit;

	$exchangerate;
}


sub add_shipto {
	my ($self, $dbh, $id) = @_;

	my $shipto;

	foreach my $item (qw(name address1 address2 city state 
						 zipcode country contact phone fax email)) {

		if ($self->{"shipto$item"} ne "") {
			$shipto = 1 if ($self->{$item} ne $self->{"shipto$item"});
		}
	}

	if ($shipto) {
		my $query = qq|
			INSERT INTO shipto 
			(trans_id, shiptoname, shiptoaddress1,
				shiptoaddress2, shiptocity, shiptostate,
				shiptozipcode, shiptocountry, shiptocontact,
				shiptophone, shiptofax, shiptoemail) 
			VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			|;

		$sth = $self->{dbh}->prepare($query) || $self->dberror($query);
		$sth->execute(
			$id, $self->{shiptoname}, $self->{shiptoaddress1},
			$self->{shiptoaddress2}, $self->{shiptocity},
			$self->{shiptostate}, 
			$self->{shiptozipcode}, $self->{shiptocountry},
			$self->{shiptocontact}, $self->{shiptophone},
			$self->{shiptofax}, $self->{shiptoemail}
		) || $self->dberror($query);
		$sth->finish;
		$self->{dbh}->commit;
	}
}


sub get_employee {
	my ($self, $dbh) = @_;

	my $login = $self->{login};
	$login =~ s/@.*//;

	my $query = qq|SELECT name, id 
					 FROM employee 
					WHERE login = ?|;

	$sth = $self->{dbh}->prepare($query);
	$sth->execute($login);
	my (@a) = $sth->fetchrow_array();
	$a[1] *= 1;

	$sth->finish;
	$self->{dbh}->commit;

	@a;
}


# this sub gets the id and name from $table
sub get_name {

	my ($self, $myconfig, $table, $transdate) = @_;

	# connect to database

	my @queryargs;
	my $where;
	if ($transdate) {
		$where = qq|
			AND (startdate IS NULL OR startdate <= ?)
					AND (enddate IS NULL OR enddate >= ?)|;

		@queryargs = ($transdate, $transdate);
	}

	my $name = $self->like(lc $self->{$table});

	my $query = qq|
		SELECT * FROM $table
		WHERE (lower(name) LIKE ? OR ${table}number LIKE ?)
		$where
		ORDER BY name|;

	unshift(@queryargs, $name, $name);
	my $sth = $self->{dbh}->prepare($query);

	$sth->execute(@queryargs) || $self->dberror($query);

	my $i = 0;
	@{ $self->{name_list} } = ();

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push(@{ $self->{name_list} }, $ref);
		$i++;
	}

	$sth->finish;
	$self->{dbh}->commit;

	$i;

}


sub all_vc {

	my ($self, $myconfig, $vc, $module, $dbh, $transdate, $job) = @_;

	my $ref;
	my $disconnect = 0;

	$dbh = $self->{dbh};

	my $sth;

	my $query = qq|SELECT count(*) FROM $vc|;
	my $where;
	my @queryargs = ();

	if ($transdate) {
		$query .= qq| WHERE (startdate IS NULL OR startdate <= ?)
					AND (enddate IS NULL OR enddate >= ?)|;

		@queryargs = ($transdate, $transdate);		
	}

	$sth = $dbh->prepare($query);

	$sth->execute(@queryargs);

	my ($count) = $sth->fetchrow_array;

	$sth->finish;
	@queryargs = ();
	# build selection list
	if ($count < $myconfig->{vclimit}) {

		$self->{"${vc}_id"} *= 1;

		$query = qq|SELECT id, name
					  FROM $vc
					 WHERE 1=1
						   $where

					 UNION 

					SELECT id,name
					  FROM $vc
					 WHERE id = ?
				  ORDER BY name|;

		push(@queryargs, $self->{"${vc}_id"});

		$sth = $dbh->prepare($query);
		$sth->execute(@queryargs) || $self->dberror($query);

		@{ $self->{"all_$vc"} } = ();

		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
			push @{ $self->{"all_$vc"} }, $ref;
		}

		$sth->finish;

	}

	# get self
	if (! $self->{employee_id}) {
		($self->{employee}, $self->{employee_id}) = split /--/, $self->{employee};
		($self->{employee}, $self->{employee_id}) = $self->get_employee($dbh) unless $self->{employee_id};
	}

	$self->all_employees($myconfig, $dbh, $transdate, 1);

	$self->all_departments($myconfig, $dbh, $vc);

	$self->all_projects($myconfig, $dbh, $transdate, $job);

	# get language codes
	$query = qq|SELECT *
				  FROM language
			  ORDER BY 2|;

	$sth = $dbh->prepare($query);
	$sth->execute || $self->dberror($query);

	$self->{all_language} = ();

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $self->{all_language} }, $ref;
	}

	$sth->finish;
	$self->all_taxaccounts($myconfig, $dbh, $transdate);
	$self->{dbh}->commit;
}


sub all_taxaccounts {

	my ($self, $myconfig, $dbh2, $transdate) = @_;

	my $dbh = $self->{dbh};

	my $sth;
	my $query;
	my $where;

	my @queryargs = ();

	if ($transdate) {
		$where = qq| AND (t.validto >= ? OR t.validto IS NULL)|;
		push(@queryargs, $transdate);
	}

	if ($self->{taxaccounts}) {

		# rebuild tax rates
		$query = qq|SELECT t.rate, t.taxnumber 
					  FROM tax t 
					  JOIN chart c ON (c.id = t.chart_id) 
					 WHERE c.accno = ?
					$where
				  ORDER BY accno, validto|;

		$sth = $dbh->prepare($query) || $self->dberror($query);

		foreach my $accno (split / /, $self->{taxaccounts}) {
			$sth->execute($accno, @queryargs); 
			($self->{"${accno}_rate"}, $self->{"${accno}_taxnumber"}) = $sth->fetchrow_array;
			$sth->finish;
		}
	}
	$self->{dbh}->commit;
}


sub all_employees {

	my ($self, $myconfig, $dbh2, $transdate, $sales) = @_;

	my $dbh = $self->{dbh};
	my @whereargs = ();
	# setup employees/sales contacts
	my $query = qq|SELECT id, name
					 FROM employee
					WHERE 1 = 1|;

	if ($transdate) {
		$query .= qq| AND (startdate IS NULL OR startdate <= ?)
		AND (enddate IS NULL OR enddate >= ?)|;
		@whereargs = ($transdate, $transdate);
	} else {
		$query .= qq| AND enddate IS NULL|;
	}

	if ($sales) {
		$query .= qq| AND sales = '1'|;
	}

	$query .= qq| ORDER BY name|;
	my $sth = $dbh->prepare($query);
	$sth->execute(@whereargs) || $self->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $self->{all_employee} }, $ref;
	}

	$sth->finish;
	$dbh->commit;
}



sub all_projects {

	my ($self, $myconfig, $dbh2, $transdate, $job) = @_;

	my $dbh = $self->{dbh};
	my @queryargs = ();

	my $where = "1 = 1";

	$where = qq|id NOT IN (SELECT id
							 FROM parts
							WHERE project_id > 0)| if ! $job;

	my $query = qq|SELECT *
					 FROM project
					WHERE $where|;

	if ($self->{language_code}) {

		$query = qq|
			SELECT pr.*, t.description AS translation
			FROM project pr
			LEFT JOIN translation t ON (t.trans_id = pr.id)
			WHERE t.language_code = ?|;
		push(@queryargs, $self->{language_code});
	}

	if ($transdate) {
		$query .= qq| AND (startdate IS NULL OR startdate <= ?)
				AND (enddate IS NULL OR enddate >= ?)|;
		push(@queryargs, $transdate, $transdate);
	}

	$query .= qq| ORDER BY projectnumber|;

	$sth = $dbh->prepare($query);
	$sth->execute(@queryargs)|| $self->dberror($query);

	@{ $self->{all_project} } = ();

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $self->{all_project} }, $ref;
	}

	$sth->finish;
	$dbh->commit;
}


sub all_departments {

	my ($self, $myconfig, $dbh2, $vc) = @_;

	$dbh = $self->{dbh};

	my $where = "1 = 1";

	if ($vc) {
		if ($vc eq 'customer') {
			$where = " role = 'P'";
		}
	}

	my $query = qq|SELECT id, description
					 FROM department
					WHERE $where
				 ORDER BY 2|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $self->dberror($query);

	@{ $self->{all_department} } = ();

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $self->{all_department} }, $ref;
	}

	$sth->finish;
	$self->all_years($myconfig);
	$dbh->commit;
}


sub all_years {

	my ($self, $myconfig, $dbh2) = @_;

	$dbh = $self->{dbh};

	# get years
	my $query = qq|
		SELECT (SELECT MIN(transdate) FROM acc_trans),
		       (SELECT MAX(transdate) FROM acc_trans)|;

	my ($startdate, $enddate) = $dbh->selectrow_array($query);

	if ($myconfig->{dateformat} =~ /^yy/) {
		($startdate) = split /\W/, $startdate;
		($enddate) = split /\W/, $enddate;
	} else { 
		(@_) = split /\W/, $startdate;
		$startdate = $_[2];
		(@_) = split /\W/, $enddate;
		$enddate = $_[2]; 
	}

	$self->{all_years} = ();
	$startdate = substr($startdate,0,4);
	$enddate = substr($enddate,0,4);

	while ($enddate >= $startdate) {
		push @{ $self->{all_years} }, $enddate--;
	}

	#this should probably be changed to use locale
	%{ $self->{all_month} } = ( 
		'01' => 'January',
		'02' => 'February',
		'03' => 'March',
		'04' => 'April',
		'05' => 'May ',
		'06' => 'June',
		'07' => 'July',
		'08' => 'August',
		'09' => 'September',
		'10' => 'October',
		'11' => 'November',
		'12' => 'December' );

	$dbh->commit;
}


sub create_links {

	my ($self, $module, $myconfig, $vc, $job) = @_;

	# get last customers or vendors
	my ($query, $sth);

	$dbh = $self->{dbh};

	my %xkeyref = ();


	# now get the account numbers
	$query = qq|SELECT accno, description, link
				  FROM chart
				 WHERE link LIKE ?
			  ORDER BY accno|;

	$sth = $dbh->prepare($query);
	$sth->execute("%"."$module%") || $self->dberror($query);

	$self->{accounts} = "";

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

		foreach my $key (split /:/, $ref->{link}) {

			if ($key =~ /$module/) {
				# cross reference for keys
				$xkeyref{$ref->{accno}} = $key;

				push @{ $self->{"${module}_links"}{$key} }, 
					{ accno => $ref->{accno},
					description => $ref->{description} };

				$self->{accounts} .= "$ref->{accno} " 
					unless $key =~ /tax/;
			}
		}
	}

	$sth->finish;

	my $arap = ($vc eq 'customer') ? 'ar' : 'ap';

	if ($self->{id}) {

		$query = qq|
			SELECT a.invnumber, a.transdate,
				a.${vc}_id, a.datepaid, a.duedate, a.ordnumber,
				a.taxincluded, a.curr AS currency, a.notes, 
				a.intnotes, c.name AS $vc, a.department_id, 
				d.description AS department,
				a.amount AS oldinvtotal, a.paid AS oldtotalpaid,
				a.employee_id, e.name AS employee, 
				c.language_code, a.ponumber
			FROM $arap a
			JOIN $vc c ON (a.${vc}_id = c.id)
			LEFT JOIN employee e ON (e.id = a.employee_id)
			LEFT JOIN department d ON (d.id = a.department_id)
			WHERE a.id = ?|;

		$sth = $dbh->prepare($query);
		$sth->execute($self->{id}) || $self->dberror($query);

		$ref = $sth->fetchrow_hashref(NAME_lc);

		foreach $key (keys %$ref) {
			$self->{$key} = $ref->{$key};
		}

		$sth->finish;


		# get printed, emailed
		$query = qq|
			SELECT s.printed, s.emailed, s.spoolfile, s.formname
			FROM status s WHERE s.trans_id = ?|;

		$sth = $dbh->prepare($query);
		$sth->execute($self->{id}) || $self->dberror($query);

		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
			$self->{printed} .= "$ref->{formname} " 
				if $ref->{printed};
			$self->{emailed} .= "$ref->{formname} " 
				if $ref->{emailed};
			$self->{queued} .= "$ref->{formname} ".
				"$ref->{spoolfile} " if $ref->{spoolfile};
		}

		$sth->finish;
		for (qw(printed emailed queued)) { $self->{$_} =~ s/ +$//g }

		# get recurring
		$self->get_recurring($dbh);

		# get amounts from individual entries
		$query = qq|
			SELECT c.accno, c.description, a.source, a.amount,
				a.memo, a.transdate, a.cleared, a.project_id,
				p.projectnumber
			FROM acc_trans a
			JOIN chart c ON (c.id = a.chart_id)
			LEFT JOIN project p ON (p.id = a.project_id)
			WHERE a.trans_id = ?
				AND a.fx_transaction = '0'
			ORDER BY transdate|;

		$sth = $dbh->prepare($query);
		$sth->execute($self->{id}) || $self->dberror($query);


		my $fld = ($vc eq 'customer') ? 'buy' : 'sell';

		$self->{exchangerate} = $self->get_exchangerate($dbh, 
				$self->{currency}, $self->{transdate}, $fld);

		# store amounts in {acc_trans}{$key} for multiple accounts
		while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
			$ref->{exchangerate} = $self->get_exchangerate($dbh, 
					$self->{currency}, 
					$ref->{transdate}, 
					$fld);

			push @{ $self->{acc_trans}{$xkeyref{$ref->{accno}}} }, 
				$ref;
		}

		$sth->finish;

		for (qw(curr closedto revtrans)){
			$query = qq|
				SELECT value FROM defaults 
				 WHERE setting_key = '$_'|;

			$sth = $dbh->prepare($query);
			$sth->execute || $self->dberror($query);

			($val) = $sth->fetchrow_array();
			if ($_ eq 'curr'){
				$self->{currencies} = $val;
			} else {
				$self->{$_} = $val;
			}
			$sth->finish;
		}

	} else {

		for (qw(current_date curr closedto revtrans)){
			$query = qq|
				SELECT value FROM defaults 
				 WHERE setting_key = '$_'|;

			$sth = $dbh->prepare($query);
			$sth->execute || $self->dberror($query);

			($val) = $sth->fetchrow_array();
			if ($_ eq 'curr'){
				$self->{currencies} = $val;
			} elsif ($_ eq 'current_date'){
				$self->{transdate} = $val;
			} else {
				$self->{$_} = $val;
			}
			$sth->finish;
		}

		if (! $self->{"$self->{vc}_id"}) {
			$self->lastname_used($myconfig, $dbh, $vc, $module);
		}
	}

	$self->all_vc($myconfig, $vc, $module, $dbh, $self->{transdate}, $job);
	$self->{dbh}->commit;
}


sub lastname_used {

	my ($self, $myconfig, $dbh2, $vc, $module) = @_;

	my $dbh = $self->{dbh};

	my $arap = ($vc eq 'customer') ? "ar" : "ap";
	my $where = "1 = 1";
	my $sth;

	if ($self->{type} =~ /_order/) {
		$arap = 'oe';
		$where = "quotation = '0'";
	}

	if ($self->{type} =~ /_quotation/) {
		$arap = 'oe'; 
		$where = "quotation = '1'";
	}

	my $query = qq|
		SELECT id 
		FROM $arap
		WHERE id IN 
			(SELECT MAX(id) 
			FROM $arap
			WHERE $where AND ${vc}_id > 0)|;

	my ($trans_id) = $dbh->selectrow_array($query);

	$trans_id *= 1;

	my $DAYS = ($myconfig->{dbdriver} eq 'DB2') ? "DAYS" : "";

	$query = qq|
		SELECT ct.name AS $vc, a.curr AS currency, a.${vc}_id,
			current_date + ct.terms $DAYS AS duedate, 
			a.department_id, d.description AS department, ct.notes, 
			ct.curr AS currency
		FROM $arap a
		JOIN $vc ct ON (a.${vc}_id = ct.id)
		LEFT JOIN department d ON (a.department_id = d.id)
		WHERE a.id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($trans_id)|| $self->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	for (keys %$ref) { $self->{$_} = $ref->{$_} }
	$sth->finish;
	$dbh->commit;
}



sub current_date {

	my ($self, $myconfig, $thisdate, $days) = @_;

	my $dbh = $self->{dbh};
	my $query;

	$days *= 1;
	if ($thisdate) {

		my $dateformat = $myconfig->{dateformat};

		if ($myconfig->{dateformat} !~ /^y/) {
			my @a = split /\D/, $thisdate;
			$dateformat .= "yy" if (length $a[2] > 2);
		}

		if ($thisdate !~ /\D/) {
			$dateformat = 'yyyymmdd';
		}

		$query = qq|SELECT to_date(?, ?) 
				+ ?::interval AS thisdate|;
		@queryargs = ($thisdate, $dateformat, $days);

	} else {
		$query = qq|SELECT current_date AS thisdate|;
		@queryargs = ();
	}

	$sth = $dbh->prepare($query);
	$sth->execute(@queryargs);
	($thisdate) = $sth->fetchrow_array;
	$dbh->commit;
	$thisdate;
}


sub like {

	my ($self, $str) = @_;

	"%$str%";
}


sub redo_rows {

	my ($self, $flds, $new, $count, $numrows) = @_;

	my @ndx = ();

	for (1 .. $count) { 
		push @ndx, { num => $new->[$_-1]->{runningnumber}, ndx => $_ } 
	}

	my $i = 0;
	# fill rows
	foreach my $item (sort { $a->{num} <=> $b->{num} } @ndx) {
		$i++;
		$j = $item->{ndx} - 1;
		for (@{$flds}) { $self->{"${_}_$i"} = $new->[$j]->{$_} }
	}

	# delete empty rows
	for $i ($count + 1 .. $numrows) {
		for (@{$flds}) { delete $self->{"${_}_$i"} }
	}
}


sub get_partsgroup {

	my ($self, $myconfig, $p) = @_;

	my $dbh = $self->{dbh};

	my $query = qq|SELECT DISTINCT pg.id, pg.partsgroup
					 FROM partsgroup pg
					 JOIN parts p ON (p.partsgroup_id = pg.id)|;

	my $where;
	my $sortorder = "partsgroup";

	if ($p->{searchitems} eq 'part') {
		$where = qq| WHERE (p.inventory_accno_id > 0
					   AND p.income_accno_id > 0)|;
	}

	if ($p->{searchitems} eq 'service') {
		$where = qq| WHERE p.inventory_accno_id IS NULL|;
	}

	if ($p->{searchitems} eq 'assembly') {
		$where = qq| WHERE p.assembly = '1'|;
	}

	if ($p->{searchitems} eq 'labor') {
		$where = qq| WHERE p.inventory_accno_id > 0 AND p.income_accno_id IS NULL|;
	}

	if ($p->{searchitems} eq 'nolabor') {
		$where = qq| WHERE p.income_accno_id > 0|;
	}

	if ($p->{all}) {
		$query = qq|SELECT id, partsgroup
					  FROM partsgroup|;
	} 
	my @queryargs = ();

	if ($p->{language_code}) {
		$sortorder = "translation";

		$query = qq|
			SELECT DISTINCT pg.id, pg.partsgroup,
				t.description AS translation
			FROM partsgroup pg
			JOIN parts p ON (p.partsgroup_id = pg.id)
			LEFT JOIN translation t ON (t.trans_id = pg.id 
				AND t.language_code = ?)|;
		@queryargs = ($p->{language_code});
	}

	$query .= qq| $where ORDER BY $sortorder|;

	my $sth = $dbh->prepare($query);
	$sth->execute(@queryargs)|| $self->dberror($query);

	$self->{all_partsgroup} = ();

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $self->{all_partsgroup} }, $ref;
	}

	$sth->finish;
	$dbh->commit;
}


sub update_status {

	my ($self, $myconfig) = @_;

	# no id return
	return unless $self->{id};

	my $dbh = $self->{dbh};

	my %queued = split / +/, $self->{queued};
	my $spoolfile = ($queued{$self->{formname}}) ? "'$queued{$self->{formname}}'" : 'NULL';

	my $query = qq|DELETE FROM status
					WHERE formname = ?
					  AND trans_id = ?|;

	$sth=$dbh->prepare($query);
	$sth->execute($self->{formname}, $self->{id}) || $self->dberror($query);

	$sth->finish;

	my $printed = ($self->{printed} =~ /$self->{formname}/) ? "1" : "0";
	my $emailed = ($self->{emailed} =~ /$self->{formname}/) ? "1" : "0";

	$query = qq|
		INSERT INTO status 
			(trans_id, printed, emailed, spoolfile, formname) 
		VALUES (?, ?, ?, ?, ?)|;

	$sth = $dbh->prepare($query);
	$sth->execute($self->{id}, $printed, $emailed, $spoolfile, 
			$self->{formname});
	$sth->finish;

	$dbh->commit;
}


sub save_status {

	my ($self) = @_;

	$dbh = $self->{dbh};

	my $formnames = $self->{printed};
	my $emailforms = $self->{emailed};

	my $query = qq|DELETE FROM status
					WHERE trans_id = ?|;

	my $sth = $dbh->prepare($query);
	$sth->execute($self->{id});
	$sth->finish;

	my %queued;
	my $formname;

	if ($self->{queued}) {

		%queued = split / +/, $self->{queued};

		foreach $formname (keys %queued) {

			$printed = ($self->{printed} =~ /$formname/) ? "1" : "0";
			$emailed = ($self->{emailed} =~ /$formname/) ? "1" : "0";

			if ($queued{$formname}) {
				$query = qq|
					INSERT INTO status 
						(trans_id, printed, emailed,
						spoolfile, formname)
					VALUES (?, ?, ?, ?, ?)|;

				$sth = $dbh->prepare($query);
				$sth->execute($self->{id}, $pinted, $emailed,
					$queued{$formname}, $formname)
					|| $self->dberror($query);
				$sth->finish;
			}

			$formnames =~ s/$formname//;
			$emailforms =~ s/$formname//;

		}
	}

	# save printed, emailed info
	$formnames =~ s/^ +//g;
	$emailforms =~ s/^ +//g;

	my %status = ();
	for (split / +/, $formnames) { $status{$_}{printed} = 1 }
	for (split / +/, $emailforms) { $status{$_}{emailed} = 1 }

	foreach my $formname (keys %status) {
		$printed = ($formnames =~ /$self->{formname}/) ? "1" : "0";
		$emailed = ($emailforms =~ /$self->{formname}/) ? "1" : "0";

		$query = qq|
			INSERT INTO status (trans_id, printed, emailed, 
				formname)
			VALUES (?, ?, ?, ?)|;

		$sth = $dbh->prepare($query);
		$sth->execute($self->{id}, $printed, $emailed, $formname);
		$sth->finish;
	}
	$dbh->commit;
}


sub get_recurring {

	my ($self) = @_;

	$dbh = $self->{dbh};
	my $query = qq/
		SELECT s.*, se.formname || ':' || se.format AS emaila,
			se.message, sp.formname || ':' || 
				sp.format || ':' || sp.printer AS printa
		FROM recurring s
		LEFT JOIN recurringemail se ON (s.id = se.id)
		LEFT JOIN recurringprint sp ON (s.id = sp.id)
		WHERE s.id = ?/;

	my $sth = $dbh->prepare($query);
	$sth->execute($self->{id}) || $self->dberror($query);

	for (qw(email print)) { $self->{"recurring$_"} = "" }

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		for (keys %$ref) { $self->{"recurring$_"} = $ref->{$_} }
		$self->{recurringemail} .= "$ref->{emaila}:";
		$self->{recurringprint} .= "$ref->{printa}:";
		for (qw(emaila printa)) { delete $self->{"recurring$_"} }
	}

	$sth->finish;
	chop $self->{recurringemail};
	chop $self->{recurringprint};

	if ($self->{recurringstartdate}) {
		$self->{recurringreference} = $self->escape($self->{recurringreference},1);
		$self->{recurringmessage} = $self->escape($self->{recurringmessage},1);
		for (qw(reference startdate repeat unit howmany 
				payment print email message)) { 

			$self->{recurring} .= qq|$self->{"recurring$_"},| 
		}

		chop $self->{recurring};
	}
	$dbh->commit;
}


sub save_recurring {

	my ($self, $dbh2, $myconfig) = @_;

	my $dbh = $self->{dbh};

	my $query;

	$query = qq|DELETE FROM recurring
				 WHERE id = ?|;

	$sth = $dbh->prepare($query); 
	$sth->execute($self->{id}) || $self->dberror($query);

	$query = qq|DELETE FROM recurringemail
				 WHERE id = ?|;

	$sth = $dbh->prepare($query); 
	$sth->execute($self->{id}) || $self->dberror($query);

	$query = qq|DELETE FROM recurringprint
				 WHERE id = ?|;

	$sth = $dbh->prepare($query); 
	$sth->execute($self->{id}) || $self->dberror($query);

	if ($self->{recurring}) {

		my %s = ();
		($s{reference}, $s{startdate}, $s{repeat}, $s{unit}, 
			$s{howmany}, $s{payment}, $s{print}, $s{email}, 
			$s{message}) 
				= split /,/, $self->{recurring};

		for (qw(reference message)) { $s{$_} = $self->unescape($s{$_}) }
		for (qw(repeat howmany payment)) { $s{$_} *= 1 }

		# calculate enddate
		my $advance = $s{repeat} * ($s{howmany} - 1);
		my %interval;
		$interval{'Pg'} = 
			"(date '$s{startdate}' + interval '$advance $s{unit}')";

		$query = qq|SELECT $interval{$myconfig->{dbdriver}}|;

		my ($enddate) = $dbh->selectrow_array($query);

		# calculate nextdate
		$query = qq|
			SELECT current_date - date ? AS a,
				date ? - current_date AS b|;

		$sth = $dbh->prepare($query);
		$sth->execute($s{startdate}, $enddate);
		my ($a, $b) = $sth->fetchrow_array;

		if ($a + $b) {
			$advance = int(($a / ($a + $b)) * ($s{howmany} - 1) + 1) * $s{repeat};
		} else {
			$advance = 0;
		}

		my $nextdate = $enddate;
		if ($advance > 0) {
			if ($advance < ($s{repeat} * $s{howmany})) {
				%interval = ( 'Pg'  => "(date '$s{startdate}' + interval '$advance $s{unit}')",
							  'DB2' => qq|(date ('$s{startdate}') + "$advance $s{unit}")|,);

				$interval{Oracle} = $interval{PgPP} = $interval{Pg};


				$query = qq|SELECT $interval{$myconfig->{dbdriver}}|;

				($nextdate) = $dbh->selectrow_array($query);
			}

		} else {
			$nextdate = $s{startdate};
		}

		if ($self->{recurringnextdate}) {

			$nextdate = $self->{recurringnextdate};

			$query = qq|SELECT '$enddate' - date '$nextdate'|;

			if ($dbh->selectrow_array($query) < 0) {
				undef $nextdate;
			}
		}

		$self->{recurringpayment} *= 1;

		$query = qq|
			INSERT INTO recurring 
				(id, reference, startdate, enddate, nextdate, 
				repeat, unit, howmany, payment)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)|;

		$sth = $dbh->prepare($query);
		$sth->execute($self->{id}, $s{reference}, $s{startdate},
			$enddate, $nextdate, $s{repeat}, $s{unit}, $s{howmany},
			$s{payment});


		my @p;
		my $p;
		my $i;
		my $sth;

		if ($s{email}) {
			# formname:format
			@p = split /:/, $s{email};

			$query = qq|INSERT INTO recurringemail (id, formname, format, message)
						VALUES (?, ?, ?, ?)|;

			$sth = $dbh->prepare($query) || $self->dberror($query);

			for ($i = 0; $i <= $#p; $i += 2) {
				$sth->execute($self->{id}, $p[$i], $p[$i+1], 
					$s{message});
			}

			$sth->finish;
		}

		if ($s{print}) {
			# formname:format:printer
			@p = split /:/, $s{print};

			$query = qq|INSERT INTO recurringprint (id, formname, format, printer)
						VALUES (?, ?, ?, ?)|;

			$sth = $dbh->prepare($query) || $self->dberror($query);

			for ($i = 0; $i <= $#p; $i += 3) {
				$p = ($p[$i+2]) ? $p[$i+2] : "";
				$sth->execute($self->{id}, $p[$i], $p[$i+1], $p);
			}

			$sth->finish;
		}
	}

	$dbh->commit;
}


sub save_intnotes {

	my ($self, $myconfig, $vc) = @_;

	# no id return
	return unless $self->{id};

	my $dbh = $self->dbconnect($myconfig);

	my $query = qq|UPDATE $vc SET intnotes = ? WHERE id = ?|;

	$sth=$dbh->prepare($query);
	$sth->execute($self->{intnotes}, $self->{id}) || $self->dberror($query);
	$dbh->commit;
}


sub update_defaults {

	my ($self, $myconfig, $fld) = @_;

	if (!$self->{dbh} && $self){
		$self->db_init($myconfig);
	} 
		
	my $dbh = $self->{dbh};

	if (!$self){
		$dbh = $_[3];
	}

	my $query = qq|
		SELECT value FROM defaults 
		 WHERE setting_key = ? FOR UPDATE|;
	$sth = $dbh->prepare($query);
	$sth->execute($fld);
	($_) = $sth->fetchrow_array();

	$_ = "0" unless $_;

	# check for and replace
	# <?lsmb DATE ?>, <?lsmb YYMMDD ?>, <?lsmb YEAR ?>, <?lsmb MONTH ?>, <?lsmb DAY ?> or variations of
	# <?lsmb NAME 1 1 3 ?>, <?lsmb BUSINESS ?>, <?lsmb BUSINESS 10 ?>, <?lsmb CURR... ?>
	# <?lsmb DESCRIPTION 1 1 3 ?>, <?lsmb ITEM 1 1 3 ?>, <?lsmb PARTSGROUP 1 1 3 ?> only for parts
	# <?lsmb PHONE ?> for customer and vendors

	my $num = $_;
	($num) = $num =~ /(\d+)/;

	if (defined $num) {
		my $incnum;
		# if we have leading zeros check how long it is

		if ($num =~ /^0/) {
			my $l = length $num;
			$incnum = $num + 1;
			$l -= length $incnum;

			# pad it out with zeros
			my $padzero = "0" x $l;
			$incnum = ("0" x $l) . $incnum;
		} else {
			$incnum = $num + 1;
		}

		s/$num/$incnum/;
	}

	my $dbvar = $_;
	my $var = $_;
	my $str;
	my $param;

	if (/<\?lsmb /) {

		while (/<\?lsmb /) {

			s/<\?lsmb .*? \?>//;
			last unless $&;
		$param = $&;
			$str = "";

			if ($param =~ /<\?lsmb date \?>/i) {
				$str = ($self->split_date($myconfig->{dateformat}, $self->{transdate}))[0];
				$var =~ s/$param/$str/;
			}

			if ($param =~ /<\?lsmb (name|business|description|item|partsgroup|phone|custom)/i) {

				my $fld = lc $&;
				$fld =~ s/<\?lsmb //;

				if ($fld =~ /name/) {
					if ($self->{type}) {
						$fld = $self->{vc};
					}
				}

				my $p = $param;
				$p =~ s/(<|>|%)//g;
				my @p = split / /, $p;
				my @n = split / /, uc $self->{$fld};

				if ($#p > 0) {

					for (my $i = 1; $i <= $#p; $i++) {
						$str .= substr($n[$i-1], 0, $p[$i]);
					}

				} else {
					($str) = split /--/, $self->{$fld};
				}

				$var =~ s/$param/$str/;
				$var =~ s/\W//g if $fld eq 'phone';
			}

			if ($param =~ /<\?lsmb (yy|mm|dd)/i) {

				my $p = $param;
				$p =~ s/(<|>|%)//g;
				my $spc = $p;
				$spc =~ s/\w//g;
				$spc = substr($spc, 0, 1);
				my %d = ( yy => 1, mm => 2, dd => 3 );
				my @p = ();

				my @a = $self->split_date($myconfig->{dateformat}, $self->{transdate});
				for (sort keys %d) { push @p, $a[$d{$_}] if ($p =~ /$_/) }
				$str = join $spc, @p;
				$var =~ s/$param/$str/;
			}

			if ($param =~ /<\?lsmb curr/i) {
				$var =~ s/$param/$self->{currency}/;
			}
		}
	}

	$query = qq|
		UPDATE defaults
		   SET value = ?
		 WHERE setting_key = ?|;

	$sth = $dbh->prepare($query); 
	$sth->execute($dbvar, $fld) || $self->dberror($query);

	$dbh->commit;

	$var;
}

sub db_prepare_vars {
	for (@_){
		if (!$self->{$_} and $self->{$_} ne "0"){
			undef $self->{$_};
		}
	}
}

sub split_date {

	my ($self, $dateformat, $date) = @_;

	my @d = localtime;
	my $mm;
	my $dd;
	my $yy;
	my $rv;

	if (! $date) {
		$dd = $d[3];
		$mm = ++$d[4];
		$yy = substr($d[5],-2);
		$mm = substr("0$mm", -2);
		$dd = substr("0$dd", -2);
	}

	if ($dateformat =~ /^yy/) {

		if ($date) {

			if ($date =~ /\D/) {
				($yy, $mm, $dd) = split /\D/, $date;
				$mm *= 1;
				$dd *= 1;
				$mm = substr("0$mm", -2);
				$dd = substr("0$dd", -2);
				$yy = substr($yy, -2);
				$rv = "$yy$mm$dd";
			} else {
				$rv = $date;
			}
		} else {
			$rv = "$yy$mm$dd";
		}
	}

	if ($dateformat =~ /^mm/) {

		if ($date) { 

			if ($date =~ /\D/) {
				($mm, $dd, $yy) = split /\D/, $date;
				$mm *= 1;
				$dd *= 1;
				$mm = substr("0$mm", -2);
				$dd = substr("0$dd", -2);
				$yy = substr($yy, -2);
				$rv = "$mm$dd$yy";
			} else {
				$rv = $date;
			}
		} else {
			$rv = "$mm$dd$yy";
		}
	}

	if ($dateformat =~ /^dd/) {

		if ($date) {

			if ($date =~ /\D/) {
				($dd, $mm, $yy) = split /\D/, $date;
				$mm *= 1;
				$dd *= 1;
				$mm = substr("0$mm", -2);
				$dd = substr("0$dd", -2);
				$yy = substr($yy, -2);
				$rv = "$dd$mm$yy";
			} else {
				$rv = $date;
			}
		} else {
			$rv = "$dd$mm$yy";
		}
	}

	($rv, $yy, $mm, $dd);
}


sub from_to {

	my ($self, $yy, $mm, $interval) = @_;

	use Time::Local;

	my @t;
	my $dd = 1;
	my $fromdate = "$yy${mm}01";
	my $bd = 1;

	if (defined $interval) {

		if ($interval == 12) {
			$yy++;
		} else {

			if (($mm += $interval) > 12) {
				$mm -= 12;
				$yy++;
			}

			if ($interval == 0) {
				@t = localtime(time);
				$dd = $t[3];
				$mm = $t[4] + 1;
				$yy = $t[5] + 1900;
				$bd = 0;
			}
		}

	} else {

		if (++$mm > 12) {
			$mm -= 12;
			$yy++;
		}
	}

	$mm--;
	@t = localtime(timelocal(0,0,0,$dd,$mm,$yy) - $bd);

	$t[4]++;
	$t[4] = substr("0$t[4]",-2);
	$t[3] = substr("0$t[3]",-2);
	$t[5] += 1900;

	($fromdate, "$t[5]$t[4]$t[3]");
}


sub audittrail {

	my ($self, $dbh, $myconfig, $audittrail) = @_;

	# table, $reference, $formname, $action, $id, $transdate) = @_;

	my $query;
	my $rv;
	my $disconnect;

	if (! $dbh) {
		$dbh = $self->{dbh};
	}

	# if we have an id add audittrail, otherwise get a new timestamp

	my @queryargs;

	if ($audittrail->{id}) {

		$query = qq|
			SELECT value FROM defaults 
			 WHERE setting_key = 'audittrail'|;

		if ($dbh->selectrow_array($query)) {

			my ($null, $employee_id) = $self->get_employee($dbh);

			if ($self->{audittrail} && !$myconfig) {

				chop $self->{audittrail};

				my @a = split /\|/, $self->{audittrail};
				my %newtrail = ();
				my $key;
				my $i;
				my @flds = qw(tablename reference formname action transdate);

				# put into hash and remove dups
				while (@a) {
					$key = "$a[2]$a[3]";
					$i = 0;
					$newtrail{$key} = { map { $_ => $a[$i++] } @flds };
					splice @a, 0, 5;
				}

				$query = qq|
					INSERT INTO audittrail 
						(trans_id, tablename, reference,
						formname, action, transdate, 
						employee_id)
					VALUES (?, ?, ?, ?, ?, ?, ?)|;

				my $sth = $dbh->prepare($query) || $self->dberror($query);

				foreach $key (sort { $newtrail{$a}{transdate} cmp $newtrail{$b}{transdate} } keys %newtrail) {

					$i = 2;
					$sth->bind_param(1, $audittrail->{id});

					for (@flds) { $sth->bind_param($i++, $newtrail{$key}{$_}) }
					$sth->bind_param($i++, $employee_id);
					$sth->execute || $self->dberror;
					$sth->finish;
				}
			}

			if ($audittrail->{transdate}) {

				$query = qq|
					INSERT INTO audittrail (
						trans_id, tablename, reference,
						formname, action, employee_id, 
						transdate)
					VALUES (?, ?, ?, ?, ?, ?, ?)|;
				@queryargs = (
					$audittrail->{id}, 
					$audittrail->{tablename},
					$audittrail->{reference},
					$audittrail->{formname},
					$audittrail->{action},
					$employee_id,
					$audittrail->{transdate}
				);
			} else {
				$query = qq|
					INSERT INTO audittrail 
						(trans_id, tablename, reference,
						formname, action, employee_id)
					VALUES (?, ?, ?, ?, ?, ?)|;
				@queryargs = (
					$audittrail->{id}, 
					$audittrail->{tablename},
					$audittrail->{reference},
					$audittrail->{formname},
					$audittrail->{action},
					$employee_id,
				);
			}

			$sth = $dbh->prepare($query);
			$sth->execute(@queryargs)||$self->dberror($query);
		}

	} else {

		$query = qq|SELECT current_timestamp|;
		my ($timestamp) = $dbh->selectrow_array($query);

		$rv = "$audittrail->{tablename}|$audittrail->{reference}|$audittrail->{formname}|$audittrail->{action}|$timestamp|";
	}

	$dbh->commit;
	$rv;
}

1;

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
# Copyright (C) 2002
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors: 
#
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# this is the default code for the Check package
#
#=====================================================================


sub init {
	my $self = shift;
	my $locale = $self->{'locale'};

	%{ $self->{numbername} } =
                   (0 => $locale->text('Zero'),
                    1 => $locale->text('One'),
                    2 => $locale->text('Two'),
	            3 => $locale->text('Three'),
		    4 => $locale->text('Four'),
		    5 => $locale->text('Five'),
		    6 => $locale->text('Six'),
		    7 => $locale->text('Seven'),
		    8 => $locale->text('Eight'),
		    9 => $locale->text('Nine'),
		   10 => $locale->text('Ten'),
		   11 => $locale->text('Eleven'),
		   12 => $locale->text('Twelve'),
		   13 => $locale->text('Thirteen'),
		   14 => $locale->text('Fourteen'),
		   15 => $locale->text('Fifteen'),
		   16 => $locale->text('Sixteen'),
		   17 => $locale->text('Seventeen'),
		   18 => $locale->text('Eighteen'),
		   19 => $locale->text('Nineteen'),
		   20 => $locale->text('Twenty'),
		   30 => $locale->text('Thirty'),
		   40 => $locale->text('Forty'),
		   50 => $locale->text('Fifty'),
		   60 => $locale->text('Sixty'),
		   70 => $locale->text('Seventy'),
		   80 => $locale->text('Eighty'),
		   90 => $locale->text('Ninety'),
                10**2 => $locale->text('Hundred'),
                10**3 => $locale->text('Thousand'),
		10**6 => $locale->text('Million'),
		10**9 => $locale->text('Billion'),
	       10**12 => $locale->text('Trillion'),
		);

}


sub num2text {
	my ($self, $amount) = @_;

	return $self->{numbername}{0} unless $amount;

	my @textnumber = ();

	# split amount into chunks of 3
	my @num = reverse split //, abs($amount);
	my @numblock = ();
	my @a;
	my $i;

	while (@num) {
		@a = ();
		for (1 .. 3) {
			push @a, shift @num;
		}
		push @numblock, join / /, reverse @a;
	}
    
	while (@numblock) {

		$i = $#numblock;
		@num = split //, $numblock[$i];
    
		if ($numblock[$i] == 0) {
 			pop @numblock;
			next;
		}
   
		if ($numblock[$i] > 99) {
			# the one from hundreds
			push @textnumber, $self->{numbername}{$num[0]};
     
			# add hundred designation
			push @textnumber, $self->{numbername}{10**2};

			# reduce numblock
			$numblock[$i] -= $num[0] * 100;
      
		}
    
		$numblock[$i] *= 1;
    
		if ($numblock[$i] > 9) {
			# tens
			push @textnumber, $self->format_ten($numblock[$i]);
		} elsif ($numblock[$i] > 0) {
			# ones
			push @textnumber, $self->{numbername}{$numblock[$i]};
		}
    
		# add thousand, million
		if ($i) {
			$num = 10**($i * 3);
			push @textnumber, $self->{numbername}{$num};
		}
      
		pop @numblock;
    
	}

	join ' ', @textnumber;

}


sub format_ten {
	my ($self, $amount) = @_;
  
	my $textnumber = "";
	my @num = split //, $amount;

	if ($amount > 20) {
		$textnumber = $self->{numbername}{$num[0]*10};
		$amount = $num[1];
	} else {
		$textnumber = $self->{numbername}{$amount};
		$amount = 0;
	}

	$textnumber .= " ".$self->{numbername}{$amount} if $amount;

	$textnumber;
  
}


1;


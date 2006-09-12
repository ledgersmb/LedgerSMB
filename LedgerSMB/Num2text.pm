#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# http://sourceforge.net/projects/ledger-smb/
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

  %{ $self->{numbername} } =
                   (0 => 'Zero',
                    1 => 'One',
                    2 => 'Two',
	            3 => 'Three',
		    4 => 'Four',
		    5 => 'Five',
		    6 => 'Six',
		    7 => 'Seven',
		    8 => 'Eight',
		    9 => 'Nine',
		   10 => 'Ten',
		   11 => 'Eleven',
		   12 => 'Twelve',
		   13 => 'Thirteen',
		   14 => 'Fourteen',
		   15 => 'Fifteen',
		   16 => 'Sixteen',
		   17 => 'Seventeen',
		   18 => 'Eighteen',
		   19 => 'Nineteen',
		   20 => 'Twenty',
		   30 => 'Thirty',
		   40 => 'Forty',
		   50 => 'Fifty',
		   60 => 'Sixty',
		   70 => 'Seventy',
		   80 => 'Eighty',
		   90 => 'Ninety',
                10**2 => 'Hundred',
                10**3 => 'Thousand',
		10**6 => 'Million',
		10**9 => 'Billion',
	       10**12 => 'Trillion',
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


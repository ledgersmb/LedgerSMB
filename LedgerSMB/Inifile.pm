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
#
# routines to retrieve / manipulate win ini style files
# ORDER is used to keep the elements in the order they appear in .ini
#
#=====================================================================

package Inifile;


sub new {
  my ($type, $file) = @_;

  warn "$type has no copy constructor! creating a new object." if ref($type);
  $type = ref($type) || $type;
  my $self = bless {}, $type;
  $self->add_file($file) if defined $file;

  return $self;
}


sub add_file {
  my ($self, $file) = @_;
  
  my $id = "";
  my %menuorder = ();

  for (@{$self->{ORDER}}) { $menuorder{$_} = 1 }
  
  open FH, "$file" or Form->error("$file : $!");

  while (<FH>) {
    next if /^(#|;|\s)/;
    last if /^\./;

    chop;

    # strip comments
    s/\s*(#|;).*//g;
    
    # remove any trailing whitespace
    s/^\s*(.*?)\s*$/$1/;

    if (/^\[/) {
      s/(\[|\])//g;
      $id = $_;
      push @{$self->{ORDER}}, $_ if ! $menuorder{$_};
      $menuorder{$_} = 1;
      next;
    }

    # add key=value to $id
    my ($key, $value) = split /=/, $_, 2;
    
    $self->{$id}{$key} = $value;

  }
  close FH;
  
}


1;


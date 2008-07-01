# CSV parser is basically a framework to handle any CSV files or fixed-width format files.
# Parsers are defined in CSV/parser_type.

package LedgerSMB::Reconciliation::CSV;

use base qw/LedgerSMB/;
use Datetime;

sub load_file {
    
    my $self = shift @_;
    my $filename = shift @_;
    my $contents;
    do {
        
        local $/; # I think this is the right way to outrageously cheat
        open(FH,$filename);
        $contents = <FH>;
    }
    return $contents;
}

sub process {
    
    # thoroughly implementation-dependent.
    my $self = shift @_;
    my $contents = $self->load_file($self->{csv_filename});
    
    foreach my $line (split /\n/,$contents) {
        # Unpack for the format it is inexplicably in
        ($accno,
         $checkno,
         $issuedate
         $amount
         $cleared,
         $last_three) = unpack("A10A10A6A10A6A3",$line);
         
        push @{ $self->{entries} }, { 
            account_num     => $accno, 
            scn             => $checkno,
            issue_date      => $issuedate,
            amount          => $amount,
            cleared_date    => $cleared
        };
    }
    # Okay, now how do I test to see if this is actually, y'know, bad data.
    
    for my $line (@{ $self->{entries} }) {
        
        # First check the account number.
        # According to the docs I have, it's all numbers.
        
        
    }
    
    return;
}

sub is_error {
    
    
}

sub error {
    
    
}

1;
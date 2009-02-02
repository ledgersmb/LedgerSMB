# CSV parser is basically a framework to handle any CSV files or fixed-width format files.
# Parsers are defined in CSV/parser_type.

package LedgerSMB::Reconciliation::CSV;

use base qw/LedgerSMB/;
use DateTime;

opendir (DCSV, 'LedgerSMB/Reconciliation/CSV/Formats');
for my $format (readdir(DCSV)){
	do "LedgerSMB/Reconciliation/CSV/Formats/$format";
};

sub load_file {
    
    my $self = shift @_;
    my $filename = shift @_;
    my $contents;
    do {
        
        local $/; # I think this is the right way to outrageously cheat
        open(FH,$filename);
        $contents = <FH>;
    };
    return $contents;
}

sub process {
    
    # thoroughly implementation-dependent, so depends on helper-functions
    my $self = shift @_;
    my $contents = $self->load_file($self->{csv_filename});
    my $func = "process_$self->{accno}";
    @entries = eval{&$func($self, $contents)};
    if (!$!){
       @{$self->{recon_entries}} = @entries;
       $self->{file_upload} = 1;
   }
   else {
       $self->{file_upload} = 0;
   }
}

sub is_error {
   my $self = shift @_;    
   return $self->{invalid_format};
}

1;

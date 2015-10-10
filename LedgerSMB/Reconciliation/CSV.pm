# CSV parser is basically a framework to handle any CSV files or fixed-width format files.
# Parsers are defined in CSV/parser_type.

package LedgerSMB::Reconciliation::CSV;

use strict;
use warnings;

use LedgerSMB::App_State;
use Try::Tiny;

try {
no warnings;
opendir (DCSV, 'LedgerSMB/Reconciliation/CSV/Formats');
for my $format (readdir(DCSV)){
    if ($format !~ /^\./){
        do "LedgerSMB/Reconciliation/CSV/Formats/$format";
    }
}
};

sub load_file {

    my $self = shift @_;
    my $fieldname = shift @_;

    my $contents;
    my $handle = $self->{_request}->upload($fieldname);
    $contents = join("\n", <$handle>);
    return $contents;
}

sub process {
    my $self = shift @_;

    # thoroughly implementation-dependent, so depends on helper-functions
    my ($recon, $fldname) = @_;
    my $contents = $self->load_file($fldname);

    my $func = "parse_${LedgerSMB::App_State::DBName}_$recon->{chart_id}";
    if ($self->can($func)){
       my @entries = $self->can($func)->($self,$contents);
       @{$self->{entries}} = @entries;

       $self->{file_upload} = 1;
   }
   else {
       $self->{file_upload} = 0;
   }
   return $self->{entries};
}

sub is_error {
   my $self = shift @_;
   return $self->{invalid_format};
}

1;

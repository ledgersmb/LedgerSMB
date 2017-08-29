=head1 NAME

LedgerSMB::Reconciliation::CSV - A framework for fixed-width format file handling

=head2 SYNOPSIS




=cut

# CSV parser is basically a framework to handle any CSV files or fixed-width format files.
# Parsers are defined in CSV/parser_type.

package LedgerSMB::Reconciliation::CSV;
use LedgerSMB::Reconciliation::ISO20022;

use strict;
use warnings;

use LedgerSMB::App_State;
use Try::Tiny;
use base qw(LedgerSMB::PGOld);

try {
    no warnings;
    opendir (DCSV, 'old/lib/LedgerSMB/Reconciliation/CSV/Formats');
    for my $format (readdir(DCSV)){
        if ($format !~ /^\./){
            local ($!, $@);
            my $do_ = "old/lib/LedgerSMB/Reconciliation/CSV/Formats/$format";
            unless ( do $do_ ) {
                if ($! or $@) {
                    warn "\nFailed to execute $do_ ($!): $@\n";
                    die ( "Status: 500 Internal server error (CSV.pm)\n\n" );
                }
            }
        }
    }
};

=head1 METHODS

=head2 $self->process()

Processes the input reconciliation file by calling the function
$self->parse_<account_id>() with the parsed content of the CSV file.

For now, does SEPA detection here, though that needs to be refactored.

=cut

sub process {
    my $self = shift @_;

    # thoroughly implementation-dependent, so depends on helper-functions
    my ($recon, $contents) = @_;

    if (@{$self->{entries}} = LedgerSMB::Reconciliation::ISO20022->process_xml($recon, $contents)){
        $self->{file_upload} = 1;
        return $self->{entries};
    }
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

=head2 $self->is_error()

Well,...

=cut

sub is_error {
   my $self = shift @_;
   return $self->{invalid_format};
}

1;

=head1 NAME

LedgerSMB::Reconciliation::CSV - A framework for fixed-width format file handling

=head2 SYNOPSIS

Parses reconciliation data files using the appropriate parsing function,
including installation-specific parsers loaded from
C<old/lib/LedgerSMB/Reconciliation/CSV/Formats>.

As the name suggests, this was initially built to import CSV files, but
now handles all supported reconciliation data formats.

=cut


package LedgerSMB::Reconciliation::CSV;
use LedgerSMB::Reconciliation::ISO20022;
use LedgerSMB::FileFormats::OFX::BankStatement;

use strict;
use warnings;
use base qw(LedgerSMB::PGOld);

use Syntax::Keyword::Try;

sub ___init {
# Import installation-specific parsing functions
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
}
catch {}
}

___init();

=head1 METHODS

=head2 $self->process()

Processes the input reconciliation file, returning a list of the transactions
it contains.

First tries to read the file as ISO200022 CAMT053 XML, then as OFX. If that
fails, parses the file by calling method $self->parse_<company>_<account_id>()
with the content of the CSV file, if that method exists.

=cut

sub process {
    my ($self, $recon, $contents) = @_;

    if (@{$self->{entries}} = LedgerSMB::Reconciliation::ISO20022::process_xml($contents)){
        return $self->{entries};
    }

    if (my $ofx = LedgerSMB::FileFormats::OFX::BankStatement->new($contents)) {
        return $ofx->transactions;
    }

    my $func = "parse_$self->{company}_$recon->{chart_id}";
    if ($self->can($func)){
       @{$self->{entries}} = $self->can($func)->($self,$contents);
    }
    else {
        die "no custom method `$func` exists to parse the reconciliation file";
    }

    return $self->{entries};
}

1;

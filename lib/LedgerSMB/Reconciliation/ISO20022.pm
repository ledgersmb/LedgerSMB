use strict;
use warnings;
use 5.010;

package LedgerSMB::Reconciliation::ISO20022;
use Data::Dumper;
use XML::Simple;

=head2 is_camt053

Returns true if the content is detected to be an ISO 20022 file

=cut

sub is_camt053 {
    my ($self, $content) = @_;
    return unless $content;
    return $content =~ /xmlns="urn\:iso\:std\:iso\:20022\:tech\:xsd\:camt\.053\.001\.02"/;
}

=head2 process_xml

Processes an ISO 20022 file for recon.

=cut

sub process_xml {
    my ($self, $recon, $contents) = @_;
    my $struct = XMLin($contents);
    my @elements =
           map { my $sign = (lc($_->{CdtDbtInd}) eq 'crdt') ? -1 : 1;
              { amount => $_->{Amt}->{content} * $sign, 
                cleared_date => $_->{BookgDt}->{Dt}, 
                scn => $_->{AcctSvcrRef}, 
                type => "20022 xml, $_->{Amt}->{Ccy}" }
           } @{$struct->{BkToCstmrStmt}->{Stmt}->{Ntry}};
    return @elements;
}

1;

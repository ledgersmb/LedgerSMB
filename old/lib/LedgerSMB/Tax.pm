
package Tax;

=head1 NAME

LedgerSMB::Tax - Basic tax infrastructure for LedgerSMB

=head1 DESCRIPTION

apply_taxes - applies taxes to the given subtotal
extract_taxes - extracts taxes from the given total
initialize_taxes - loads taxes from the database
calculate_taxes - calculates taxes

=head2 SYNOPSIS

  @taxes = LedgerSMB::Tax->init_taxes($request, $taxlist1, $taxlist2)

=cut

use LedgerSMB::PGNumber;
use Log::Log4perl;

use strict;
use warnings;


my $logger = Log::Log4perl->get_logger('Tax');

=head1 METHODS

This module doesn't specify any (public) methods.

=head1 FUNCTIONS

=head2 init_taxes($request, $taxlist1, $taxlist2)

Retrieves and returns a series of tax objects for the tax numbers in
$taxlist1.  If $taxlist2 is provided, only those which appear in both are
used.

Taxlists 1 and 2 are space-separated lists of tax account numbers.

=cut

sub init_taxes {
    my ( $form, $taxaccounts, $taxaccounts2 ) = @_;
    my $dbh = $form->{dbh};
    my @taxes = ();
    do { $_ = '' unless defined $_ } for ($taxaccounts, $taxaccounts2);
    my @accounts = split / /, $taxaccounts;
    if ( defined $taxaccounts2 ) {
        #my @tmpaccounts = @accounts;#unused var
        @accounts=(); # empty @accounts
        for my $acct ( split / /, $taxaccounts2 ) {
            if ( $taxaccounts =~ /\b$acct\b/ ) {
                push @accounts, $acct;
            }
        }
    }
    else{
     $logger->trace('taxaccounts2 undefined');
    }
    my $query = q{
        SELECT t.taxnumber, c.description,
            t.rate, t.chart_id, t.pass, m.taxmodulename, t.minvalue
            FROM tax t INNER JOIN account c ON (t.chart_id = c.id)
            INNER JOIN taxmodule m
                ON (t.taxmodule_id = m.taxmodule_id)
            WHERE c.accno = ?
                      AND coalesce(validto::timestamp, 'infinity')
                          >= coalesce(?::timestamp, now())
            ORDER BY validto ASC
            LIMIT 1
        };
    my $sth = $dbh->prepare($query);
    foreach my $taxaccount (@accounts) {
        next if ( !defined $taxaccount );
        if ( defined $taxaccounts2 ) {
            next if $taxaccounts2 !~ /\b$taxaccount\b/;
        }
        $form->{transdate} = undef unless $form->{transdate};
        $sth->execute($taxaccount, $form->{transdate}) || $form->dberror($query);
        my $ref = $sth->fetchrow_hashref;
        next unless $ref;
        $ref->{rate} = LedgerSMB::PGNumber->from_db($ref->{rate});
        $ref->{value} = LedgerSMB::PGNumber->from_db($ref->{value});
        $ref->{maxvalue} = LedgerSMB::PGNumber->from_db($ref->{maxvalue});
        $ref->{minvalue} = LedgerSMB::PGNumber->from_db($ref->{minvalue});
        $ref->{minvalue} //= 0;

        my $module = "LedgerSMB/Taxes/$ref->{taxmodulename}.pm";
        require $module;

        my $tax = "LedgerSMB::Taxes::$ref->{taxmodulename}"->new(%$ref);
        $tax->account($taxaccount);
        $tax->taxnumber( $ref->{'taxnumber'} );
        $tax->value( 0 );

        push @taxes, $tax;
    }
    # http://search.cpan.org/dist/DBI/DBI.pm#finish
    # documents we should NOT call $sth->finish here.
    return @taxes;
}

=head2 calculate_taxes($taxes, $request, $subtotal, $included)

Returns the total tax amount taxed. Taxes are responsible for passing back
their own total info to the invoices.

=cut

sub calculate_taxes {
    my ( $taxes, $form, $subtotal, $extract ) = @_;
    my $total = LedgerSMB::PGNumber->bzero();
    my %passes;
    foreach my $tax (@$taxes) {
        push @{ $passes{ $tax->pass } }, $tax;
    }
    my @passkeys = sort keys %passes;
    @passkeys = reverse @passkeys if $extract;
    foreach my $pass (@passkeys) {
        my $passrate  = LedgerSMB::PGNumber->bzero();
        my $passtotal = LedgerSMB::PGNumber->bzero();
        foreach my $tax ( @{ $passes{$pass} } ) {
            $passrate += $tax->rate;
        }
        foreach my $tax ( @{ $passes{$pass} } ) {
            $passtotal += $tax->apply_tax( $form, $subtotal + $total )
              if not $extract;
            $passtotal +=
              $tax->extract_tax( $form, $subtotal - $total, $passrate )
              if $extract;
        }
        $total += $passtotal;
    }
    return $total;
}

=head2 apply_taxes

A shortcut for calculating taxes without extracting (i.e. when taxes not
included)

=head2 extract_taxes

A shortcut for calculating taxes with extracting (i.e. when taxes are included)

=cut

sub apply_taxes {
    my ( $taxes, $form, $subtotal ) = @_;
    return $subtotal + calculate_taxes( $taxes, $form, $subtotal, 0 );
}

sub extract_taxes {
    my ( $taxes, $form, $subtotal ) = @_;
    return $subtotal - calculate_taxes( $taxes, $form, $subtotal, 1 );
}

1;

=head1 LICENSE AND COPYRIGHT

The original copyright notice follows:

# Copyright (C) 2006-2016
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.
#
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#

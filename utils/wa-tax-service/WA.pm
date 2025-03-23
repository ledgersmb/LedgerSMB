
package LedgerSMB::Taxes::WA;


=head1 NAME

LedgerSMB::Taxes::WA - Washington Tax service

=head1 DESCRIPTION

This package contains tax related functions:

calculate_tax - calculates tax on subtotal
apply_tax - sets $value to the tax value for the subtotal


=head1 SYNOPSIS

 my $tax_amt = $tax->calculate_tax( $form, $subtotal, $extract, $passrate);
 my $tax_amt = $tax->apply_tax( $form, $subtotal );

=cut

use strict;
use warnings;

use HTTP::Tiny;
use Feature::Compat::Try;
use Log::Any qw($logger);
use URI::Escape;
use XML::LibXML;

use Moose;
use namespace::autoclean;
use LedgerSMB::PGNumber;
use LedgerSMB::MooseTypes;

=head1 ATTRIBUTES

=over

=item taxnumber

???

=cut

has taxnumber   => (is => 'rw');

=item description

???

=cut

has description => (isa => 'Str', is => 'rw');

=item rate

The tax rate as a fractional number; fallback when the
service isn't available.

=cut

has rate        => (isa => 'LedgerSMB::PGNumber',
                    is => 'ro', coerce => 1);

=item account

=cut

has account     => (isa => 'Str', is => 'rw');

=item value

???

=cut

has value       => (isa => 'LedgerSMB::PGNumber', is => 'rw', coerce => 1);

=item minvalue

Minimum taxable amount to kick in taxation

=cut

has minvalue    => (isa => 'LedgerSMB::PGNumber', is => 'ro', coerce => 1);

=item maxvalue

Maximum taxable amount to apply tax to

=cut

has maxvalue    => (isa => 'LedgerSMB::PGNumber', is => 'ro', coerce => 1);

=item pass

Number of the pass to apply this tax.

Taxes can be applied in successive iterations ('passes'), including the
taxes of the previous iteration in the next pass's subtotal.

=cut

has pass        => (isa => 'Str', is => 'ro');

=back

=head1 METHODS

=over

=item $self->calculate_tax()


=cut

my $webclient  = HTTP::Tiny->new();
my $xml_parser = XML::LibXML->new();

sub calculate_tax {
    my ( $self, $form, $subtotal, $extract, $passrate ) = @_;
    if ($form->{subtotal} && (abs($form->{subtotal}) < $self->minvalue
                            || ($self->maxvalue &&
                               abs($form->{subtotal}) > $self->maxvalue))
    ){
         return 0;
    }

    my $rate = $self->rate;
    my $loc;
    if (my $cache = $form->{_wa_taxes}) {
        $loc  = $cache->{loc};
        $rate = $cache->{rate};
    }
    else {
        $logger->debug("state/country: $form->{state}, $form->{country}");
        if ($form->{state} eq 'WA'
            and $form->{country} eq 'US') {
            try {
                my $url =
                    'https://webgis.dor.wa.gov/webapi/addressrates.aspx?output=xml'
                    . '&addr=' . uri_escape($form->{address})
                    . '&city=' . uri_escape($form->{city})
                    . '&zip=' . uri_escape($form->{zipcode});

                $logger->debug("Request URI: $url");
                my $response = $webclient->get($url);
                if ($response->{success}) {
                    my $content = $response->{content};
                    my $doc     = $xml_parser->parse_string($content);
                    my $root    = $doc->documentElement;

                    if ($root->getAttribute('rate') eq '-1') {
                        $logger->error('Tax rate lookup failure: ' . $root->getAttribute('debughint'));
                        $logger->warn('Falling back to default rate due to lookup failure');
                    }
                    else {
                        $rate = $root->getAttribute('rate');
                        $loc  = $root->getAttribute('loccode');
                        $logger->debug($content);
                        $logger->debug("Extracted rate and location code: ($rate, $loc)");
                        $form->{_wa_taxes} = {
                            rate => $rate,
                            loc  => $loc,
                        };
                    }
                }
                else {
                    $logger->warn($response->{content});
                }
            }
            catch ($e) {
                $logger->error('Failed to look up tax rate: ' . $e);
            }
        }
        else {
            $logger->warn("Not a Washington state address; falling back to default rate $rate");
        }
    }
    $form->{acc_trans}{ $form->{id} }{ $self->account }{source} = $loc
        if $form->{id};
    $form->{'taxsource_' . $self->account} = $loc;
    my $tax = $subtotal * $rate / ( LedgerSMB::PGNumber->bone() + $passrate );
    $tax = $subtotal * $rate if not $extract;
    return $tax;
}

=item $self->apply_tax

=cut

sub apply_tax {
    my ( $self, $form, $subtotal ) = @_;
    my $tax = $self->calculate_tax( $form, $subtotal, 0 );
    $tax = LedgerSMB::PGNumber->bzero unless $tax;
    $self->value($tax);
    return $tax;
}

=item $self->extract_tax

=cut

sub extract_tax {
    die 'Extraction not supported with LedgerSMB::Taxes::WA';
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2021 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;


1;

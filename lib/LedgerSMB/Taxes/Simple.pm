
package LedgerSMB::Taxes::Simple;

#=====================================================================
#
# Simple Tax support module for LedgerSMB
# Taxes::Simple
#  Default simple tax application
#
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.
#
#
#======================================================================
# This package contains tax related functions:
#
# calculate_tax - calculates tax on subtotal
# apply_tax - sets $value to the tax value for the subtotal
# extract_tax - sets $value to the tax value on a tax-included subtotal
#
#====================================================================

=head1 NAME

LedgerSMB::Taxes::Simple - Simple tax calculations

=head1 DESCRIPTION

This package contains tax related functions:

calculate_tax - calculates tax on subtotal
apply_tax - sets $value to the tax value for the subtotal
extract_tax - sets $value to the tax value on a tax-included subtotal


=head1 SYNOPSIS

 my $tax_amt = $tax->calculate_tax( $form, $subtotal, $extract, $passrate);
 my $tax_amt = $tax->apply_tax( $form, $subtotal );
 my $tax_amt = $tax->extract_tax( $form, $subtotal );

=cut

use strict;
use warnings;

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

The tax rate as a fractional number.

=cut

has rate        => (isa => 'LedgerSMB::Moose::Number',
                    is => 'ro', coerce => 1);

=item account

=cut

has account     => (isa => 'Str', is => 'rw');

=item value

???

=cut

has value       => (isa => 'LedgerSMB::Moose::Number', is => 'rw', coerce => 1);

=item minvalue

Minimum taxable amount to kick in taxation

=cut

has minvalue    => (isa => 'LedgerSMB::Moose::Number', is => 'ro', coerce => 1);

=item maxvalue

Maximum taxable amount to apply tax to

=cut

has maxvalue    => (isa => 'LedgerSMB::Moose::Number', is => 'ro', coerce => 1);

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

sub calculate_tax {
    my ( $self, $form, $subtotal, $extract, $passrate ) = @_;
    my $rate = $self->rate;
    if ($form->{subtotal} && (abs($form->{subtotal}) < $self->minvalue
                            || ($self->maxvalue &&
                               abs($form->{subtotal}) > $self->maxvalue))
    ){
         return 0;
    }
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

=item $seslf->extract_tax

=cut

sub extract_tax {
    my ( $self, $form, $subtotal, $passrate ) = @_;
    my $tax = $self->calculate_tax( $form, $subtotal, 1, $passrate );
    $self->value($tax);
    return $tax;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;


1;

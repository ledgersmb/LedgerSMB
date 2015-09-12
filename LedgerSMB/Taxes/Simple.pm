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
package LedgerSMB::Taxes::Simple;

use strict;
use warnings;

use Class::Struct;
use LedgerSMB::PGNumber;

struct 'LedgerSMB::Taxes::Simple' => {
    taxnumber   => '$',
    description => '$',
    rate        => 'LedgerSMB::PGNumber',
    chart       => '$',
    account     => '$',
    value       => 'LedgerSMB::PGNumber',
    minvalue    => 'LedgerSMB::PGNumber', #Ignored in Simple Tax rules
    maxvalue    => 'LedgerSMB::PGNumber', #Ignored in Simple Tax rules
    pass        => '$'
};

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

sub apply_tax {
    my ( $self, $form, $subtotal ) = @_;
    my $tax = $self->calculate_tax( $form, $subtotal, 0 );
    $tax = LedgerSMB::PGNumber->bzero unless $tax;
    $self->value($tax);
    return $tax;
}

sub extract_tax {
    my ( $self, $form, $subtotal, $passrate ) = @_;
    my $tax = $self->calculate_tax( $form, $subtotal, 1, $passrate );
    $self->value($tax);
    return $tax;
}

1;

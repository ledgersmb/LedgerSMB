
package LedgerSMB::MooseTypes;

=head1 NAME

LedgerSMB::MooseTypes - Moose subtypes and coercions for LedgerSMB

=head1 DESCRIPTION

This includes a general set of wrapper types, currently limited to dates and
numbers, for automatic instantiation from strings.

=cut

use strict;
use warnings;

use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;

use PGObject::Type::ByteString;
use LedgerSMB::PGDate;
use LedgerSMB::PGNumber;

=head1 SYNPOSIS

 has 'date_from' => (is => 'rw',
                    isa => 'LedgerSMB::Moose::Date',
                 coerce => 1
 );

 has 'amount_from'  => (is => 'rw',
                       isa => 'LedgerSMB::Moose::Number',
                    coerce => 1
 );

=head1 METHODS

This module doesn't specify any (public) methods.

=head1 SUBTYPES

=head2 LedgerSMB::Moose::Date

This wraps the LedgerSMB::PGDate class for automagic handling of i18n and
date formats.

=cut

subtype 'LedgerSMB::Moose::Date', as 'Maybe[LedgerSMB::PGDate]';



=head3 Coercions

The only coercion provided is from a string, and it calls the PGDate class's
from_input method.  A second coercion is provided for
Maybe[LedgerSMB::Moose::Date].

=cut

coerce 'LedgerSMB::Moose::Date'
    => from 'Str'
    => via { LedgerSMB::PGDate->from_input($_) };

=head2 LedgerSMB::Moose::Number

This wraps the LedgerSMB::PGNumber class for automagic handling of i18n and
number formats.

=cut

subtype 'LedgerSMB::Moose::Number', as 'LedgerSMB::PGNumber';


=head3 Coercions

The only coercion provided is from a string and it calls the PGNumber class's
from_input method.  A second coercian is provided for
Maybe[LedgerSMB::Moose::Number]

=cut

coerce 'LedgerSMB::Moose::Number',
  from 'Str',
   via { LedgerSMB::PGNumber->from_input($_) };


=head2 LedgerSMB::Moose::FileContent

Wraps a reference to a UTF-8 encoded string in a PGObject::Type::ByteString
for serialization through PGObject.

=cut

subtype 'LedgerSMB::Moose::FileContent', as 'PGObject::Type::ByteString';

=head3 Coercions

Two coercions are supplied. One for a string, the other for a
scalar reference to a string.

=cut

coerce 'LedgerSMB::Moose::FileContent',
  from 'Str',
  via { PGObject::Type::ByteString->new($_) };

coerce 'LedgerSMB::Moose::FileContent',
  from 'ScalarRef[Str]',
  via { PGObject::Type::ByteString->new($_) };



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;


1;

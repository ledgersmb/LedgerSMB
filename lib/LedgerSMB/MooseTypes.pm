
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
use LedgerSMB::PGTimestamp;

=head1 SYNPOSIS

 has 'file_content' => (is => 'rw',
                        isa => 'LedgerSMB::Moose::ByteString',
                        coerce => 1
 );

=head1 METHODS

This module doesn't specify any (public) methods.

=head1 SUBTYPES

=head2 LedgerSMB::Moose::Timestamp

This wraps the LedgerSMB::PGTimestamp class for automagic handling of i18n and
date formats.

=cut

subtype 'LedgerSMB::Moose::Timestamp', as 'Maybe[LedgerSMB::PGTimestamp]';

=head3 Coercions

The only coercion provided is from a string, and it calls the PGTimestamp class's
from_input method.  A second coercion is provided for
Maybe[LedgerSMB::Moose::Timestamp].

=cut

coerce 'LedgerSMB::Moose::Timestamp'
    => from 'Str'
    => via { LedgerSMB::PGTimestamp->from_input($_) };


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

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

LedgerSMB::MooseTypes - Moose subtypes and coercions for LedgerSMB

=cut

package LedgerSMB::MooseTypes;
use Moose;
use Moose::Util::TypeConstraints;
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

=head1 DESCRIPTION

This includes a general set of wrapper types, currently limited to dates and
numbers, for automatic instantiation from strings.

=head1 SUBTYPES

=head2 LedgerSMB::Moose::Date

This wraps the LedgerSMB::PGDate class for automagic handling of i18n and
date formats.

=cut

subtype 'LedgerSMB::Moose::Date', as 'Maybe[LedgerSMB::PGDate]';



=head3 Coercions

The only coercion provided is from a string, and it calls the PGDate class's
from_input method.  A second coercian is provided for
Maybe[LedgerSMB::Moose::Date].

=cut

coerce 'LedgerSMB::Moose::Date'
    => from 'Str'
    => via { LedgerSMB::PGDate->from_input($_) };

=head2 LedgerSMB::Moose::Number

This wraps the LedgerSMB::PGNumber class for automagic handling if i18n and
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

1;


=head1 NAME

LedgerSMB::DBobject::Date - Date Handling Back-end Routines for LedgerSMB

=head1 SYNOPSIS

Provides the functions for generating the data structures for dates used in
LedgerSMB.

=cut

package LedgerSMB::DBObject::Date;
use base qw(LedgerSMB::PGOld);
use strict;
use warnings;

use LedgerSMB::PGNumber;
our $VERSION = '0.1.0';

=head1 METHODS

=over

=item LedgerSMB::DBObject::Payment->new()

Inherited from LedgerSMB::DBObject.  Please see that documnetation for details.

=item $self->build_filter_by_period()

This function takes $locale as an argument to build the list boxes, of the
period filter.

It sets $self->{yearsOptions}, $self->{$monthsOptions}, $self->{radioOptions}
so you just pass the hash to the template system. :)

=back

=cut


sub build_filter_by_period {
    my ($self, $locale) = @_;
    my @all_years = $self->call_procedure(funcname => 'date_get_all_years');

    for my $day (1 .. 31) {
      push@{$self->{daysOptions}} , { value => $day, text => $day }
    }

    for my $ref (0 .. $#all_years) {
      if ($all_years[$ref]{year})
      {
        push @{$self->{yearsOptions}} , { value => $all_years[$ref]{year},
                                          text  => $all_years[$ref]{year}}
      } else {
        push @{$self->{yearsOptions}} , { value => $all_years[$ref]{date_get_all_years},
                                          text  => $all_years[$ref]{date_get_all_years}}
      }
    }
    @{$self->{monthsOptions}} = (
          { value => '01', text => $locale->text('January')},
          { value => '02', text => $locale->text('February')},
          { value => '03', text => $locale->text('March')},
          { value => '04', text => $locale->text('April')},
          { value => '05', text => $locale->text('May')},
          { value => '06', text => $locale->text('June')},
          { value => '07', text => $locale->text('July')},
          { value => '08', text => $locale->text('August')},
          { value => '09', text => $locale->text('September')},
          { value => '10', text => $locale->text('October')},
          { value => '11', text => $locale->text('November')},
          { value => '12', text => $locale->text('December')}
          );


    @{$self->{radioOptions}} = (
               {
                  label  => $locale->text('Current'),
                  name   => 'radioPeriod',
                  value  => '1',
              },
              {
                  label => $locale->text('Month'),
          name    => 'radioPeriod',
          value   => '2',
          active => '1',
              },
              {
        label => $locale->text('Quarter'),
        name => 'radioPeriod',
        value => '3',
          },
          {
        label => $locale->text('Year'),
        name => 'radioPeriod',
        value => '4',
          });
}

=head1 COPYRIGHT

Copyright (c) 2009, the LedgerSMB Core Team.  This is licensed under the GNU
General Public License, version 2, or at your option any later version.  Please
see the accompanying License.txt for more information.

=cut


1;


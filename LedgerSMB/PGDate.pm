=head1 NAME
LedgerSMB::PgDate

=cut

use Moose;
package LedgerSMB::PGDate;

=head1 SYNPOSIS
This class handles formatting and mapping between the DateTime module and
PostgreSQL.

=head1 PROPERTIES

=over

=item format
The textual representation of the format.  See supported formats below.

=cut

has format => (isa => 'Str', is => 'ro', required => '1');

=item date
A DateTime object for internal storage and processing.

=cut

has date => (isa => 'DateTime', is=> 'ro', required => '1');

=back

=head1 SUPPORTED FORMATS

Formats are written with hyphens as separators.  You can actually use any other
character other than D, M, or Y as the separator, so instead of YYYY-MM-DD, you
could have YYYY/MM/DD, YYYY!MM!DD, etc.

On the database side, these are all converted to YYYY-MM-DD format.

=over

=item 'YYYY-MM-DD'

=cut

our $formats = { # Dispatch and metadata table for formats
    'YYYY-MM-DD' => {
d          to_string => sub { 
                           my ($self, $sep) = @_;
                           return $self->date->ymd($sep);
                       },
         from_string => sub {
                           my ($string, $format) = @_;
                           my ($year, $month, $day) = split /[^DMY]/, $string;
                           return LedgerSMB::PgDate->new({
                                 date => DateTime->new(
                                                        year => $year, 
                                                       month => $month, 
                                                         day => $day,
                               ),
                               format => $format,
                           });
                       },
    },

=item DD-MM-YYYY

=cut

    'DD-MM-YYYY' => {
          to_string => sub {
                           my ($self, $sep) = @_;
                           return $self->date->dmy($sep);
                       },
         from_string => sub {
                           my ($string, $format) = @_;
                           my ($day, $month, $year) = split /[^DMY]/, $string;
                           return LedgerSMB::PgDate->new({
                                 date => DateTime->new(
                                                        year => $year, 
                                                       month => $month, 
                                                         day => $day,
                               ),
                               format => $format,
                           });
                       },
    },

=item MM-DD-YYYY

=cut

    'MM-DD-YYYY' => {
          to_string => sub {
                           my ($self, $sep) = @_;
                           return $self->date->mdy($sep);
                       },
        from_string => sub {
                           my ($string, $format) = @_;
                           my ($month, $day, $year)  = split /[^DMY]/, $string;
                           return LedgerSMB::PgDate->new({
                                 date => DateTime->new(
                                                        year => $year, 
                                                       month => $month, 
                                                         day => $day,
                               ),
                               format => $format,
                           });
                       },
    },

=item YYYYMMDD

=cut

      'YYYYMMDD' => {
          to_string => sub { 
                          return $_[0]->date->ymd('');
                       },
        from_string => sub {
                           my ($string) = @_;
                           $string =~ /(\d\d\d\d)(\d\d)(\d\d)/;
                           return LedgerSMB::PgDate->new({
                                 date => DateTime->new(
                                                       year => $1,
                                                      month => $2,
                                                        day => $3,
                                 ),
                               format => 'YYYYMMDD',
                           });
                       },
    },

=item DDMMYYYY

=cut

      'DDMMYYYY' => {
          to_string => sub {
                          return $_[0]->date->dmy('');
                       },
        from_string => sub {
                           my ($string) = @_;
                           $string =~ /(\d\d)(\d\d)(\d\d\d\d)/;
                           return LedgerSMB::PgDate->new({
                                 date => DateTime->new(
                                                       year => $3,
                                                      month => $2,
                                                        day => $1,
                                 ),
                               format => 'DDMMYYYY',
                           });
                       },
    },

=item MMDDYYYY

=cut

      'MMDDYYYY' => {
          to_string => sub {
                           return $_[0]->date->mdy('');
                       },
        from_string => sub {
                           my ($string) = @_;
                           $string =~ /(\d\d)(\d\d)(\d\d\d\d)/;
                           return LedgerSMB::PgDate->new({
                                 date => DateTime->new(
                                                       year => $3,
                                                      month => $1,
                                                        day => $2,
                                 ),
                               format => 'MMDDYYYY',
                           });
                       },
    },
}

=back

=head1 CONSTRUCTOR SYNTAX

There are two ways of calling the constructor.  Both require a format argument
to be passed in, and but one accepts a string and the other accepts a date.

So you can:  
LedgerSMB::PgDate->new({ date => DateTime->new(year => 2012, day => 31, month =>
12), format => 'MM/DD/YYYY' });
or
LedgerSMB::PgDate->new({ string => '12/31/2012', format => 'MM/DD/YYYY' });

Note that strings are parsed such that any character other than D, M, and Y is
a separator.

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    if ($args{string}){
        return $formats->{$args{format}}->from_string(
                                                   $args{string}, $args{format}
        );
    } else {
        return $class->$orig(@_);
    }
};

=head1 METHODS

=over

=item to_string
This returns the human readable formatted date.

=cut

sub to_string {
    my ($self) = @_;
    my $sep;
    if ($self->format =~ /[^YMD]/){
        $self->format =~ /MM(.)/;
        $sep = $1; 
    } else {
        $sep = '';
    }
    $formats->{"$self->format"}->to_string($self, $sep);
}

=item to_dbstring
This returns the preferred form for database queries.

=cut

sub to_dbstring {
    my ($self) = @_;
    $formats->{"YYYY-MM-DD"}->to_string($self, '-');
}

1;

=head1 Copyright (C) 2011, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

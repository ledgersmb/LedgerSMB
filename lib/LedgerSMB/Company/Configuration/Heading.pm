package LedgerSMB::Company::Configuration::Heading;

=head1 NAME

LedgerSMB::Company::Configuration::Heading - GL account heading configuration

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh  = LedgerSMB::Database->new( connect_data => { ... })
       ->connect;
   my $c    = LedgerSMB::Company->new(dbh => $dbh)->configuration;
   my $h    = $c->coa_nodes->get(by => (accno => 'H-150'));
   my $head = $c->coa_nodes->create(type        => 'heading',
                                    heading_id  => $h->id,
                                    accno       => 'H-1500',
                                    description => 'Heading description',
                                    );
   $head->save;


=head1 DESCRIPTION

Configuration of GL headings, i.e. an (optional) parent heading, the heading
code (accno) and the heading description.

=cut


use warnings;
use strict;

use Log::Any qw($log);

use Moose;
use namespace::autoclean;
with 'PGObject::Simple::Role';

=head1 ATTRIBUTES

=head2 id

Internal identification of the heading. Read-only.

=cut

has id => (is => 'rw', reader => 'id', writer => '_id');

=head2 accno (required)

User defined heading number. Must be unique across headings and accounts.
Read-only.

=cut

has accno => (is => 'ro', required => 1);

=head2 description

One-line description of the heading. Read-write.

=cut

has description => (is => 'rw');

###???? Category???
has category => (is => 'ro', required => 1);

=head2 heading_id

Contains the internal ID of the heading (parent) associated with the account.

=cut

###initialized from the database using 'parent_id' :-(
has heading_id => (is => 'rw');


=head1 CONSTRUCTOR ARGUMENTS

In addition to the attributes from the previous section, the following
named arguments can (or even must) be provided to the C<new> constructor.

=head2 dbh (required)

The database access handle. This is provided upon instantiation by the
C<LedgerSMB::Company::Configuration::COANodes> collection.

=head1 METHODS

Deletes the heading. Note that this function cannot succesfully complete
when the heading is being referenced from other headings, accounts or other
configuration items.

=head2 delete

=cut

sub delete {
    my $self = shift;

    $self->call_dbmethod(funcname => 'account_heading__delete');
    return undef;
}

=head2 save

Saves a created or changed heading into the company configuration.

=cut

sub save {
    my $self = shift;

    $log->infof('Saving heading %s (%s)',
                $self->accno, $self->description);
    my ($row) = $self->call_dbmethod(
        funcname => 'account_heading_save',
        args => {
            parent => $self->heading_id,
        });
    return $self->_id($row->{account_heading_save});
}

=head2 translation($code, [$new_value])

Returns the translated heading description for language C<$code> when
C<$new_value> isn't provided, or when it is, sets it to the value provided.

=cut

sub translation {
    my ($self, $code, $new_value) = @_;

    if (@_ > 2) {
        # new value provided
        $log->debugf('Saving translation for %s on %s',$code, $self->accno);
        $self->call_dbmethod(
            funcname => 'account_heading__save_translation',
            args     => {
                id            => $self->id,
                language_code => $code,
                description   => $new_value,
            });
    }
    #TODO: return the current value
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;

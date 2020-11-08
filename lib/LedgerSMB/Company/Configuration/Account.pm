package LedgerSMB::Company::Configuration::Account;

=head1 NAME

LedgerSMB::Company::Configuration::Account - GL account configuration

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh = LedgerSMB::Database->new( connect_data => { ... })
       ->connect;
   my $c   = LedgerSMB::Company->new(dbh => $dbh)->configuration;
   my $h   = $c->coa_nodes->get(by => (accno => 'H-1500'));
   my $acc = $c->coa_nodes->create(type        => 'account',
                                   heading_id  => $h->id,
                                   accno       => '1501',
                                   description => 'Account description',
                                   );
   $acc->save;

=head1 DESCRIPTION

Configuration of GL accounts, such as account type (Asset/Liability/Income/...)
as well as account number, account description, linked GIFI code, but also
whether the account is associated with a tax rate ('is a tax account') and
whether or not the account can be reconciled.

Read-write fields are synced back to the database by calling the C<save>
method.

=cut


use warnings;
use strict;

use Log::Any qw($log);

use Moose;
use namespace::autoclean;
with 'PGObject::Simple::Role';

=head1 ATTRIBUTES

=head2 id

Internal identification of the account. Read-only.

=cut

has id => (is => 'rw', reader => 'id', writer => '_id');


=head2 accno (required)

User defined account number. Must be unique. Read-only.

=cut

has accno => (is => 'ro', required => 1);

=head2 description

One-line description of the account. Read-write.

=cut

has description => (is => 'rw');

=head2 category (required)

Account category (Asset/Liability/Income/Expense/eQuity). Single
character indicating the category: A/L/I/E/Q.

=cut

has category => (is => 'ro', required => 1);

=head2 contra

Indicates that the amounts posted on the account are negative values
in their category.

An example of this type of account is the Accumulated Depreciation that
goes with an Asset account. The sum of the Asset and the Accumulated
Depreciation account represents the current remaining value of the asset.

=cut

has contra => (is => 'ro', default => 0);

=head2 tax

Indicates that the account is associated with a tax rate. See the
C<tax_rate> method about retrieving the actual rate(s).

=cut

has tax => (is => 'ro', default => 0);

=head2 recon

Indicates that the account is set up for (bank) reconciliation.

=cut

has recon => (is => 'rw', default => 0);

=head2 obsolete

Indicates that the account is obsolete; i.e. should not be used in
new transactions and should not be shown to the user, unless it is
part of an old transaction or configuration item.

=cut

has obsolete => (is => 'ro', default => 0);

=head2 link

TODO: Needs a better name.

Contains an array of "links": names of roles an account can assume. These
correspond to the checkmarks in the GL Account screen.

=cut

###TODO: create a more descriptive name!
has link => (is => 'rw', default => sub { [] });

=head2 is_temp

TODO: Needs a better name.

Indicates whether this account needs to be zeroed at year-end. Only applies
to Equity accounts.

=cut

###TODO: create a more descriptive name!
has is_temp => (is => 'ro', default => 0);

=head2 heading_id (required)

Contains the internal ID of the heading associated with the account.

=cut

###initialized from the database using 'heading' :-(
has heading_id => (is => 'rw', required => 1);

=head2 gifi_id

Contains the internal ID of the GIFI code associated with the account.

=cut

###initialized from the database using 'gifi_accno' :-(
has gifi_id => (is => 'rw');

=head1 CONSTRUCTOR ARGUMENTS

In addition to the attributes from the previous section, the following
named arguments can (or even must) be provided to the C<new> constructor.

=head2 dbh (required)

The database access handle. This is provided upon instantiation by the
C<LedgerSMB::Company::Configuration::COANodes> collection.

=head1 METHODS

=head2 delete

Deletes the account. Note that this function cannot succesfully complete
when the account is being referenced in transactions or other configuration
items.

=cut

sub delete {
    my $self = shift;

    $self->call_dbmethod(funcname => 'account__delete');
}

=head2 save

Saves a created or changed account into the company configuration.

=cut

sub save {
    my $self = shift;

    $log->infof('Saving account %s (%s)', $self->accno, $self->description);
    my ($row) = $self->call_dbmethod(funcname => 'account__save',
                                     args => { heading => $self->heading_id });
    return $self->_id($row->{account__save});
}

=head2 tax_rate([$date])

To be implemented.

DEPRECATED. Taxes really want to be implemented separate of accounts,
being linked only to accounts to post their collectables on, if they have
any. However, not all tax categories result in accounting entries, e.g.
'tax exempt'.

=cut

sub tax_rate {
    my ($self, $date) = @_;

    ...;
}


=head2 add_tax_rate(rate => $rate, validto => $date, minvalue => $amount, maxvalue => $amount, taxnumber => $string, pass => $pass, taxmodule_id => $taxmodule_id )

DEPRECATED. Taxes really want to be implemented separate of accounts,
being linked only to accounts to post their collectables on, if they have
any. However, not all tax categories result in accounting entries, e.g.
'tax exempt'.

=cut

sub add_tax_rate {
    my ($self, %args) = @_;

    # If 'taxmodule_id' isn't provided, but 'taxmodule' is, query
    # the ID of the module based on the module value.

    if (exists $args{taxmodule}
        and not exists $args{taxmodule_id}) {
        my $sth =
            $self->dbh->prepare('SELECT * FROM taxmodule WHERE taxmodulename = ?')
            or die $self->dbh->errstr;

        $sth->execute($args{taxmodule})
            or die $sth->errstr;

        my $row = $sth->fetchrow_hashref('NAME_lc');
        $args{taxmodule_id} = $row->{taxmodule_id};
    }
    # $old_validto => $date exists to modify existing values
    # as we're *adding* a new value, not changing it, we don't supply it.
    $log->debugf('Saving tax rate on account %s', $self->accno);
    $self->call_dbmethod(funcname => 'account__save_tax',
                         args     => { %args, chart_id => $self->id });
}

=head2 translation($code, [$new_value])

Returns the translated account description for language C<$code> when
C<$new_value> isn't provided, or when it is, sets it to the value provided.

=cut

sub translation {
    my ($self, $code, $new_value) = @_;

    if (@_ > 2) {
        # new value provided
        $log->debugf('Saving translation for %s on %s',$code, $self->accno);
        $self->call_dbmethod(
            funcname => 'account__save_translation',
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

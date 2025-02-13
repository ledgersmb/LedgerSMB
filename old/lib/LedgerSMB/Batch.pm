=head1 NAME

LedgerSMB::Batch - Batch/voucher management model for LedgerSMB 1.3

=head1 SYNOPSIS

    use LedgerSMB::Batch

    # Create a new batch
    my $data = {
        dbh => $dbh,
        batch_number => 'TEST-001',
        batch_class => 'ap',
        batch_date => '2018-09-08',
        description => 'Test Description',
    };
    my $batch = LedgerSMB::Batch->new(%$data);
    my $id = $batch->create;

    # Retrieve a batch
    $data = {
        dbh => $dbh,
        batch_id => $id,
    };
    $batch = LedgerSMB::Batch->new(%$data);
    my $result = $batch->get;
    my $description = $result->{description};

    # Delete a batch
    $data = {
        dbh => $dbh,
        batch_id => $id,
    };
    $batch = LedgerSMB::Batch->new(%$data);
    $batch->delete;

=head1 METHODS

=over

=cut

package LedgerSMB::Batch;

use strict;
use warnings;
use parent qw(LedgerSMB::PGOld);

use LedgerSMB::Magic qw( BC_PAYMENT BC_PAYMENT_REVERSAL BC_RECEIPT BC_RECEIPT_REVERSAL );
use LedgerSMB::Setting;

use Log::Any qw($log);


sub _iterate_batch_items {
    my ($self, $cb) = @_;
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(<<~'QUERY'
        SELECT v.trans_id, w.workflow_id, w.type
          from transactions t
          join voucher v on t.id = v.trans_id
          join workflow w using (workflow_id)
         WHERE v.batch_id = ?
        QUERY
      )
        or die $dbh->errstr();
    $sth->execute( $self->{batch_id} )
        or die $sth->errstr;

    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        $cb->( %$row );
    }
}

=item get_new_info

This gets the information required for the new batch screen.  Currently this
just populates the batch_number hashref value.

=cut

sub get_new_info {
    my $self = shift @_;
    my $cc_object = LedgerSMB::Setting->new(%$self);
    $cc_object->{key} = 'batch_cc';
    return $self->{batch_number} = $cc_object->increment;
}

=item create

Inserts a new batch and populates the class C<id> attribute with the id of
the inserted batch record.

The following object attributes must be defined before calling this method:

  * dbh
  * batch_number [populates control_code field]
  * batch_class  [ap|ar|gl... See batch_class table)
  * batch_date   [populates default_date field]
  * description

This method returns the C<id> of the newly inserted batch on success.

=cut

sub create {
    my $self = shift @_;
    my ($ref) = $self->call_dbmethod(funcname => 'batch_create');
    $self->{id} = $ref->{batch_create};
    return $self->{id};
}

=item delete_voucher($id)

Deletes the voucher specified by $id.

=cut

sub delete_voucher {
    my ($self, $voucher_id) = @_;
    return $self->call_procedure(funcname => 'voucher__delete', args => [$voucher_id]);
}

=item unlock($id)

Unlocks a given batch

=cut

sub unlock{
    my ($self, $id) = @_;
    return $self->call_procedure(funcname => 'batch__unlock', args => [$id]);
}

=item get_search_criteria
Sets all hash values needed for the search interface:

=over

=item batch_classes
List of all batch classes

=item batch_users
List of all users

=back

=cut

sub get_search_criteria {
    my $self = shift @_;
    my ($custom_types) = @_;
    @{$self->{batch_classes}} = $self->call_dbmethod(
         funcname => 'batch_list_classes'
    );
    for (keys %$custom_types){
        if ($custom_types->{$_}->{map_to}){
            push @{$self->{batch_classes}}, {id => $_, class => $_};
        }
    }

    @{$self->{batch_users}} = $self->call_dbmethod(
         funcname => 'batch_get_users'
    );
    return unshift @{$self->{batch_users}}
            , {username => $self->{_locale}->text('Any'), id => '0', entity_id => '0'};
}

=item get_search_method (private)

Determines the appropriate search method, either for empty, mini, or full
searches

Returns the appropriate stored proc name.

=cut

# This needs to be refactored.  Input sanitation should be moved to
# get_search_results
sub get_search_method {
    my ($self, $args) = @_;
    my $search_proc;

    if ($self->{empty}){
        $search_proc = "batch_search_empty";
    } elsif ($args->{mini}){
        $search_proc = "batch_search_mini";
    } else {
        $search_proc = "batch__search";
    }

    if ( !defined $self->{created_by_eid} || $self->{created_by_eid} == 0){
        delete $self->{created_by_eid};
    }

    if ( !defined $self->{class_id} )
    {
        delete $self->{class_id};
    }

    if ( ( defined $args->{custom_types} ) && ( defined $self->{class_id} ) && ( $args->{custom_types}->{$self->{class_id}}->{select_method} ) ){
        $search_proc
             = $args->{custom_types}->{$self->{class_id}}->{select_method};
    } elsif ( ( defined $self->{class_id} ) && ( $self->{class_id} =~ /[\D]/ ) ){
          $self->error("Invalid Batch Type");
    }

    return $search_proc;
}

=item get_search_results

Returns the appropriate search as detected by get_search_method.

=cut

sub get_search_results {
    my ($self, $args) = @_;
    my $search_proc = $self->get_search_method($args);
    @{$self->{search_results}} =
        $self->call_dbmethod(
            funcname => $search_proc,
            # add the orderby argument *only* if there's one specified
            $self->{order_by} ? (orderby => [ $self->{order_by} ] ) : (),
        );
    return @{$self->{search_results}};
}

=item get_class_id($type)

Returns the class_id corresponding the the specified batch class label.
Performs a lookup on the database C<batch_class> table.

=cut

sub get_class_id {
    my ($self, $type) = @_;
    my @results = $self->call_procedure(
        funcname => 'batch_get_class_id',
        args     => [$type]
    );
    my $result = pop @results;
    return $result->{batch_get_class_id};
}

=item post

Posts the batch to the books with C<id> matching the current object's
C<batch_id> and makes the vouchers show up in transaction reports,
financial statements, and more. Marks the batch as approved.

Returns the batch C<approved_on> date (being the current database date).

=cut

sub post {
    my ($self) = @_;

    my $id = $self->{id} // '';
    my $batch_class_id = $self->{batch_class_id} // '';
    $log->info("Deleting batch $id of class $batch_class_id");
    if (not ($batch_class_id ne ''
             and ($batch_class_id == BC_PAYMENT
                  or $batch_class_id == BC_PAYMENT_REVERSAL
                  or $batch_class_id == BC_RECEIPT
                  or $batch_class_id == BC_RECEIPT_REVERSAL))) {
        # payments and receipts (and reversals) are part of a transaction
        # which may already have been approved, meaning that 'batch-approve'
        # isn't available...
        $self->_iterate_batch_items(
            sub {
                my %args = @_;
                my $wf = $self->{_wire}->get('workflows')->fetch_workflow(
                    $args{type}, $args{workflow_id}
                    );
                $wf->execute_action( 'batch-approve' );
                $log->info("Updated workflow $args{workflow_id}, batch-approve");
            });
    }

    ($self->{post_return_ref}) = $self->call_dbmethod(funcname => 'batch_post');
    return $self->{post_return_ref}->{batch_post};
}

=item delete

Deletes the batch with C<id> matching the current object's C<batch_id>
attribute and all vouchers under it. A batch cannot be deleted once it
is approved/posted.

Returns true on success.

=cut

sub delete {
    my ($self) = @_;

    $self->_iterate_batch_items(
        sub {
            my %args = @_;
            my $wf = $self->{_wire}->get('workflows')->fetch_workflow(
                $args{type}, $args{workflow_id}
                );
            $wf->execute_action( 'batch-delete' );
            $log->info("Updated workflow $args{workflow_id}, batch-delete");
        });

    my ($ref) = $self->call_dbmethod(funcname => 'batch_delete');
    return $ref->{batch_delete};
}

=item list_vouchers

Returns a list of all vouchers in the batch and attaches that list to
$self->{vouchers}

=cut

sub list_vouchers {
    my ($self) = @_;
    @{$self->{vouchers}} = $self->call_dbmethod(funcname => 'voucher_list');
    return @{$self->{vouchers}};
}

=item get

Retrieves the batch with C<id> matching the current object's C<batch_id>
attribute, setting object properties according to the retrieved record's
fields.

The following object attributes must be defined before calling this method:

  * dbh
  * batch_id

Note that the C<batch_id> attribute used to specify retrieval is different
to the C<id> attribute used for the returned result field (though they
will match after a successful retrieval).

Returns a reference to the current object regardless of whether a matching
batch was found. If no match was found, the object's C<id> field will be
C<undef>.

After successful retrieval, the following object attributes will be populated
according to the retrieved record:

    * id
    * batch_class_id
    * control_code
    * description
    * default_date
    * created_by
    * approved_on
    * created_on
    * locked_by
    * approved_by

=cut

sub get {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'voucher_get_batch');
    @{$self}{keys %$ref} = values %$ref if $ref;
    return $self;
}

1;

=back

=head1 Copyright (C) 2009-2018, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;

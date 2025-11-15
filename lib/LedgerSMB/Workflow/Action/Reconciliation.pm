package LedgerSMB::Workflow::Action::Reconciliation;

use v5.36;
use warnings;
no warnings "experimental::for_list"; ## no critic -- accepted in 5.40
no warnings "experimental::builtin"; ## no critic -- accepted in 5.40

use parent qw( LedgerSMB::Workflow::Action );

use builtin qw(indexed);
use List::Util qw(sum0);

=head1 NAME

LedgerSMB::Workflow::Action::Reconciliation - Collection of actions for reconciliations

=head1 SYNOPSIS

  <action name="submit"
          class="LedgerSMB::Workflow::Action::Reconciliation"
          entrypoint="submit" />

=head1 DESCRIPTION

This action holds all functionality required to run a (basic) reconciliation
process: matching of (bank) statement lines against what is recorded in the
books.

=head2 Book-side algorithm

In some cases, it's required or desirable to combine multiple journal lines
into a single line to be matched with the (bank) statement.  One case concerns
payments; these are recorded as multiple journal lines when they are used to
clear multiple invoices, however in practice there's only a single payment.

A special case is where a payment is combined with transaction costs; the payment
is recorded in the cash screen and the transaction costs (or other correction) is
recorded using a general journal, using the same C< source >.

Last, all general journal lines with the same C< source > are combined into a
single line; except where the C< source > is an empty string or C< NULL > value.


=head2 Reconciliation algorithm

Items are taken from the C< _stmt_todo > context parameter in the order given.
Handling of items differs between the cases where the statement item has a
C< source > specified or not.

If there B<is> a C<source>, the algorithm finds items in the books which have
the same posting date I<and> C<source> value. If there is only one, it's a
match. If there are multiple, the search is repeated; this time the C<amount>
is included. If there is exactly one resulting item, it's a match. Otherwise
the algorithm fails.

If there is B<no> C<source>, the algorithm searches items in the books where
C<amount> and C<post_date> match and the book item does not have a C<source>
value. The first of all matching items is considered a match.

=head1 PROPERTIES

=head2 entrypoint

The actual operation the C< execute > routine should delegate to.

Available values:

=over 8

=item * add_pending_items

Processes payments and general journal lines, combining them into
lines which are eligible for inclusion into the reconciliation report.

The C<_book_todo> context parameter is modified to include the result.

=item * approve

=item * delete

=item * reconcile

Processes the items in the C<_book_todo> and C<_stmt_todo> context
parameters. Matched items are moved to the C<_recon_done> context
parameter.

The C<_stmt_todo> parameter needs to be set up in the context based
on an imported statement file before invoking this action.

=item * reject

=item * submit

=back

=cut

my @PROPS = qw( entrypoint );
__PACKAGE__->mk_accessors( @PROPS );

=head1 METHODS

=head2 init

Called during initialization to set up the instance properties.

=cut

sub init($self, $wf, $params) {
    $self->SUPER::init($wf, $params);

    $self->entrypoint( $params->{entrypoint} );
}

=head2 execute

Used by the workflow engine to dispatch work to the action instance.

=cut

sub execute($self, $wf) {
    if ($self->entrypoint eq 'add_pending_items') {
        $self->_add_pending_items( $wf );
    }
    elsif ($self->entrypoint eq 'approve') {
        $self->_approve( $wf );
    }
    elsif ($self->entrypoint eq 'delete') {
        $self->_delete( $wf );
    }
    elsif ($self->entrypoint eq 'reconcile') {
        $self->_reconcile( $wf );
    }
    elsif ($self->entrypoint eq 'submit') {
        $self->_submit( $wf );
    }
    elsif ($self->entrypoint eq 'reject') {
        $self->_reject( $wf );
    }
}

#####################################
#
# add_pending_items
#
#####################################

sub _add_pending_payments($recon_fx, $pending) {
    # group lines of a single payment
    my %payments = ( __NOPAYMENT__ => [] );
    for my $pl ($pending->@*) {
        if (defined $pl->{payment_id}) {
            $payments{$pl->{payment_id}} //= [];
            push $payments{$pl->{payment_id}}->@*, $pl;
        }
        else {
            push $payments{__NOPAYMENT__}->@*, $pl;
        }
    }

    # add payment lines awaiting reconciliation
    my @new_recon;
    for my ($payment_id, $lines) (%payments) {
        next if $payment_id eq '__NOPAYMENT__';

        push @new_recon, {
            amount    => (sum0
                          map {
                              $recon_fx ? $_->{amount_tc} : $_->{amount_bc}
                          } $lines->@*),
            post_date => $lines->[0]->{paymentdate},
            source    => $lines->[0]->{source},
            links     => $lines,
        };
    }

    return ($payments{__NOPAYMENT__}, \@new_recon);
}

sub _adjust_todo_lines($recon_fx, $pending, $book_todo) {
    # add adjustment lines to existing payment lines
    my %existing_sources;
    for my $line ($book_todo->@*) {
        $existing_sources{$line->{source}} //= [];
        push $existing_sources{$line->{source}}->@*, $line;
    }

    for my ($line, $index) (reverse indexed $pending->@*) {
        next unless exists $existing_sources{$line->{source}};
        my $existing = $existing_sources{$line->{source}};
        my @same_date = grep {
            $_->{post_date} eq $line->{transdate}
        } $existing->@*;
        next if scalar(@same_date) != 1;

        splice $pending->@*, $index, 1;
        push $same_date[0]->{links}->@*, $line;
        $same_date[0]->{amount} +=
            $recon_fx ? $line->{amount_tc} : $line->{amount_bc};
    }

    return;
}

sub _add_remaining_lines($recon_fx, $pending, $book_todo) {
    my %dates;
    for my $line ($pending->@*) {
        $dates{$line->{transdate}} //= {};
        $dates{$line->{transdate}}->{$line->{source} // ''} //= [];
        push $dates{$line->{transdate}}->{$line->{source} // ''}->@*, $line;
    }
    for my ($date, $sources) (%dates) {
        for my ($source, $lines) ($sources->%*) {
            if ($source) {
                my $amount = sum0
                    map {
                        $recon_fx ? $_->{amount_tc} : $_->{amount_bc}
                } $lines->@*;
                push $book_todo->@*, {
                    amount    => $amount,
                    post_date => $date,
                    source    => $source,
                    links     => $lines,
                };
            }
            else {
                for my $line ($lines->@*) {
                    my $amount =
                        $recon_fx ? $line->{amount_tc} : $line->{amount_bc};
                    push $book_todo->@*, {
                        amount    => $amount,
                        post_date => $date,
                        links     => [ $line ],
                    };
                }
            }
        }
    }
    return;
}

sub _add_pending_items($self, $wf) {
    my ($pending, $new_recon) =
        _add_pending_payments(
            $wf->context->param( 'recon_fx' ),
            $wf->context->param( '_pending_items' ) );
    my $book_todo = $wf->context->param( '_book_todo');
    push $book_todo->@*, $new_recon->@*;

    # modifies $pending->@* and $book_todo->@*
    _adjust_todo_lines(
        $wf->context->param( 'recon_fx' ),
        $pending,
        $book_todo );

    # add the remaining lines grouped by source, if they have one
    # modifies $book_todo->@*
    _add_remaining_lines( $wf->context->param( 'recon_fx' ), $pending, $book_todo );

    return;
}

#####################################
#
# approve
#
#####################################

sub _approve($self, $wf) {
    $wf->context->param( 'approved', 1 );
}

#####################################
#
# delete
#
#####################################

sub _delete($self, $wf) {
    $wf->context->param( 'deleted', 1 );
}

#####################################
#
# reconcile
#
#####################################

sub _reconcile_source_id( $stmt, $source_id, $book_todo, $recon_done ) {
    my $lc_source_id = lc($source_id);

    my $candidates = [
        grep {
            lc($book_todo->[$_]->{source}) eq $lc_source_id
                and $book_todo->[$_]->{post_date} eq $stmt->{post_date}
        } 0..$book_todo->$#*
        ];

    return unless $candidates->@*;

    if (scalar($candidates->@*) == 1) {
        push $recon_done->@*, {
            book => [ splice $book_todo->@*, $candidates->[0], 1 ],
            stmt => [ $stmt ],
        };
        return 1;
    }

    $candidates = [
        grep {
            $book_todo->[$_]->{amount} == $stmt->{amount}
            and lc($book_todo->[$_]->{source}) eq $lc_source_id
            and $book_todo->[$_]->{post_date} eq $stmt->{post_date}
        } 0..$book_todo->$#*
        ];

    return unless $candidates->@*;

    push $recon_done->@*, {
        book => [ splice $book_todo->@*, $candidates->[0], 1 ],
        stmt => [ $stmt ],
    };
    return 1;
}

sub _reconcile_no_source_id($stmt, $prefix,
                            $book_todo, $recon_done) {
    my $candidates = [
        grep {
            $book_todo->[$_]->{amount} == $stmt->{amount}
            and $book_todo->[$_]->{post_date} eq $stmt->{post_date}
            and (not $book_todo->[$_]->{source}
                 or $book_todo->[$_]->{source} !~ m/^\Q$prefix\E/)
        } 0..$book_todo->$#*
        ];

    return unless $candidates->@*;

    push $recon_done->@*, {
        book => [ splice $book_todo->@*, $candidates->[0], 1 ],
        stmt => [ $stmt ],
    };
    return 1;
}

sub _reconcile($self, $wf) {
    # This function iterates over the lines in the bank statement which
    # have not yet been matched with a (group of) lines in the books
    #
    # When a match is found, the respective line on the statement is
    # moved to the list of statement lines which have been reconciled
    #
    my $stmt_todo    = $wf->context->param( '_stmt_todo' );
    my $book_todo    = $wf->context->param( '_book_todo' );
    my $recon_done   = $wf->context->param( '_recon_done' );
    my $prefix       = $wf->context->param( '_prefix' );

    for my ($stmt) ($stmt_todo->@*) {
        my $source_id;
        if (defined $stmt->{source}) {
            if ($stmt->{source} =~ m/^[0-9]+$/) {
                $source_id = "$prefix $stmt->{source}";
            }
            elsif ($stmt->{source} ne '') {
                $source_id = $stmt->{source};
            }
        }

        if (defined $source_id) {
            if (_reconcile_source_id(
                    $stmt, $source_id, $book_todo, $recon_done )) {
                $stmt->{_matched} = 1;
            }
            next;
        }

        if (_reconcile_no_source_id(
                $stmt, $prefix, $book_todo, $recon_done )) {
            $stmt->{_matched} = 1;
        }
    }

    my @stmt_todo = grep { ! $_->{_matched} } $stmt_todo->@*;
    $wf->context->param( '_stmt_todo', \@stmt_todo );
    return;
}

#####################################
#
# reject
#
#####################################

sub _reject($self, $wf) {
    $wf->context->param( 'rejected', 1 );
}

#####################################
#
# submit
#
#####################################

sub _submit($self, $wf) {
    $wf->context->param( 'submitted', 1 );
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.


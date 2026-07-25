package LedgerSMB::Workflow::Persister::ExtraData;

=head1 NAME

LedgerSMB::Workflow::Persister::ExtraData - Store additional workflow data

=head1 SYNOPSIS

  <persisters>
    <persister name="Email"
               class="LedgerSMB::Workflow::Persister::ExtraData"
               driver="Pg"
               extra_table="email"
               extra_data_field="from,to,cc,bcc,notify,subject,body,sent_date">
    </persister>
  </persisters>

=head1 DESCRIPTION

This module loads additional data for workflows from a specified table.

=head1 METHODS

=cut


use warnings;
use strict;
use parent qw( LedgerSMB::Workflow::Persister );

use experimental 'try';

use Log::Any qw($log);
use JSON::MaybeXS;
use Workflow::Exception qw( configuration_error persist_error );


my @FIELDS = qw( table data_field context_key );
__PACKAGE__->mk_accessors(@FIELDS);


=head2 init($params)

Parses the input parameters and sets instance fields.

=cut

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init($params);

    my @not_found = ();
    foreach (qw( table data_field )) {
        push @not_found, $_ unless ( $params->{"extra_$_"} );
    }
    if ( scalar @not_found ) {
        $self->log->error( 'Required configuration fields not found: ',
            join ', ', @not_found );
        configuration_error
            'To fetch extra data with each workflow with this implementation ',
            'you must specify: ', join ', ', @not_found;
    }

    $self->table( $params->{extra_table} );
    my $data_field = $params->{extra_data_field};

    # If multiple data fields specified we don't allow the user to
    # specify a context key

    if ( $data_field =~ /,/ ) {
        $self->data_field( [ split /\s*,\s*/, $data_field ] );
    } else {
        $self->data_field($data_field);
        my $context_key = $params->{extra_context_key} || $data_field;
        $self->context_key($context_key);
    }
    $self->log->info( 'Configured extra data fetch with: ',
                      join( '; ', $self->table, $data_field,
                            ( defined $self->context_key
                              ? $self->context_key : '' ) ) );
}



=head2 fetch_workflow( $app, $wf_id )


Implements Workflow::Persister protocol; in addition to restoring the
workflow state (as per the parent persister Workflow::Persister::DBI),
also restores the workflow context.

=cut


my $json = JSON::MaybeXS->new(
    pretty => 0, indent => 0, convert_blessed => 0,
    allow_bignum => 1, utf8 => 0, space_before => 0,
    space_after => 0, canonical => 0, allow_barekey => 0,
    allow_singlequote => 0 );

sub fetch_workflow {
    my ($self, $app, $wf_id) = @_;
    my $wf_info = $self->SUPER::fetch_workflow( $app, $wf_id );
    my $context = ($wf_info->{context} //= {});

    $self->log->debug( q{Fetching extra workflow data for '}, $wf_id, q{'} );

    my $sql = q{SELECT %s FROM %s WHERE workflow_id = ?};
    my $data_field = $self->data_field;
    my $dbh = $app->dbh;
    my $select_data_fields
        = ( ref $data_field )
        ? join( ', ',
                map { $dbh->quote_identifier($_) } @{$data_field} )
        : $dbh->quote_identifier($data_field);
    $sql = sprintf $sql, $select_data_fields,
        $dbh->quote_identifier( $self->table );
    $self->log->debug( 'Using SQL: ', $sql);
    $self->log->debug( 'Bind parameters: ', $wf_id );

    my ($sth);
    try {
        $sth = $dbh->prepare($sql);
        $sth->execute( $wf_id );
    }
    catch ($error) {
        persist_error 'Failed to retrieve extra data from table ',
            $self->table, ": $error";
    }

    $self->log->debug('Prepared/executed extra data fetch ok');
    my $row = $sth->fetchrow_arrayref;
    if ( ref $data_field ) {
        foreach my $i ( 0 .. $#{$data_field} ) {
            $context->{$data_field->[$i]} = $row->[$i];
            $self->log->info(
                sprintf( 'Set data from %s.%s into context key %s ok',
                         $self->table, $data_field->[$i],
                         $data_field->[$i] ) );
        }
    } else {
        my $value = $row->[0];
        $context->{ $self->context_key } = $value;
        $self->log->info(
            sprintf( 'Set data from %s.%s into context key %s ok',
                     $self->table, $self->data_field,
                     $self->context_key ) );
    }

    return $wf_info;
}


1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.


package LedgerSMB::Workflow::Persister::Email::TiedContent;

use v5.32;
use warnings;

=head1 NAME

LedgerSMB::Workflow::Persister::Email::TiedContent - Delayed database retrieval

=head1 SYNOPSIS

  my $attachment = {
    id          => 42,
    description => 'some desc',
    file_name   => 'attachment.pdf',
    mime_type   => 'application/pdf',
  };

  tie $attachment->{content},
    'LedgerSMB::Workflow::Persister::Email::TiedContent',
    id    => $id,
    dbh   => $dbh,
    wf_id => $wf_id;

=head1 DESCRIPTION

This module provides the means to delay loading the content of attachments
from the database until explicitly requested.  This approach both saves
memory and performance.

To achieve this without the caller noticing, the method uses tied variables.

=head1 METHODS (tied scalars)

=head2 TIESCALAR

Constructor. Called by Perl's C< tie() >.

=cut

sub TIESCALAR {
    my $class = shift;
    my %args = @_;
    my $self = bless { %args }, $class;

    $self->{dirty}     = defined $self->{value};
    $self->{has_value} = defined $self->{value};
    return $self;
}

=head2 FETCH

Called each time the variable's value is retrieved.

=cut

sub FETCH {
    my $self = shift;
    return $self->{value} if $self->{has_value};

    my $dbh = $self->{dbh};
    my $sth = $dbh->prepare(
        q{select content from file_email where ref_key = ? and id = ?})
        or die $dbh->errstr;
    $sth->execute( $self->{wf_if}, $self->{id} )
        or die $sth->errstr;

    ($self->{value}) = $sth->fetchrow_array;
    if (not defined $self->{value} and $sth->err) {
        die $sth->errstr;
    }
    $sth->finish;

    $self->{dirty} = '';
    return $self->{value};
}

=head2 STORE

Called each time the variable is being assigned a new value.

=cut

sub STORE {
    my ($self, $value) = @_;

    $self->{dirty} = 1;
    $self->{value} = $value;
    $self->{has_value} = 1;
}

=head1 METHODS (other)

=head2 persist

Not implemented.

=cut

sub persist {
    my ($self) = @_;
    return if not $self->{dirty};

    if ($self->{id}) { # update
    }
    else { # create
    }
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.


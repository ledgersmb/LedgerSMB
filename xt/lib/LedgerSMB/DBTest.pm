
=head1 NAME

LedgerSMB::DBTest - LedgerSMB commit filter for test cases.

=head1 SYOPSIS

This module creates a DBI-like interface but ensures autocommit is off,
and filters commit statements such that they don't do anything.  This can be
used for making API test cases which involve DB commits safe for production
environments.

=head1 USAGE

Both LedgerSMB.pm and LedgerSMB/Form.pm assign a global database handler for all
database access within a script in the dbh property (for example,
$request->{dbh} or $form->{dbh}).  By setting this early to a
LedgerSMB::DBTest (instead of a DBI object), the tests can be made safe.

However, there are a few limitations to be aware of.  One cannot run tests
through the standard request handler and use this module. Hence this is limited
to unit tests of files in the LedgerSMB, scripts, and bin directories.

Here is an example of how this could be done:

 my $lsmb = LedgerSMB->new();
 $lsmb->merge($testdata);
 my $dbh = LedgerSMB::DBTest->connect("dbi:Pg:dbname=$company", "$username",
     "$password",)
 $lsmb->{dbh} = $dbh;


=head1 METHODS

=over

=item connect($dsn, $user, $pass)

Connects to the database and returns a LedgerSMB::DBTest object

=item commit()

Tests the current transaction (issues a 'SELECT 1;' to the database).  If this
is successful returns 1, if not, rolls back and returns false.

Note that this means all past tests are rolled back and this is inconsistent
with normal transactional behavior.

=item prepare()

Returns a statement handle, via the private DBI database handle.

=item do()

passes this statement on to the private database handle

=item errstr()

passes this call on to the private database handle

=item err()

passes this call on to the private database handle

=item quote()

passes this call on to the private database handle

=item quote_identifier()

passes this call on to the private database handle

=item rollback()

passes this call on to the private database handle.  Note that this will roll
back all statements issues through this object.

=back

=cut

package LedgerSMB::DBTest;

use strict;
use warnings;
use DBI;

sub DESTROY {
    my ($self) = @_;
    $self->disconnect;
}

sub connect{
    my ($class, $dsn, $user, $pass) = @_;
    my $self = {};
    $self->{_dbh} = DBI->connect($dsn, $user, $pass, {AutoCommit => 0 });
    bless $self, $class;
    return $self;
}

sub commit {
    my ($self) = shift;
    my $sth = $self->{_dbh}->prepare('SELECT 1');
    $sth->execute;
    my ($retval) = $sth->fetchrow_array;
    if (!$retval){
       $self->{_dbh}->rollback;
    }
    return $retval;
}

sub selectrow_array {
    my ($self) = shift;
    return $self->{_dbh}->selectrow_array(@_);
}

sub disconnect {
    my ($self) = @_;
    $self->rollback;
    $self->{_dbh}->disconnect;
}

sub do {
    my ($self, $statement) = @_;
    return $self->{_dbh}->do($statement);
}

sub err{
    my ($self) = @_;
    return $self->{_dbh}->err;
}

sub errstr{
    my ($self) = @_;
    return $self->{_dbh}->errstr;
}

sub quote{
    my $self = shift @_;
    return $self->{_dbh}->quote(@_);
}

sub quote_identifier{
    my $self = shift @_;
    return $self->{_dbh}->quote_identifier(@_);
}

sub prepare{
    my ($self, $statement) = @_;
    return $self->{_dbh}->prepare($statement);
}

sub rollback {
    my ($self) = @_;
    return $self->{_dbh}->rollback;
}

sub state{
    my ($self) = @_;
    return $self->{_dbh}->state;
}

1;

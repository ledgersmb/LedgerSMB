=head1 NAME

LedgerSMB::Request::Error - HTTP Request error handling for LedgerSMB

=head1 SYNOPSIS

 die LedgerSMB::Request::Error->new(msg => 'something went wrong');

or

 die LedgerSMB::Request::Error->new(status => 422, msg => "you forgot to fill in country code");

=head1 PROPERTIES

=cut

package LedgerSMB::Request::Error;
use LedgerSMB::App_State;
use Moose;

=head2 status (default 500)

HTTP status to send

=cut

has status => (is => 'ro', isa => 'Int', default => '500');

=head2 msg

String to send as error message

=cut

has msg => (is => 'ro', isa => 'Str', required => 1);

=head1 METHODS

=head2 http_response($additional_html)

Generates full http response based on error.  Does NOT exit

=cut

sub http_response {
    my ($self, $additional_html) = @_;
    my $status = $self->status;
    my $msg = $self->msg;
    $msg ||= '';
    $msg =~ s#\n#<br \/>\n#g;
    $additional_html ||= '';
    $additional_html =~ s#\n#<br />\n#g;
    my $user = LedgerSMB::App_State::User;
    my $stylesheet = $user->{stylesheet} || '';

    return qq|Status: $status ISE\nContent-Type: text/html; charset=utf-8\n\n|
           . "<head><link rel='stylesheet' href='css/$stylesheet' type='text/css'></head>"
           . qq|<body><h2 class="error">Error!</h2> <p><b>$msg</b></p>
         $additional_html
         </body>|;
}

=head2 throw

Dies with the status as return code after displaying error.

=cut

sub throw {
    my ($self) = @_;
    warn $self->msg;
    exit $self->status;
}

__PACKAGE__->meta->make_immutable;

1;

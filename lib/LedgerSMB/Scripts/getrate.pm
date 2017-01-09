=head1 NAME

LedgerSMB::Scripts::getrate

=cut

package LedgerSMB::Scripts::getrate;
use Plack::App::Proxy;
use LedgerSMB::Setting;
use LedgerSMB::PGDate;
use Plack::Response;
use strict;
use warnings;

=head1 FUNCTIONS

=head2 getrate

Returns the cached FX rate if available, otherwise pass request to a proxied
server for actual data

=cut

use Data::Printer caller_info => 3, deparse => 1,
  filters => {
    'LedgerSMB::PGNumber' => sub { $_[0]->to_output },
    'LedgerSMB::PGDate'   => sub { $_[0]->to_output }
};

sub getrate {
    my ($request,$env) = @_;
    my $response = Plack::Response->new(400,
                      [ 'Content-Type' => 'text/plain; charset=utf-8'],
                      [ 'Bad Parameters' ]
    );
    my $date = LedgerSMB::PGDate->from_input($request->{date});
    if ( $date && $date->is_date && $request->{company}) {
        # Get buy rate
        my ($fxrate) = $request->call_procedure(
                        funcname => 'currency_get_exchangerate',
                        args => [$request->{curr},$date,2]);
        if ( $fxrate->{currency_get_exchangerate} ) {
            $response->status(200);
            $response->body([$fxrate->{currency_get_exchangerate}]);
        } else {
            my $currencies = LedgerSMB::Setting->get('curr');
            my @default = split /:/,$currencies;
            my $url = '/getrate'
                    . '/' . $date->to_output('yyyy-mm-dd')
                    . '/' . $request->{curr}
                    . '/' . $default[0];
            $env->{'plack.proxy.url'} = 'http://currencies.apps.grandtrunk.net'
                                      . $url;
            return Plack::App::Proxy->new->to_app->($env);
        }
    }
    $response->finalize;
}

1;

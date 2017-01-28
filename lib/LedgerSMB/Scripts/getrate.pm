=head1 NAME

LedgerSMB::Scripts::getrate

=cut

package LedgerSMB::Scripts::getrate;
use strict;
use warnings;

use Plack::App::Proxy;
use Plack::Response;

use LedgerSMB::Setting;
use LedgerSMB::PGDate;

=head1 FUNCTIONS

=head2 getrate

Returns the cached FX rate if available, otherwise pass request to a proxied
server for actual data

=cut

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
            my $remote = 'http://currencies.apps.grandtrunk.net';
            my $url = '/getrate'
                    . '/' . $date->to_output('yyyy-mm-dd')
                    . '/' . $request->{curr}
                    . '/' . $default[0];
            $env->{'plack.proxy.url'} = $remote . $url;
            return Plack::App::Proxy->new(backend => 'LWP')->to_app->($env);
        }
    }
    return $response->finalize;
}

1;


package LedgerSMB::Scripts::login;

=head1 NAME

LedgerSMB:Scripts::login - web entry points for session creation

=head1 DESCRIPTION

This script contains the request handlers for logging in of LedgerSMB.

=head1 METHODS

=over

=cut

use strict;
use warnings;

use Digest::MD5 qw( md5_hex );
use HTTP::Status qw( HTTP_OK HTTP_UNAUTHORIZED HTTP_FORBIDDEN );
use JSON::MaybeXS;
use URI::Escape;

use LedgerSMB::PSGI::Util;

our $VERSION = 1.0;

=item __default (no action specified, do this)

Displays the login screen.

=cut

sub __default {
    my ($request) = @_;

    $request->{_req}->env->{'lsmb.session.expire'} = 1;
    $request->{stylesheet} = 'ledgersmb.css';
    $request->{titlebar} = "LedgerSMB $request->{version}";
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'login', $request);
}

=item authenticate

This routine checks for the authentication information and if successful
sends either a HTTP_FOUND redirect or a HTTP_OK successful response.

If unsuccessful sends a HTTP_BAD_REQUEST if the username/password is bad,
or a HTTP_454 error if the database does not exist.

=cut

my $json = JSON::MaybeXS->new( pretty => 1,
                               utf8 => 1,
                               indent => 1,
                               convert_blessed => 1,
                               allow_bignum => 1);

sub authenticate {
    my ($request) = @_;

    if ($request->{_req}->content_length > 4096) {
        # Obviously, the request to log in can't be slurped into memory
        # when bigger than 4k (which it ***NEVER*** should be...
        return LedgerSMB::PSGI::Util::unauthorized();
    }
    my $r;
    {
        local $/ = undef;
        my $fh = $request->{_req}->body;
        my $body = <$fh>;
        $r = $json->decode($body);
    }
    if (! $r->{login}
        || ! $r->{password}) {
        return LedgerSMB::PSGI::Util::unauthorized();
    }

    if (my $settings = $request->{_wire}->get( 'login_settings' )) {
        $r->{company} ||= $settings->{default_db};
    }
    
    # Check TOTP if configured
    # Note: We check TOTP before creating the session but after we know
    # we have login credentials. The database connection itself validates
    # the password, so we're not leaking TOTP status before auth succeeds.
    my $totp_config = $request->{_wire}->get('totp_settings') // {};
    if ($totp_config->{enabled}) {
        # Try to connect temporarily to check TOTP status
        # This connection validates username/password
        my $dbh;
        eval {
            my $db_factory = $request->{_wire}->get('db');
            $dbh = $db_factory->instance(
                dbname => $r->{company},
                user => $r->{login},
                password => $r->{password}
            )->connect;
        };
        
        # If connection failed, invalid credentials - let normal flow handle it
        if (!$dbh) {
            # Fall through to _create_session which will return unauthorized
        }
        elsif ($dbh) {
            # Successfully connected - password is valid
            # Now check TOTP status for this user
            my $totp_info = $dbh->selectrow_hashref(
                q{SELECT totp_enabled, totp_secret, totp_locked_until 
                  FROM users WHERE username = ?},
                undef,
                $r->{login}
            );
            
            if ($totp_info && $totp_info->{totp_enabled}) {
                # Check if locked and lockout period is still active
                if ($totp_info->{totp_locked_until}) {
                    # Query current timestamp from database to compare
                    my ($current_time) = $dbh->selectrow_array(
                        q{SELECT CURRENT_TIMESTAMP}
                    );
                    my ($locked_until) = $dbh->selectrow_array(
                        q{SELECT ?::timestamp > ?::timestamp},
                        undef,
                        $totp_info->{totp_locked_until},
                        $current_time
                    );
                    
                    if ($locked_until) {
                        $dbh->disconnect;
                        return [
                            HTTP::Status::HTTP_FORBIDDEN,
                            [ 'Content-Type' => 'application/json' ],
                            [ $json->encode({
                                error => 'Account temporarily locked due to failed TOTP attempts',
                                locked => 1,
                                locked_until => $totp_info->{totp_locked_until}
                            }) ]
                        ];
                    }
                }
                
                # TOTP is enabled, code required
                my $totp_code = $r->{totp_code};
                if (!defined $totp_code || $totp_code eq '') {
                    $dbh->disconnect;
                    return [
                        HTTP::Status::HTTP_UNAUTHORIZED,
                        [ 'Content-Type' => 'application/json',
                          'X-LedgerSMB-TOTP-Required' => '1' ],
                        [ $json->encode({
                            error => 'TOTP verification code required',
                            totp_required => 1
                        }) ]
                    ];
                }
                
                # Verify TOTP code
                use LedgerSMB::TOTP;
                my $totp = LedgerSMB::TOTP->new(
                    secret => $totp_info->{totp_secret},
                    time_window => $totp_config->{time_window} // 1,
                );
                
                my $is_valid = $totp->verify_code($totp_code);
                
                # Update TOTP status
                my $max_failures = $totp_config->{max_failures} // 5;
                my $lockout_duration = ($totp_config->{lockout_duration} // 900) . ' seconds';
                
                my $result = $dbh->selectrow_hashref(
                    q{SELECT * FROM user__totp_verify_and_update(?, ?, ?, ?::interval)},
                    undef,
                    $r->{login},
                    $is_valid ? 1 : 0,
                    $max_failures,
                    $lockout_duration
                );
                
                $dbh->disconnect;
                
                if (!$is_valid) {
                    return [
                        HTTP::Status::HTTP_UNAUTHORIZED,
                        [ 'Content-Type' => 'application/json' ],
                        [ $json->encode({
                            error => 'Invalid TOTP code',
                            totp_required => 1,
                            failures => $result->{failures}
                        }) ]
                    ];
                }
                
                if ($result && $result->{is_locked}) {
                    return [
                        HTTP::Status::HTTP_FORBIDDEN,
                        [ 'Content-Type' => 'application/json' ],
                        [ $json->encode({
                            error => 'Too many failed TOTP attempts. Account locked.',
                            locked => 1
                        }) ]
                    ];
                }
            }
            else {
                $dbh->disconnect;
            }
        }
    }
    
    if (my $r = $request->{_create_session}->($r->{login},
                                              $r->{password},
                                              $r->{company})) {
        return $r;
    }

    $request->{_req}->env->{'lsmb.session'}->{company_path} =
        md5_hex( $r->{company} );
    my $token = $request->{_req}->env->{'lsmb.session'}->{company_path};
    my $user  = uri_escape( $r->{login} );
    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json' ],
             [ qq|{ "target":  "$token/erp.pl?user=$user" }| ]];
}


=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;

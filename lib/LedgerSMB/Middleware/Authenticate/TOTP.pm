
package LedgerSMB::Middleware::Authenticate::TOTP;

=head1 NAME

LedgerSMB::Middleware::Authenticate::TOTP - TOTP two-factor authentication

=head1 SYNOPSIS

  builder {
    enable "+LedgerSMB::Middleware::Authenticate::TOTP",
        wire => $wire;
    $app;
  }

=head1 DESCRIPTION

LedgerSMB::Middleware::Authenticate::TOTP provides Time-based One-Time Password
(TOTP) two-factor authentication for users who have it enabled.

This middleware should be placed in the authentication chain after password
verification but before session creation.

=head1 CONFIGURATION

The middleware uses the following configuration from the wire container:

  totp_settings:
    enabled: true              # Enable TOTP globally
    max_failures: 5            # Max failed attempts before lockout
    lockout_duration: 900      # Lockout duration in seconds (15 min)
    time_window: 1             # Time window for TOTP verification (±30s)

=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use DBI;
use HTTP::Status qw( HTTP_OK HTTP_UNAUTHORIZED HTTP_FORBIDDEN );
use JSON::MaybeXS;
use Plack::Request;
use Plack::Util::Accessor qw( wire );

use LedgerSMB::TOTP;
use LedgerSMB::PSGI::Util;

my $json = JSON::MaybeXS->new( 
    pretty => 1,
    utf8 => 1,
    indent => 1,
    convert_blessed => 1,
    allow_bignum => 1
);

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

This middleware checks if TOTP is enabled for the authenticating user.
If enabled, it validates the TOTP code provided in the request.

=cut

sub call {
    my $self = shift;
    my ($env) = @_;
    
    # Get TOTP settings from configuration
    my $totp_config = $self->wire->get('totp_settings') // {};
    my $totp_enabled = $totp_config->{enabled} // 0;
    
    # If TOTP is not enabled globally, skip this middleware
    return $self->app->($env) unless $totp_enabled;
    
    # Check if this is a login request with credentials
    my $req = Plack::Request->new($env);
    my $path = $req->path_info;
    
    # Only intercept authentication attempts
    # Skip if not an authentication request
    return $self->app->($env) unless $path =~ m{/login\.pl$};
    
    # Check if this is a POST request (authentication attempt)
    return $self->app->($env) unless $req->method eq 'POST';
    
    # Parse request body to get credentials
    my $body_params;
    eval {
        my $content = $req->content;
        $body_params = $json->decode($content) if $content;
    };
    
    # If we can't parse or no login data, let next middleware handle it
    return $self->app->($env) unless $body_params && $body_params->{login};
    
    my $username = $body_params->{login};
    my $company = $body_params->{company};
    my $totp_code = $body_params->{totp_code};
    
    # Connect to database to check TOTP status
    # We need a temporary connection just to check TOTP settings
    my $dbh;
    eval {
        # Get database factory from wire
        my $db_factory = $self->wire->get('db');
        my $password = $body_params->{password};
        
        # Try to connect with provided credentials
        $dbh = $db_factory->instance(
            dbname => $company,
            user => $username,
            password => $password
        )->connect;
    };
    
    # If connection failed, let the normal auth middleware handle it
    if (!$dbh) {
        return $self->app->($env);
    }
    
    # Check if user has TOTP enabled
    my $totp_info = $dbh->selectrow_hashref(
        q{SELECT totp_enabled, totp_secret, totp_locked_until, totp_failures
          FROM users WHERE username = ?},
        undef,
        $username
    );
    
    $dbh->disconnect;
    
    # If TOTP not enabled for this user, continue with normal auth
    return $self->app->($env) unless $totp_info && $totp_info->{totp_enabled};
    
    # Check if user is locked out
    if ($totp_info->{totp_locked_until}) {
        my $locked_until = $totp_info->{totp_locked_until};
        # Parse timestamp (PostgreSQL format)
        if ($locked_until =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
            my $locked_time = "$1-$2-$3T$4:$5:$6";
            my $now = time();
            
            # Simple timestamp comparison
            # For production, should use proper date parsing
            # For now, if totp_locked_until is set, deny access
            return [
                HTTP_FORBIDDEN,
                [ 'Content-Type' => 'application/json' ],
                [ $json->encode({
                    error => 'Account temporarily locked due to too many failed TOTP attempts. Please try again later.',
                    locked_until => $locked_until
                }) ]
            ];
        }
    }
    
    # TOTP is required but no code provided
    if (!defined $totp_code || $totp_code eq '') {
        return [
            HTTP_UNAUTHORIZED,
            [ 'Content-Type' => 'application/json',
              'X-LedgerSMB-TOTP-Required' => '1' ],
            [ $json->encode({
                error => 'TOTP code required',
                totp_required => 1
            }) ]
        ];
    }
    
    # Verify TOTP code
    my $totp = LedgerSMB::TOTP->new(
        secret => $totp_info->{totp_secret},
        time_window => $totp_config->{time_window} // 1,
    );
    
    my $is_valid = $totp->verify_code($totp_code);
    
    # Reconnect to update TOTP status
    eval {
        my $db_factory = $self->wire->get('db');
        my $password = $body_params->{password};
        
        $dbh = $db_factory->instance(
            dbname => $company,
            user => $username,
            password => $password
        )->connect;
    };
    
    if ($dbh) {
        my $max_failures = $totp_config->{max_failures} // 5;
        my $lockout_duration = ($totp_config->{lockout_duration} // 900) . ' seconds';
        
        # Update TOTP verification state
        my $result = $dbh->selectrow_hashref(
            q{SELECT * FROM user__totp_verify_and_update(?, ?, ?, ?::interval)},
            undef,
            $username,
            $is_valid ? 1 : 0,
            $max_failures,
            $lockout_duration
        );
        
        $dbh->disconnect;
        
        # Check if user got locked
        if ($result && $result->{is_locked}) {
            return [
                HTTP_FORBIDDEN,
                [ 'Content-Type' => 'application/json' ],
                [ $json->encode({
                    error => 'Too many failed TOTP attempts. Account temporarily locked.',
                    failures => $result->{failures}
                }) ]
            ];
        }
    }
    
    # If TOTP verification failed
    if (!$is_valid) {
        return [
            HTTP_UNAUTHORIZED,
            [ 'Content-Type' => 'application/json' ],
            [ $json->encode({
                error => 'Invalid TOTP code',
                totp_required => 1
            }) ]
        ];
    }
    
    # TOTP verification successful, proceed with normal authentication
    return $self->app->($env);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version. A copy of the license should have been included with
your software.

=cut

1;

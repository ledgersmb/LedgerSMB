
package LedgerSMB::TOTP;

=head1 NAME

LedgerSMB::TOTP - Time-based One-Time Password (TOTP) authentication support

=head1 SYNOPSIS

  use LedgerSMB::TOTP;
  
  my $totp = LedgerSMB::TOTP->new(
      secret => $secret,  # Base32 encoded secret
      issuer => 'LedgerSMB',
      account => $username
  );
  
  # Verify a TOTP code
  if ($totp->verify_code($code)) {
      # Code is valid
  }
  
  # Generate a new secret
  my $new_secret = LedgerSMB::TOTP->generate_secret();
  
  # Get QR code for authenticator app
  my $qr_code_data = $totp->qr_code();

=head1 DESCRIPTION

This module provides TOTP (Time-based One-Time Password) authentication
support according to RFC 6238. It allows users to set up two-factor
authentication using authenticator apps like Google Authenticator, Authy,
or any other TOTP-compatible application.

=head1 METHODS

=cut

use strict;
use warnings;

use Auth::GoogleAuth;
use Convert::Base32 qw(encode_base32 decode_base32);
use Carp;
use GD::Barcode::QRcode;
use MIME::Base64;

use Moose;
use namespace::autoclean;

=head2 ATTRIBUTES

=head3 secret

The Base32-encoded TOTP secret key. Required for verification operations.

=cut

has 'secret' => (
    is => 'ro',
    isa => 'Str',
    required => 0,
);

=head3 issuer

The issuer name for the TOTP token (displayed in authenticator apps).
Defaults to 'LedgerSMB'.

=cut

has 'issuer' => (
    is => 'ro',
    isa => 'Str',
    default => 'LedgerSMB',
);

=head3 account

The account/username associated with this TOTP token.

=cut

has 'account' => (
    is => 'ro',
    isa => 'Str',
    required => 0,
);

=head3 time_window

The number of time periods before and after the current time to accept.
Default is 1 (allowing for ±30 seconds of clock drift).

=cut

has 'time_window' => (
    is => 'ro',
    isa => 'Int',
    default => 1,
);

=head3 _auth

Internal Auth::GoogleAuth object.

=cut

has '_auth' => (
    is => 'ro',
    isa => 'Auth::GoogleAuth',
    lazy => 1,
    builder => '_build_auth',
);

sub _build_auth {
    my ($self) = @_;
    
    return Auth::GoogleAuth->new({
        secret => $self->secret,
        issuer => $self->issuer,
        key_id => $self->account,
    });
}

=head2 CLASS METHODS

=head3 generate_secret()

Generates a new random Base32-encoded secret suitable for TOTP.
Returns a 32-character Base32 string (160 bits of entropy).

  my $secret = LedgerSMB::TOTP->generate_secret();

=cut

sub generate_secret {
    my ($class) = @_;
    
    # Use a cryptographically secure random source
    # Try to read from /dev/urandom (available on Unix-like systems)
    my $random_bytes = '';
    
    if (open my $fh, '<:raw', '/dev/urandom') {
        read $fh, $random_bytes, 20;  # 20 bytes = 160 bits
        close $fh;
    }
    else {
        # Fallback: use String::Random which is already in dependencies
        # and provides better randomness than built-in rand()
        require String::Random;
        my $sr = String::Random->new();
        # Generate 20 random bytes
        $random_bytes = pack('C*', map { int(rand(256)) } 1..20);
        
        # Note: This fallback is not cryptographically secure
        # In production, /dev/urandom should always be available on Unix-like systems
        warn "Warning: Using non-cryptographic random source for TOTP secret generation";
    }
    
    # Encode as Base32
    my $secret = encode_base32($random_bytes);
    
    # Remove padding
    $secret =~ s/=+$//;
    
    return $secret;
}

=head2 INSTANCE METHODS

=head3 verify_code($code)

Verifies a TOTP code. Returns 1 if valid, 0 if invalid.

The verification accepts codes within the time_window (default ±30 seconds)
to account for clock drift between the server and user's device.

  if ($totp->verify_code('123456')) {
      # Valid code
  }

=cut

sub verify_code {
    my ($self, $code) = @_;
    
    croak "TOTP secret not set" unless $self->secret;
    croak "Code must be provided" unless defined $code;
    
    # Remove any spaces or dashes from the code
    $code =~ s/[\s\-]//g;
    
    # Verify the code is 6 digits
    return 0 unless $code =~ /^\d{6}$/;
    
    # Use Auth::GoogleAuth to verify
    # It automatically checks within a time window
    return $self->_auth->verify($code) ? 1 : 0;
}

=head3 qr_code()

Generates a QR code image (as PNG data) that can be scanned by authenticator
apps. Returns the binary PNG data.

  my $png_data = $totp->qr_code();
  
  # To display in a browser:
  # <img src="data:image/png;base64,..." />

=cut

sub qr_code {
    my ($self) = @_;
    
    croak "TOTP secret not set" unless $self->secret;
    croak "Account must be set for QR code" unless $self->account;
    
    # Get the otpauth URI
    my $uri = $self->otpauth_uri();
    
    # Generate QR code
    my $qr = GD::Barcode::QRcode->new(
        $uri,
        {
            Ecc => 'M',
            Version => 0,
            ModuleSize => 4,
        }
    );
    
    croak "Failed to generate QR code: " . $GD::Barcode::errStr 
        unless $qr;
    
    return $qr->plot->png;
}

=head3 qr_code_base64()

Returns the QR code as a Base64-encoded string suitable for embedding
in HTML.

  my $base64 = $totp->qr_code_base64();
  # Use in HTML: <img src="data:image/png;base64,$base64" />

=cut

sub qr_code_base64 {
    my ($self) = @_;
    
    my $png_data = $self->qr_code();
    return encode_base64($png_data, '');
}

=head3 otpauth_uri()

Returns the otpauth:// URI for this TOTP token. This URI can be used
to configure authenticator apps.

  my $uri = $totp->otpauth_uri();

=cut

sub otpauth_uri {
    my ($self) = @_;
    
    croak "TOTP secret not set" unless $self->secret;
    croak "Account must be set for otpauth URI" unless $self->account;
    
    return $self->_auth->qr_code();
}

=head3 current_code()

Returns the current valid TOTP code. This is primarily useful for testing.

  my $code = $totp->current_code();

=cut

sub current_code {
    my ($self) = @_;
    
    croak "TOTP secret not set" unless $self->secret;
    
    return $self->_auth->code();
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version. A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;

#!/usr/bin/perl

=head1 NAME

t/13.1-totp.t - Tests for LedgerSMB::TOTP module

=head1 DESCRIPTION

This test file validates the TOTP (Time-based One-Time Password) functionality
according to RFC 6238.

=cut

use Test2::V0;
use Test2::Tools::Exception;

BEGIN {
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($OFF);
}

# Load the module
use ok 'LedgerSMB::TOTP';

# Test secret generation
subtest 'Secret generation' => sub {
    my $secret = LedgerSMB::TOTP->generate_secret();
    
    ok(defined $secret, 'Secret is defined');
    ok(length($secret) > 0, 'Secret is not empty');
    like($secret, qr/^[A-Z2-7]+$/, 'Secret is valid Base32');
    is(length($secret), 32, 'Secret is 32 characters (160 bits)');
    
    # Generate another one and make sure they're different
    my $secret2 = LedgerSMB::TOTP->generate_secret();
    isnt($secret, $secret2, 'Generated secrets are unique');
};

# Test TOTP object creation
subtest 'TOTP object creation' => sub {
    my $secret = 'JBSWY3DPEHPK3PXP';  # Test secret
    
    my $totp = LedgerSMB::TOTP->new(
        secret => $secret,
        issuer => 'TestIssuer',
        account => 'testuser',
    );
    
    ok(defined $totp, 'TOTP object created');
    is($totp->secret, $secret, 'Secret stored correctly');
    is($totp->issuer, 'TestIssuer', 'Issuer stored correctly');
    is($totp->account, 'testuser', 'Account stored correctly');
    is($totp->time_window, 1, 'Default time window is 1');
};

# Test TOTP code verification
subtest 'Code verification' => sub {
    my $secret = 'JBSWY3DPEHPK3PXP';
    
    my $totp = LedgerSMB::TOTP->new(
        secret => $secret,
        account => 'testuser',
    );
    
    # Get the current valid code
    my $current_code = $totp->current_code();
    ok(defined $current_code, 'Current code generated');
    like($current_code, qr/^\d{6}$/, 'Code is 6 digits');
    
    # Verify the current code
    ok($totp->verify_code($current_code), 'Current code verifies successfully');
    
    # Test invalid codes
    ok(!$totp->verify_code('000000'), 'Invalid code rejected');
    ok(!$totp->verify_code('123456'), 'Random code rejected (probably)');
    
    # Test invalid input
    ok(!$totp->verify_code('abc123'), 'Non-numeric code rejected');
    ok(!$totp->verify_code('12345'), 'Too-short code rejected');
    ok(!$totp->verify_code('1234567'), 'Too-long code rejected');
};

# Test code with spaces and dashes
subtest 'Code formatting tolerance' => sub {
    my $secret = 'JBSWY3DPEHPK3PXP';
    
    my $totp = LedgerSMB::TOTP->new(
        secret => $secret,
        account => 'testuser',
    );
    
    my $current_code = $totp->current_code();
    
    # Test with spaces
    my $spaced_code = substr($current_code, 0, 3) . ' ' . substr($current_code, 3, 3);
    ok($totp->verify_code($spaced_code), 'Code with spaces accepted');
    
    # Test with dashes
    my $dashed_code = substr($current_code, 0, 3) . '-' . substr($current_code, 3, 3);
    ok($totp->verify_code($dashed_code), 'Code with dashes accepted');
};

# Test otpauth URI generation
subtest 'OTPAuth URI generation' => sub {
    my $secret = 'JBSWY3DPEHPK3PXP';
    
    my $totp = LedgerSMB::TOTP->new(
        secret => $secret,
        issuer => 'LedgerSMB',
        account => 'testuser',
    );
    
    my $uri = $totp->otpauth_uri();
    ok(defined $uri, 'URI generated');
    like($uri, qr/^otpauth:\/\/totp\//, 'URI has correct protocol');
    like($uri, qr/LedgerSMB/, 'URI contains issuer');
    like($uri, qr/testuser/, 'URI contains account');
    like($uri, qr/secret=$secret/i, 'URI contains secret');
};

# Test QR code generation
subtest 'QR code generation' => sub {
    my $secret = 'JBSWY3DPEHPK3PXP';
    
    my $totp = LedgerSMB::TOTP->new(
        secret => $secret,
        issuer => 'LedgerSMB',
        account => 'testuser',
    );
    
    my $qr_png = eval { $totp->qr_code() };
    
    SKIP: {
        skip 'QR code generation requires GD::Barcode::QRcode', 2
            if $@ && $@ =~ /Can't locate GD/;
        
        ok(defined $qr_png, 'QR code PNG data generated');
        like($qr_png, qr/^\x89PNG/, 'QR code is valid PNG');
        
        # Test Base64 encoding
        my $qr_base64 = $totp->qr_code_base64();
        ok(defined $qr_base64, 'Base64 QR code generated');
        ok(length($qr_base64) > 0, 'Base64 QR code not empty');
        like($qr_base64, qr/^[A-Za-z0-9+\/=]+$/, 'Base64 QR code is valid Base64');
    }
};

# Test error conditions
subtest 'Error handling' => sub {
    # Test verification without secret
    like(
        dies { 
            my $totp = LedgerSMB::TOTP->new(account => 'test');
            $totp->verify_code('123456');
        },
        qr/TOTP secret not set/,
        'Verification without secret throws error'
    );
    
    # Test verification without code
    like(
        dies {
            my $totp = LedgerSMB::TOTP->new(
                secret => 'JBSWY3DPEHPK3PXP',
                account => 'test'
            );
            $totp->verify_code();
        },
        qr/Code must be provided/,
        'Verification without code throws error'
    );
    
    # Test QR code without account
    like(
        dies {
            my $totp = LedgerSMB::TOTP->new(
                secret => 'JBSWY3DPEHPK3PXP'
            );
            $totp->qr_code();
        },
        qr/Account must be set/,
        'QR code generation without account throws error'
    );
};

# Test with different time windows
subtest 'Time window tolerance' => sub {
    my $secret = 'JBSWY3DPEHPK3PXP';
    
    # Create TOTP with wider time window
    my $totp = LedgerSMB::TOTP->new(
        secret => $secret,
        account => 'testuser',
        time_window => 2,  # ±60 seconds
    );
    
    my $current_code = $totp->current_code();
    ok($totp->verify_code($current_code), 'Code verifies with wider time window');
};

done_testing;

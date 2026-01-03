# Two-Factor Authentication (TOTP)

## Overview

LedgerSMB supports Time-based One-Time Password (TOTP) authentication as an additional security layer for user accounts. TOTP provides two-factor authentication using authenticator apps like Google Authenticator, Authy, Microsoft Authenticator, or any other TOTP-compatible application.

## Features

- **RFC 6238 Compliant**: Implements standard TOTP algorithm
- **Optional per-user**: Users can opt-in to enable TOTP on their accounts
- **QR Code Setup**: Easy setup by scanning a QR code with authenticator app
- **Brute Force Protection**: Automatic lockout after multiple failed attempts
- **Clock Drift Tolerance**: Configurable time window to handle clock synchronization issues
- **Fallback Support**: Users without TOTP enabled can still use password-only authentication

## Configuration

TOTP can be configured in the `ledgersmb.yaml` or `ledgersmb.conf` configuration file.

### YAML Configuration (ledgersmb.yaml)

```yaml
totp_settings:
  enabled: true              # Enable TOTP globally (default: false)
  max_failures: 5            # Maximum failed attempts before lockout (default: 5)
  lockout_duration: 900      # Lockout duration in seconds (default: 900 = 15 minutes)
  time_window: 1             # Time window for code acceptance (default: 1 = ±30 seconds)
```

### Legacy INI Configuration (ledgersmb.conf)

```ini
[main]
totp_enabled = 1
totp_max_failures = 5
totp_lockout_duration = 900
totp_time_window = 1
```

### Configuration Options

- **enabled**: When `true`, TOTP functionality is available. Users can still choose to enable or disable it individually.
- **max_failures**: Number of consecutive failed TOTP verification attempts before the account is temporarily locked.
- **lockout_duration**: Time in seconds that an account remains locked after exceeding max_failures. 
- **time_window**: Number of 30-second periods before and after the current time to accept codes. A value of 1 means ±30 seconds tolerance.

## User Setup

### Enabling TOTP

1. Log in to LedgerSMB with your username and password
2. Navigate to **User Preferences** (typically from the user menu)
3. Click on the **Two-Factor Authentication** tab
4. Click **Manage Two-Factor Authentication**
5. Scan the displayed QR code with your authenticator app, or manually enter the secret key
6. Enter the 6-digit verification code from your app to confirm setup
7. Click **Enable Two-Factor Authentication**

### Disabling TOTP

1. Log in to LedgerSMB (you'll need your authenticator app)
2. Navigate to **User Preferences**
3. Click on the **Two-Factor Authentication** tab
4. Click **Disable Two-Factor Authentication**
5. Confirm the action

## Login Process with TOTP

Once TOTP is enabled for a user:

1. Enter your username, password, and company as usual
2. Click **Login**
3. If TOTP is enabled, you'll be prompted for a verification code
4. Open your authenticator app and enter the 6-digit code
5. Click **Verify** to complete login

## Security Considerations

### Best Practices

- **Backup Your Secret**: Save the secret key in a secure location in case you lose access to your authenticator device
- **Time Synchronization**: Ensure your device's time is synchronized (use NTP) for codes to work correctly
- **Recovery Plan**: Have a procedure for account recovery if a user loses their authenticator device
- **Administrative Override**: Administrators can disable TOTP for a user who has lost access to their authenticator

### Brute Force Protection

The system automatically protects against brute force attacks:

- After 5 failed attempts (by default), the account is locked for 15 minutes
- During lockout, the user cannot attempt TOTP verification
- The lockout counter resets after a successful login

### Account Recovery

If a user loses access to their authenticator device:

1. An administrator can disable TOTP for the user using SQL:
   ```sql
   SELECT admin__totp_disable_user('username');
   ```

2. Or reset just the failure count if the account is locked:
   ```sql
   SELECT admin__totp_reset_failures('username');
   ```

## Technical Details

### Database Schema

TOTP adds the following columns to the `users` table:

- `totp_secret`: Base32-encoded secret key (160 bits)
- `totp_enabled`: Boolean flag indicating if TOTP is active
- `totp_last_used`: Timestamp of last successful TOTP verification (prevents replay)
- `totp_failures`: Count of consecutive failed attempts
- `totp_locked_until`: Timestamp until which the account is locked

### Supported Authenticator Apps

Any TOTP-compatible authenticator application can be used, including:

- Google Authenticator
- Microsoft Authenticator
- Authy
- 1Password
- Bitwarden
- LastPass Authenticator
- FreeOTP
- AndOTP

### Time Synchronization

TOTP codes are time-based and change every 30 seconds. For proper operation:

- Server time should be synchronized via NTP
- User devices should have accurate time
- The `time_window` setting provides tolerance for clock drift

### API Integration

When authenticating via API, include the TOTP code in the authentication payload:

```json
{
  "login": "username",
  "password": "password",
  "company": "mycompany",
  "totp_code": "123456"
}
```

The API will respond with:
- `X-LedgerSMB-TOTP-Required: 1` header if TOTP code is needed
- `401 Unauthorized` for invalid TOTP code
- `403 Forbidden` if account is locked

## Troubleshooting

### Code Not Working

1. **Check Time Synchronization**: Ensure your device and server times are synchronized
2. **Verify Secret**: Make sure you scanned the correct QR code or entered the right secret
3. **Check Code Freshness**: TOTP codes expire every 30 seconds; enter a fresh code
4. **Time Zone Issues**: Server and device should use the same time standard (UTC)

### Account Locked

If you see "Account temporarily locked":

1. Wait for the lockout duration (default 15 minutes)
2. Or contact an administrator to reset the lockout

### Lost Authenticator Device

1. Contact your LedgerSMB administrator
2. Administrator can disable TOTP for your account
3. You can then re-enable TOTP with a new device

## Migration and Updates

### Enabling TOTP on Existing Systems

1. Update LedgerSMB to a version that supports TOTP
2. Run database migrations (automatic with `setup.pl`)
3. Enable TOTP in configuration
4. Notify users they can enable TOTP in their preferences

### Disabling TOTP Globally

To disable TOTP for all users:

1. Set `totp_enabled = 0` in configuration
2. Restart LedgerSMB
3. Users with TOTP enabled can still use password-only authentication

## References

- [RFC 6238 - TOTP: Time-Based One-Time Password Algorithm](https://tools.ietf.org/html/rfc6238)
- [RFC 4226 - HOTP: An HMAC-Based One-Time Password Algorithm](https://tools.ietf.org/html/rfc4226)

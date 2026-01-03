-- Add TOTP (Time-based One-Time Password) authentication support
-- RFC 6238 compliant two-factor authentication

-- Add TOTP columns to users table
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS totp_secret VARCHAR(32), -- Base32 encoded secret (160 bits)
  ADD COLUMN IF NOT EXISTS totp_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS totp_last_used TIMESTAMP,
  ADD COLUMN IF NOT EXISTS totp_failures INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS totp_locked_until TIMESTAMP;

COMMENT ON COLUMN users.totp_secret IS $$
  The Base32-encoded TOTP secret key (160 bits, 32 characters).
  This is used to generate time-based one-time passwords.
  Must be kept confidential.
$$;

COMMENT ON COLUMN users.totp_enabled IS $$
  Whether TOTP two-factor authentication is enabled for this user.
  When TRUE, the user must provide a valid TOTP code in addition to
  their password to authenticate.
$$;

COMMENT ON COLUMN users.totp_last_used IS $$
  Timestamp of when a TOTP code was last successfully used.
  Used to prevent replay attacks by ensuring the same code
  cannot be used twice.
$$;

COMMENT ON COLUMN users.totp_failures IS $$
  Number of consecutive failed TOTP verification attempts.
  Reset to 0 on successful authentication.
  Used for brute force protection.
$$;

COMMENT ON COLUMN users.totp_locked_until IS $$
  Timestamp until which TOTP authentication is locked due to
  excessive failed attempts. NULL if not locked.
$$;

-- Create index for locked users lookup
CREATE INDEX IF NOT EXISTS users_totp_locked_idx 
  ON users(totp_locked_until) 
  WHERE totp_locked_until IS NOT NULL;

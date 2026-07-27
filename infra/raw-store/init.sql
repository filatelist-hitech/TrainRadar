CREATE TABLE IF NOT EXISTS encrypted_raw_observation (
    observation_id uuid PRIMARY KEY,
    ciphertext bytea NOT NULL,
    nonce bytea NOT NULL,
    wrapped_dek bytea NOT NULL,
    observed_at timestamptz NOT NULL,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT retention_positive CHECK (expires_at > observed_at),
    CONSTRAINT retention_max_24h CHECK (expires_at <= observed_at + interval '24 hours')
);

COMMENT ON TABLE encrypted_raw_observation IS
  'Ciphertext-only raw GPS boundary. Deletion worker and key destruction are not implemented in M0.';

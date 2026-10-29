CREATE TABLE IF NOT EXISTS licenses (
 id TEXT PRIMARY KEY, key_hash TEXT NOT NULL UNIQUE, customer TEXT,
 subscription TEXT UNIQUE, status TEXT NOT NULL, expires INTEGER NOT NULL,
 updated INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS billing_events(id TEXT PRIMARY KEY,created INTEGER NOT NULL);
CREATE INDEX IF NOT EXISTS licenses_status ON licenses(status,expires);

CREATE TABLE IF NOT EXISTS license_recovery (
 license_id TEXT PRIMARY KEY REFERENCES licenses(id), recovery_hash TEXT NOT NULL UNIQUE
);

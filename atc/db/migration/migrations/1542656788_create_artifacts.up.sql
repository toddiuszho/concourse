BEGIN;
  CREATE TABLE worker_artifacts (
    id SERIAL PRIMARY KEY,
    path TEXT NOT NULL,
    checksum TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
  );
COMMIT;

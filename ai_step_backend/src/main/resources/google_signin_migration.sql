-- Migration to add Google Sign-In support
-- Add google_id column to users table

ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) UNIQUE;
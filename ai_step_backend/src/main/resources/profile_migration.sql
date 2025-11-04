-- SQL migration to add profile fields to users table
-- This migration adds fields for user profile information

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS height_cm DOUBLE,
ADD COLUMN IF NOT EXISTS weight_kg DOUBLE,
ADD COLUMN IF NOT EXISTS gender VARCHAR(20),
ADD COLUMN IF NOT EXISTS activity_level VARCHAR(50),
ADD COLUMN IF NOT EXISTS goal VARCHAR(20),
ADD COLUMN IF NOT EXISTS birth_date VARCHAR(10),
ADD COLUMN IF NOT EXISTS age INTEGER;

-- Add constraints for data validation
ALTER TABLE users 
ADD CONSTRAINT chk_height CHECK (height_cm IS NULL OR (height_cm >= 50 AND height_cm <= 300)),
ADD CONSTRAINT chk_weight CHECK (weight_kg IS NULL OR (weight_kg >= 30 AND weight_kg <= 500)),
ADD CONSTRAINT chk_gender CHECK (gender IS NULL OR gender IN ('male', 'female', 'other')),
ADD CONSTRAINT chk_activity_level CHECK (activity_level IS NULL OR activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active')),
ADD CONSTRAINT chk_goal CHECK (goal IS NULL OR goal IN ('lose', 'maintain', 'gain')),
ADD CONSTRAINT chk_age CHECK (age IS NULL OR (age >= 13 AND age <= 120));

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_users_profile ON users(gender, activity_level, goal);
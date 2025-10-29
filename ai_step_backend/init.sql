-- Create database schema for AI Step application

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email_verified BOOLEAN DEFAULT FALSE,
    locale VARCHAR(10),
    timezone VARCHAR(50),
    units_preference VARCHAR(20) DEFAULT 'metric',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Steps table
CREATE TABLE IF NOT EXISTS steps (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    device_id VARCHAR(255),
    step_count INTEGER NOT NULL DEFAULT 0,
    distance_m DOUBLE PRECISION,
    calories_burned DOUBLE PRECISION,
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    recorded_date DATE NOT NULL,
    CONSTRAINT fk_steps_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for steps table
CREATE INDEX IF NOT EXISTS idx_steps_user_id ON steps(user_id);
CREATE INDEX IF NOT EXISTS idx_steps_recorded_date ON steps(recorded_date);
CREATE INDEX IF NOT EXISTS idx_steps_user_date ON steps(user_id, recorded_date);

-- Step data table (detailed accelerometer data)
CREATE TABLE IF NOT EXISTS step_data (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    step_count INTEGER NOT NULL DEFAULT 0,
    accelerometer_x DOUBLE PRECISION,
    accelerometer_y DOUBLE PRECISION,
    accelerometer_z DOUBLE PRECISION,
    magnitude DOUBLE PRECISION,
    confidence_score DOUBLE PRECISION,
    is_valid_step BOOLEAN DEFAULT TRUE,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    device_orientation VARCHAR(50),
    activity_type VARCHAR(50),
    CONSTRAINT fk_step_data_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for step_data table
CREATE INDEX IF NOT EXISTS idx_step_data_user_id ON step_data(user_id);
CREATE INDEX IF NOT EXISTS idx_step_data_timestamp ON step_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_step_data_user_timestamp ON step_data(user_id, timestamp);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at in users table
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- View for daily step totals (based on DailyStepTotals model)
CREATE OR REPLACE VIEW daily_step_totals AS
SELECT 
    user_id,
    recorded_date AS day,
    SUM(step_count) AS total_steps,
    SUM(distance_m) AS total_distance_m,
    SUM(calories_burned)::INTEGER AS total_calories,
    MAX(recorded_at) AS last_entry_at
FROM steps
GROUP BY user_id, recorded_date;

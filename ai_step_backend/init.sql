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

CREATE TABLE IF NOT EXISTS weekly_progress (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    total_steps INTEGER NOT NULL DEFAULT 0,
    total_distance_m DOUBLE PRECISION,
    total_calories DOUBLE PRECISION,
    daily_average_steps INTEGER,
    goal_days_count INTEGER DEFAULT 0,
    best_day_steps INTEGER,
    best_day_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_weekly_progress_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT unique_user_week UNIQUE (user_id, week_start_date),
    CONSTRAINT check_week_dates CHECK (week_end_date >= week_start_date),
    CONSTRAINT check_total_steps CHECK (total_steps >= 0),
    CONSTRAINT check_goal_days CHECK (goal_days_count >= 0 AND goal_days_count <= 7)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_weekly_progress_user_id ON weekly_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_progress_week_start ON weekly_progress(week_start_date);
CREATE INDEX IF NOT EXISTS idx_weekly_progress_user_week ON weekly_progress(user_id, week_start_date);
CREATE INDEX IF NOT EXISTS idx_weekly_progress_user_week_desc ON weekly_progress(user_id, week_start_date DESC);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_weekly_progress_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row update
CREATE TRIGGER trigger_update_weekly_progress_updated_at
    BEFORE UPDATE ON weekly_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_weekly_progress_updated_at();

-- Comments for documentation
COMMENT ON TABLE weekly_progress IS 'Stores aggregated weekly step progress for users';
COMMENT ON COLUMN weekly_progress.user_id IS 'Reference to user who owns this weekly progress';
COMMENT ON COLUMN weekly_progress.week_start_date IS 'Monday of the week (start date)';
COMMENT ON COLUMN weekly_progress.week_end_date IS 'Sunday of the week (end date)';
COMMENT ON COLUMN weekly_progress.total_steps IS 'Total steps for the entire week';
COMMENT ON COLUMN weekly_progress.total_distance_m IS 'Total distance in meters for the week';
COMMENT ON COLUMN weekly_progress.total_calories IS 'Total calories burned for the week';
COMMENT ON COLUMN weekly_progress.daily_average_steps IS 'Average daily steps for the week';
COMMENT ON COLUMN weekly_progress.goal_days_count IS 'Number of days the daily goal was achieved';
COMMENT ON COLUMN weekly_progress.best_day_steps IS 'Highest step count in the week';
COMMENT ON COLUMN weekly_progress.best_day_date IS 'Date when the best day occurred';

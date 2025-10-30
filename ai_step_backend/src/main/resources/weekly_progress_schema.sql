-- Weekly Progress Table Schema
-- Stores aggregated weekly step progress for users

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

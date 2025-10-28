-- SQL script for steps table creation
-- This will be automatically created by Hibernate due to spring.jpa.hibernate.ddl-auto=update

CREATE TABLE IF NOT EXISTS steps (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    device_id VARCHAR(255),
    step_count INTEGER NOT NULL CHECK (step_count >= 0),
    distance_m DOUBLE,
    calories_burned DOUBLE,
    recorded_at TIMESTAMP NOT NULL,
    recorded_date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_steps_user_recorded_date ON steps(user_id, recorded_date);
CREATE INDEX IF NOT EXISTS idx_steps_user_recorded_at ON steps(user_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_steps_device ON steps(device_id);
-- SQL script for step_data table creation (if needed)
-- This will be automatically created by Hibernate due to spring.jpa.hibernate.ddl-auto=update

CREATE TABLE IF NOT EXISTS step_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    step_count INTEGER NOT NULL,
    accelerometer_x DOUBLE,
    accelerometer_y DOUBLE,
    accelerometer_z DOUBLE,
    magnitude DOUBLE,
    confidence_score DOUBLE,
    is_valid_step BOOLEAN DEFAULT TRUE,
    timestamp TIMESTAMP NOT NULL,
    device_orientation VARCHAR(50),
    activity_type VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_step_data_user_timestamp ON step_data(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_step_data_valid_steps ON step_data(user_id, is_valid_step, timestamp);
CREATE INDEX IF NOT EXISTS idx_step_data_confidence ON step_data(confidence_score);
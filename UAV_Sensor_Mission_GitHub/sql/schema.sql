CREATE DATABASE IF NOT EXISTS uav_farm
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE uav_farm;

CREATE TABLE IF NOT EXISTS sensor_nodes (
    sensor_id VARCHAR(20) PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE IF NOT EXISTS sensor_measurements (
    measurement_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sensor_id VARCHAR(20) NOT NULL,
    soil_moisture DECIMAL(6,2) NOT NULL,
    air_temperature DECIMAL(6,2) NOT NULL,
    air_humidity DECIMAL(6,2) NOT NULL,
    light_intensity DECIMAL(10,2) NOT NULL,
    ph_value DECIMAL(4,2) NOT NULL,
    water_level DECIMAL(6,2) NOT NULL,
    collected_at DATETIME NOT NULL,
    source VARCHAR(30) NOT NULL DEFAULT 'UAV_GATEWAY',
    CONSTRAINT fk_measurement_sensor
        FOREIGN KEY (sensor_id) REFERENCES sensor_nodes(sensor_id)
);

CREATE TABLE IF NOT EXISTS uav_gateways (
    gateway_id VARCHAR(20) PRIMARY KEY,
    uav_name VARCHAR(100) NOT NULL,
    battery DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE'
);

CREATE TABLE IF NOT EXISTS missions (
    mission_id VARCHAR(20) PRIMARY KEY,
    mission_name VARCHAR(150) NOT NULL,
    gateway_id VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'READY',
    start_time DATETIME NULL,
    end_time DATETIME NULL,
    CONSTRAINT fk_mission_gateway
        FOREIGN KEY (gateway_id) REFERENCES uav_gateways(gateway_id)
);

CREATE TABLE IF NOT EXISTS waypoints (
    waypoint_id VARCHAR(20) PRIMARY KEY,
    mission_id VARCHAR(20) NOT NULL,
    sequence_no INT NOT NULL,
    sensor_id VARCHAR(20) NOT NULL,
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    altitude DECIMAL(8,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'WAITING',
    UNIQUE KEY uq_mission_sequence (mission_id, sequence_no),
    CONSTRAINT fk_waypoint_mission
        FOREIGN KEY (mission_id) REFERENCES missions(mission_id),
    CONSTRAINT fk_waypoint_sensor
        FOREIGN KEY (sensor_id) REFERENCES sensor_nodes(sensor_id)
);

CREATE TABLE IF NOT EXISTS mission_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    mission_id VARCHAR(20) NOT NULL,
    waypoint_id VARCHAR(20) NULL,
    message VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_mission
        FOREIGN KEY (mission_id) REFERENCES missions(mission_id),
    CONSTRAINT fk_log_waypoint
        FOREIGN KEY (waypoint_id) REFERENCES waypoints(waypoint_id)
);

INSERT INTO sensor_nodes(sensor_id, zone_name, status)
VALUES
('S001', 'Zone A', 'ACTIVE'),
('S002', 'Zone A', 'ACTIVE'),
('S003', 'Zone B', 'ACTIVE')
ON DUPLICATE KEY UPDATE
zone_name = VALUES(zone_name),
status = VALUES(status);

INSERT INTO uav_gateways(gateway_id, uav_name, battery, status)
VALUES ('GW01', 'UAV-FARM-01', 100.00, 'AVAILABLE')
ON DUPLICATE KEY UPDATE
uav_name = VALUES(uav_name);

USE uav_farm;

-- Xem các bảng
SHOW TABLES;

-- Sensor Node
SELECT * FROM sensor_nodes;

-- Dữ liệu cảm biến
SELECT
    sensor_id,
    soil_moisture,
    air_temperature,
    air_humidity,
    light_intensity,
    ph_value,
    water_level,
    collected_at
FROM sensor_measurements
ORDER BY measurement_id DESC
LIMIT 10;

-- Mission
SELECT
    mission_id,
    mission_name,
    status,
    start_time,
    end_time
FROM missions;

-- Waypoint
SELECT
    waypoint_id,
    mission_id,
    sequence_no,
    sensor_id,
    status
FROM waypoints
ORDER BY sequence_no;

-- UAV Gateway
SELECT
    gateway_id,
    uav_name,
    battery,
    status
FROM uav_gateways;

-- Mission Log
SELECT
    log_id,
    mission_id,
    waypoint_id,
    message,
    created_at
FROM mission_logs
ORDER BY log_id DESC
LIMIT 15;
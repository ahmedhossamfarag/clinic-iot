-- Create Table routers
CREATE TABLE routers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    location_x FLOAT DEFAULT 0.0,
    location_y FLOAT DEFAULT 0.0
);

-- Create Table devices
CREATE TABLE devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    holder_name VARCHAR(255)
);

-- Create Table records
create table records (
    router_id UUID REFERENCES routers (id),
    device_id UUID REFERENCES devices (id),
    timestamp timestamp DEFAULT NOW()
);

-- Create view latest_records that retreives the latest record for each device
CREATE OR REPLACE VIEW latest_records AS
SELECT DISTINCT ON (device_id) 
    device_id,
    router_id,
    timestamp
FROM
    records
ORDER BY
    device_id,
    timestamp DESC;

-- Create view routers_map that retreives the location and the number of devices connected to each router
CREATE OR REPLACE VIEW routers_map AS
SELECT
    routers.id,
    routers.location_x,
    routers.location_y,
    COUNT(latest_records.device_id) AS connected_devices_count
FROM
    routers
    LEFT JOIN latest_records ON routers.id = latest_records.router_id
GROUP BY
    routers.id;

-- Create view routers_devices that retreives the devices connected to each router
-- CREATE OR REPLACE VIEW routers_devices AS
-- SELECT
--     routers.id,
--     routers.name,
--     routers.location_x,
--     routers.location_y,
--     json_agg(row_to_json(devices)) AS connected_devices
-- FROM
--     routers
--     JOIN latest_records ON routers.id = latest_records.router_id
--     JOIN devices ON devices.id = latest_records.device_id
-- GROUP BY
--     routers.id;

-- Create view devices_routers that retreives the router connected to each device
-- CREATE OR REPLACE VIEW devices_routers AS
-- SELECT
--     devices.id,
--     devices.name,
--     devices.holder_name,
--     latest_records.timestamp,
--     json_build_object('id', routers.id, 'name', routers.name) AS connected_router
-- FROM
--     devices
--     JOIN latest_records ON devices.id = latest_records.device_id
--     JOIN routers ON routers.id = latest_records.router_id;
CREATE OR REPLACE VIEW devices_routers AS
SELECT
    devices.id,
    devices.name,
    devices.holder_name,
    latest_records.timestamp as last_record_timestamp,
    routers.id AS router_id,
    routers.name AS router_name
FROM
    devices
    JOIN latest_records ON devices.id = latest_records.device_id
    JOIN routers ON routers.id = latest_records.router_id;

-- Create view hourly_records that retreives the number of records for each hour
CREATE OR REPLACE VIEW hourly_records AS
SELECT
    date_trunc('hour', timestamp) AS hour,
    COUNT(*) AS records_count
FROM
    records
GROUP BY
    hour
ORDER BY
    hour;

-- Create view hourly_devices that retreives the number of devices for each hour
CREATE OR REPLACE VIEW hourly_devices AS
SELECT
    date_trunc('hour', timestamp) AS hour,
    COUNT(DISTINCT device_id) AS devices_count
FROM
    records
GROUP BY
    hour
ORDER BY
    hour;

-- Create view devices_routers_sessions that retreives the session duration for each device at each router
CREATE OR REPLACE VIEW devices_routers_sessions AS
SELECT
    device_id,
    router_id,
    MIN(timestamp) AS start_time,
    MAX(timestamp) - MIN(timestamp) AS duration
FROM
    records
GROUP BY
    device_id, router_id
ORDER BY
    start_time;

-- Create view routers_hourly_sessions that retreives the average session duration for each router at different hours
CREATE OR REPLACE VIEW routers_hourly_sessions AS
SELECT
    router_id,
    date_trunc('hour', start_time) AS hour,
    COUNT(*) AS sessions_count,
    AVG(duration) AS average_session_duration
FROM
    devices_routers_sessions
GROUP BY
    router_id, hour
ORDER BY
    hour;

-- Create view devices_sessions that retrieves the total session duration for each device
CREATE OR REPLACE VIEW devices_sessions AS
SELECT
    device_id,
    MIN(start_time) AS earliest_start_time,
    SUM(duration) AS total_duration
FROM
    devices_routers_sessions
GROUP BY
    device_id
ORDER BY
    earliest_start_time;

-- Create view devices_hourly_sessions that retreives the average total session duration for devices at different hours
CREATE OR REPLACE VIEW devices_hourly_sessions AS
SELECT
    date_trunc('hour', earliest_start_time) AS hour,
    AVG(total_duration) AS average_total_session_duration
FROM
    devices_sessions
GROUP BY
    hour
ORDER BY
    hour;



CREATE SCHEMA IF NOT EXISTS "DINASORE"; 
SET SEARCH_PATH TO "DINASORE";




CREATE TABLE IF NOT EXISTS PRODUCTION_LINE (
    production_line_id SERIAL PRIMARY KEY,
    "type" VARCHAR(50) NOT NULL
);


CREATE TABLE IF NOT EXISTS STATION (
    station_id SERIAL PRIMARY KEY,
    "type" VARCHAR(50) NOT NULL,
    "state" VARCHAR(50) NOT NULL,
    production_line_id INT NOT NULL,
    CONSTRAINT fk_production_line FOREIGN KEY (production_line_id) 
        REFERENCES PRODUCTION_LINE(production_line_id)
);


CREATE TABLE IF NOT EXISTS ACTUATOR (
    actuator_id SERIAL PRIMARY KEY,
    "type" VARCHAR(50) NOT NULL,
    "state" VARCHAR(50) NOT NULL
);


CREATE TABLE IF NOT EXISTS SENSOR (
    sensor_id SERIAL PRIMARY KEY,
    "type" VARCHAR(50) NOT NULL,
    iso_units VARCHAR(20) NOT NULL,
    normal_values FLOAT[], 
    abnormal_values FLOAT[],
    station_id INT NOT NULL,
    actuator_id INT, -- Referência opcional (#)
    CONSTRAINT fk_station FOREIGN KEY (station_id) 
        REFERENCES STATION(station_id),
    CONSTRAINT fk_actuator FOREIGN KEY (actuator_id) 
        REFERENCES ACTUATOR(actuator_id)
);


CREATE TABLE IF NOT EXISTS HISTORICAL_PRODUCTION (
    production_id SERIAL PRIMARY KEY,
    "date" TIMESTAMP NOT NULL,
    "value" FLOAT NOT NULL,
    "label" VARCHAR(100),
    sensor_id INT NOT NULL,
    CONSTRAINT fk_sensor FOREIGN KEY (sensor_id) 
        REFERENCES SENSOR(sensor_id)
);


CREATE TABLE IF NOT EXISTS RULE (
    rule_id SERIAL PRIMARY KEY,
    threshold FLOAT NOT NULL,
    station_id INT NOT NULL,
    CONSTRAINT fk_station_rule FOREIGN KEY (station_id) 
        REFERENCES STATION(station_id)
);

--- ====================================================================
--- US-5: Database triggers to flag values exceeding historical norms
--- ====================================================================

--- 1. Create a table to store anomaly logs
CREATE TABLE IF NOT EXISTS "DINASORE".ANOMALY_ALERTS (
    alert_id SERIAL PRIMARY KEY,
    production_id INT,
    sensor_id INT,
    detected_value FLOAT,
    avg_historical_value FLOAT,
    alert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_production_alert FOREIGN KEY (production_id) REFERENCES "DINASORE".HISTORICAL_PRODUCTION(production_id)
);

--- 2. Function to calculate if the value deviates from the norm (Mean + 3*Standard Deviation)
CREATE OR REPLACE FUNCTION "DINASORE".fn_check_historical_norms()
RETURNS TRIGGER AS $$
DECLARE
    avg_val FLOAT;
    std_dev_val FLOAT;
BEGIN
    -- Fetch statistics for the specific sensor (EXCLUDING the value currently being inserted)
    SELECT AVG("value"), STDDEV("value")
    INTO avg_val, std_dev_val
    FROM "DINASORE".HISTORICAL_PRODUCTION
    WHERE sensor_id = NEW.sensor_id AND production_id != NEW.production_id;

    -- If there is sufficient data (std dev > 0) and the value is an anomaly (3-Sigma Rule)
    IF std_dev_val IS NOT NULL AND std_dev_val > 0 AND ABS(NEW."value" - avg_val) > (3 * std_dev_val) THEN
        INSERT INTO "DINASORE".ANOMALY_ALERTS (production_id, sensor_id, detected_value, avg_historical_value)
        VALUES (NEW.production_id, NEW.sensor_id, NEW."value", avg_val);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--- 3. Activate the Trigger on the production table
CREATE OR REPLACE TRIGGER trg_validate_production_value
AFTER INSERT ON "DINASORE".HISTORICAL_PRODUCTION
FOR EACH ROW
EXECUTE FUNCTION "DINASORE".fn_check_historical_norms();

--- ====================================================================
--- US-5: SQL View for Hourly Sensor Averages (Trend Analysis)
--- ====================================================================

CREATE OR REPLACE VIEW "DINASORE".vw_hourly_sensor_averages AS
SELECT 
    sensor_id,
    DATE_TRUNC('hour', "date") AS hour_bucket,
    ROUND(AVG("value")::numeric, 2) AS hourly_avg_value,
    MIN("value") AS hourly_min_value,
    MAX("value") AS hourly_max_value,
    COUNT("value") AS total_readings
FROM 
    "DINASORE".HISTORICAL_PRODUCTION
GROUP BY 
    sensor_id, 
    DATE_TRUNC('hour', "date");
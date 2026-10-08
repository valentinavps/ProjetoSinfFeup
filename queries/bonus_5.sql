SET search_path TO gearworks_lite;

-- ==========================================
-- 1 & 2. Query execution BEFORE the index
-- ==========================================
EXPLAIN (ANALYZE)
SELECT * FROM machine_telemetry
WHERE machine_id = 1 
  AND sensor_code = 'TEMP_SPINDLE'
  AND ts >= '2026-03-01 00:00:00+00' 
  AND ts < '2026-03-02 00:00:00+00';

-- ==========================================
-- 3. Create an optimized composite index
-- ==========================================
-- Criamos um índice B-Tree compósito na exata ordem dos filtros do WHERE.
CREATE INDEX ix_telemetry_machine_sensor_time 
ON machine_telemetry(machine_id, sensor_code, ts);

-- ==========================================
-- 4. Query execution AFTER the index
-- ==========================================
EXPLAIN (ANALYZE)
SELECT * FROM machine_telemetry
WHERE machine_id = 1 
  AND sensor_code = 'TEMP_SPINDLE'
  AND ts >= '2026-03-01 00:00:00+00' 
  AND ts < '2026-03-02 00:00:00+00';
-- B1. Downtime analysis

WITH StateChanges AS (
    SELECT 
        machine_id,
        state_code,
        ts AS start_ts,
        LEAD(ts) OVER (PARTITION BY machine_id ORDER BY ts) AS end_ts
    FROM machine_state_log
), 
Downtime AS(
SELECT 
machine_id,
        start_ts::date AS event_date,
EXTRACT(EPOCH FROM (end_ts - start_ts)) / 60 AS duration_minutes
    FROM StateChanges
   WHERE state_code = 'DOWN' AND end_ts IS NOT NULL 
) 
SELECT 
   machine_id,
    event_date,
    SUM(duration_minutes) AS total_downtime_minutes 
FROM Downtime
GROUP BY machine_id, event_date
ORDER BY event_date , machine_id ;


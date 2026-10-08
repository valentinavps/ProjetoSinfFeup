-- B3. Daily performance dashboard
WITH StateChanges AS (
    SELECT 
        machine_id,
        state_code,
        ts AS start_ts,
        LEAD(ts) OVER (PARTITION BY machine_id ORDER BY ts) AS end_ts
    FROM machine_state_log
), 
DowntimeDaily AS (
    SELECT 
        machine_id,
        start_ts::date AS event_date,
        SUM(EXTRACT(EPOCH FROM (end_ts - start_ts)) / 60) AS total_downtime_minutes
    FROM StateChanges
    WHERE state_code = 'DOWN' AND end_ts IS NOT NULL
    GROUP BY machine_id, start_ts::date
),
ProductionDaily AS (
    SELECT 
        machine_id,
        start_ts::date AS prod_date,
        SUM(produced_qty - scrap_qty) AS total_good_qty
    FROM production_run
    GROUP BY machine_id, start_ts::date
)
SELECT 
    m.asset_tag,
    p.prod_date AS day,
    COALESCE(d.total_downtime_minutes, 0) AS downtime_mins,
    p.total_good_qty
FROM ProductionDaily p
JOIN machine m ON p.machine_id = m.machine_id
LEFT JOIN DowntimeDaily d ON p.machine_id = d.machine_id AND p.prod_date = d.event_date
ORDER BY day DESC, asset_tag;
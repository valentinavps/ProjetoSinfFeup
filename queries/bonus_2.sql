-- B2. Rolling averages

SELECT 
    machine_id,
    ts,
    value,
    AVG(value) OVER (
        PARTITION BY machine_id
        ORDER BY ts
        RANGE BETWEEN INTERVAL '1 hour' PRECEDING AND CURRENT ROW
    ) AS rolling_avg_temp
FROM machine_telemetry
WHERE sensor_code = 'TEMP_SPINDLE'
ORDER BY machine_id, ts;
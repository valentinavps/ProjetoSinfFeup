-- 6. Grinder Production Runs

SELECT 
    pr.run_id, 
    pr.machine_id, 
    pr.produced_qty, 
    pr.start_ts, 
    pr.end_ts
FROM production_run pr
JOIN machine m ON pr.machine_id = m.machine_id
WHERE m.machine_type = 'GRINDER';

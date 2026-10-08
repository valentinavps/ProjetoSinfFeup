-- 15. Production Runs per Line

SET search_path TO gearworks_lite;

SELECT 
    pl.line_name, 
    COUNT(pr.run_id) AS total_runs
FROM production_line pl
JOIN machine m ON pl.line_id = m.line_id
JOIN production_run pr ON m.machine_id = pr.machine_id
GROUP BY pl.line_name;
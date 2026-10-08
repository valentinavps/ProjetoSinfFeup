-- 10. Runs on a Specific Machine
SET search_path TO gearworks_lite;

SELECT COUNT(pr.run_id) AS run_count 
FROM production_run pr
JOIN machine m ON pr.machine_id = m.machine_id
WHERE m.asset_tag = 'M-PortoPlant-Line-01-01';
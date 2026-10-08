-- 20. Top‑Producing Machine
SET search_path TO gearworks_lite;

SELECT 
    m.asset_tag, 
    SUM(pr.produced_qty) AS total_produced_qty
FROM production_run pr
JOIN machine m ON pr.machine_id = m.machine_id
GROUP BY m.asset_tag
ORDER BY total_produced_qty DESC
LIMIT 1;
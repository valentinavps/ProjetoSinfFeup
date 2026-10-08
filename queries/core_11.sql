-- 11. Run Count per Machine

SELECT
asset_tag,
COUNT(pr.run_id)
FROM machine m
LEFT JOIN production_run pr on m.machine_id = pr.machine_id
GROUP BY m.asset_tag;

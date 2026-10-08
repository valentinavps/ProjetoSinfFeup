/* 
 * 9. Weekly Production Summary (Week 9, 2026)
 */
SELECT
    COUNT(run_id) AS total_production_runs,
    SUM(produced_qty) AS total_produced_quantity
FROM gearworks_lite.production_run
WHERE EXTRACT(ISOYEAR FROM start_ts) = 2026
  AND EXTRACT(WEEK FROM start_ts) = 9;
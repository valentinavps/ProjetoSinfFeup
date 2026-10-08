/* 
 * 19. Top-Producing Operator (2026)
 */
SELECT
    o.operator_id,
    o.first_name,
    o.last_name,
    SUM(pr.produced_qty) AS total_quantity_produced
FROM gearworks_lite.production_run pr
JOIN gearworks_lite.operator o ON pr.operator_id = o.operator_id
WHERE EXTRACT(YEAR FROM pr.start_ts) = 2026
GROUP BY o.operator_id, o.first_name, o.last_name
ORDER BY total_quantity_produced DESC
LIMIT 1;
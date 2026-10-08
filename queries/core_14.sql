/* 
 * 14. Run Count per Product
 */
SELECT
    p.product_code,
    COUNT(pr.run_id) AS run_count
FROM gearworks_lite.production_run pr
JOIN gearworks_lite.work_order wo ON pr.work_order_id = wo.work_order_id
JOIN gearworks_lite.product p ON wo.product_id = p.product_id
GROUP BY p.product_code
ORDER BY p.product_code;
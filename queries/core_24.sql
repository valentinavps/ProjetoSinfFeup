/* 
 * 24. Most Frequent Defect Type
 */
SELECT
    dt.code AS defect_code,
    dt.description AS defect_description,
    SUM(d.quantity) AS total_defect_quantity
FROM gearworks_lite.defect d
JOIN gearworks_lite.defect_type dt ON d.defect_type_id = dt.defect_type_id
GROUP BY dt.code, dt.description
ORDER BY total_defect_quantity DESC
LIMIT 1;
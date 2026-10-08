/*
 * B4. Quality hotspot detection
 */

WITH InspectionDefects AS (
    SELECT 
        inspection_id, 
        SUM(quantity) AS total_defect_qty
    FROM gearworks_lite.defect
    GROUP BY inspection_id
),
DailyStats AS (
    SELECT
        p.product_code,
        ie.inspected_ts::date AS inspection_day,
        SUM(ie.sample_size) AS total_inspected_parts,
        COALESCE(SUM(id.total_defect_qty), 0) AS total_defects,
        CAST(COALESCE(SUM(id.total_defect_qty), 0) AS NUMERIC) / SUM(ie.sample_size) AS defect_rate
    FROM gearworks_lite.inspection_event ie
    JOIN gearworks_lite.production_run pr ON ie.run_id = pr.run_id
    JOIN gearworks_lite.work_order wo ON pr.work_order_id = wo.work_order_id
    JOIN gearworks_lite.product p ON wo.product_id = p.product_id
    LEFT JOIN InspectionDefects id ON ie.inspection_id = id.inspection_id
    GROUP BY p.product_code, ie.inspected_ts::date
),
RankedDays AS (
    SELECT
        product_code,
        inspection_day,
        total_inspected_parts,
        total_defects,
        defect_rate,
        ROW_NUMBER() OVER (PARTITION BY product_code ORDER BY defect_rate DESC, inspection_day DESC) as ranking
    FROM DailyStats
    WHERE total_inspected_parts > 0
)
SELECT
    product_code,
    inspection_day AS worst_quality_day,
    total_inspected_parts,
    total_defects,
    ROUND(defect_rate, 4) AS highest_defect_rate
FROM RankedDays
WHERE ranking = 1;
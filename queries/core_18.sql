-- 18. Total Production per Operator

SELECT 
    first_name || ' ' || last_name AS operator_name, 
    SUM(produced_qty) AS total_produced
FROM 
    production_run
JOIN 
    operator ON production_run.operator_id = operator.operator_id
GROUP BY 
    operator.operator_id, first_name, last_name
ORDER BY 
    total_produced DESC;
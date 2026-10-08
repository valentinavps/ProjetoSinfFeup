-- 7. Production Runs per Operator

SELECT o.first_name || ' ' || o.last_name AS operator_full_name, pr.run_id
FROM operator o JOIN
production_run pr ON pr.operator_id=o.operator_id;
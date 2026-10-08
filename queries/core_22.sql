-- 22. Inspections per Inspector

SELECT o.operator_id, COUNT(ie.inspection_id) AS i_per_i
FROM operator o
JOIN inspection_event ie ON ie.inspector_id = o.operator_id
WHERE o.role='INSPECTOR'
GROUP BY o.operator_id;
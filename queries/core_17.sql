-- 17. Inspections per Production Run

SELECT pr.run_id, COUNT(ie.inspection_id) AS ie_per_run
FROM production_run pr 
LEFT JOIN inspection_event ie ON pr.run_id=ie.run_id
GROUP BY pr.run_id;

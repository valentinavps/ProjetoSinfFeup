-- 21. Top‑Producing Product

SELECT 
    p.product_code,
    wo.product_id, 
    SUM(pr.produced_qty) AS total_qty
FROM production_run pr
JOIN work_order wo ON pr.work_order_id = wo.work_order_id
JOIN product p ON wo.product_id = p.product_id
GROUP BY wo.product_id, p.product_code  
ORDER BY total_qty DESC
LIMIT 1;

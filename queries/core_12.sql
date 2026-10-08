-- 12. Production Runs with Product Code

SELECT p.product_code,pr.run_id
FROM product p
JOIN work_order wo ON wo.product_id = p.product_id
JOIN production_run pr ON pr.work_order_id=wo.work_order_id;
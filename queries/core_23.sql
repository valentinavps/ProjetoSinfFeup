-- 23. Scrap Quantity per Product

SELECT 
    product_code, 
    SUM(scrap_qty) AS total_scrap
FROM production_run
JOIN work_order ON production_run.work_order_id = work_order.work_order_id
JOIN product ON work_order.product_id = product.product_id
GROUP BY product_code
ORDER BY total_scrap DESC;
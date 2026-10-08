SELECT 
    produced_qty, 
    scrap_qty, 
    product_code, 
    first_name || ' ' || last_name AS operator_name
FROM production_run
JOIN operator ON production_run.operator_id = operator.operator_id
JOIN work_order ON production_run.work_order_id = work_order.work_order_id
JOIN product ON work_order.product_id = product.product_id;
SELECT
    order_id,
    customer_id,
    order_date,
    status
FROM orders
WHERE status = 'completed'

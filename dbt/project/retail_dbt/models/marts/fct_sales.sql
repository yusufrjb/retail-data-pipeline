{{ config(
    materialized='incremental',
    unique_key='order_item_id'
) }}

SELECT
    oi.order_item_id,
    o.order_id,
    o.customer_id,
    oi.product_id,
    o.order_date::date AS sales_date,
    oi.quantity,
    oi.unit_price,
    oi.total_sales
FROM {{ ref('stg_orders') }} o
JOIN {{ ref('stg_order_items') }} oi
    ON o.order_id = oi.order_id

{% if is_incremental() %}
WHERE oi.order_item_id > (
    SELECT COALESCE(MAX(order_item_id), 0)
    FROM {{ this }}
)
{% endif %}

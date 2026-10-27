-- Monthly sales from completed (delivered) orders.
-- Grain: one row per purchase month.
-- Revenue is item price only; freight is shown separately.
-- Aggregate items to one row per order before joining to orders.

WITH item_totals_by_order AS (
    SELECT
        order_id,
        SUM(price) AS product_revenue,
        SUM(freight_value) AS freight_value,
        COUNT(*) AS item_count
    FROM olist_raw.order_items
    GROUP BY order_id
)
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS purchase_month,
    COUNT(*) AS delivered_orders,
    SUM(i.product_revenue) AS product_revenue,
    SUM(i.freight_value) AS freight_value,
    ROUND(SUM(i.product_revenue) / COUNT(*)::NUMERIC, 2) AS avg_product_order_value,
    SUM(i.item_count) AS items_sold
FROM olist_raw.orders AS o
JOIN item_totals_by_order AS i
    ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
ORDER BY purchase_month;

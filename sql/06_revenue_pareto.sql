-- Customer revenue concentration (Pareto curve) using delivered orders.
-- Grain: one row per customer_unique_id with at least one delivered order.
-- Monetary value is item price only; freight is excluded.

WITH item_totals_by_order AS (
    SELECT
        order_id,
        SUM(price) AS product_revenue
    FROM olist_raw.order_items
    GROUP BY order_id
),
customer_revenue AS (
    SELECT
        c.customer_unique_id,
        SUM(i.product_revenue) AS product_revenue
    FROM olist_raw.orders AS o
    JOIN olist_raw.customers AS c
        ON c.customer_id = o.customer_id
    JOIN item_totals_by_order AS i
        ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
),
ranked_customers AS (
    SELECT
        customer_unique_id,
        product_revenue,
        ROW_NUMBER() OVER (
            ORDER BY product_revenue DESC, customer_unique_id
        ) AS customer_rank,
        COUNT(*) OVER () AS customer_count,
        SUM(product_revenue) OVER () AS total_product_revenue,
        SUM(product_revenue) OVER (
            ORDER BY product_revenue DESC, customer_unique_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_product_revenue
    FROM customer_revenue
)
SELECT
    customer_unique_id,
    customer_rank,
    ROUND(product_revenue, 2) AS product_revenue,
    ROUND(100.0 * customer_rank / customer_count, 2) AS cumulative_customer_share_pct,
    ROUND(100.0 * cumulative_product_revenue / total_product_revenue, 2)
        AS cumulative_revenue_share_pct
FROM ranked_customers
ORDER BY customer_rank;

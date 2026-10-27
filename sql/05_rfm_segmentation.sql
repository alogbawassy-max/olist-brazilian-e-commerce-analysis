-- Customer RFM segmentation using delivered orders.
-- Customer identity: customer_unique_id.
-- Monetary value is item price only; freight is excluded.
-- Recency anchor: one day after the latest purchase timestamp in the orders table.
-- R and M use tie-preserving percentile bands; F uses business bands because
-- the customer base is heavily concentrated in one-time buyers.

WITH data_cutoff AS (
    SELECT MAX(order_purchase_timestamp)::DATE + 1 AS as_of_date
    FROM olist_raw.orders
),
item_totals_by_order AS (
    SELECT
        order_id,
        SUM(price) AS product_revenue
    FROM olist_raw.order_items
    GROUP BY order_id
),
customer_metrics AS (
    SELECT
        c.customer_unique_id,
        (dc.as_of_date - MAX(o.order_purchase_timestamp)::DATE) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency_orders,
        SUM(i.product_revenue) AS monetary_value
    FROM olist_raw.orders AS o
    JOIN olist_raw.customers AS c
        ON c.customer_id = o.customer_id
    JOIN item_totals_by_order AS i
        ON i.order_id = o.order_id
    CROSS JOIN data_cutoff AS dc
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id, dc.as_of_date
),
ranked_metrics AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency_orders,
        monetary_value,
        PERCENT_RANK() OVER (ORDER BY recency_days ASC) AS recency_percent_rank,
        PERCENT_RANK() OVER (ORDER BY monetary_value ASC) AS monetary_percent_rank
    FROM customer_metrics
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency_orders,
        monetary_value,
        LEAST(5, FLOOR((1 - recency_percent_rank) * 5)::INTEGER + 1) AS r_score,
        CASE
            WHEN frequency_orders = 1 THEN 1
            WHEN frequency_orders = 2 THEN 3
            ELSE 5
        END AS f_score,
        LEAST(5, FLOOR(monetary_percent_rank * 5)::INTEGER + 1) AS m_score
    FROM ranked_metrics
)
SELECT
    customer_unique_id,
    recency_days,
    frequency_orders,
    ROUND(monetary_value, 2) AS monetary_value,
    r_score,
    f_score,
    m_score,
    r_score::TEXT || f_score::TEXT || m_score::TEXT AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score = 5 AND m_score >= 4 THEN 'High value'
        WHEN f_score >= 3 AND r_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score = 1 THEN 'Recent'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At risk'
        WHEN r_score <= 2 AND f_score = 1 THEN 'Needs attention'
        ELSE 'Regular'
    END AS customer_segment
FROM rfm_scores
ORDER BY monetary_value DESC, frequency_orders DESC;

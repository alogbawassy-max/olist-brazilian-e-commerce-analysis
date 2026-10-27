-- Monthly customer retention by first delivered-order month.
-- A retained customer has at least one delivered order in that calendar month.
-- Customer identity: customer_unique_id (not the order-level customer_id).

WITH customer_months AS (
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS purchase_month
    FROM olist_raw.orders AS o
    JOIN olist_raw.customers AS c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND c.customer_unique_id IS NOT NULL
),
customer_cohorts AS (
    SELECT
        customer_unique_id,
        MIN(purchase_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_unique_id
),
cohort_activity AS (
    SELECT
        cc.cohort_month,
        cm.purchase_month,
        ((EXTRACT(YEAR FROM cm.purchase_month) - EXTRACT(YEAR FROM cc.cohort_month)) * 12
          + EXTRACT(MONTH FROM cm.purchase_month) - EXTRACT(MONTH FROM cc.cohort_month))::INTEGER
            AS months_since_first_order,
        cm.customer_unique_id
    FROM customer_months AS cm
    JOIN customer_cohorts AS cc
        ON cc.customer_unique_id = cm.customer_unique_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_customers
    FROM customer_cohorts
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    ca.months_since_first_order,
    COUNT(DISTINCT ca.customer_unique_id) AS active_customers,
    cs.cohort_customers,
    ROUND(
        100.0 * COUNT(DISTINCT ca.customer_unique_id) / cs.cohort_customers,
        2
    ) AS retention_pct
FROM cohort_activity AS ca
JOIN cohort_sizes AS cs
    ON cs.cohort_month = ca.cohort_month
GROUP BY
    ca.cohort_month,
    ca.months_since_first_order,
    cs.cohort_customers
ORDER BY
    ca.cohort_month,
    ca.months_since_first_order;

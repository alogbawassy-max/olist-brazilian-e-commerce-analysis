-- Delivery delay and review-score association.
-- Grain before grouping: one row per delivered order with at least one review.
-- Multiple reviews per order are averaged before joining, avoiding row multiplication.
-- Delay is based on calendar dates: actual delivery date minus estimated date.

WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score::NUMERIC) AS average_review_score,
        COUNT(*) AS review_count
    FROM olist_raw.order_reviews
    WHERE review_score IS NOT NULL
    GROUP BY order_id
),
delivered_order_feedback AS (
    SELECT
        o.order_id,
        (o.order_delivered_customer_date::DATE - o.order_estimated_delivery_date::DATE)
            AS delay_days,
        r.average_review_score
    FROM olist_raw.orders AS o
    JOIN review_by_order AS r
        ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
delay_bands AS (
    SELECT
        order_id,
        delay_days,
        average_review_score,
        CASE
            WHEN delay_days <= 0 THEN 'On time or early'
            WHEN delay_days <= 3 THEN '1-3 days late'
            WHEN delay_days <= 7 THEN '4-7 days late'
            ELSE '8+ days late'
        END AS delivery_group,
        CASE WHEN average_review_score <= 2 THEN 1.0 ELSE 0.0 END AS low_score_flag
    FROM delivered_order_feedback
)
SELECT
    delivery_group,
    COUNT(*) AS orders,
    ROUND(AVG(delay_days), 2) AS average_delay_days,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(100.0 * AVG(low_score_flag), 2) AS low_review_pct
FROM delay_bands
GROUP BY delivery_group
ORDER BY
    CASE delivery_group
        WHEN 'On time or early' THEN 1
        WHEN '1-3 days late' THEN 2
        WHEN '4-7 days late' THEN 3
        ELSE 4
    END;

# Metric definitions

These definitions are used throughout the SQL analysis and Power BI report.

| Metric | Working definition |
|---|---|
| Product revenue | Sum of `order_items.price` for delivered orders; freight is reported separately. Values are shown in Brazilian reais (R$). |
| Freight value | Sum of `order_items.freight_value`. |
| Delivered order | An order with status `delivered`. Sales, cohort, and RFM queries use delivered orders; delivery/review analysis further requires usable delivery dates and a review. |
| Average order value | Product revenue divided by the count of included delivered orders. Monthly averages should be weighted by order count for an overall KPI. |
| Delivery delay days | Calendar date of actual customer delivery minus estimated delivery date; positive means late and negative means early. |
| Customer identity | `customer_unique_id` for repeat purchase and cohort analysis; `customer_id` is the order-level customer record key. |
| RFM analysis date | One day after the maximum purchase timestamp in the loaded dataset. |
| RFM scoring | Recency and monetary scores use tie-preserving percentile bands; frequency uses explicit bands: one delivered order = 1, two = 3, three or more = 5. This avoids splitting the many tied one-time buyers across quintiles. |

## Join grain rule

Orders, items, payments, and reviews can have different row counts per order. Aggregate each one-to-many table to the target grain before combining metrics. Otherwise a direct join can duplicate item revenue or payment values.

## Interpretation rule

Delivery delay and review-score comparisons describe association in the observed data. They do not prove that delays caused score changes.


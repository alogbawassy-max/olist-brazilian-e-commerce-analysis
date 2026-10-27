-- Run after importing the eight CSVs into the matching olist_raw tables.

-- Row counts
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM olist_raw.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM olist_raw.order_items
UNION ALL SELECT 'customers', COUNT(*) FROM olist_raw.customers
UNION ALL SELECT 'order_payments', COUNT(*) FROM olist_raw.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM olist_raw.order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM olist_raw.products
UNION ALL SELECT 'sellers', COUNT(*) FROM olist_raw.sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM olist_raw.category_translation
ORDER BY table_name;

-- Null or duplicate order IDs
SELECT COUNT(*) AS null_order_ids FROM olist_raw.orders WHERE order_id IS NULL;
SELECT order_id, COUNT(*) AS rows_per_id
FROM olist_raw.orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY rows_per_id DESC
LIMIT 20;

-- Basic date range and order status profile
SELECT MIN(order_purchase_timestamp) AS first_purchase,
       MAX(order_purchase_timestamp) AS last_purchase,
       COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS missing_purchase_dates
FROM olist_raw.orders;

SELECT order_status, COUNT(*) AS orders
FROM olist_raw.orders
GROUP BY order_status
ORDER BY orders DESC;

-- Foreign-key coverage checks. These report orphan rows without altering source data.
SELECT COUNT(*) AS items_without_order
FROM olist_raw.order_items i
LEFT JOIN olist_raw.orders o USING (order_id)
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orders_without_customer
FROM olist_raw.orders o
LEFT JOIN olist_raw.customers c USING (customer_id)
WHERE c.customer_id IS NULL;

-- Table grain / one-to-many checks: a nonzero count is expected for these tables.
SELECT order_id, COUNT(*) AS item_rows
FROM olist_raw.order_items
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY item_rows DESC
LIMIT 10;

SELECT order_id, COUNT(*) AS payment_rows
FROM olist_raw.order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_rows DESC
LIMIT 10;

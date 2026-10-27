# Power BI build guide

The report uses five CSV exports from the SQL result sets. This keeps the Power BI model simple and avoids a separate PostgreSQL connection.

## 1. Export the SQL results

Run each analysis query in `sql/` and save its result from pgAdmin's **Data Output → Save results to file** action. Keep column headers and use comma-delimited CSV. Save the files in `powerbi/exports/`:

- `monthly_sales.csv` from `sql/03_monthly_sales.sql`
- `cohort_retention.csv` from `sql/04_cohort_retention.sql`
- `rfm_segments.csv` from the corrected `sql/05_rfm_segmentation.sql`
- `revenue_pareto.csv` from `sql/06_revenue_pareto.sql`
- `delivery_review.csv` from `sql/07_delivery_review_analysis.sql`

Export one query result at a time. The result grid changes when another query runs. These exports are local input files and are ignored by Git.

## 2. Import and check data types

In Power BI Desktop, choose **Home → Get data → Text/CSV**, select an export, confirm the preview has headers and data rows, then load it. Repeat for all five files. These are analysis outputs at different grains; no relationships are required for the report pages.

Use these types:

- Month fields: Date
- `months_since_first_order`, R/F/M scores, frequency, counts and ranks: Whole Number
- Revenue, freight and monetary values: Decimal Number
- Customer IDs and `rfm_score`: Text
- `retention_pct`, `cumulative_customer_share_pct`, `cumulative_revenue_share_pct`, and `low_review_pct`: Decimal Number stored on a 0–100 scale in the CSV

The percentage exports use values such as `41.10` to mean 41.10%. Divide by 100 in a DAX measure before applying Power BI's Percentage format.

## 3. Add core measures

Copy the report measures from [`powerbi/measures.dax`](measures.dax) into Power BI Desktop one at a time. DAX files are reference text; Power BI does not import the file directly.

If Power BI imported a table with a different name, replace the table name in the formulas.

### Overview: weighted average order value

The monthly `avg_product_order_value` field should not be averaged across months because that gives each month equal weight. Use this measure instead:

```DAX
Weighted AOV =
DIVIDE(
    SUM(monthly_sales[product_revenue]),
    SUM(monthly_sales[delivered_orders])
)
```

### Cohort retention: correctly formatted cell value

```DAX
Retention % =
DIVIDE(AVERAGE(cohort_retention[retention_pct]), 100)
```

Format `Retention %` as Percentage. Use it in the matrix instead of the raw `retention_pct` column.

### Cohort retention: distinct cohort and customer totals

`cohort_customers` repeats on each cohort's month rows. Sum one value per cohort:

```DAX
Number of Cohorts =
DISTINCTCOUNT(cohort_retention[cohort_month])
```

```DAX
Total Cohort Customers =
SUMX(
    VALUES(cohort_retention[cohort_month]),
    CALCULATE(MAX(cohort_retention[cohort_customers]))
)
```

For Month 1 and Month 2 retention cards and the retention curve, use the measures in [`measures.dax`](measures.dax). They count zero-activity cells as zero and exclude cohorts whose given month is not observable by the latest delivered purchase month. Avoid averaging the sparse `retention_pct` rows directly, since that omits cohorts with no observed returns.

### RFM: customer measures

```DAX
Total Customers =
DISTINCTCOUNT(rfm_segments[customer_unique_id])
```

```DAX
Repeat Customers =
CALCULATE(
    [Total Customers],
    rfm_segments[frequency_orders] > 1
)
```

```DAX
Repeat Customer % =
DIVIDE([Repeat Customers], [Total Customers])
```

```DAX
High Value Customers =
CALCULATE(
    [Total Customers],
    rfm_segments[customer_segment] = "High value"
)
```

## 4. Build the report pages

### Overview

- KPI cards: delivered orders, product revenue, freight value, weighted AOV.
- Line chart: `purchase_month` by `product_revenue`; optionally include `freight_value` as a second series.
- Supporting visuals: monthly items sold, monthly AOV, freight as a share of product revenue, and delivered orders by month.
- Use a date slicer on `purchase_month`. The delivered-order analysis has activity from September 2016 through August 2018.
- Label order totals as **Delivered Orders**, since the monthly sales query filters to delivered orders.

### Cohort Retention

- KPI cards: number of cohorts, total cohort customers, Month 1 retention, and Month 2 retention.
- Matrix: rows `cohort_month`, columns `months_since_first_order`, values `Retention %`.
- Apply a sequential background color scale. Month 0 should read 100% by definition.
- Blank cells can indicate no recorded activity or an unobserved future period. The source output is sparse; a missing month number may have no activity rows.
- Optional line chart: `months_since_first_order` by the weighted `Retention Curve %` measure.

### RFM Customer Segmentation

- KPI cards: total customers, repeat-customer percentage, average product spend per customer, and average recency days.
- Bar charts: customer count and product revenue by `customer_segment`.
- Segment summary table: customer count/share, product revenue/share, average product spend, and average recency.
- Optional `customer_segment` slicer and a customer detail table with customer ID, segment, recency, frequency, monetary value, and RFM score.
- Use “product” in monetary metric labels because freight is excluded. Lower recency days means a more recent purchase.

### Delivery Performance

- KPI cards: orders analyzed, average review score, mean delivery difference, and low-review percentage.
- Compare `average_review_score` and `low_review_pct` by `delivery_group` using the SQL's intended order: on time or early, 1–3 days late, 4–7 days late, 8+ days late.
- Label the order count **Orders Analyzed**; this output includes 95,824 orders, excluding 654 delivered orders with a missing required review or date.
- Define low review as a score of 2 or below. Present the result as an association, not causation.

### Revenue Pareto Analysis

- KPI cards: total customers, total product revenue, top 20% revenue share, and top 1% revenue share.
- Line chart: `cumulative_customer_share_pct` on X and `cumulative_revenue_share_pct` on Y, sorted by `customer_rank` ascending.
- Optional decile bar chart for revenue share by customer decile.
- Format both curve axes as percentages. Add reference lines at 50% and 80% revenue if desired.

## 5. Finish and save

- Use a consistent 16:9 canvas, page titles, typography, and color palette.
- Format monetary measures as Brazilian reais (R$), and label product revenue and freight separately.
- Check that date axes sort chronologically and delivery groups sort in their intended order.
- Add a note to the Delivery page that the comparison is observational and excludes records with missing review or delivery-date information.
- Save as `powerbi/olist_ecommerce_report.pbix`.


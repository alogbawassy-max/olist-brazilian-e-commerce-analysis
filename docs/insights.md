# Initial findings

These findings are based on the delivered-order SQL outputs. Revenue means item price; freight is reported separately.

## Sales

- Delivered orders: 96,478.
- Product revenue: 13,221,498.11 in the dataset's currency.
- Freight value: 2,198,275.64 in the dataset's currency.
- November 2017 is the highest delivered-order purchase month in product revenue at 987,765.37.
- The delivered-order trend has activity from September 2016 through August 2018. Some months have no delivered orders and therefore do not appear in the grouped output.

## Cohort retention

- There are 23 first-delivered-order cohorts in the result.
- Every cohort has 100% retention in month zero, as expected by definition.
- The export only includes cohort-months with active customers. For a matrix, distinguish zero activity in an observed month from future months outside the data window.

## RFM segments

- The corrected export contains 93,358 customers with at least one delivered order.
- Frequency is strongly skewed: 90,557 customers have one delivered order, 2,573 have two, and 228 have three or more.
- The corrected scoring keeps equal frequency values together: one order = F1, two = F3, three or more = F5.
- Segment counts: Recent 36,345; Needs attention 36,094; Regular 18,118; Loyal 1,704; At risk 982; High value 115.
- RFM segment labels are working definitions based on the project score rules, not an externally validated customer taxonomy.

## Revenue concentration

- Top 1% of customers account for 11.47% of product revenue.
- Top 10% account for 41.10%; top 20% account for 56.62%; top 50% account for 83.31%.
- The Pareto output total matches the monthly sales product revenue total.

## Delivery and reviews

- The comparison covers 95,824 delivered orders with usable delivery dates and at least one review; 654 delivered orders are excluded because a required review or date is unavailable.
- On-time or early deliveries average 4.29 review points, with 9.23% low reviews (average order score <= 2).
- For orders 1-3 days late, the average score is 3.29 and the low-review rate is 32.18%.
- For orders 4-7 days late, the average score is 2.11 and the low-review rate is 67.56%.
- For orders 8+ days late, the average score is 1.70 and the low-review rate is 79.18%.
- This is an association in the observed data; it does not establish that delivery delay caused the review score.

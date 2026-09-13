/*
===============================================================================
Analytical Query: Daily Customer Acquisition & Cumulative Growth
===============================================================================
Purpose:
    - Identifies the acquisition date (first purchase date) for each unique customer.
    - Aggregates daily new customer cohort volumes (`new_customers_at_date`).
    - Calculates a running total (`new_customers_running_total`) to track cumulative 
      marketplace customer base expansion over time.
===============================================================================
*/


SELECT 
  acquisition_date,
  new_customers_at_date,
  LAG(new_customers_at_date) OVER(),
  new_customers_at_date / LAG(new_customers_at_date) OVER()
FROM (
WITH customer_first_orders AS (
  SELECT
    customer_id,
    MIN(order_purchase_timestamp::DATE) AS acquisition_date
  FROM gold.fact_sales
  WHERE order_purchase_timestamp IS NOT NULL
  GROUP BY customer_id
)
SELECT
  acquisition_date,
  COUNT(customer_id) AS new_customers_at_date,
  SUM(COUNT(customer_id)) OVER(ORDER BY acquisition_date) new_customers_running_total
FROM customer_first_orders
GROUP BY acquisition_date
ORDER BY acquisition_date ASC
)



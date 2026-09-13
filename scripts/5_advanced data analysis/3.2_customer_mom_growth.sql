WITH customer_first_orders AS (
  SELECT
    customer_id,
    MIN(order_purchase_timestamp::DATE) AS acquisition_date
  FROM gold.fact_sales
  WHERE order_purchase_timestamp IS NOT NULL
  GROUP BY customer_id
),
monthly_new_customers AS (
  SELECT
    DATE_TRUNC('month', acquisition_date)::DATE AS acquisition_month,
    COUNT(customer_id) AS new_customers
  FROM customer_first_orders
  GROUP BY DATE_TRUNC('month', acquisition_date)
)
SELECT
  acquisition_month,
  new_customers,
  LAG(new_customers) OVER (ORDER BY acquisition_month) AS prev_month_new_customers,
  ROUND(
    (new_customers::NUMERIC - LAG(new_customers) OVER (ORDER BY acquisition_month))
    / NULLIF(LAG(new_customers) OVER (ORDER BY acquisition_month), 0) * 100
  , 2) AS mom_growth_pct
FROM monthly_new_customers
WHERE acquisition_month > '2017-01-01'
ORDER BY acquisition_month;
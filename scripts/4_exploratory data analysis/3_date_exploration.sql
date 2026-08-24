-- Find the date of the first and the last order
-- How many months are available?
SELECT 
  MIN(order_purchase_timestamp) AS first_order_date,
  MAX(order_purchase_timestamp) AS last_order_date,
  EXTRACT(MONTH FROM AGE(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp))) AS order_range_months
FROM gold.fact_sales;

-- How are orders distributed by year?
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year_timestamp,
  COUNT(order_id) AS order_count
FROM gold.fact_sales
GROUP BY EXTRACT(YEAR FROM order_purchase_timestamp);

-- How are orders distributed by month?
SELECT 
  TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS year_month_date,
  COUNT(order_id) AS order_count
FROM gold.fact_sales
GROUP BY TO_CHAR(order_purchase_timestamp, 'YYYY-MM');

-- Top 3 months with highest orders
SELECT 
  TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS year_month_date,
  COUNT(order_id) AS order_count
FROM gold.fact_sales
GROUP BY TO_CHAR(order_purchase_timestamp, 'YYYY-MM')
ORDER BY COUNT(order_id) DESC
LIMIT 3;

-- Top 3 months with lowest orders
SELECT 
  TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS year_month_date,
  COUNT(order_id) AS order_count
FROM gold.fact_sales
GROUP BY TO_CHAR(order_purchase_timestamp, 'YYYY-MM')
ORDER BY COUNT(order_id) ASC
LIMIT 3;
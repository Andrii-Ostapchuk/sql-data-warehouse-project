/*
===============================================================================
Analytical Query: Daily & 30-Day Rolling Freight-to-Price Ratio
===============================================================================
Purpose:
    - Measures shipping cost burden relative to item prices over time.
    - Aggregates daily net product spend and freight spend to compute the daily ratio.
    - Applies a 30-day rolling window (`RANGE BETWEEN INTERVAL '29 days' PRECEDING`) 
      to smooth out daily volatility and highlight macro logistics trends.
===============================================================================
*/

WITH aggregated_dates AS (
  SELECT
  s.order_purchase_timestamp::DATE order_date,
  SUM(s.price)::NUMERIC AS price,
  SUM(s.freight_value)::NUMERIC AS freight_value,
  (SUM(s.freight_value) / NULLIF(SUM(price), 0))::NUMERIC AS freight_to_price,
  MODE() WITHIN GROUP (ORDER BY p.product_category_name) AS most_frequent_category
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p ON s.product_id = p.product_id
GROUP BY order_purchase_timestamp::DATE
)
SELECT 
  most_frequent_category,
  order_date,
  price,
  freight_value,
  ROUND(freight_to_price, 4) AS daily_freight_ratio,
  ROUND(AVG(freight_to_price) OVER(ORDER BY order_date RANGE BETWEEN INTERVAL '29 days' PRECEDING AND CURRENT ROW), 4) AS rolling_30d_avg_freight_ratio
FROM aggregated_dates
WHERE order_date BETWEEN '2017-02-01' AND '2018-08-31'





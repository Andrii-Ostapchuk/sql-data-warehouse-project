-- Finding Count of most frequent categories
SELECT 
  most_frequent_category,
  COUNT(*) AS orders_per_category
FROM (
  WITH aggregated_dates AS (
    SELECT
      s.order_purchase_timestamp::DATE AS order_date,
      SUM(s.price)::NUMERIC AS price,
      SUM(s.freight_value)::NUMERIC AS freight_value,
      (SUM(s.freight_value) / NULLIF(SUM(s.price), 0))::NUMERIC AS freight_to_price,
      MODE() WITHIN GROUP (ORDER BY p.product_category_name) AS most_frequent_category
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p ON s.product_id = p.product_id
    GROUP BY s.order_purchase_timestamp::DATE
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
    AND freight_to_price > 0.18
) sub
GROUP BY most_frequent_category
ORDER BY orders_per_category DESC
LIMIT 3;

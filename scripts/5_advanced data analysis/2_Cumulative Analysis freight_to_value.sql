CREATE OR REPLACE VIEW gold.freight_to_price_30d_rolling_avg AS (
  WITH aggregated_dates AS (
    SELECT
    order_purchase_timestamp::DATE order_date,
    SUM(price)::NUMERIC AS price,
    SUM(freight_value)::NUMERIC AS freight_value,
    (SUM(freight_value) / NULLIF(SUM(price), 0))::NUMERIC AS freight_to_price
  FROM gold.fact_sales
  GROUP BY order_purchase_timestamp::DATE
  )

  SELECT 
    order_date,
    price,
    freight_value,
    ROUND(freight_to_price, 4) AS daily_freight_ratio,
    ROUND(AVG(freight_to_price) OVER(ORDER BY order_date RANGE BETWEEN INTERVAL '29 days' PRECEDING AND CURRENT ROW), 4) AS rolling_30d_avg_freight_ratio
  FROM aggregated_dates
  WHERE order_date BETWEEN '2017-02-01' AND '2018-08-31'
);


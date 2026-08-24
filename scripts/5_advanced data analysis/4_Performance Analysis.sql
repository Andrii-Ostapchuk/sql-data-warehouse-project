WITH seller_monthly_revenue AS (
  SELECT 
    seller_id,
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS revenue_month,
    ROUND(SUM(total_item_value)::NUMERIC, 2) AS current_sales
  FROM gold.fact_sales
  GROUP BY seller_id, TO_CHAR(order_purchase_timestamp, 'YYYY-MM')
),

seller_performance AS (
  SELECT
    seller_id,
    revenue_month,
    current_sales,
    ROUND(AVG(current_sales) OVER(PARTITION BY seller_id), 2) AS avg_sales,
    ROUND(current_sales - AVG(current_sales) OVER(PARTITION BY seller_id), 2) diff_avg,
    ROUND(LAG(current_sales) OVER(PARTITION BY seller_id ORDER BY revenue_month), 2) pm_sales,
    ROUND(current_sales - LAG(current_sales) OVER(PARTITION BY seller_id ORDER BY revenue_month), 2) diff_pm
  FROM seller_monthly_revenue
)

SELECT
  seller_id,
  revenue_month,
  current_sales,
  avg_sales,
  diff_avg,
  pm_sales,
  diff_pm,
  CASE
    WHEN diff_pm IS NULL THEN 'Insufficient Data'
    WHEN diff_avg > 0 AND diff_pm > 0 THEN 'Growth Leader'
    WHEN diff_avg > 0 AND diff_pm <= 0 THEN 'Cooling Off'
    WHEN diff_avg <= 0 AND diff_pm > 0 THEN 'Recovering'
    WHEN diff_avg <= 0 AND diff_pm <= 0 THEN 'Underperforming'
  END AS seller_performance_status
FROM seller_performance;
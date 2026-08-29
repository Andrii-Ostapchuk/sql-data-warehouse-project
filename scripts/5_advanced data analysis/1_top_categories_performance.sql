/*
===============================================================================
Analytical Query: Top 5 Categories Month-over-Month (MoM) Performance
===============================================================================
Purpose:
    - Identifies the Top 5 product categories by total historical gross sales.
    - Constructs a dense continuous monthly timeline using a calendar grid to 
      prevent zero-sales periods from breaking time-series continuity.
    - Tracks monthly revenue trajectories and computes percentage Month-over-Month 
      (MoM) revenue growth for each leading category.
===============================================================================
*/

-- Analyze MoM performance of Rop 5 Categories with Most Sales
WITH top_5_categories AS (
  SELECT
    p.product_category_name,
    ROUND(SUM(s.total_item_value)) AS category_sales,
    ROW_NUMBER() OVER(ORDER BY SUM(s.total_item_value) DESC) AS category_rank
  FROM gold.dim_products p
  LEFT JOIN gold.fact_sales s
    ON s.product_id = p.product_id
  GROUP BY p.product_category_name
  ORDER BY SUM(s.total_item_value) DESC
  LIMIT 5
), 
all_months AS (
  SELECT GENERATE_SERIES(
    '2016-09-01'::DATE,
    '2018-08-01'::DATE,
    '1 month'::interval
  )::DATE AS order_month
),
category_month_grid AS (
  SELECT
    t.product_category_name,
    m.order_month
  FROM top_5_categories t
  CROSS JOIN all_months m
),
actual_sales AS (
  SELECT
    p.product_category_name,
    DATE_TRUNC('month', s.order_purchase_timestamp)::DATE AS order_month,
    ROUND(SUM(s.total_item_value)) AS total_revenue
  FROM gold.fact_sales s
  JOIN gold.dim_products p 
    ON s.product_id = p.product_id
  GROUP BY 1, 2
)
SELECT
  g.product_category_name,
  TO_CHAR(g.order_month, 'YYYY-MM') AS order_month,
  COALESCE(a.total_revenue, 0) AS total_revenue,
  ((a.total_revenue / LAG(a.total_revenue) OVER(PARTITION BY g.product_category_name) - 1) * 100) AS mom_growth
FROM category_month_grid g
LEFT JOIN actual_sales a
  ON g.product_category_name = a.product_category_name
  AND g.order_month = a.order_month
WHERE TO_CHAR(g.order_month, 'YYYY-MM') > '2017-01'
ORDER BY g.product_category_name, g.order_month;
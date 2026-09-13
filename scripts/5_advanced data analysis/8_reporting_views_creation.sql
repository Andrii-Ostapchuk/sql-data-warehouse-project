/*
===============================================================================
DDL Script: Reporting Layer Views Initialization
===============================================================================
Script Purpose:
    - Creates production-ready analytical views optimized for Power BI ingestion.
    - Encapsulates complex business logic, cohort analyses, and time-series metrics.
===============================================================================
*/

-- ============================================================================
-- 1. Top Categories Performance View
-- Purpose: Analyzes MoM gross revenue trajectories and growth rates for the 
--          top 5 revenue-generating product categories over a continuous timeline.
-- ============================================================================
CREATE OR REPLACE VIEW reporting.top_categories_performance AS (
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
  ORDER BY g.product_category_name, g.order_month
);


-- ============================================================================
-- 2. 30-Day Rolling Freight-to-Price Ratio View
-- Purpose: Tracks logistics cost burden by calculating the daily ratio of freight 
--          spend to item price alongside a smoothed 30-day moving average.
-- ============================================================================
CREATE OR REPLACE VIEW reporting.freight_to_price_30d_rolling_avg AS (
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


-- Finding Count of most frequent categories
CREATE OR REPLACE VIEW reporting.most_frequent_categories_freight_to_price_high AS (
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
  LIMIT 3
);


-- ============================================================================
-- 3. Customer Acquisition Rate View
-- Purpose: Measures daily marketplace customer acquisition velocity and tracks 
--          the running cumulative growth of unique customers over time.
-- ============================================================================
CREATE OR REPLACE VIEW reporting.customer_acquisition_rate AS (
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
);

CREATE OR REPLACE VIEW reporting.customer_acquisition_mom AS (
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
  ORDER BY acquisition_month
);

-- ============================================================================
-- 4. Seller Performance View
-- Purpose: Evaluates monthly seller revenue momentum against their lifetime baseline 
--          and previous month, classifying accounts into 4 operational health tiers.
-- ============================================================================
CREATE OR REPLACE VIEW reporting.seller_performance AS (
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
  FROM seller_performance
);


-- ============================================================================
-- 5. Payment Type per State Performance View
-- Purpose: Breaks down regional revenue by payment method to evaluate state-level 
--          payment preferences and relative payment type share percentages.
-- ============================================================================
CREATE OR REPLACE VIEW reporting.payment_type_per_state_performance AS (
  WITH payment_type_per_state_performance AS (
    SELECT 
      c.customer_state,
      p.payment_type,
      SUM(s.total_item_value)::NUMERIC AS combined_total_item_value
    FROM gold.fact_sales s
    LEFT JOIN gold.fact_payments p ON s.customer_id = p.customer_id
    LEFT JOIN gold.dim_customers c ON s.customer_id = c.customer_id
    GROUP BY 1, 2
  )

  SELECT
    customer_state,
    payment_type,
    ROUND(combined_total_item_value, 2) AS combined_total_item_value,
    ROUND(SUM(combined_total_item_value) OVER(PARTITION BY customer_state), 2) AS sales_per_state,
    ROUND((combined_total_item_value / SUM(combined_total_item_value) OVER(PARTITION BY customer_state)) * 100, 2) AS payment_type_proportion
  FROM payment_type_per_state_performance
  ORDER BY 1, 2
);

CREATE OR REPLACE VIEW reporting.orders_per_state_ratio AS (
  WITH all_orders AS (
    SELECT COUNT(DISTINCT order_id) AS all_orders
    FROM gold.fact_sales
  )

  SELECT 
    c.customer_state,
    ROUND((COUNT(DISTINCT s.order_id)::NUMERIC / ao.all_orders) * 100, 2) AS orders_per_state_percentage
  FROM gold.fact_sales s
  LEFT JOIN gold.dim_customers c ON s.customer_id = c.customer_id
  CROSS JOIN all_orders ao
  GROUP BY 1, ao.all_orders
  ORDER BY orders_per_state_percentage DESC
);

-- ============================================================================
-- 6. Seller Volume & Feedback Segmentation View
-- Purpose: Constructs a 2-axis operational matrix segmenting sellers across 
--          fulfillment capacity (Volume) and customer satisfaction (Rating).
-- ============================================================================
CREATE OR REPLACE VIEW reporting.seller_volume_feedback_segmentation AS (
  SELECT 
    s.seller_id,
    COUNT(s.order_id) AS orders_per_seller,
    CASE
      WHEN COUNT(s.order_id) > 200 THEN 'High Volume'
      WHEN COUNT(s.order_id) > 50 THEN 'Medium Volume'
      ELSE 'Low Volume'
    END AS volume_segmentation,
    ROUND(AVG(f.review_score), 2),
    CASE
      WHEN AVG(f.review_score) >= 4.0 THEN 'Excellent'
      WHEN AVG(f.review_score) >= 3.0 THEN 'Needs Improvement'
      ELSE 'Bad'
    END AS rating_segmentation
  FROM gold.fact_sales s 
  LEFT JOIN gold.fact_feedback f ON s.order_id = f.order_id
  GROUP BY s.seller_id
  ORDER BY COUNT(s.order_id) DESC
);


-- ============================================================================
-- 7. Customer 360 & RFM View
-- Purpose: Unified customer intelligence view combining dynamic RFM cohorting 
--          with granular lifetime KPIs (spend, delays, installments, cross-state).
-- ============================================================================
CREATE OR REPLACE VIEW reporting.customer_360 AS (
  WITH global_purchase_date_max AS (
    SELECT MAX(order_purchase_timestamp)::DATE AS max_date
    FROM gold.fact_sales
  ),

  -- 1. Pre-aggregate payments and feedback to the ORDER level to prevent fan-outs
  order_payments AS (
    SELECT order_id, AVG(payment_installments) AS avg_installments
    FROM gold.fact_payments
    GROUP BY order_id
  ),
  order_feedback AS (
    SELECT order_id, AVG(review_score) AS avg_score
    FROM gold.fact_feedback
    GROUP BY order_id
  ),

  -- 2. Base metrics (All Orders)
  customers_grouped AS (
    SELECT
      customer_id,
      COUNT(DISTINCT order_id) AS frequency_order_count,
      MAX(order_purchase_timestamp)::DATE AS last_order,
      SUM(total_item_value) AS monetary
    FROM gold.fact_sales
    GROUP BY customer_id
  ),

  -- 3. Lifetime metrics (Delivered Orders Only)
  lifetime_metrics AS (
    SELECT
      fs.customer_id,
      COUNT(DISTINCT fs.order_id) AS total_orders_completed,
      SUM(fs.price) AS total_net_product_value,
      SUM(fs.freight_value) AS total_freight_paid,
      SUM(fs.freight_value) / NULLIF(SUM(fs.price), 0) AS lifetime_freight_ratio,
      COUNT(DISTINCT dp.product_category_name) AS distinct_categories_purchased,
      AVG((fs.order_delivered_customer_date::DATE) - (fs.order_estimated_delivery_date::DATE)) AS avg_delivery_delay_days,
      CASE
        WHEN BOOL_OR(dc.customer_state != ds.seller_state) = TRUE THEN 'Yes'
        ELSE 'No'
      END AS is_cross_state_buyer
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products dp ON fs.product_id = dp.product_id
    LEFT JOIN gold.dim_customers dc ON fs.customer_id = dc.customer_id
    LEFT JOIN gold.dim_sellers ds ON fs.seller_id = ds.seller_id
    WHERE fs.order_status = 'delivered'
    GROUP BY fs.customer_id
  ),

  -- 4. Aggregate the pre-aggregated order metrics to the CUSTOMER level
  lifetime_pre_aggregated_metrics AS (
    SELECT 
      fs.customer_id,
      AVG(op.avg_installments) AS installment_dependency,
      AVG(ofb.avg_score) AS avg_satisfaction_score
    FROM (SELECT DISTINCT customer_id, order_id, order_status FROM gold.fact_sales) fs
    LEFT JOIN order_payments op ON fs.order_id = op.order_id
    LEFT JOIN order_feedback ofb ON fs.order_id = ofb.order_id
    WHERE fs.order_status = 'delivered'
    GROUP BY fs.customer_id
  ),

  customers_rfm AS (
    SELECT
      c.customer_id,
      (g.max_date - c.last_order)::INTEGER AS recency_days,
      c.frequency_order_count,
      ROUND(c.monetary::NUMERIC, 2) AS monetary,
      NTILE(5) OVER(ORDER BY g.max_date - c.last_order DESC) AS r_score,
      CASE 
        WHEN c.frequency_order_count >= 3 THEN 5
        WHEN c.frequency_order_count = 2 THEN 3
        ELSE 1
      END AS f_score,
      NTILE(5) OVER(ORDER BY monetary ASC) AS m_score
    FROM customers_grouped c
    CROSS JOIN global_purchase_date_max g
  )

  SELECT
    rfm.customer_id,
    rfm.recency_days,
    rfm.frequency_order_count,
    rfm.monetary,
    rfm.r_score,
    rfm.f_score,
    rfm.m_score,
    CASE
      -- The Elite: (Repeat buyers in Olist are rare; heavily prioritize them)
      WHEN f_score >= 3 AND r_score >= 3 AND m_score >= 3 THEN 'Champion'
      WHEN f_score >= 3 THEN 'Loyal Customer'
      
      -- High Spenders: (Restrict to top 20%, not 40%, to prevent category bloat)
      WHEN m_score = 5 THEN 'Cannot Lose Them'
      
      -- Recent Additions: (Capture top 40% of recency who haven't spent massive amounts yet)
      WHEN r_score >= 4 THEN 'Recent / New Customer'
      
      -- The Middle Class: (NEW - This absorbs the massive group currently falling into ELSE)
      WHEN r_score = 3 AND m_score >= 3 THEN 'Promising / Average'
      
      -- The True Bottom: (Bottom 40% recency AND bottom 40% monetary)
      WHEN r_score <= 2 AND m_score <= 2 THEN 'Lost / Hibernating'
      
      -- Old buyers with average or decent spend
      WHEN r_score <= 2 AND m_score >= 3 THEN 'At Risk'
      
      -- The Remnants: (Average recency (3), low spend (1,2). This becomes your TRUE trailing segment)
      ELSE 'General / Low Value'
    END AS rfm_segmentation,
    l.total_orders_completed,
    ROUND(l.total_net_product_value::NUMERIC, 2) AS total_net_product_value,
    ROUND(l.total_freight_paid::NUMERIC, 2) AS total_freight_paid,
    ROUND(l.lifetime_freight_ratio::NUMERIC, 4) AS lifetime_freight_ratio,
    l.distinct_categories_purchased,
    ROUND(l.avg_delivery_delay_days::NUMERIC) AS avg_delivery_delay_days,
    ROUND(lpg.installment_dependency::NUMERIC) AS installment_dependency,
    ROUND(lpg.avg_satisfaction_score::NUMERIC, 1) AS avg_satisfaction_score,
    l.is_cross_state_buyer
  FROM customers_rfm rfm
  LEFT JOIN lifetime_metrics l ON l.customer_id = rfm.customer_id
  LEFT JOIN lifetime_pre_aggregated_metrics lpg ON lpg.customer_id = rfm.customer_id
  ORDER BY r_score + f_score + m_score DESC
);
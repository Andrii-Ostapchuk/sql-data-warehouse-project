/*
======================================================================================
Advanced Customer 360 & RFM Cohort Report (Olist E-commerce)
======================================================================================
Purpose:
  - Generate a comprehensive, materialized view of true customer lifetime behavior.

Requirements:

1. Advanced RFM Segmentation (Dynamic):
   - Calculate Recency (days since last delivered order relative to the max date 
     in the dataset, not CURRENT_DATE).
   - Calculate Frequency (count of distinct `order_id`s).
   - Calculate Monetary (Total Gross Spend).
   - Assign customers an RFM Segment ('Champions', 'At Risk', 'Lost', etc.) using 
     NTILE(5) window functions across the three vectors.

2. Granular Aggregations (Lifetime):
   - `total_orders_completed`
   - `total_net_product_value` (Price only)
   - `total_freight_paid`
   - `lifetime_freight_ratio` (Total Freight / Total Net Product Value)
   - `distinct_categories_purchased` (Breadth of their purchasing habits)

3. Olist-Specific KPIs & Behavior Vectors:
   - `avg_delivery_delay_days`: Average difference between 
     `order_delivered_customer_date` and `order_estimated_delivery_date`.
   - `installment_dependency`: Average number of `payment_installments` used 
     across all their orders.
   - `avg_satisfaction_score`: Average `review_score` given by this customer.
   - `is_cross_state_buyer`: Boolean flag (TRUE if they bought from a seller 
     located in a different state than their own).

customer_unique_id, recency, frequency, monetary, RFM_segment, total_orders_completed, 
total_net_product_value, total_freight_paid, lifetime_freight_ratio, distinct_categories_purchased, 
avg_delivery_delay_days, installment_dependency, avg_satisfaction_score, is_cross_state_buyer

======================================================================================
*/


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
    BOOL_OR(dc.customer_state != ds.seller_state) AS is_cross_state_buyer
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
      WHEN c.frequency_order_count >= 5 THEN 5
      WHEN c.frequency_order_count IN (3, 4) THEN 4
      WHEN c.frequency_order_count = 2 THEN 2
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
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
    WHEN f_score >= 4 AND m_score >= 3 THEN 'Loyal Customer'
    WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent / New Customer'
    WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
    WHEN r_score <= 2 AND m_score >= 3 THEN 'Cannot Lose Them'
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
ORDER BY r_score + f_score + m_score DESC;

/*Champions: Bought recently, buy often, and spend the most. Action: Reward them, offer early access to new products.

Loyal Customers: Buy on a regular basis and spend good money. Action: Upsell higher-value products, engage via loyalty programs.

At-Risk Customers: Used to buy often and spend a lot, but haven't purchased in a long time. Action: Send personalized reactivation campaigns, special discounts.

Can't Lose Them: Made huge purchases in the past but haven't returned recently. Action: Direct outreach, high-value win-back offers.

New Customers: Made their first purchase recently. Action: Onboarding flows, nurture campaigns to drive a second purchase.

Lost / Hibernating: Low recency, low frequency, low monetary value. Action: Ignore or put on low-cost automated email sweeps.*/


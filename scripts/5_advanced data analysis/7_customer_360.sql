/*
===============================================================================
Advanced Customer 360 & RFM Cohort Analysis (Olist E-commerce)
===============================================================================
Purpose:
    - Generates a unified Customer 360 analytical dataset and behavioral profile.
    - Implements custom RFM (Recency, Frequency, Monetary) segmentation tuned 
      specifically for marketplace dynamics (handling low repeat-purchase rates).
    - Tracks granular customer lifetime value (LTV), logistics friction (freight ratio, 
      delivery delay), payment preferences, and satisfaction metrics.

Evaluation Hierarchy & RFM Segments:
    1. Champion:               Top recency, frequency, and spend (elite marketplace users).
    2. Loyal Customer:          Repeat buyers with multiple completed transactions.
    3. Cannot Lose Them:        Top 20% spenders (M=5) who have stopped buying recently.
    4. Recent / New Customer:   High recency (top 40%) first-time/moderate buyers.
    5. Promising / Average:     Mid-tier recency with above-average spend.
    6. Lost / Hibernating:      Low recency and low monetary spend (churned long-tail).
    7. At Risk:                 Low recency with historical mid-to-high spend.
    8. General / Low Value:     Remaining baseline/trailing single-order buyers.
===============================================================================
*/

-- 1. Anchor date: Get the latest order timestamp in the dataset to calculate recency
WITH global_purchase_date_max AS (
  SELECT MAX(order_purchase_timestamp)::DATE AS max_date
  FROM gold.fact_sales
),

-- 2. Pre-aggregate order payments to the order grain to prevent fan-out in joins
order_payments AS (
  SELECT order_id, AVG(payment_installments) AS avg_installments
  FROM gold.fact_payments
  GROUP BY order_id
),

-- 3. Pre-aggregate customer feedback to the order grain to prevent fan-out in joins
order_feedback AS (
  SELECT order_id, AVG(review_score) AS avg_score
  FROM gold.fact_feedback
  GROUP BY order_id
),

-- 4. Calculate raw RFM metrics across all customer orders
customers_grouped AS (
  SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS frequency_order_count,
    MAX(order_purchase_timestamp)::DATE AS last_order,
    SUM(total_item_value) AS monetary
  FROM gold.fact_sales
  GROUP BY customer_id
),

-- 5. Compute lifetime logistics, fulfillment, and cross-state behavioral metrics (Delivered only)
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

-- 6. Aggregate order-level payment installments and review scores to the customer grain
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

-- 7. Assign standardized RFM scores (R via NTILE, F via discrete tiers, M via NTILE)
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

-- 8. Final Customer 360 output with segment assignment and behavioral KPIs
SELECT
  rfm.customer_id,
  rfm.recency_days,
  rfm.frequency_order_count,
  rfm.monetary,
  rfm.r_score,
  rfm.f_score,
  rfm.m_score,
  CASE
    -- 1. The Elite: High recency, repeat buyers (>=2 orders), and top spenders
    WHEN f_score >= 3 AND r_score >= 3 AND m_score >= 3 THEN 'Champion'
    
    -- 2. Repeat Buyers: Frequent purchasers regardless of recent activity
    WHEN f_score >= 3 THEN 'Loyal Customer'
    
    -- 3. High Spenders: Top 20% gross spend who have not purchased recently
    WHEN m_score = 5 THEN 'Cannot Lose Them'
    
    -- 4. Recent Additions: Top 40% recency single-order buyers
    WHEN r_score >= 4 THEN 'Recent / New Customer'
    
    -- 5. The Middle Class: Mid-tier recency with above-average spend
    WHEN r_score = 3 AND m_score >= 3 THEN 'Promising / Average'
    
    -- 6. The True Bottom: Bottom 40% recency AND bottom 40% monetary spend
    WHEN r_score <= 2 AND m_score <= 2 THEN 'Lost / Hibernating'
    
    -- 7. Dormant High Spenders: Low recency with historic mid-to-high spend
    WHEN r_score <= 2 AND m_score >= 3 THEN 'At Risk'
    
    -- 8. The Remnants: Mid-to-low recency with low transaction spend
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

/*
======================================================================================
RFM Cohort Segment Definitions & Business Actions (Evaluated in Exact Priority Order)
======================================================================================

1. Champion
   - Criteria: f_score >= 3, r_score >= 3, m_score >= 3 (Repeat buyers with recent activity and high spend).
   - Profile: The most valuable cohort. Highly engaged, frequent purchasers with top lifetime gross spend.
   - Recommended Action: VIP loyalty programs, early access to new product drops, personalized appreciation perks.

2. Loyal Customer
   - Criteria: f_score >= 3 (Repeat buyers who have placed 2 or more orders).
   - Profile: Highly engaged recurring customers in a marketplace where ~97% of users only buy once.
   - Recommended Action: Upsell higher-margin product categories, incentivize cross-category purchasing, subscription offers.

3. Cannot Lose Them
   - Criteria: m_score = 5 (Top 20% lifetime spenders who have become dormant).
   - Profile: High-value "whale" accounts that generated substantial revenue but have not returned recently.
   - Recommended Action: Aggressive reactivation incentives, premium win-back discounts, dedicated customer outreach.

4. Recent / New Customer
   - Criteria: r_score >= 4 (Top 40% recency who have not reached top monetary tiers yet).
   - Profile: Freshly acquired buyers with recent transaction activity; high potential for repeat conversion.
   - Recommended Action: Onboarding email sequences, second-purchase discount coupons, product recommendation engines.

5. Promising / Average
   - Criteria: r_score = 3, m_score >= 3 (Moderate recency with above-average historical spend).
   - Profile: Steady middle-tier customers with solid purchasing power who buy periodically.
   - Recommended Action: Category cross-selling, seasonal promotional campaigns, time-limited incentives.

6. Lost / Hibernating
   - Criteria: r_score <= 2, m_score <= 2 (Bottom 40% recency and bottom 40% spend).
   - Profile: Churned one-time buyers who spent minimal amounts a long time ago.
   - Recommended Action: Exclude from expensive marketing channels; include only in low-cost automated quarterly re-engagement sweeps.

7. At Risk
   - Criteria: r_score <= 2, m_score >= 3 (Bottom 40% recency, but mid-to-high historical spend).
   - Profile: Previously solid spenders who have disengaged and are on the verge of becoming completely lost.
   - Recommended Action: Personalized win-back surveys, targeted promotional bundles, feedback inquiries.

8. General / Low Value
   - Criteria: ELSE (Residual cohort: moderate/low recency combined with low spend).
   - Profile: Baseline transactional buyers with low lifetime monetary impact.
   - Recommended Action: Standard automated promotional newsletters, low-cost remarketing.
======================================================================================
*/
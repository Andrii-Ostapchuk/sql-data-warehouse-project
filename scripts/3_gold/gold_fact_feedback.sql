/*
===============================================================================
Fact View: gold.fact_feedback
===============================================================================
Purpose:
    - Creates the Customer Review and Satisfaction Fact table.
    - Captures numerical ratings (1-5) and qualitative customer feedback per order.
    - Resolves customer identity to persistent `customer_unique_id` (aliased as `customer_id`) 
      to allow direct relationships with `gold.dim_customers`.
    - Enforces data hygiene by filtering only orders that passed chronological validation 
      checks (`is_valid_date_sequence = TRUE`).
===============================================================================
*/

CREATE OR REPLACE VIEW gold.fact_feedback AS (
  SELECT
    -- Primary and foreign keys
    r.review_id,
    r.order_id,
    c.customer_unique_id AS customer_id, 

    -- Review score and qualitative feedback
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,

    -- Survey lifecycle timestamps
    r.review_creation_date,
    r.review_answer_timestamp,

    -- Order milestone timestamps for response latency analysis
    o.order_purchase_timestamp,
    o.order_approved_at
  FROM silver.olist_order_reviews_dataset r
  INNER JOIN silver.olist_orders_dataset o
    ON r.order_id = o.order_id
  INNER JOIN silver.olist_customers_dataset c
    ON c.customer_id = o.customer_id
  -- Exclude records with corrupted or invalid milestone chronology
  WHERE o.is_valid_date_sequence = TRUE
);
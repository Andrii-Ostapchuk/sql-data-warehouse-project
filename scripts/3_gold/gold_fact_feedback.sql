CREATE OR REPLACE VIEW gold.fact_feedback AS (
  SELECT
    r.review_id,
    r.order_id,
    c.customer_unique_id AS customer_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp,
    o.order_purchase_timestamp,
    o.order_approved_at
  FROM silver.olist_order_reviews_dataset r
  INNER JOIN silver.olist_orders_dataset o
    ON r.order_id = o.order_id
  INNER JOIN silver.olist_customers_dataset c
    ON c.customer_id = o.customer_id
  WHERE o.is_valid_date_sequence = TRUE
);


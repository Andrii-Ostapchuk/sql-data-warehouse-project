CREATE OR REPLACE VIEW gold.fact_payments AS (
  SELECT
    p.order_id,
    c.customer_unique_id AS customer_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    o.order_purchase_timestamp,
    o.order_approved_at
  FROM silver.olist_order_payments_dataset p
  INNER JOIN silver.olist_orders_dataset o
    ON p.order_id = o.order_id
  INNER JOIN silver.olist_customers_dataset c
    ON c.customer_id = o.customer_id
  WHERE o.is_valid_date_sequence = TRUE
);


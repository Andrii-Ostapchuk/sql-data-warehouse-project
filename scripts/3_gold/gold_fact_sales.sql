CREATE OR REPLACE VIEW gold.fact_sales AS (
  SELECT
    i.order_id,
    c.customer_unique_id AS customer_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    i.shipping_limit_date,
    i.price,
    i.freight_value,
    (i.price + i.freight_value) AS total_item_value,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date
  FROM silver.olist_order_items_dataset i
  INNER JOIN silver.olist_orders_dataset o 
    ON i.order_id = o.order_id
  INNER JOIN silver.olist_customers_dataset c
    ON o.customer_id = c.customer_id
  WHERE o.is_valid_date_sequence = TRUE
);

















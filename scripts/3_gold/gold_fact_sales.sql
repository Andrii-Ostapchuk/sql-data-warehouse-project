/*
===============================================================================
Fact View: gold.fact_sales
===============================================================================
Purpose:
    - Creates the central Sales Fact table at the granular line-item level 
      (Grain: 1 row per `order_id` + `order_item_id`).
    - Connects order items with customer, product, and seller dimensions in a star schema.
    - Standardizes customer identification by resolving transient `customer_id` to 
      persistent `customer_unique_id` (aliased as `customer_id`) for joins with `gold.dim_customers`.
    - Computes `total_item_value` (gross item spend including product price and freight).
    - Enforces data quality by filtering only orders with valid chronological milestones 
      (`is_valid_date_sequence = TRUE`).
===============================================================================
*/

CREATE OR REPLACE VIEW gold.fact_sales AS (
  SELECT
    -- Primary transaction grain and foreign keys
    i.order_id,
    c.customer_unique_id AS customer_id, -- Standardized customer dimension foreign key
    i.order_item_id,
    i.product_id,
    i.seller_id,

    -- Shipping limit deadline
    i.shipping_limit_date,

    -- Financial metrics
    i.price,
    i.freight_value,
    (i.price + i.freight_value) AS total_item_value, -- Gross transaction value per line item

    -- Order lifecycle status and milestone timestamps
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
  -- Exclude records with corrupted or invalid milestone chronology
  WHERE o.is_valid_date_sequence = TRUE
);


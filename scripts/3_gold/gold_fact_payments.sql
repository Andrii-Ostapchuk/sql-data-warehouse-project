/*
===============================================================================
Fact View: gold.fact_payments
===============================================================================
Purpose:
    - Creates the Payment Transactions Fact table (Grain: 1 row per payment attempt/split per order).
    - Tracks financial settlement methods, installment counts, and transaction amounts.
    - Standardizes customer identification by resolving transient `customer_id` to 
      persistent `customer_unique_id` (aliased as `customer_id`) for joins with `gold.dim_customers`.
    - Enforces data quality by filtering only orders with valid chronological milestones 
      (`is_valid_date_sequence = TRUE`).
===============================================================================
*/

CREATE OR REPLACE VIEW gold.fact_payments AS (
  SELECT
    -- Foreign keys
    p.order_id,
    c.customer_unique_id AS customer_id, 

    -- Payment breakdown and terms
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,

    -- Order milestones for payment timing and cohort analysis
    o.order_purchase_timestamp,
    o.order_approved_at
  FROM silver.olist_order_payments_dataset p
  INNER JOIN silver.olist_orders_dataset o
    ON p.order_id = o.order_id
  INNER JOIN silver.olist_customers_dataset c
    ON c.customer_id = o.customer_id
  -- Exclude records with corrupted or invalid milestone chronology
  WHERE o.is_valid_date_sequence = TRUE
);
/*
===============================================================================
Dimension View: gold.dim_customers
===============================================================================
Purpose:
    - Creates a single-grain Customer Dimension table (Grain: 1 row per unique customer).
    - Resolves multi-account / multi-order customer entities by mapping multiple 
      transient `customer_id` records to a persistent `customer_unique_id`.
    - Retains the customer's most recent known address based on their latest order timestamp.
    - Enriches customer records with deduplicated latitude/longitude coordinates from the silver geolocation layer.
===============================================================================
*/

CREATE OR REPLACE VIEW gold.dim_customers AS (
  WITH relevant_addresses AS (
    SELECT
      c.customer_unique_id,
      c.customer_id,
      c.customer_zip_code_prefix,
      c.customer_city,
      c.customer_state,
      -- Rank addresses to pick the most recent location profile per unique customer
      ROW_NUMBER() OVER (
        PARTITION BY c.customer_unique_id 
        ORDER BY o.order_purchase_timestamp DESC NULLS LAST, c.customer_id
      ) AS row_num
    FROM silver.olist_customers_dataset c
    LEFT JOIN silver.olist_orders_dataset o
      ON c.customer_id = o.customer_id
  )

  SELECT
    -- Standardize unique customer identifier as the primary dimension key
    ra.customer_unique_id AS customer_id,
    ra.customer_zip_code_prefix,
    ra.customer_city,
    ra.customer_state,
    g.geolocation_lat,
    g.geolocation_lng
  FROM relevant_addresses ra
  -- Enrich with deduplicated spatial coordinates
  LEFT JOIN silver.olist_geolocation_dataset g
    ON g.geolocation_zip_code_prefix = ra.customer_zip_code_prefix
  WHERE ra.row_num = 1
);
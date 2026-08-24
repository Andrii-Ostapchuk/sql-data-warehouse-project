CREATE OR REPLACE VIEW gold.dim_customers AS (
  WITH relevant_addresses AS(
    SELECT
      c.customer_unique_id,
      c.customer_id, -- The following customer_id's have the correct address info.
      c.customer_zip_code_prefix,
      c.customer_city,
      c.customer_state,
      ROW_NUMBER() OVER (
        PARTITION BY c.customer_unique_id 
        ORDER BY o.order_purchase_timestamp DESC NULLS LAST, c.customer_id) AS row_num
    FROM silver.olist_customers_dataset c
    LEFT JOIN silver.olist_orders_dataset o
      ON c.customer_id = o.customer_id
  )
  SELECT
    ra.customer_unique_id AS customer_id,
    ra.customer_zip_code_prefix,
    ra.customer_city,
    ra.customer_state,
    g.geolocation_lat,
    g.geolocation_lng
  FROM relevant_addresses ra
  LEFT JOIN silver.olist_geolocation_dataset g
    ON g.geolocation_zip_code_prefix = ra.customer_zip_code_prefix
  WHERE ra.row_num = 1
);




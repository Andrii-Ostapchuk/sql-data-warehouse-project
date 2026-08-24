CREATE OR REPLACE VIEW gold.dim_sellers AS (
  SELECT
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    g.geolocation_lat,
    g.geolocation_lng
  FROM silver.olist_sellers_dataset s
    LEFT JOIN silver.olist_geolocation_dataset g  
      ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
);


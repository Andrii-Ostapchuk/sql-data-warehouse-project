/*
===============================================================================
Dimension View: gold.dim_sellers
===============================================================================
Purpose:
    - Creates a single-grain Seller Dimension table (Grain: 1 row per unique `seller_id`).
    - Standardizes seller regional location attributes (zip prefix, city, state).
    - Enriches seller profiles with deduplicated geographic coordinates (latitude/longitude)
      to support spatial analytics, distance modeling, and cross-state fulfillment analysis.
===============================================================================
*/

CREATE OR REPLACE VIEW gold.dim_sellers AS (
  SELECT
    -- Primary dimension key
    s.seller_id,
    
    -- Regional and address attributes
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    
    -- Geospatial coordinates enriched from deduplicated geolocation layer
    g.geolocation_lat,
    g.geolocation_lng
  FROM silver.olist_sellers_dataset s
  LEFT JOIN silver.olist_geolocation_dataset g  
    ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
);
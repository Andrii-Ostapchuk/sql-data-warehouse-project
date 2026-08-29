/*
===============================================================================
Dimension View: gold.dim_products
===============================================================================
Purpose:
    - Creates a single-grain Product Dimension table (Grain: 1 row per unique `product_id`).
    - Standardizes product categories by mapping Portuguese categories to English names, 
      with a fallback to the original Portuguese value if no translation exists.
    - Preserves the original Portuguese category name for localized reporting.
    - Derives volumetric dimensions (`product_volume_cm3`) for logistics and freight analysis.
    - Carries forward data quality integrity flags from the Silver layer.
===============================================================================
*/

CREATE OR REPLACE VIEW gold.dim_products AS (
  SELECT
      p.product_id,
      -- Standardized English category name with fallback to Portuguese if unmapped
      COALESCE(t.product_category_name_english, p.product_category_name) AS product_category_name,
      -- Retain raw category name for localization and lineage
      p.product_category_name AS product_category_name_portuguese,
      -- Catalog content quality metrics
      p.product_name_lenght,
      p.product_description_lenght,
      p.product_photos_qty,
      -- Physical package specifications
      p.product_weight_g,
      p.product_length_cm,
      p.product_height_cm,
      p.product_width_cm,
      -- Calculated volumetric metric for shipping/freight modeling
      (p.product_length_cm * p.product_height_cm * p.product_width_cm) AS product_volume_cm3,
      -- Data quality validation flag from Silver layer
      p.physical_dimentions_integrity
  FROM silver.olist_products_dataset p
  LEFT JOIN silver.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
);
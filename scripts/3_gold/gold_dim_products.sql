CREATE OR REPLACE VIEW gold.dim_products AS (
  SELECT
      p.product_id,
      COALESCE(t.product_category_name_english, p.product_category_name) AS product_category_name,
      p.product_category_name AS product_category_name_portuguese,
      p.product_name_lenght,
      p.product_description_lenght,
      p.product_photos_qty,
      p.product_weight_g,
      p.product_length_cm,
      p.product_height_cm,
      p.product_width_cm,
      (p.product_length_cm * p.product_height_cm * p.product_width_cm) AS product_volume_cm3,
      p.physical_dimentions_integrity
  FROM silver.olist_products_dataset p
  LEFT JOIN silver.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
);


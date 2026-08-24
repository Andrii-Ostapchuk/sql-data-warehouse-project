CREATE EXTENSION IF NOT EXISTS unaccent SCHEMA bronze;


-- olist_customers_dataset
TRUNCATE TABLE silver.olist_customers_dataset;

INSERT INTO silver.olist_customers_dataset

SELECT 
  customer_id,
  customer_unique_id,
  customer_zip_code_prefix,
  LOWER(TRIM(bronze.unaccent(customer_city))) customer_city,
  customer_state
FROM bronze.olist_customers_dataset;

-- Geolocation removing duplicate zip code prefixes
TRUNCATE TABLE silver.olist_geolocation_dataset;

INSERT INTO silver.olist_geolocation_dataset

SELECT 
  geolocation_zip_code_prefix,
  AVG(geolocation_lat) geolocation_lat,
  AVG(geolocation_lng) geolocation_lng,
  LOWER(TRIM(bronze.unaccent(MODE() WITHIN GROUP (ORDER BY geolocation_city)))) geolocation_city,
  MODE() WITHIN GROUP (ORDER BY geolocation_state) geolocation_state
FROM bronze.olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix;


-- olist_order_items_dataset
TRUNCATE TABLE silver.olist_order_items_dataset;

INSERT INTO silver.olist_order_items_dataset

SELECT
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date,
  price,
  freight_value
FROM bronze.olist_order_items_dataset;


-- olist_order_payments_dataset
TRUNCATE TABLE silver.olist_order_payments_dataset;

INSERT INTO silver.olist_order_payments_dataset

SELECT
  order_id,
  payment_sequential,
  payment_type,
  CASE
    WHEN payment_installments = 0 THEN 1
    ELSE payment_installments
  END AS payment_installments,
  payment_value
FROM bronze.olist_order_payments_dataset;


-- olist_order_reviews_dataset
TRUNCATE TABLE silver.olist_order_reviews_dataset;

INSERT INTO silver.olist_order_reviews_dataset

SELECT
  review_id,
  order_id,
  review_score,
  review_comment_title,
  review_comment_message,
  review_creation_date,
  review_answer_timestamp
FROM bronze.olist_order_reviews_dataset;


-- olist_orders_dateset
TRUNCATE TABLE silver.olist_orders_dataset;

INSERT INTO silver.olist_orders_dataset

SELECT
  order_id,
  customer_id,
  order_status,
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date,
  order_estimated_delivery_date,
  CASE
  
    WHEN
    -- Upstream Milestone Occurs AFTER Downstream Milestone 
      order_purchase_timestamp > order_delivered_customer_date OR 
      order_purchase_timestamp > order_delivered_carrier_date OR
      order_purchase_timestamp > order_estimated_delivery_date OR

      order_approved_at > order_delivered_customer_date OR 
      order_approved_at > order_delivered_carrier_date OR
      order_approved_at > order_estimated_delivery_date OR

      order_delivered_carrier_date > order_delivered_customer_date OR

      order_purchase_timestamp > order_approved_at OR

    -- Status-to-Timestamp Integrity
      (order_status = 'delivered' AND order_delivered_customer_date IS NULL) OR
      (order_status = 'shipped' AND order_delivered_carrier_date IS NULL)
    THEN FALSE
    ELSE TRUE
  END AS is_valid_date_sequence
FROM bronze.olist_orders_dataset;


-- olist_products_dataset
TRUNCATE TABLE silver.olist_products_dataset;

INSERT INTO silver.olist_products_dataset

SELECT
  product_id,
  product_category_name,
  product_name_lenght,
  product_description_lenght,
  product_photos_qty,
  product_weight_g,
  product_length_cm,
  product_height_cm,
  product_width_cm,
  CASE
    WHEN product_weight_g = 0 OR
      product_length_cm = 0 OR
      product_height_cm = 0 OR
      product_width_cm = 0
    THEN FALSE
    ELSE TRUE
  END AS physical_dimentions_integrity
FROM bronze.olist_products_dataset;

-- olist_sellers_dataset
TRUNCATE TABLE silver.olist_sellers_dataset;

INSERT INTO silver.olist_sellers_dataset

SELECT
  seller_id,
  seller_zip_code_prefix,
  LOWER(TRIM(bronze.unaccent(seller_city))) seller_city,
  seller_state
FROM bronze.olist_sellers_dataset;


-- product_category_name_translation
-- Checking for unmatched values 
/*
SELECT DISTINCT
  p.product_category_name product,
  t.product_category_name translation
FROM bronze.olist_products_dataset p
FULL JOIN bronze.product_category_name_translation t 
ON t.product_category_name = p.product_category_name;

-- Adding missing values
INSERT INTO bronze.product_category_name_translation (product_category_name, product_category_name_english)
VALUES 
    ('pc_gamer', 'pc_gamer'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers');

SELECT *
FROM bronze.olist_customers_dataset



UPDATE silver.product_category_name_translation
SET product_category_name_english = 'home_comfort'
WHERE product_category_name_english = 'home_confort';

UPDATE silver.product_category_name_translation
SET product_category_name_english = 'fashion_female_clothing'
WHERE product_category_name_english = 'fashio_female_clothing';
*/


TRUNCATE TABLE silver.product_category_name_translation;

INSERT INTO silver.product_category_name_translation

SELECT
  product_category_name,
  product_category_name_english
FROM bronze.product_category_name_translation;

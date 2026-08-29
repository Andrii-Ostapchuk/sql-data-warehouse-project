/*
===============================================================================
Data Transformation & Cleansing Script: Bronze to Silver Layer
===============================================================================
Script Purpose:
    - Truncates and reloads conformed Silver tables from raw Bronze staging.
    - Applies text normalization (accent stripping, trimming, lowercasing).
    - Deduplicates geographical entities using aggregate coordinate averaging and mode values.
    - Implements data quality validation flags (chronological integrity and dimension sanity).
    - Cleanses edge cases (e.g., zero installment handling).
===============================================================================
*/

-- Enable the unaccent extension to strip diacritics and special characters from text fields
CREATE EXTENSION IF NOT EXISTS unaccent SCHEMA bronze;


-- ============================================================================
-- 1. Customers Dataset
-- Cleansing: Standardize city text by trimming whitespace, lowercasing, and removing diacritics.
-- ============================================================================
TRUNCATE TABLE silver.olist_customers_dataset;

INSERT INTO silver.olist_customers_dataset (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    LOWER(TRIM(bronze.unaccent(customer_city))) AS customer_city,
    customer_state
FROM bronze.olist_customers_dataset;


-- ============================================================================
-- 2. Geolocation Dataset
-- Cleansing: Deduplicate zip codes to a single unique record by:
--   - Averaging latitude and longitude coordinates.
--   - Selecting the statistical MODE (most frequent value) for city and state.
--   - Normalizing city names.
-- ============================================================================
TRUNCATE TABLE silver.olist_geolocation_dataset;

INSERT INTO silver.olist_geolocation_dataset (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT 
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS geolocation_lat,
    AVG(geolocation_lng) AS geolocation_lng,
    LOWER(TRIM(bronze.unaccent(MODE() WITHIN GROUP (ORDER BY geolocation_city)))) AS geolocation_city,
    MODE() WITHIN GROUP (ORDER BY geolocation_state) AS geolocation_state
FROM bronze.olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix;


-- ============================================================================
-- 3. Order Items Dataset
-- Cleansing: Standardize transactional line-item pricing and freight values.
-- ============================================================================
TRUNCATE TABLE silver.olist_order_items_dataset;

INSERT INTO silver.olist_order_items_dataset (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM bronze.olist_order_items_dataset;


-- ============================================================================
-- 4. Order Payments Dataset
-- Cleansing: Correct anomalies where payment installments are recorded as 0 (default to 1).
-- ============================================================================
TRUNCATE TABLE silver.olist_order_payments_dataset;

INSERT INTO silver.olist_order_payments_dataset (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
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


-- ============================================================================
-- 5. Order Reviews Dataset
-- Cleansing: Cast review scores, text feedback, and timestamps into conformed schema.
-- ============================================================================
TRUNCATE TABLE silver.olist_order_reviews_dataset;

INSERT INTO silver.olist_order_reviews_dataset (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM bronze.olist_order_reviews_dataset;


-- ============================================================================
-- 6. Orders Dataset
-- Cleansing: Derive data quality flag `is_valid_date_sequence` to flag chronological 
-- anomalies (e.g., purchase after delivery) and missing milestone timestamps.
-- ============================================================================
TRUNCATE TABLE silver.olist_orders_dataset;

INSERT INTO silver.olist_orders_dataset (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    is_valid_date_sequence
)
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
        -- 1. Upstream Milestone Occurs AFTER Downstream Milestone
        WHEN order_purchase_timestamp > order_delivered_customer_date 
          OR order_purchase_timestamp > order_delivered_carrier_date 
          OR order_purchase_timestamp > order_estimated_delivery_date 
          OR order_approved_at > order_delivered_customer_date 
          OR order_approved_at > order_delivered_carrier_date 
          OR order_approved_at > order_estimated_delivery_date 
          OR order_delivered_carrier_date > order_delivered_customer_date 
          OR order_purchase_timestamp > order_approved_at 

        -- 2. Status-to-Timestamp Completeness Check
          OR (order_status = 'delivered' AND order_delivered_customer_date IS NULL) 
          OR (order_status = 'shipped' AND order_delivered_carrier_date IS NULL)
        THEN FALSE
        ELSE TRUE
    END AS is_valid_date_sequence
FROM bronze.olist_orders_dataset;


-- ============================================================================
-- 7. Products Dataset
-- Cleansing: Derive `physical_dimentions_integrity` flag to identify missing/zero package metrics.
-- ============================================================================
TRUNCATE TABLE silver.olist_products_dataset;

INSERT INTO silver.olist_products_dataset (
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    physical_dimentions_integrity
)
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
        WHEN product_weight_g = 0 
          OR product_length_cm = 0 
          OR product_height_cm = 0 
          OR product_width_cm = 0 
        THEN FALSE
        ELSE TRUE
    END AS physical_dimentions_integrity
FROM bronze.olist_products_dataset;


-- ============================================================================
-- 8. Sellers Dataset
-- Cleansing: Standardize seller city text by stripping accents, trimming whitespace, and lowercasing.
-- ============================================================================
TRUNCATE TABLE silver.olist_sellers_dataset;

INSERT INTO silver.olist_sellers_dataset (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    LOWER(TRIM(bronze.unaccent(seller_city))) AS seller_city,
    seller_state
FROM bronze.olist_sellers_dataset;


-- ============================================================================
-- 9. Product Category Name Translation
-- Cleansing: Ingest mapped English category names from reference data.
-- ============================================================================
TRUNCATE TABLE silver.product_category_name_translation;

INSERT INTO silver.product_category_name_translation (
    product_category_name,
    product_category_name_english
)
SELECT
    product_category_name,
    product_category_name_english
FROM bronze.product_category_name_translation;
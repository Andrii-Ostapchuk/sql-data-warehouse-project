/*===============================================================================
Script: Drop All Primary Keys and Foreign Keys
===============================================================================*/

-- 1. Drop Foreign Keys First (Child tables must be dropped before dropping parent Primary Keys)

-- Table: silver.olist_order_items_dataset
ALTER TABLE silver.olist_order_items_dataset
  DROP CONSTRAINT IF EXISTS fk_olist_order_items_dataset__olist_orders_dataset,
  DROP CONSTRAINT IF EXISTS fk_olist_order_items_dataset__olist_products_dataset,
  DROP CONSTRAINT IF EXISTS fk_olist_order_items_dataset__olist_sellers_dataset;

-- Table: silver.olist_order_payments_dataset
ALTER TABLE silver.olist_order_payments_dataset
  DROP CONSTRAINT IF EXISTS fk_olist_order_payments_dataset__olist_orders_dataset;

-- Table: silver.olist_order_reviews_dataset
ALTER TABLE silver.olist_order_reviews_dataset
  DROP CONSTRAINT IF EXISTS fk_olist_order_reviews_dataset__olist_orders_dataset;

-- Table: silver.olist_orders_dataset
ALTER TABLE silver.olist_orders_dataset
  DROP CONSTRAINT IF EXISTS fk_olist_orders_dataset__olist_customers_dataset;

-- Table: silver.olist_products_dataset
ALTER TABLE silver.olist_products_dataset
  DROP CONSTRAINT IF EXISTS fk_olist_products_dataset__product_category_name_translation;


-- 2. Drop Primary Keys

-- Table: silver.olist_customers_dataset
ALTER TABLE silver.olist_customers_dataset
  DROP CONSTRAINT IF EXISTS pk_olist_customers_dataset;

-- Table: silver.olist_orders_dataset
ALTER TABLE silver.olist_orders_dataset
  DROP CONSTRAINT IF EXISTS pk_olist_orders_dataset;

-- Table: silver.olist_products_dataset
ALTER TABLE silver.olist_products_dataset
  DROP CONSTRAINT IF EXISTS pk_olist_products_dataset;

-- Table: silver.olist_sellers_dataset
ALTER TABLE silver.olist_sellers_dataset
  DROP CONSTRAINT IF EXISTS pk_olist_sellers_dataset;

-- Table: silver.product_category_name_translation
ALTER TABLE silver.product_category_name_translation
  DROP CONSTRAINT IF EXISTS pk_product_category_name_translation;



/*================
PRIMARY KEYS
================*/

ALTER TABLE silver.olist_customers_dataset
  ADD CONSTRAINT pk_olist_customers_dataset 
  PRIMARY KEY (customer_id);

-- Cheking for ID duplicates
SELECT *
FROM (
  SELECT
    customer_id,
    COUNT(*) OVER(PARTITION BY customer_id) id_count
  FROM silver.olist_customers_dataset
)
WHERE id_count > 1;


ALTER TABLE silver.olist_orders_dataset
  ADD CONSTRAINT pk_olist_orders_dataset
  PRIMARY KEY (order_id);


ALTER TABLE silver.olist_products_dataset
  ADD CONSTRAINT pk_olist_products_dataset
  PRIMARY KEY (product_id);


ALTER TABLE silver.olist_sellers_dataset
  ADD CONSTRAINT pk_olist_sellers_dataset
  PRIMARY KEY (seller_id);


ALTER TABLE silver.product_category_name_translation
  ADD CONSTRAINT pk_product_category_name_translation
  PRIMARY KEY (product_category_name);


ALTER TABLE silver.olist_geolocation_dataset
  ADD CONSTRAINT pk_olist_geolocation_dataset
  PRIMARY KEY (geolocation_zip_code_prefix);

/*================
FOREIGN KEYS
================*/


-- olist_order_items_dataset

ALTER TABLE silver.olist_order_items_dataset
  ADD CONSTRAINT fk_olist_order_items_dataset__olist_orders_dataset
  FOREIGN KEY (order_id)
  REFERENCES silver.olist_orders_dataset (order_id);

ALTER TABLE silver.olist_order_items_dataset
  ADD CONSTRAINT fk_olist_order_items_dataset__olist_products_dataset
  FOREIGN KEY (product_id)
  REFERENCES silver.olist_products_dataset (product_id);

ALTER TABLE silver.olist_order_items_dataset
  ADD CONSTRAINT fk_olist_order_items_dataset__olist_sellers_dataset
  FOREIGN KEY (seller_id)
  REFERENCES silver.olist_sellers_dataset (seller_id);


-- olist_order_payments_dataset
ALTER TABLE silver.olist_order_payments_dataset
  ADD CONSTRAINT fk_olist_order_payments_dataset__olist_orders_dataset
  FOREIGN KEY (order_id)
  REFERENCES silver.olist_orders_dataset (order_id);


-- olist_order_reviews_dataset
ALTER TABLE silver.olist_order_reviews_dataset
  ADD CONSTRAINT fk_olist_order_reviews_dataset__olist_orders_dataset
  FOREIGN KEY (order_id)
  REFERENCES silver.olist_orders_dataset (order_id);


-- olist_orders_dataset
ALTER TABLE silver.olist_orders_dataset
  ADD CONSTRAINT fk_olist_orders_dataset__olist_customers_dataset
  FOREIGN KEY (customer_id)
  REFERENCES silver.olist_customers_dataset (customer_id);


-- olist_products_dataset
ALTER TABLE silver.olist_products_dataset
  ADD CONSTRAINT fk_olist_products_dataset__product_category_name_translation
  FOREIGN KEY (product_category_name)
  REFERENCES silver.product_category_name_translation (product_category_name)


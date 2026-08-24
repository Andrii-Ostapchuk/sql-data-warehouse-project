DROP TABLE IF EXISTS silver.olist_customers_dataset;
CREATE TABLE silver.olist_customers_dataset (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(40),
    customer_state VARCHAR(2),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.olist_geolocation_dataset;
CREATE TABLE silver.olist_geolocation_dataset (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(40),
    geolocation_state VARCHAR(2),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.olist_order_items_dataset;
CREATE TABLE silver.olist_order_items_dataset (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price FLOAT,
    freight_value FLOAT,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.olist_order_payments_dataset;
CREATE TABLE silver.olist_order_payments_dataset (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value FLOAT,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.olist_order_reviews_dataset;
CREATE TABLE silver.olist_order_reviews_dataset (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(50),
    review_comment_message TEXT,
    review_creation_date DATE,
    review_answer_timestamp TIMESTAMP,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.olist_orders_dataset;
CREATE TABLE silver.olist_orders_dataset (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(12),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    is_valid_date_sequence BOOLEAN,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.olist_products_dataset;
CREATE TABLE silver.olist_products_dataset (
    product_id VARCHAR(50),
    product_category_name VARCHAR(50),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,
    physical_dimentions_integrity BOOLEAN,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.olist_sellers_dataset;
CREATE TABLE silver.olist_sellers_dataset (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(40),
    seller_state VARCHAR(2),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.product_category_name_translation;
CREATE TABLE silver.product_category_name_translation (
    product_category_name VARCHAR(50),
    product_category_name_english VARCHAR(50),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
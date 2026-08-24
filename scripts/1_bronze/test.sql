CREATE TABLE gold.dim_customers_t (
    customer_id VARCHAR PRIMARY KEY,
    customer_zip_code_prefix VARCHAR,
    customer_city VARCHAR,
    customer_state VARCHAR,
    geolocation_lat FLOAT8,
    geolocation_lng FLOAT8
);

CREATE TABLE gold.dim_products_t (
    product_id VARCHAR PRIMARY KEY,
    product_category_name VARCHAR,
    product_category_name_portuguese VARCHAR,
    product_name_lenght INT4,
    product_description_lenght INT4,
    product_photos_qty INT4,
    product_weight_g INT4,
    product_length_cm INT4,
    product_height_cm INT4,
    product_width_cm INT4,
    product_volume_cm3 INT4,
    physical_dimentions_integrity BOOLEAN
);

CREATE TABLE gold.dim_sellers_t (
    seller_id VARCHAR PRIMARY KEY,
    seller_zip_code_prefix VARCHAR,
    seller_city VARCHAR,
    seller_state VARCHAR,
    geolocation_lat FLOAT8,
    geolocation_lng FLOAT8
);

CREATE TABLE gold.fact_sales_t (
    order_id VARCHAR,
    customer_id VARCHAR,
    order_item_id INT4,
    product_id VARCHAR,
    seller_id VARCHAR,
    shipping_limit_date TIMESTAMP,
    price FLOAT8,
    freight_value FLOAT8,
    total_item_value FLOAT8,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (customer_id) REFERENCES gold.dim_customers_t(customer_id),
    FOREIGN KEY (product_id) REFERENCES gold.dim_products_t(product_id),
    FOREIGN KEY (seller_id) REFERENCES gold.dim_sellers_t(seller_id)
);

CREATE TABLE gold.fact_payments_t (
    order_id VARCHAR,
    customer_id VARCHAR,
    payment_sequential INT4,
    payment_type VARCHAR,
    payment_installments INT4,
    payment_value FLOAT8,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (customer_id) REFERENCES gold.dim_customers_t(customer_id)
);

CREATE TABLE gold.fact_feedback_t (
    review_id VARCHAR,
    order_id VARCHAR,
    customer_id VARCHAR,
    review_score INT4,
    review_comment_title VARCHAR,
    review_comment_message TEXT,
    review_creation_date DATE,
    review_answer_timestamp TIMESTAMP,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (customer_id) REFERENCES gold.dim_customers_t(customer_id)
);




DROP TABLE IF EXISTS gold.fact_sales_t CASCADE;
DROP TABLE IF EXISTS gold.fact_payments_t CASCADE;
DROP TABLE IF EXISTS gold.fact_feedback_t CASCADE;

DROP TABLE IF EXISTS gold.dim_customers_t CASCADE;
DROP TABLE IF EXISTS gold.dim_products_t CASCADE;
DROP TABLE IF EXISTS gold.dim_sellers_t CASCADE;
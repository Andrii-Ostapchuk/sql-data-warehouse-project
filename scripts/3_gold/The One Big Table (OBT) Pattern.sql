
SELECT order_id, order_item_id, COUNT(*)
FROM(
WITH deduplicated_reviews AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        review_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    FROM silver.olist_order_reviews_dataset
    ORDER BY order_id, review_answer_timestamp DESC
)
SELECT 
    -- 1. Grain & Business Keys
    o.order_id,
    i.order_item_id,
    c.customer_id,
    c.customer_unique_id,
    p.product_id,
    s.seller_id,

    -- 2. Order Lifecycle & Status
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    i.shipping_limit_date,

    -- 3. Core Financial Measures (Line-Item Grain)
    i.price,
    i.freight_value,
    (i.price + i.freight_value) AS total_item_value,

    -- 4. Product Dimension Attributes
    COALESCE(t.product_category_name_english, p.product_category_name) AS product_category_name,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    (p.product_length_cm * p.product_height_cm * p.product_width_cm) AS product_volume_cm3,

    -- 5. Customer Geographic Dimension
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,

    -- 6. Seller Geographic Dimension
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,

    -- 7. Review & Satisfaction Dimension
    r.review_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp

FROM silver.olist_orders_dataset o
JOIN silver.olist_order_items_dataset i 
    ON o.order_id = i.order_id
JOIN silver.olist_products_dataset p 
    ON i.product_id = p.product_id
LEFT JOIN silver.product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
JOIN silver.olist_customers_dataset c 
    ON o.customer_id = c.customer_id
JOIN silver.olist_sellers_dataset s 
    ON i.seller_id = s.seller_id
LEFT JOIN deduplicated_reviews r 
    ON o.order_id = r.order_id

WHERE o.is_valid_date_sequence IS TRUE
  AND p.physical_dimentions_integrity IS TRUE
)
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

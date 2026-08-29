/*
===============================================================================
Data Ingestion Script for Stored Procedure: Bronze Layer Bulk Load (with Execution Timing)
===============================================================================
Script Purpose:
    - Populates raw Bronze layer tables by bulk importing data from CSV source files.
    - Uses PostgreSQL COPY statement with standard CSV options (HEADER true, DELIMITER ',').
    - Tracks and prints step-by-step execution duration as well as total procedure runtime
      using clock_timestamp() and RAISE NOTICE messaging.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMPTZ;
    v_end_time   TIMESTAMPTZ;
    v_step_start TIMESTAMPTZ;
    v_step_end   TIMESTAMPTZ;
BEGIN
    v_start_time := clock_timestamp();
    
    RAISE NOTICE '==================================================';
    RAISE NOTICE 'Starting Bronze Layer Loading Process';
    RAISE NOTICE '==================================================';

    -- ============================================================================
    -- 1. Load Customer Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.olist_customers_dataset CASCADE;

    COPY bronze.olist_customers_dataset
    FROM 'D:\Data Analysis\1_SQL\dwh_project\sql-data-warehouse-project1\datasets\olist_customers_dataset.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.olist_customers_dataset" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- 2. Load Geolocation Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.olist_geolocation_dataset CASCADE;

    COPY bronze.olist_geolocation_dataset
    FROM 'D:\Data Analysis\1_SQL\dwh_project\sql-data-warehouse-project1\datasets\olist_geolocation_dataset.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.olist_geolocation_dataset" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- 3. Load Items Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.olist_order_items_dataset CASCADE;

    COPY bronze.olist_order_items_dataset
    FROM 'D:/Data Analysis/1_SQL/dwh_project/sql-data-warehouse-project1/datasets/olist_order_items_dataset.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.olist_order_items_dataset" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- 4. Load Payments Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.olist_order_payments_dataset CASCADE;

    COPY bronze.olist_order_payments_dataset
    FROM 'D:/Data Analysis/1_SQL/dwh_project/sql-data-warehouse-project1/datasets/olist_order_payments_dataset.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.olist_order_payments_dataset" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- 5. Load Reviews Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.olist_order_reviews_dataset CASCADE;

    COPY bronze.olist_order_reviews_dataset
    FROM 'D:/Data Analysis/1_SQL/dwh_project/sql-data-warehouse-project1/datasets/olist_order_reviews_dataset.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.olist_order_reviews_dataset" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- 6. Load Orders Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.olist_orders_dataset CASCADE;

    COPY bronze.olist_orders_dataset
    FROM 'D:/Data Analysis/1_SQL/dwh_project/sql-data-warehouse-project1/datasets/olist_orders_dataset.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.olist_orders_dataset" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- 7. Load Products Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.olist_products_dataset CASCADE;

    COPY bronze.olist_products_dataset
    FROM 'D:/Data Analysis/1_SQL/dwh_project/sql-data-warehouse-project1/datasets/olist_products_dataset.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.olist_products_dataset" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- 8. Load Sellers Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.olist_sellers_dataset CASCADE;

    COPY bronze.olist_sellers_dataset
    FROM 'D:/Data Analysis/1_SQL/dwh_project/sql-data-warehouse-project1/datasets/olist_sellers_dataset.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.olist_sellers_dataset" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- 9. Load Category Translation Data
    -- ============================================================================
    v_step_start := clock_timestamp();
    
    TRUNCATE TABLE bronze.product_category_name_translation CASCADE;

    COPY bronze.product_category_name_translation
    FROM 'D:/Data Analysis/1_SQL/dwh_project/sql-data-warehouse-project1/datasets/product_category_name_translation.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    
    v_step_end := clock_timestamp();
    RAISE NOTICE 'Table "bronze.product_category_name_translation" loaded in: %', (v_step_end - v_step_start);

    -- ============================================================================
    -- Summary Reporting
    -- ============================================================================
    v_end_time := clock_timestamp();
    
    RAISE NOTICE '==================================================';
    RAISE NOTICE 'Bronze Layer Loading Completed Successfully';
    RAISE NOTICE 'Total Execution Time: %', (v_end_time - v_start_time);
    RAISE NOTICE '==================================================';

END;
$$;

CALL bronze.load_bronze();
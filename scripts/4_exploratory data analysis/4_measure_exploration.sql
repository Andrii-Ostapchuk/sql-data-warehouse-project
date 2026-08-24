/*===========================
ADD EXCHANGE RATE!!!!!!!!!!!
===========================*/



-- Find the Total number of Orders
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM gold.fact_sales;
 
-- Find how many items are sold
SELECT COUNT(order_id) AS total_items
FROM gold.fact_sales;

-- Find the total number of products
SELECT COUNT(product_id) AS total_products
FROM gold.dim_products;

-- Find the Total Sales
SELECT ROUND(SUM(total_item_value)) AS total_sales
FROM gold.fact_sales;

-- Find the average selling price
SELECT ROUND(AVG(price)) AS avg_price
FROM gold.fact_sales;

-- Find the total number of customers
SELECT COUNT(customer_id) AS total_customers
FROM gold.dim_customers;

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_id) AS total_customers_placed_order
FROM gold.fact_sales;


-- Create a report showing key metrics
SELECT 
  'Total Nr. Orders' AS measure_name,
  COUNT(DISTINCT order_id) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Items', COUNT(order_id) 
FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products', COUNT(product_id) 
FROM gold.dim_products
UNION ALL
SELECT 'Total Sales', ROUND(SUM(total_item_value)) 
FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', ROUND(AVG(price)) 
FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Customers', COUNT(customer_id) 
FROM gold.dim_customers
UNION ALL
SELECT 'Total Nr. Customers with Order', COUNT(DISTINCT customer_id) 
FROM gold.fact_sales;
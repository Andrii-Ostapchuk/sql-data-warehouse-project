-- Calculating the percentage of orders in each state to all orders
WITH all_orders AS (
  SELECT COUNT(DISTINCT order_id) AS all_orders
  FROM gold.fact_sales
)

SELECT 
  c.customer_state,
  ROUND((COUNT(DISTINCT s.order_id)::NUMERIC / ao.all_orders) * 100, 2) AS orders_per_state_percentage
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c ON s.customer_id = c.customer_id
CROSS JOIN all_orders ao
GROUP BY 1, ao.all_orders
ORDER BY orders_per_state_percentage DESC;

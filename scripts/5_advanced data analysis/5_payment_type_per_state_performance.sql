/*
===============================================================================
Analytical Query: Payment Method Preference & Market Share by State
===============================================================================
Purpose:
    - Breaks down sales volume by customer state and payment method.
    - Computes the aggregate sales value per state.
    - Calculates the percentage share (`payment_type_proportion`) of each payment 
      method within each state to analyze regional payment preferences.
===============================================================================
*/

WITH payment_type_per_state_performance AS (
  SELECT 
    c.customer_state,
    p.payment_type,
    SUM(s.total_item_value)::NUMERIC AS combined_total_item_value
  FROM gold.fact_sales s
  LEFT JOIN gold.fact_payments p ON s.customer_id = p.customer_id
  LEFT JOIN gold.dim_customers c ON s.customer_id = c.customer_id
  GROUP BY 1, 2
)
SELECT
  customer_state,
  payment_type,
  ROUND(combined_total_item_value, 2) AS combined_total_item_value,
  ROUND(SUM(combined_total_item_value) OVER(PARTITION BY customer_state), 2) AS sales_per_state,
  ROUND((combined_total_item_value / SUM(combined_total_item_value) OVER(PARTITION BY customer_state)) * 100, 2) AS payment_type_proportion
FROM payment_type_per_state_performance
ORDER BY 1, 2;



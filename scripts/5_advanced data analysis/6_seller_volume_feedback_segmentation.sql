/*
===============================================================================
Analytical Query: Seller Volume vs. Customer Feedback Segmentation
===============================================================================
Purpose:
    - Measures total order fulfillment volume and average review score per seller.
    - Categorizes sellers across two operational dimensions:
        1. Order Volume: High Volume (>200), Medium Volume (51-200), Low Volume (<=50).
        2. Satisfaction Rating: Excellent (>=4.0), Needs Improvement (3.0-3.99), Bad (<3.0).
    - Enables quadrant matrix analysis to detect high-volume sellers with quality issues.
===============================================================================
*/

SELECT 
  s.seller_id,
  COUNT(s.order_id) AS orders_per_seller,
  CASE
    WHEN COUNT(s.order_id) > 200 THEN 'High Volume'
    WHEN COUNT(s.order_id) > 50 THEN 'Medium Volume'
    ELSE 'Low Volume'
  END AS volume_segmentation,
  ROUND(AVG(f.review_score), 2) AS avg_review_score,
  CASE
    WHEN AVG(f.review_score) >= 4.0 THEN 'Excellent'
    WHEN AVG(f.review_score) >= 3.0 THEN 'Needs Improvement'
    ELSE 'Bad'
  END AS rating_segmentation
FROM gold.fact_sales s 
LEFT JOIN gold.fact_feedback f ON s.order_id = f.order_id
GROUP BY s.seller_id
ORDER BY COUNT(s.order_id) DESC;
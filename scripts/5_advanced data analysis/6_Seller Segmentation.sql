SELECT 
  s.seller_id,
  COUNT(s.order_id),
  CASE
    WHEN COUNT(s.order_id) > 200 THEN 'High Volume'
    WHEN COUNT(s.order_id) > 50 THEN 'Medium Volume'
    ELSE 'Low Volume'
  END AS volume_segmentation,
  ROUND(AVG(f.review_score), 2),
  CASE
    WHEN AVG(f.review_score) >= 4.0 THEN 'Excellent'
    WHEN AVG(f.review_score) >= 3.0 THEN 'Needs Improvement'
    ELSE 'Bad'
  END AS rating_segmentation
FROM gold.fact_sales s 
LEFT JOIN gold.fact_feedback f ON s.order_id = f.order_id
GROUP BY s.seller_id
ORDER BY COUNT(s.order_id) DESC;
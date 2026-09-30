/*
PROJECT: Olist E-Commerce Analytics
PURPOSE: End-to-end performance analysis across business growth, products, customers, and operations.
*/

/* ============================================================================
   1. BUSINESS PERFORMANCE
   ============================================================================ */

-- Monthly cash collected vs. successful order volume
WITH ValidOrders AS (
    SELECT order_id, DATE_TRUNC('month', order_purchase_timestamp) AS order_month
    FROM orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
),
OrderPayments AS (
    SELECT order_id, SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
)
SELECT 
    TO_CHAR(v.order_month, 'YYYY-MM') AS month,
    COUNT(v.order_id) AS total_orders,
    ROUND(SUM(p.total_payment), 2) AS total_cash_collected
FROM ValidOrders v
JOIN OrderPayments p ON v.order_id = p.order_id
GROUP BY v.order_month
ORDER BY v.order_month;


-- Month-over-month cash collected growth
WITH MonthlyCash AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        SUM(p.payment_value) AS monthly_cash_collected
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
),
LaggedCash AS (
    SELECT 
        order_month,
        monthly_cash_collected,
        LAG(monthly_cash_collected) OVER(ORDER BY order_month) AS prev_month_cash
    FROM MonthlyCash
)
SELECT 
    TO_CHAR(order_month, 'YYYY-MM') AS month,
    monthly_cash_collected,
    prev_month_cash,
    ROUND(((monthly_cash_collected - prev_month_cash) / prev_month_cash) * 100, 2) AS mom_growth_pct
FROM LaggedCash
ORDER BY order_month;


-- Cumulative running total of cash collected
WITH MonthlyCash AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        SUM(p.payment_value) AS monthly_cash_collected
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT 
    TO_CHAR(order_month, 'YYYY-MM') AS month,
    monthly_cash_collected,
    SUM(monthly_cash_collected) OVER(ORDER BY order_month) AS cumulative_cash_collected
FROM MonthlyCash
ORDER BY order_month;


-- Average order value by maximum payment installments utilized
WITH OrderTotals AS (
    SELECT 
        order_id,
        MAX(payment_installments) AS max_installments,
        SUM(payment_value) AS total_order_value
    FROM order_payments
    GROUP BY order_id
)
SELECT 
    max_installments,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(total_order_value), 2) AS avg_order_value
FROM OrderTotals
WHERE max_installments >= 1
GROUP BY max_installments
ORDER BY max_installments;


/* ============================================================================
   2. PRODUCT & CATEGORY ANALYTICS
   ============================================================================ */

-- Top 10 categories by merchandise value
SELECT 
    p.product_category_name_english AS category,
    COUNT(i.order_item_id) AS total_items_sold,
    ROUND(SUM(i.price), 2) AS total_merchandise_value
FROM order_items i
JOIN products p ON i.product_id = p.product_id
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name_english IS NOT NULL
GROUP BY p.product_category_name_english
ORDER BY total_merchandise_value DESC
LIMIT 10;


-- Freight-to-merchandise ratio by category (minimum 500 items sold)
SELECT 
    p.product_category_name_english AS category,
    COUNT(i.order_item_id) AS items_sold,
    ROUND(AVG(i.price), 2) AS avg_item_value,
    ROUND(AVG(i.freight_value), 2) AS avg_freight_cost,
    ROUND(AVG(i.freight_value) / NULLIF(AVG(i.price), 0) * 100, 2) AS freight_to_item_ratio_pct
FROM order_items i
JOIN products p ON i.product_id = p.product_id
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name_english IS NOT NULL
GROUP BY p.product_category_name_english
HAVING COUNT(i.order_item_id) > 500
ORDER BY freight_to_item_ratio_pct DESC
LIMIT 10;


-- Top 3 revenue-generating products within the top 5 product categories
WITH CategoryRank AS (
    SELECT 
        p.product_category_name_english,
        SUM(i.price) as cat_merchandise_value,
        DENSE_RANK() OVER(ORDER BY SUM(i.price) DESC) as cat_rank
    FROM order_items i
    JOIN products p ON i.product_id = p.product_id
    JOIN orders o ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name_english IS NOT NULL
    GROUP BY p.product_category_name_english
),
ProductRank AS (
    SELECT 
        p.product_category_name_english,
        i.product_id,
        SUM(i.price) as product_merchandise_value,
        ROW_NUMBER() OVER(PARTITION BY p.product_category_name_english ORDER BY SUM(i.price) DESC) as prod_rank
    FROM order_items i
    JOIN products p ON i.product_id = p.product_id
    JOIN orders o ON i.order_id = o.order_id
    JOIN CategoryRank cr ON p.product_category_name_english = cr.product_category_name_english
    WHERE o.order_status = 'delivered' 
      AND cr.cat_rank <= 5
    GROUP BY p.product_category_name_english, i.product_id
)
SELECT 
    product_category_name_english,
    product_id,
    product_merchandise_value,
    prod_rank
FROM ProductRank
WHERE prod_rank <= 3
ORDER BY product_category_name_english, prod_rank;


/* ============================================================================
   3. CUSTOMER ANALYTICS
   ============================================================================ */

-- Merchandise value contribution: One-Time vs. Repeat Customers
WITH OrderMerchandise AS (
    SELECT 
        order_id,
        SUM(price) AS order_merchandise_value
    FROM order_items
    GROUP BY order_id
),
CustomerLifetime AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS lifetime_orders,
        SUM(om.order_merchandise_value) AS lifetime_merchandise_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN OrderMerchandise om ON o.order_id = om.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE WHEN lifetime_orders > 1 THEN 'Repeat Customer' ELSE 'One-Time Customer' END AS customer_segment,
    COUNT(customer_unique_id) AS total_customers,
    ROUND(SUM(lifetime_merchandise_value), 2) AS total_merchandise_value
FROM CustomerLifetime
GROUP BY 1;


-- Customer revenue concentration (Top 10% Spend Decile)
WITH OrderPayments AS (
    SELECT order_id, SUM(payment_value) AS order_payment_value
    FROM order_payments
    GROUP BY order_id
),
CustomerSpend AS (
    SELECT 
        c.customer_unique_id,
        SUM(op.order_payment_value) AS lifetime_payment_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN OrderPayments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
DecileRanking AS (
    SELECT 
        customer_unique_id,
        lifetime_payment_value,
        NTILE(10) OVER(ORDER BY lifetime_payment_value DESC) AS spend_decile,
        PERCENT_RANK() OVER(ORDER BY lifetime_payment_value DESC) AS pct_rank
    FROM CustomerSpend
)
SELECT 
    CASE WHEN spend_decile = 1 THEN 'Top 10% VIPs' ELSE 'Bottom 90%' END AS customer_tier,
    COUNT(customer_unique_id) AS customer_count,
    ROUND(SUM(lifetime_payment_value), 2) AS tier_payment_value
FROM DecileRanking
GROUP BY 1;


-- Top spending individual customer per state
WITH OrderPayments AS (
    SELECT order_id, SUM(payment_value) AS order_payment_value
    FROM order_payments
    GROUP BY order_id
),
CustomerStateSpend AS (
    SELECT 
        c.customer_state,
        c.customer_unique_id,
        SUM(op.order_payment_value) AS state_lifetime_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN OrderPayments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state, c.customer_unique_id
),
StateRanked AS (
    SELECT 
        customer_state,
        customer_unique_id,
        state_lifetime_spend,
        ROW_NUMBER() OVER(PARTITION BY customer_state ORDER BY state_lifetime_spend DESC) as state_rank
    FROM CustomerStateSpend
)
SELECT 
    customer_state,
    customer_unique_id,
    state_lifetime_spend AS top_payment_value
FROM StateRanked
WHERE state_rank = 1
ORDER BY top_payment_value DESC;


/* ============================================================================
   4. SELLER ANALYTICS
   ============================================================================ */

-- Seller merchandise value concentration (Cumulative % of total platform volume)
WITH SellerTotals AS (
    SELECT 
        seller_id,
        SUM(price) AS total_merchandise_value
    FROM order_items i
    JOIN orders o ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY seller_id
),
CumulativeSellers AS (
    SELECT 
        seller_id,
        total_merchandise_value,
        SUM(total_merchandise_value) OVER(ORDER BY total_merchandise_value DESC) AS running_merchandise_value,
        SUM(total_merchandise_value) OVER() AS grand_total_merchandise
    FROM SellerTotals
)
SELECT 
    seller_id,
    total_merchandise_value,
    ROUND((running_merchandise_value / grand_total_merchandise) * 100, 2) AS cumulative_pct_of_total
FROM CumulativeSellers
ORDER BY total_merchandise_value DESC
LIMIT 50;


-- High-volume sellers (>100 items) with poor average review scores (<3.5)
WITH SellerVolume AS (
    SELECT 
        i.seller_id,
        COUNT(i.order_item_id) AS total_items_sold
    FROM order_items i
    JOIN orders o ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY i.seller_id
    HAVING COUNT(i.order_item_id) > 100
),
SellerReviews AS (
    SELECT 
        i.seller_id,
        AVG(r.review_score) AS avg_review_score
    FROM order_items i
    JOIN order_reviews r ON i.order_id = r.order_id
    GROUP BY i.seller_id
)
SELECT 
    v.seller_id,
    v.total_items_sold,
    ROUND(r.avg_review_score, 2) AS avg_review_score
FROM SellerVolume v
JOIN SellerReviews r ON v.seller_id = r.seller_id
WHERE r.avg_review_score < 3.5
ORDER BY v.total_items_sold DESC;


-- Seller late delivery rates
WITH OrderDelivery AS (
    SELECT 
        o.order_id,
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_late
    FROM orders o
    WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
),
SellerDeliveries AS (
    SELECT 
        i.seller_id,
        COUNT(DISTINCT i.order_id) as total_orders,
        SUM(d.is_late) as late_orders
    FROM order_items i
    JOIN OrderDelivery d ON i.order_id = d.order_id
    GROUP BY i.seller_id
)
SELECT 
    seller_id,
    total_orders,
    late_orders,
    ROUND((late_orders::NUMERIC / total_orders) * 100, 2) AS late_pct
FROM SellerDeliveries
WHERE total_orders > 50
ORDER BY late_pct DESC
LIMIT 10;


/* ============================================================================
   5. OPERATIONS & CUSTOMER EXPERIENCE
   ============================================================================ */

-- Average delivery days by state (excludes time-travel anomalies)
SELECT 
    c.customer_state,
    COUNT(o.order_id) AS orders_delivered,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400)::numeric, 1) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_purchase_timestamp 
GROUP BY c.customer_state
HAVING COUNT(o.order_id) > 100
ORDER BY avg_delivery_days DESC;


-- Review score degradation associated with late deliveries
WITH DeliveryStatus AS (
    SELECT 
        order_id,
        CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late' ELSE 'On-Time' END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
)
SELECT 
    d.delivery_status,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM DeliveryStatus d
JOIN order_reviews r ON d.order_id = r.order_id
GROUP BY d.delivery_status;


-- Review behavior: percentage of ratings submitted with empty comments
SELECT 
    review_score,
    COUNT(review_id) AS total_reviews,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS empty_comments,
    ROUND((SUM(CASE WHEN review_comment_message IS NULL THEN 1.0 ELSE 0.0 END) / COUNT(review_id)) * 100, 2) AS empty_comment_pct
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;


-- Monthly order cancellation rate
SELECT 
    TO_CHAR(DATE_TRUNC('month', order_purchase_timestamp), 'YYYY-MM') AS order_month,
    COUNT(order_id) as total_orders,
    SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END) AS canceled_orders,
    ROUND((SUM(CASE WHEN order_status = 'canceled' THEN 1.0 ELSE 0.0 END) / COUNT(order_id)) * 100, 2) AS cancellation_rate_pct
FROM orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY order_month;


-- Regional logistics inefficiency: freight burden ratio by state

WITH StateCosts AS (
    SELECT 
        c.customer_state,
        SUM(i.price) AS total_state_merchandise,
        SUM(i.freight_value) AS total_state_freight
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT 
    customer_state,
    ROUND(total_state_merchandise, 2) AS merchandise_value,
    ROUND(total_state_freight, 2) AS freight_value,
    ROUND((total_state_freight / NULLIF(total_state_merchandise, 0)) * 100, 2) AS freight_burden_pct
FROM StateCosts
ORDER BY freight_burden_pct DESC;
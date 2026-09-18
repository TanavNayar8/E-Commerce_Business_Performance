/* ============================================================================
   1. BUSINESS PERFORMANCE
   ============================================================================ */

-- Q1: Monthly Cash Collected vs. Order Volume
-- Business Question: What is our monthly trend for total cash collected and successful order volume?
-- Business Value: Assesses macroeconomic growth and seasonality of the marketplace using top-line cash flow metrics.
WITH ValidOrders AS (
    -- Exclude canceled/unavailable orders but keep all valid checkout events
    SELECT order_id, DATE_TRUNC('month', order_purchase_timestamp) AS order_month
    FROM orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
),
OrderPayments AS (
    -- Pre-aggregate payments to the order level to avoid double-counting split payments
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


-- Q2: Month-over-Month Cash Collected Growth
-- Business Question: How is our cash collected growing month-over-month in percentage terms?
-- Business Value: MoM growth is the primary metric for startup and marketplace valuation.
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
    -- Use LAG to pull the previous month's cash onto the same row for easy math
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


-- Q3: Cumulative (Running) Total of Cash Collected
-- Business Question: What is our running total of cash collected over the dataset's history?
-- Business Value: Shows total historical transaction volume processed by the platform.
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
    -- Window function to create a running sum down the rows
    SUM(monthly_cash_collected) OVER(ORDER BY order_month) AS cumulative_cash_collected
FROM MonthlyCash
ORDER BY order_month;


-- Q4: Order Value by Maximum Payment Installments
-- Business Question: How does order value vary by the maximum number of payment installments used in an order?
-- Business Value: Informs financing and buy-now-pay-later (BNPL) strategies by revealing if longer financing terms are associated with larger purchases.
WITH OrderTotals AS (
    -- Get the longest financing term used for the order, and the total value
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

-- Q5: Top 10 Categories by Merchandise Value
-- Business Question: Which product categories generate the highest merchandise value?
-- Business Value: Dictates marketing spend, inventory strategy, and seller acquisition targeting for key verticals.
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


-- Q6: Categories with the Highest Freight-to-Merchandise Ratio
-- Business Question: Which categories are the most inefficient to ship relative to their item value?
-- Business Value: High shipping costs relative to item price cause cart abandonment. Identifies categories needing logistics optimization.
SELECT 
    p.product_category_name_english AS category,
    COUNT(i.order_item_id) AS items_sold,
    ROUND(AVG(i.price), 2) AS avg_item_value,
    ROUND(AVG(i.freight_value), 2) AS avg_freight_cost,
    -- NULLIF prevents division-by-zero errors if average price evaluates to 0
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


-- Q7: Top 3 Products within the Top 5 Categories (Top-N within Groups)
-- Business Question: What are the top 3 best-selling specific products within our 5 largest categories?
-- Business Value: Operational focus on hero SKUs within key verticals for inventory and promotion management.
WITH CategoryRank AS (
    -- Find the top 5 categories globally
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
    -- Rank products 1 through N *within* each of those top 5 categories
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




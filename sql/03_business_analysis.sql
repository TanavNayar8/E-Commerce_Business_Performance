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
-- Check 1: Did all rows import? 

SELECT 'Orders' as table_name, COUNT(*) as row_count FROM orders
UNION ALL
SELECT 'Items', COUNT(*) FROM order_items
UNION ALL
SELECT 'Customers', COUNT(*) FROM customers;

-- Check 2: Are there any orphan order items? (Items linked to an order that doesn't exist)
SELECT COUNT(i.order_id) 

FROM order_items i
LEFT JOIN orders o ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

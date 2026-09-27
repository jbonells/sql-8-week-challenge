/* --------------------
   Case Study Questions
   --------------------*/

-- A. High Level Sales Analysis

-- 1. What was the total quantity sold for all products?
SELECT
	SUM(qty) AS total_quantity_sold
FROM sales;

-- 2. What is the total generated revenue for all products before discounts?
SELECT
	SUM(qty * price) AS total_revenue
FROM sales;

-- 3. What was the total discount amount for all products?
SELECT
	ROUND(SUM(qty * price * discount / 100.0), 2) AS total_discount
FROM sales;


-- B. Transaction Analysis

-- 1. How many unique transactions were there?
SELECT
	COUNT(DISTINCT txn_id) AS unique_transactions
FROM sales;

-- 2. What is the average unique products purchased in each transaction?
SELECT
	ROUND(AVG(unique_products), 2) AS average_unique_products
FROM (
	SELECT
		txn_id,
		COUNT(DISTINCT prod_id) AS unique_products
	FROM sales
	GROUP BY txn_id
) AS txn_products;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH revenue AS(
	SELECT
		txn_id,
		SUM(qty * price) AS total_revenue
	FROM sales
	GROUP BY txn_id
)

SELECT 
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue) AS percentile_25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) AS percentile_50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) AS percentile_75
FROM revenue;

-- 4. What is the average discount value per transaction?
WITH discount AS(
	SELECT
		txn_id,
		SUM(qty * price * discount / 100.0) AS total_discount
	FROM sales
	GROUP BY txn_id
)

SELECT
	ROUND(AVG(total_discount), 2) AS average_discount
FROM discount

-- 5. What is the percentage split of all transactions for members vs non-members?
WITH transactions AS(
	SELECT
		COUNT(DISTINCT txn_id) FILTER (WHERE member = 't') AS members,
		COUNT(DISTINCT txn_id) FILTER (WHERE member = 'f') AS non_members,
		COUNT(DISTINCT txn_id) AS total
	FROM sales
)

SELECT
	ROUND((100.0 * members / total), 2) AS members_percentage,
	ROUND((100.0 * non_members / total), 2) AS non_members_percentage
FROM transactions;

-- 6. What is the average revenue for member transactions and non-member transactions?
WITH transactions AS (
	SELECT
		txn_id,
		member,
		SUM(qty * price) AS total_revenue
	FROM sales
	GROUP BY txn_id, member
)
SELECT
	ROUND(AVG(total_revenue) FILTER (WHERE member = 't'), 2) AS average_members,
	ROUND(AVG(total_revenue) FILTER (WHERE member = 'f'), 2) AS average_non_members
FROM transactions;


-- C. Product Analysis

-- 1. What are the top 3 products by total revenue before discount?
SELECT
	pd.product_name,
	SUM(s.qty * s.price) AS total_revenue
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY total_revenue DESC
LIMIT 3;

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT
	pd.segment_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS total_discount
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.segment_name
ORDER BY pd.segment_name;

-- 3. What is the top selling product for each segment?
WITH top_selling AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY pd.segment_name ORDER BY SUM(s.qty) DESC) AS ranking,
		pd.segment_name,
		pd.product_name,
		SUM(s.qty) AS total_quantity    
	FROM sales s
	INNER JOIN product_details pd
		ON s.prod_id = pd.product_id
	GROUP BY pd.segment_name, pd.product_name
)

SELECT
	segment_name,
	product_name,
	total_quantity
FROM top_selling
WHERE ranking = 1
ORDER BY segment_name;

-- 4. What is the total quantity, revenue and discount for each category?
SELECT
	pd.category_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS total_discount
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;

-- 5. What is the top selling product for each category?
WITH top_selling AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY pd.category_name ORDER BY SUM(s.qty) DESC) AS ranking,
		pd.category_name,
		pd.product_name,
		SUM(s.qty) AS total_quantity    
	FROM sales s
	INNER JOIN product_details pd
		ON s.prod_id = pd.product_id
	GROUP BY pd.category_name, pd.product_name
)

SELECT
	category_name,
	product_name,
	total_quantity
FROM top_selling
WHERE ranking = 1
ORDER BY category_name;

-- 6. What is the percentage split of revenue by product for each segment?
SELECT
	pd.segment_name,
	pd.product_name,
	ROUND(
		100.0 * SUM(s.qty * s.price)
		/ SUM(SUM(s.qty * s.price)) OVER (PARTITION BY pd.segment_name),
		2
	) AS revenue_percentage
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.segment_name, pd.product_name
ORDER BY pd.segment_name, revenue_percentage DESC;

-- 7. What is the percentage split of revenue by segment for each category?
SELECT
	pd.category_name,
	pd.segment_name,
	ROUND(
		100.0 * SUM(s.qty * s.price)
		/ SUM(SUM(s.qty * s.price)) OVER (PARTITION BY pd.category_name),
		2
	) AS revenue_percentage
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name, pd.segment_name
ORDER BY pd.category_name, revenue_percentage DESC;

-- 8. What is the percentage split of total revenue by category?
SELECT
	pd.category_name,
	ROUND(
		100.0 * SUM(s.qty * s.price)
		/ SUM(SUM(s.qty * s.price)) OVER (),
		2
	) AS revenue_percentage
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;

-- 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
WITH product_penetration AS (
	SELECT
		DISTINCT prod_id,
		COUNT(DISTINCT txn_id) AS product_penetration
	FROM sales
	GROUP BY prod_id
),
total_transactions AS (
	SELECT
		COUNT(DISTINCT txn_id) AS total_transaction
	FROM sales
)

SELECT
	pd.product_name,
	ROUND(100.0 * pp.product_penetration / tt.total_transaction, 2) AS penetration_percentage
FROM product_penetration pp
CROSS JOIN total_transactions tt
INNER JOIN product_details pd
	ON pp.prod_id = pd.product_id
ORDER BY penetration_percentage DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH product_transactions AS (
	SELECT
		txn_id,
		prod_id
	FROM sales
	GROUP BY txn_id, prod_id
),
all_combinations AS (
	SELECT
		pt1.txn_id,
		pt1.prod_id AS p1,
		pt2.prod_id AS p2,
		pt3.prod_id AS p3
	FROM product_transactions pt1
	INNER JOIN product_transactions pt2
		ON pt1.txn_id = pt2.txn_id
		AND pt1.prod_id < pt2.prod_id
	INNER JOIN product_transactions pt3
		ON pt2.txn_id = pt3.txn_id
		AND pt2.prod_id < pt3.prod_id
)

SELECT
    pd1.product_name AS product_1,
    pd2.product_name AS product_2,
    pd3.product_name AS product_3,
    COUNT(DISTINCT ac.txn_id) AS combinations
FROM all_combinations ac
INNER JOIN product_details pd1
	ON ac.p1 = pd1.product_id
INNER JOIN product_details pd2
	ON ac.p2 = pd2.product_id
INNER JOIN product_details pd3
	ON ac.p3 = pd3.product_id
GROUP BY pd1.product_name, pd2.product_name, pd3.product_name
ORDER BY combinations DESC
LIMIT 1;


-- D. Reporting Challenge
-- Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
-- Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.
-- He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).
-- Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks.

-- 1. What are the top 3 products by total revenue before discount?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
)

SELECT
	pd.product_name,
	SUM(sm.qty * sm.price) AS total_revenue
FROM sales_monthly sm
INNER JOIN product_details pd
	ON sm.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY total_revenue DESC
LIMIT 3;

-- 2. What is the total quantity, revenue and discount for each segment?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
)

SELECT
	pd.segment_name,
    SUM(sm.qty) AS total_quantity,
    SUM(sm.qty * sm.price) AS total_revenue,
    ROUND(SUM(sm.qty * sm.price * sm.discount / 100.0), 2) AS total_discount
FROM sales_monthly sm
INNER JOIN product_details pd
	ON sm.prod_id = pd.product_id
GROUP BY pd.segment_name
ORDER BY pd.segment_name;

-- 3. What is the top selling product for each segment?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
),
top_selling AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY pd.segment_name ORDER BY SUM(sm.qty) DESC) AS ranking,
		pd.segment_name,
		pd.product_name,
		SUM(sm.qty) AS total_quantity    
	FROM sales_monthly sm
	INNER JOIN product_details pd
		ON sm.prod_id = pd.product_id
	GROUP BY pd.segment_name, pd.product_name
)

SELECT
	segment_name,
	product_name,
	total_quantity
FROM top_selling
WHERE ranking = 1
ORDER BY segment_name;

-- 4. What is the total quantity, revenue and discount for each category?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
)

SELECT
	pd.category_name,
    SUM(sm.qty) AS total_quantity,
    SUM(sm.qty * sm.price) AS total_revenue,
    ROUND(SUM(sm.qty * sm.price * sm.discount / 100.0), 2) AS total_discount
FROM sales_monthly sm
INNER JOIN product_details pd
	ON sm.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;

-- 5. What is the top selling product for each category?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
),
top_selling AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY pd.category_name ORDER BY SUM(sm.qty) DESC) AS ranking,
		pd.category_name,
		pd.product_name,
		SUM(sm.qty) AS total_quantity    
	FROM sales_monthly sm
	INNER JOIN product_details pd
		ON sm.prod_id = pd.product_id
	GROUP BY pd.category_name, pd.product_name
)

SELECT
	category_name,
	product_name,
	total_quantity
FROM top_selling
WHERE ranking = 1
ORDER BY category_name;

-- 6. What is the percentage split of revenue by product for each segment?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
)

SELECT
	pd.segment_name,
	pd.product_name,
	ROUND(
		100.0 * SUM(sm.qty * sm.price)
		/ SUM(SUM(sm.qty * sm.price)) OVER (PARTITION BY pd.segment_name),
		2
	) AS revenue_percentage
FROM sales_monthly sm
INNER JOIN product_details pd
	ON sm.prod_id = pd.product_id
GROUP BY pd.segment_name, pd.product_name
ORDER BY pd.segment_name, revenue_percentage DESC;

-- 7. What is the percentage split of revenue by segment for each category?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
)

SELECT
	pd.category_name,
	pd.segment_name,
	ROUND(
		100.0 * SUM(sm.qty * sm.price)
		/ SUM(SUM(sm.qty * sm.price)) OVER (PARTITION BY pd.category_name),
		2
	) AS revenue_percentage
FROM sales_monthly sm
INNER JOIN product_details pd
	ON sm.prod_id = pd.product_id
GROUP BY pd.category_name, pd.segment_name
ORDER BY pd.category_name, revenue_percentage DESC;

-- 8. What is the percentage split of total revenue by category?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
)

SELECT
	pd.category_name,
	ROUND(
		100.0 * SUM(sm.qty * sm.price)
		/ SUM(SUM(sm.qty * sm.price)) OVER (),
		2
	) AS revenue_percentage
FROM sales_monthly sm
INNER JOIN product_details pd
	ON sm.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;

-- 9. What is the total transaction “penetration” for each product?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
),
product_penetration AS (
	SELECT
		DISTINCT prod_id,
		COUNT(DISTINCT txn_id) AS product_penetration
	FROM sales_monthly
	GROUP BY prod_id
),
total_transactions AS (
	SELECT
		COUNT(DISTINCT txn_id) AS total_transaction
	FROM sales_monthly
)

SELECT
	pd.product_name,
	ROUND(100.0 * pp.product_penetration / tt.total_transaction, 2) AS penetration_percentage
FROM product_penetration pp
CROSS JOIN total_transactions tt
INNER JOIN product_details pd
	ON pp.prod_id = pd.product_id
ORDER BY penetration_percentage DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),
sales_monthly AS (
	SELECT
		s.*
	FROM sales s
	CROSS JOIN report_month rm
	WHERE s.start_txn_time >= rm.month_start
		AND s.start_txn_time < rm.month_start + INTERVAL '1 month'
),
product_transactions AS (
	SELECT
		txn_id,
		prod_id
	FROM sales_monthly
	GROUP BY txn_id, prod_id
),
all_combinations AS (
	SELECT
		pt1.txn_id,
		pt1.prod_id AS p1,
		pt2.prod_id AS p2,
		pt3.prod_id AS p3
	FROM product_transactions pt1
	INNER JOIN product_transactions pt2
		ON pt1.txn_id = pt2.txn_id
		AND pt1.prod_id < pt2.prod_id
	INNER JOIN product_transactions pt3
		ON pt2.txn_id = pt3.txn_id
		AND pt2.prod_id < pt3.prod_id
)

SELECT
    pd1.product_name AS product_1,
    pd2.product_name AS product_2,
    pd3.product_name AS product_3,
    COUNT(DISTINCT ac.txn_id) AS combinations
FROM all_combinations ac
INNER JOIN product_details pd1
	ON ac.p1 = pd1.product_id
INNER JOIN product_details pd2
	ON ac.p2 = pd2.product_id
INNER JOIN product_details pd3
	ON ac.p3 = pd3.product_id
GROUP BY pd1.product_name, pd2.product_name, pd3.product_name
ORDER BY combinations DESC
LIMIT 1;

-- E. Bonus Challenge
-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
-- Hint: you may want to consider using a recursive CTE to solve this problem!
WITH RECURSIVE hierarchy_path AS (
	SELECT
		id,
		parent_id,
		level_name,
		id AS category_id,
		level_text AS category_name,
		CAST(NULL AS INTEGER) AS segment_id,
		CAST(NULL AS VARCHAR) AS segment_name,
		CAST(NULL AS INTEGER) AS style_id,
		CAST(NULL AS VARCHAR) AS style_name
	FROM product_hierarchy
	WHERE parent_id IS NULL

    UNION ALL

    SELECT
		ph.id,
		ph.parent_id,
		ph.level_name,
		hp.category_id,
		hp.category_name,
		CASE WHEN ph.level_name = 'Segment' THEN ph.id ELSE hp.segment_id END,
		CASE WHEN ph.level_name = 'Segment' THEN ph.level_text ELSE hp.segment_name END,
		CASE WHEN ph.level_name = 'Style' THEN ph.id ELSE hp.style_id END,
		CASE WHEN ph.level_name = 'Style' THEN ph.level_text ELSE hp.style_name END
    FROM product_hierarchy ph
    INNER JOIN hierarchy_path hp
		ON ph.parent_id = hp.id
)
SELECT
	pp.product_id,
	pp.price,
	CONCAT(hp.style_name, ' ', hp.segment_name, ' - ', hp.category_name) AS product_name,
	hp.category_id,
	hp.segment_id,
	hp.style_id,
	hp.category_name,
	hp.segment_name,
	hp.style_name
FROM hierarchy_path hp
INNER JOIN product_prices pp
	ON hp.id = pp.id
WHERE hp.level_name = 'Style'
ORDER BY hp.category_id, hp.segment_id, hp.style_id;
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
	ROUND((100.0 * members / total), 2) AS percentage_members,
	ROUND((100.0 * non_members / total), 2) AS percentage_non_members
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
	) AS percentage_of_revenue
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.segment_name, pd.product_name
ORDER BY pd.segment_name, percentage_of_revenue DESC;

-- 7. What is the percentage split of revenue by segment for each category?
SELECT
	pd.category_name,
	pd.segment_name,
	ROUND(
		100.0 * SUM(s.qty * s.price)
		/ SUM(SUM(s.qty * s.price)) OVER (PARTITION BY pd.category_name),
		2
	) AS percentage_of_revenue
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name, pd.segment_name
ORDER BY pd.category_name, percentage_of_revenue DESC;

-- 8. What is the percentage split of total revenue by category?
SELECT
	pd.category_name,
	ROUND(
		100.0 * SUM(s.qty * s.price)
		/ SUM(SUM(s.qty * s.price)) OVER (),
		2
	) AS percentage_of_revenue
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;

-- 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)


-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

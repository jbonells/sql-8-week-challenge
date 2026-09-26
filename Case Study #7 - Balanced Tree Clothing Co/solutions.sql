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
	ROUND(AVG(unique_products), 2) AS avg_unique_products
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
	ROUND(AVG(total_discount), 2) AS avg_discount
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
	ROUND(AVG(total_revenue) FILTER (WHERE member = 't'), 2) AS members_average,
	ROUND(AVG(total_revenue) FILTER (WHERE member = 'f'), 2) AS non_members_average
FROM transactions;

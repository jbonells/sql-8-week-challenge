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


-- 4. What is the average discount value per transaction?


-- 5. What is the percentage split of all transactions for members vs non-members?


-- 6. What is the average revenue for member transactions and non-member transactions?

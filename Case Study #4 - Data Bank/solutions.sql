/* --------------------
   Case Study Questions
   --------------------*/

-- A. Customer Nodes Exploration

-- 1. How many unique nodes are there on the Data Bank system?
SELECT
	COUNT(DISTINCT node_id) AS nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT
	r.region_name,
    COUNT(DISTINCT cn.node_id) AS nodes
FROM customer_nodes cn
INNER JOIN regions r
	ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

-- 3. How many customers are allocated to each region?
SELECT
	r.region_name,
    COUNT(DISTINCT cn.customer_id) AS customers
FROM customer_nodes cn
INNER JOIN regions r
	ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

-- 4. How many days on average are customers reallocated to a different node?


-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?



-- B. Customer Transactions
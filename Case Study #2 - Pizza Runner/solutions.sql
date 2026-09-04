/* --------------------
   Case Study Questions
   --------------------*/

-- A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT
	s.customer_id,
	SUM(m.price) AS total_sales
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id ASC;

-- 2. How many unique customer orders were made?

-- 3. How many successful orders were delivered by each runner?

-- 4. How many of each type of pizza was delivered?

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

-- 6. What was the maximum number of pizzas delivered in a single order?

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

-- 8. How many pizzas were delivered that had both exclusions and extras?

-- 9. What was the total volume of pizzas ordered for each hour of the day?

-- 10. What was the volume of orders for each day of the week?

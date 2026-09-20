/* ------------------------------
   Data Cleaning & Transformation
   ------------------------------*/

-- Table: customer_orders
CREATE TEMP TABLE t_customer_orders AS
SELECT
    order_id,
    customer_id,
    pizza_id,
    NULLIF(NULLIF(exclusions, 'null'), '') AS exclusions,
    NULLIF(NULLIF(extras, 'null'), '') AS extras,
    order_time
FROM customer_orders;

-- Table: runner_orders
CREATE TEMP TABLE t_runner_orders AS
SELECT
    order_id,
    runner_id,
    NULLIF(NULLIF(pickup_time, 'null'), '')::TIMESTAMP AS pickup_time,
    NULLIF(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g'), '')::NUMERIC AS distance,
    NULLIF(REGEXP_REPLACE(duration, '[^0-9]', '', 'g'), '')::INTEGER AS duration,
    NULLIF(NULLIF(cancellation, 'null'), '') AS cancellation
FROM runner_orders;

-- NOTE: I have added both temp tables to schema.sql to run the solution easily.


/* --------------------
   Case Study Questions
   --------------------*/

-- A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT
	COUNT(*) AS pizza_order_count
FROM t_customer_orders;

-- 2. How many unique customer orders were made?
SELECT
	COUNT(DISTINCT order_id) AS unique_order_count
FROM t_customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT
	runner_id,
	COUNT(order_id) AS successful_orders
FROM t_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT
	pn.pizza_name,
    COUNT(co.pizza_id) AS pizzas_delivered
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
INNER JOIN pizza_names pn
	ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	customer_id,
    SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS meat_lovers,
    SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM t_customer_orders
GROUP BY customer_id
ORDER BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT
	co.order_id,
	COUNT(co.pizza_id) AS pizzas_delivered
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.order_id
ORDER BY pizzas_delivered DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	co.customer_id,
    SUM(CASE WHEN co.exclusions IS NOT NULL OR co.extras IS NOT NULL THEN 1 ELSE 0 END) AS change,
    SUM(CASE WHEN co.exclusions IS NULL AND co.extras IS NULL THEN 1 ELSE 0 END) AS no_change
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
    SUM(CASE WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 1 ELSE 0 END) AS changed_pizza
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(order_id) AS total_pizzas
FROM t_customer_orders
GROUP BY order_hour
ORDER BY order_hour;

-- 10. What was the volume of orders for each day of the week?
SELECT
    TO_CHAR(order_time, 'FMDay') AS day_of_week,
    COUNT(DISTINCT order_id) AS total_orders
FROM t_customer_orders
GROUP BY TO_CHAR(order_time, 'FMDay'), EXTRACT(ISODOW FROM order_time)
ORDER BY EXTRACT(ISODOW FROM order_time);


-- B. Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    (FLOOR(DATE_PART('day', registration_date - TIMESTAMP '2021-01-01') / 7))::INTEGER + 1 AS registration_week,
    COUNT(runner_id) AS runner_signup
FROM runners
GROUP BY registration_week
ORDER BY registration_week;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH order_time AS (
	SELECT 
		co.order_id,
  		ro.runner_id,
		co.order_time,
  		ro.pickup_time
	FROM t_customer_orders co
	INNER JOIN t_runner_orders ro
		ON co.order_id = ro.order_id
  	WHERE ro.cancellation IS NULL
  	GROUP BY co.order_id, ro.runner_id, co.order_time, ro.pickup_time
)

SELECT
	runner_id,
    ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60)::NUMERIC, 2) AS average_time
FROM order_time
GROUP BY runner_id
ORDER BY runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH order_time AS (
	SELECT 
		co.order_id,
  		COUNT(co.order_id) AS num_pizzas,
		co.order_time,
  		ro.pickup_time
	FROM t_customer_orders co
	INNER JOIN t_runner_orders ro
		ON co.order_id = ro.order_id
  	WHERE ro.cancellation IS NULL
  	GROUP BY co.order_id, co.order_time, ro.pickup_time
)

SELECT
    num_pizzas,
    ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time))::NUMERIC / 60), 2) AS average_time,
    ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time))::NUMERIC / 60) / num_pizzas, 2) AS average_time_per_pizza
FROM order_time
GROUP BY num_pizzas
ORDER BY num_pizzas;

-- 4. What was the average distance travelled for each customer?
WITH order_distances AS (
    SELECT DISTINCT
        co.order_id,
        co.customer_id,
        ro.distance
    FROM t_customer_orders co
    INNER JOIN t_runner_orders ro
        ON co.order_id = ro.order_id
    WHERE ro.distance IS NOT NULL
)

SELECT 
    customer_id,
    ROUND(AVG(distance), 2) AS average_distance
FROM order_distances
GROUP BY customer_id
ORDER BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
    MAX(duration) AS longest_delivery,
	MIN(duration) AS shortest_delivery,
	MAX(duration) - MIN(duration) AS difference
FROM t_runner_orders
WHERE duration IS NOT NULL;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    runner_id,
    order_id,
    pickup_time,
    ROUND((distance / duration) * 60, 2) AS speed_kmh
FROM t_runner_orders
WHERE duration IS NOT NULL AND distance IS NOT NULL
ORDER BY runner_id, pickup_time;

-- 7. What is the successful delivery percentage for each runner?
SELECT 
    runner_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE cancellation IS NULL) / COUNT(*), 2) AS successful_delivery_percentage
FROM t_runner_orders
GROUP BY runner_id
ORDER BY runner_id;


-- C. Ingredient Optimisation

-- 1. What are the standard ingredients for each pizza?
WITH toppings AS (
    SELECT
        pn.pizza_name,
        topping_id_split::INTEGER AS topping_id
    FROM pizza_recipes pr
    INNER JOIN pizza_names pn
        ON pr.pizza_id = pn.pizza_id
    CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(pr.toppings, '[,\s]+') AS t(topping_id_split)
)

SELECT
	t.pizza_name,
	STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_id) AS standard_ingredients
FROM toppings t
INNER JOIN pizza_toppings pt
	ON t.topping_id = pt.topping_id
GROUP BY t.pizza_name
ORDER BY t.pizza_name;

-- 2. What was the most commonly added extra?
WITH extras AS (
    SELECT
        pizza_id,
  		REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+')::INTEGER AS topping_id
    FROM t_customer_orders
    WHERE extras IS NOT NULL
)

SELECT
    pt.topping_name,
    COUNT(*) AS times_added
FROM extras e
INNER JOIN pizza_toppings pt
    ON e.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY times_added DESC
LIMIT 1;

-- 3. What was the most common exclusion?
WITH exclusions AS (
    SELECT
        pizza_id,
  		REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+')::INTEGER AS topping_id
    FROM t_customer_orders
    WHERE exclusions IS NOT NULL
)

SELECT
    pt.topping_name,
    COUNT(*) AS times_removed
FROM exclusions e
INNER JOIN pizza_toppings pt
    ON e.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY times_removed DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--    - Meat Lovers
--    - Meat Lovers - Exclude Beef
--    - Meat Lovers - Extra Bacon
--    - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH ordered_pizzas AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY order_id) AS record_id,
		order_id,
        pizza_id,
        exclusions,
        extras
    FROM t_customer_orders
),
exclusions AS (
    SELECT 
        op.record_id,
        STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_id) AS exclusions
    FROM ordered_pizzas op
	CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+') AS topping
    INNER JOIN pizza_toppings pt
		ON topping::INTEGER = pt.topping_id
    WHERE op.exclusions IS NOT NULL
    GROUP BY op.record_id
),
additions AS (
    SELECT 
        op.record_id,
        STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_id) AS additions
    FROM ordered_pizzas op
	CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+') AS topping
    INNER JOIN pizza_toppings pt
        ON topping::INTEGER = pt.topping_id
    WHERE op.extras IS NOT NULL
    GROUP BY op.record_id
)

SELECT
    op.order_id,
    pn.pizza_name
		|| COALESCE(' - Exclude ' || e.exclusions, '')
		|| COALESCE(' - Extra ' || a.additions, '') AS pizza_ordered
FROM ordered_pizzas op
INNER JOIN pizza_names pn
	ON op.pizza_id = pn.pizza_id
LEFT JOIN exclusions e
	ON op.record_id = e.record_id
LEFT JOIN additions a
	ON op.record_id = a.record_id
ORDER BY op.record_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--    For example: "Meat Lovers: 2xBacon, Beef, ..., Salami"
WITH ordered_pizzas AS (
    SELECT 
		ROW_NUMBER() OVER (ORDER BY order_id) AS record_id,
		order_id,
		pizza_id,
		extras,
		exclusions		
    FROM t_customer_orders
),
ingredient_list AS (
	(
		SELECT
			op.record_id,
			base_id::INTEGER AS topping_id
		FROM ordered_pizzas op
		INNER JOIN pizza_recipes pr
			ON op.pizza_id = pr.pizza_id
		CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(pr.toppings, '[,\s]+') AS base_id
		UNION ALL
		SELECT
			op.record_id,
			extra_id::INTEGER AS topping_id
		FROM ordered_pizzas op
		CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(op.extras, '[,\s]+') AS extra_id
		WHERE op.extras IS NOT NULL
	)
	EXCEPT ALL
	SELECT
		op.record_id,
  		excluded_id::INTEGER AS topping_id
	FROM ordered_pizzas op
  	CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(op.exclusions, '[,\s]+') AS excluded_id
	WHERE op.exclusions IS NOT NULL	
),
ingredient_counts AS (
    SELECT
		il.record_id,
		pt.topping_name,
		COUNT(*) AS count
    FROM ingredient_list il
	INNER JOIN pizza_toppings pt
		ON il.topping_id = pt.topping_id
    GROUP BY il.record_id, pt.topping_name
)

SELECT
	op.order_id,
	pn.pizza_name || ': ' || STRING_AGG(
		CASE
			WHEN ic.count > 1 THEN ic.count || 'x' || ic.topping_name
			ELSE ic.topping_name
		END,
		', '
		ORDER BY LOWER(ic.topping_name)
	) AS ingredient_list
FROM ingredient_counts ic
INNER JOIN ordered_pizzas op
	ON ic.record_id = op.record_id
INNER JOIN pizza_names pn
	ON op.pizza_id = pn.pizza_id
GROUP BY op.record_id, op.order_id, pn.pizza_name
ORDER BY op.record_id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH delivered_pizzas AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY co.order_id) AS record_id,
        co.order_id,
        co.pizza_id,
        co.exclusions,
        co.extras
    FROM t_customer_orders co
    INNER JOIN t_runner_orders ro
        ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL
),
ingredient_list AS (
    (
		SELECT
			dp.record_id,
			base_id::INTEGER AS topping_id
		FROM delivered_pizzas dp
		INNER JOIN pizza_recipes pr
			ON dp.pizza_id = pr.pizza_id
		CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(pr.toppings, '[,\s]+') AS base_id
		
		UNION ALL
		
		SELECT
			dp.record_id,
			extra_id::INTEGER AS topping_id
		FROM delivered_pizzas dp
		CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(dp.extras, '[,\s]+') AS extra_id
		WHERE dp.extras IS NOT NULL
    )
    EXCEPT ALL
    SELECT
		dp.record_id,
		excluded_id::INTEGER AS topping_id
    FROM delivered_pizzas dp
    CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(dp.exclusions, '[,\s]+') AS excluded_id
    WHERE dp.exclusions IS NOT NULL
)

SELECT
    pt.topping_name,
    COUNT(*) AS quantity
FROM ingredient_list il
INNER JOIN pizza_toppings pt
	ON il.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY quantity DESC;


-- D. Pricing and Ratings

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT
    SUM(
		CASE
			WHEN co.pizza_id = 1 THEN 12
			ELSE 10
		END
	) AS revenue
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
	AND ro.cancellation IS NULL

-- 2. What if there was an additional $1 charge for any pizza extras?
--    Add cheese is $1 extra
SELECT
    SUM(
        CASE
            WHEN co.pizza_id = 1 THEN 12 
            ELSE 10 
        END 
        + COALESCE(cardinality(string_to_array(NULLIF(TRIM(co.extras), ''), ',')), 0)
    ) AS revenue
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
    ON co.order_id = ro.order_id
    AND ro.cancellation IS NULL;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
    order_id INTEGER PRIMARY KEY,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5)
);
INSERT INTO runner_ratings (order_id, rating) VALUES
(1, 5),
(2, 4),
(3, 5),
(4, 3),
(5, 5),
(7, 4),
(8, 5),
(10, 2);

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--    - customer_id
--    - order_id
--    - runner_id
--    - rating
--    - order_time
--    - pickup_time
--    - Time between order and pickup
--    - Delivery duration
--    - Average speed
--    - Total number of pizzas
SELECT
    co.customer_id,
    co.order_id,
    ro.runner_id,
    rr.rating,
    co.order_time,
    ro.pickup_time,
    ROUND(EXTRACT(EPOCH FROM (ro.pickup_time - co.order_time)) / 60)::INTEGER AS time_difference,
    ro.duration,
    ROUND((ro.distance / ro.duration) * 60, 2) AS average_speed,
    COUNT(co.pizza_id) OVER (PARTITION BY co.order_id) AS total_pizzas
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
    AND ro.cancellation IS NULL
LEFT JOIN runner_ratings rr
	ON co.order_id = rr.order_id

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH total_payouts AS (
    SELECT
		SUM(distance) * 0.30 AS payout
    FROM t_runner_orders
    WHERE cancellation IS NULL
),
total_revenue AS (
	SELECT
		SUM(
			CASE
				WHEN co.pizza_id = 1 THEN 12
				ELSE 10
			END
		) AS revenue
	FROM t_customer_orders co
	INNER JOIN t_runner_orders ro
		ON co.order_id = ro.order_id
		AND ro.cancellation IS NULL
)

SELECT
    ROUND((tr.revenue - tp.payout), 2) AS net_profit
FROM total_revenue tr, total_payouts tp;

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
	co.pizza_id,
    COUNT(co.pizza_id) AS pizzas_delivered
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id AND ro.cancellation IS NULL
GROUP BY co.pizza_id
ORDER BY co.pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	co.customer_id,
    pn.pizza_name,
    COUNT(co.pizza_id) AS pizzas_ordered
FROM t_customer_orders co
INNER JOIN pizza_names pn
	ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name
ORDER BY co.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
WITH orders AS (
	SELECT
		co.order_id,
		COUNT(co.pizza_id) AS pizzas_delivered
	FROM t_customer_orders co
	INNER JOIN t_runner_orders ro
		ON co.order_id = ro.order_id AND ro.cancellation IS NULL
	GROUP BY co.order_id
)

SELECT
	MAX(pizzas_delivered) AS max_pizzas_delivered
FROM orders

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	co.customer_id,
    SUM(
    	CASE WHEN co.exclusions IS NOT NULL OR co.extras IS NOT NULL THEN 1
    	ELSE 0
    END) AS change,
    SUM(
    	CASE WHEN co.exclusions IS NULL AND co.extras IS NULL THEN 1
    	ELSE 0
    END) AS no_change
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id AND ro.cancellation IS NULL
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
    SUM(
    	CASE WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 1
    	ELSE 0
    END) AS changed_pizza
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id AND ro.cancellation IS NULL;

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
    COUNT(order_id) AS total_pizzas
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
  		AND ro.cancellation IS NULL
  	GROUP BY co.order_id, ro.runner_id, co.order_time, ro.pickup_time
)

SELECT
	runner_id,
    ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60))::INTEGER AS average_time
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
  		AND ro.cancellation IS NULL
  	GROUP BY co.order_id, co.order_time, ro.pickup_time
)

SELECT
	num_pizzas,
    ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60))::INTEGER AS average_time
FROM order_time
GROUP BY num_pizzas
ORDER BY num_pizzas;

-- 4. What was the average distance travelled for each customer?
WITH order_distances AS (
    SELECT DISTINCT
        co.customer_id,
        ro.order_id,
        ro.distance
    FROM t_customer_orders co
    INNER JOIN t_runner_orders ro
        ON co.order_id = ro.order_id
        AND ro.distance IS NOT NULL
)

SELECT 
    customer_id,
    ROUND(AVG(distance), 2) AS average_distance
FROM order_distances
GROUP BY customer_id
ORDER BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT 
    MAX(duration) - MIN(duration) AS delivery_time_difference
FROM t_runner_orders
WHERE duration IS NOT NULL;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
    runner_id,
    order_id,
    ROUND((distance / duration) * 60, 2) AS speed_kmh
FROM t_runner_orders
WHERE duration IS NOT NULL AND distance IS NOT NULL
ORDER BY runner_id, order_id;

-- 7. What is the successful delivery percentage for each runner?
SELECT 
    runner_id,
    ROUND(100.0 * SUM(CASE 
        WHEN cancellation IS NULL THEN 1 
        ELSE 0 
    END) / COUNT(*), 2) AS successful_delivery_percentage
FROM t_runner_orders
GROUP BY runner_id
ORDER BY runner_id;


-- C. Ingredient Optimisation

-- 1. What are the standard ingredients for each pizza?
WITH toppings AS (
	SELECT 
		pizza_id,
		REGEXP_SPLIT_TO_TABLE(toppings, '[,\s]+')::INTEGER AS topping_id
	FROM pizza_recipes
)

SELECT
	t.pizza_id,
	STRING_AGG(pt.topping_name, ', ' ORDER BY LOWER(pt.topping_name)) AS standard_ingredients
FROM toppings t
INNER JOIN pizza_toppings pt
	ON t.topping_id = pt.topping_id
GROUP BY t.pizza_id
ORDER BY t.pizza_id;

-- 2. What was the most commonly added extra?
SELECT 
	pt.topping_name,
	COUNT(*) AS times_added
FROM t_customer_orders,
	LATERAL REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+') AS topping
INNER JOIN pizza_toppings pt
	ON topping::INTEGER = pt.topping_id
WHERE extras IS NOT NULL 
GROUP BY pt.topping_name
ORDER BY times_added DESC
LIMIT 1;

-- 3. What was the most common exclusion?
SELECT 
	pt.topping_name,
	COUNT(*) AS times_removed
FROM t_customer_orders,
	LATERAL REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+') AS topping
INNER JOIN pizza_toppings pt
	ON topping::INTEGER = pt.topping_id
WHERE exclusions IS NOT NULL 
GROUP BY pt.topping_name
ORDER BY times_removed DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--    - Meat Lovers
--    - Meat Lovers - Exclude Beef
--    - Meat Lovers - Extra Bacon
--    - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH numbered_orders AS (
    SELECT 
        ROW_NUMBER() OVER () AS record_id,
		order_id,
        pizza_id,
        exclusions,
        extras
    FROM t_customer_orders
),
exclusions AS (
    SELECT 
        record_id,
        STRING_AGG(pt.topping_name, ', ' ORDER BY LOWER(pt.topping_name)) AS exclusions
    FROM numbered_orders,
		LATERAL REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+') AS topping
    INNER JOIN pizza_toppings pt
		ON topping::INTEGER = pt.topping_id
    WHERE exclusions IS NOT NULL
    GROUP BY record_id
),
additions AS (
    SELECT 
        record_id,
        STRING_AGG(pt.topping_name, ', ' ORDER BY LOWER(pt.topping_name)) AS additions
    FROM numbered_orders,
		LATERAL REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+') AS topping
    INNER JOIN pizza_toppings pt
        ON topping::INTEGER = pt.topping_id
    WHERE extras IS NOT NULL
    GROUP BY record_id
)

SELECT
    no.order_id,
    pn.pizza_name || COALESCE(' - Exclude ' || e.exclusions, '') || COALESCE(' - Extra ' || a.additions, '') AS order_item
FROM numbered_orders no
INNER JOIN pizza_names pn
	ON no.pizza_id = pn.pizza_id
LEFT JOIN exclusions e
	ON no.record_id = e.record_id
LEFT JOIN additions a
	ON no.record_id = a.record_id
ORDER BY no.record_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--    For example: "Meat Lovers: 2xBacon, Beef, ..., Salami"
WITH numbered_orders AS (
    SELECT
        ROW_NUMBER() OVER () AS record_id,
        order_id,
        pizza_id,
        exclusions,
        extras
    FROM t_customer_orders
),
base_ingredients AS (
    SELECT
        no.record_id,
        topping::INTEGER AS topping_id
    FROM numbered_orders no
    JOIN pizza_recipes pr
		ON no.pizza_id = pr.pizza_id
    CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(pr.toppings, '[,\s]+') AS topping
),
extra_ingredients AS (
    SELECT
        no.record_id,
        topping::INTEGER AS topping_id
    FROM numbered_orders no
    CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(no.extras, '[,\s]+') AS topping
    WHERE no.extras IS NOT NULL
),
combined_ingredients AS (
    -- Base ingredients
    SELECT
		record_id,
		topping_id
	FROM base_ingredients
	
    UNION ALL
	
    -- Extra ingredients added to the order
    SELECT
		record_id,
		topping_id
	FROM extra_ingredients
    
    EXCEPT ALL
    
    -- Excluded ingredients removed from the order
    SELECT 
        no.record_id,
        topping::INTEGER AS topping_id
    FROM numbered_orders no
    CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(no.exclusions, '[,\s]+') AS topping
    WHERE no.exclusions IS NOT NULL
),
ingredient_counts AS (
    SELECT
        ci.record_id,
        ci.topping_id,
        COUNT(*) AS count
    FROM combined_ingredients ci
    GROUP BY ci.record_id, ci.topping_id
),
final_order_ingredients AS (
    SELECT
        ic.record_id,
        STRING_AGG(
            CASE 
                WHEN ic.count > 1 THEN ic.count || 'x' || pt.topping_name
                ELSE pt.topping_name
            END, 
            ', ' 
            ORDER BY LOWER(pt.topping_name)
        ) AS ingredient_list
    FROM ingredient_counts ic
    JOIN pizza_toppings pt
		ON ic.topping_id = pt.topping_id
    GROUP BY ic.record_id
)

SELECT
	no.order_id,
    pn.pizza_name || ': ' || foi.ingredient_list AS order_item
FROM numbered_orders no
JOIN pizza_names pn
	ON no.pizza_id = pn.pizza_id
JOIN final_order_ingredients foi
	ON no.record_id = foi.record_id
ORDER BY no.record_id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

## A. Pizza Metrics

### 1. How many pizzas were ordered?

````sql
SELECT
	COUNT(*) AS pizza_order_count
FROM t_customer_orders;
````

#### Steps:
- Apply the **COUNT** aggregate function to tally all rows, representing the total volume of individual pizza orders placed.
- (Optional) Assign the alias `pizza_order_count` to the resulting column for clear presentation in the final output report.

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- Customers ordered 14 pizzas.

### 2. How many unique customer orders were made?
````sql
SELECT
	COUNT(DISTINCT order_id) AS unique_order_count
FROM t_customer_orders;
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique order identifiers, ensuring orders with multiple pizzas are tallied as a single transaction.
- (Optional) Assign the alias `unique_order_count` to the resulting column for clear presentation in the final output report.

#### Answer:
| unique_order_count |
| ------------------ |
| 10                 |

- Customers ordered 10 times.

### 3. How many successful orders were delivered by each runner?
````sql
SELECT
	runner_id,
	COUNT(order_id) AS successful_orders
FROM t_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
````

#### Steps:
- Use the **COUNT** aggregate function to tally the total number of successful orders for each runner group.
- Apply a **WHERE** clause to filter out cancelled orders. There are several options to do this step correctly.
- Group the filtered records by `runner_id` to aggregate delivery metrics per individual runner.

#### Answer:
| runner_id | successful_orders |
| --------- | ----------------- |
| 1         | 4                 |
| 2         | 3                 |
| 3         | 1                 |

- Runner 1 delivered 4 orders.
- Runner 2 delivered 3 orders.
- Runner 3 delivered 1 orders.

### 4. How many of each type of pizza was delivered?
````sql
SELECT
	co.pizza_id,
    COUNT(co.pizza_id) AS pizzas_delivered
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id AND ro.cancellation IS NULL
GROUP BY co.pizza_id
ORDER BY co.pizza_id;
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Apply a filter condition within the join (`cancellation IS NULL`) to exclude cancelled orders.
- Use the **COUNT** aggregate function to tally the total volume delivered for each pizza type.
- Group the filtered records by `pizza_id` to aggregate delivery metrics per individual pizza type.
- (Optional) Order the final dataset in ascending sequence by `pizza_id` for structured presentation.

#### Answer:
| pizza_id | pizzas_delivered |
| -------- | ---------------- |
| 1        | 9                |
| 2        | 3                |

- Pizza 1 was delivered 9 times.
- Pizza 2 was delivered 3 times.

### 5. How many Vegetarian and Meatlovers were ordered by each customer?
````sql
SELECT
	co.customer_id,
    pn.pizza_name,
    COUNT(co.pizza_id) AS pizzas_ordered
FROM t_customer_orders co
INNER JOIN pizza_names pn
	ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name
ORDER BY co.customer_id;
````

#### Steps:
- Use an **INNER JOIN** on `pizza_id` to connect the `t_customer_orders` and `pizza_names` tables.
- Use the **COUNT** aggregate function to tally the total volume of pizzas ordered.
- Group the records by `customer_id` and `pizza_name` to break down order totals per individual customer and pizza type.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | pizzas_name | pizzas_ordered |
| ----------- | ----------- | -------------- |
| 101         | Meatlovers  | 2              |
| 101         | Vegetarian  | 1              |
| 102         | Meatlovers  | 2              |
| 102         | Vegetarian  | 1              |
| 103         | Meatlovers  | 3              |
| 103         | Vegetarian  | 1              |
| 104         | Meatlovers  | 3              |
| 105         | Vegetarian  | 1              |

- Customer 101 ordered 2 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 102 ordered 2 Meatlovers pizzas and 2 Vegetarian pizzas.
- Customer 103 ordered 3 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 104 ordered 1 Meatlovers pizza.
- Customer 105 ordered 1 Vegetarian pizza.

### 6. What was the maximum number of pizzas delivered in a single order?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`orders`) that joins the `t_customer_orders` and `t_runner_orders` tables.
- Apply a filter condition within the join (`cancellation IS NULL`) to exclude cancelled orders.
- Use the **COUNT** aggregate function to tally the total volume of pizzas delivered per order.
- Use the **MAX** aggregate function to extract the single highest pizza count from any single order.

#### Answer:
| max_pizzas_delivered |
| -------------------- |
| 3                    |

- The maximum number of pizzas delivered in a single order is 3 pizzas.

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
````sql
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
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Apply a filter condition within the join (`cancellation IS NULL`) to exclude cancelled orders.
- Use the **SUM** aggregate function counting those pizzas with at least one modification and assigning the alias `change`.
- Use the **SUM** aggregate function counting those pizzas that had no modifications whatsoever assigning the alias `no_change`.
- Group the filtered records by `customer_id` to break down metrics per individual customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | change | no_change |
| ----------- | ------ | --------- |
| 101         | 0      | 2         |
| 102         | 0      | 3         |
| 103         | 3      | 0         |
| 104         | 2      | 1         |
| 105         | 1      | 0         |

- Customer 101 ordered 2 pizzas without any change.
- Customer 102 ordered 3 pizzas without any change.
- Customer 103 ordered 3 pizzas with at least 1 change.
- Customer 104 ordered 2 pizzas with at least 1 change and 1 pizza without any change.
- Customer 105 ordered 1 pizza with at least 1 change.

### 8. How many pizzas were delivered that had both exclusions and extras?
````sql
SELECT
    SUM(
    	CASE WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 1
    	ELSE 0
    END) AS changed_pizza
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id AND ro.cancellation IS NULL;
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Apply a filter condition within the join (`cancellation IS NULL`) to exclude cancelled orders.
- Use the **SUM** aggregate function counting those pizzas with at least one exclusion and at least one extra.

#### Answer:
| changed_pizza |
| ------------- |
| 1             |

- Only 1 pizza delivered had both extra and exclusion topping.

### 9. What was the total volume of pizzas ordered for each hour of the day?
````sql
SELECT
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(order_id) AS total_pizzas
FROM t_customer_orders
GROUP BY order_hour
ORDER BY order_hour;
````

#### Steps:
- Use the **EXTRACT(HOUR FROM)** function to pull the hour component from the `order_time` column, assigning the alias `order_hour`.
- Apply the **COUNT** aggregate function to tally the total volume of pizzas ordered.
- (Optional) Order the final dataset in ascending sequence by `order_hour` for structured presentation.

#### Answer:
| order_hour | total_pizzas |
| ---------- | ------------ |
| 11         | 1            |
| 13         | 3            |
| 18         | 3            |
| 19         | 1            |
| 21         | 3            |
| 23         | 3            |

- Highest volume of pizza ordered is at 13 (1:00 pm), 18 (6:00 pm), 21 (9:00 pm) and 23 (11:00 pm).
- Lowest volume of pizza ordered is at 11 (11:00 am) and 19 (7:00 pm).

### 10. What was the volume of orders for each day of the week?
````sql
SELECT 
    TO_CHAR(order_time, 'FMDay') AS day_of_week,
    COUNT(order_id) AS total_pizzas
FROM t_customer_orders
GROUP BY TO_CHAR(order_time, 'FMDay'), EXTRACT(ISODOW FROM order_time)
ORDER BY EXTRACT(ISODOW FROM order_time);
````

#### Steps:
- Use the **TO_CHAR** function to extract and format `order_time` into the full name of the day of the week.
- Apply the **COUNT** aggregate function to tally the total volume of pizzas ordered.
- Group the records by `order_time` to break down metrics for each day of the week.
- (Optional) Order the final dataset in ascending sequence by `order_time` using the **EXTRACT(ISODOW FROM)** function for structured presentation.

#### Answer:
| day_of_week | total_pizzas |
| ----------- | ------------ |
| Monday      | 5            |
| Friday      | 5            |
| Saturday    | 3            |
| Sunday      | 1            |

- There are 5 pizzas ordered on Monday and Friday.
- There are 3 pizzas ordered on Saturday.
- There is 1 pizza ordered on Sunday.


## B. Runner and Customer Experience

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
````sql
SELECT 
    (FLOOR(DATE_PART('day', registration_date - TIMESTAMP '2021-01-01') / 7))::INTEGER + 1 AS registration_week,
    COUNT(runner_id) AS runner_signup
FROM runners
GROUP BY registration_week
ORDER BY registration_week;
````

#### Steps:
- Calculate the time elapsed from the anchor date ('2021-01-01') by subtracting **TIMESTAMP** from the `registration_date`.
- Extract the total number of elapsed days using the **DATE_PART('day', ...)** function.
- Divide the elapsed days by 7 and apply FLOOR() with integer casting.
- Add 1 to create sequential 1-week period buckets starting cleanly at 1, assigning the alias `registration_week`.
- Apply the **COUNT** aggregate function to tally the total volume of runner signups within each weekly period.
- Group and sort the final output by `registration_week` in ascending sequence for clean chronological reporting.

#### Note:
- Using `EXTRACT(WEEK FROM registration_date) AS registration_week` will also work but it starts with Week 53.
- This is because standard ISO-8601 week numbering treats the first week of the year based on where its first Thursday falls.
- Since 2021-01-01 falls on a Friday, ISO weeks see the preceding days as belonging to the final week of the previous year (Week 53 of 2020).

#### Answer:
| registration_week | runner_signup |
| ----------------- | ------------- |
| 1                 | 2             |
| 2                 | 1             |
| 3                 | 1             |

- On Week 1 of Jan 2021, 2 new runners signed up.
- On Week 2 and 3 of Jan 2021, 1 new runner signed up per week.

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`order_time`) that joins the `t_customer_orders` and `t_runner_orders` tables.
- Apply a filter condition within the join (`cancellation IS NULL`) to exclude cancelled orders.
- Group the joined records by `order_id`, `runner_id`, `order_time`, and `pickup_time` to ensure a unique grain per order transaction.
- Calculate the time interval between `order_time` and `pickup_time` by subtracting them, convert it to seconds using **EXTRACT(EPOCH FROM ...)**, and divide by 60 to transform the value into minutes.
- Apply the **AVG** aggregate function to the calculated minutes, wrap it in **ROUND** to produce a clean whole-number metric.

#### Answer:
| runner_id | average_time |
| --------- | ------------ |
| 1         | 14           |
| 2         | 20           |
| 3         | 10           |

- Runner 1's average time to arrive at the Pizza Runner HQ is 14 minutes.
- Runner 2's average time to arrive at the Pizza Runner HQ is 20 minutes.
- Runner 3's average time to arrive at the Pizza Runner HQ is 10 minutes.

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
````sql
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
````

#### Steps:
- Same as the previous exercise with two differences:
	- Remove `runner_id` from the **SELECT** statement.
	- Apply the **COUNT** aggregate function to tally the total volume of pizzas for each order.

#### Answer:
| num_pizzas | average_time |
| ---------- | ------------ |
| 1          | 12           |
| 2          | 18           |
| 3          | 29           |

- On average, an order with a single pizza takes 12 minutes to prepare.
- On average, an order with two pizzas takes 18 minutes to prepare with an average of exactly 9 minutes per pizza. This seems to be the most efficient order.
- On average, an order with three pizzas takes 29 minutes to prepare with an average of almost 10 minutes per pizza.

### 4. What was the average distance travelled for each customer?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`order_distances`) that joins the `t_customer_orders` and `t_runner_orders` tables.
- Apply **DISTINCT** to collapse duplicate rows caused by joining the pizza-level detail table to the order-level runner table, ensuring each trip distance is represented uniquely per customer.
- Apply a filter condition within the join (`distance IS NOT NULL`) to exclude cancelled orders.
- Apply the **AVG** aggregate function to the `distance` column to compute the average for each customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | average_distance |
| ----------- | ---------------- |
| 101         | 20.00            |
| 102         | 18.40            |
| 103         | 23.40            |
| 104         | 10.00            |
| 105         | 25.00            |

- Customer 101 is on average 20.00 km away from the Pizza Runner HQ.
- Customer 102 is on average 18.40 km away from the Pizza Runner HQ.
- Customer 103 is on average 23.40 km away from the Pizza Runner HQ.
- Customer 104 is on average 10.00 km away from the Pizza Runner HQ.
- Customer 105 is on average 25.00 km away from the Pizza Runner HQ.

### 5. What was the difference between the longest and shortest delivery times for all orders?
````sql
SELECT 
    MAX(duration) - MIN(duration) AS delivery_time_difference
FROM t_runner_orders
WHERE duration IS NOT NULL;
````

#### Steps:
- Apply the **MAX** aggregate function to find the longest delivery time and the **MIN** function to find the shortest delivery time.
- Subtract the shortest delivery time from the longest delivery time directly within the **SELECT** clause.
- (Optional) Apply a **WHERE** clause filtering out null records by retaining only rows where duration `IS NOT NULL`.

#### Answer:
| delivery_time_difference |
| ------------------------ |
| 30                       |

- The difference between the longest (40 minutes) and the shortest (10 minutes) delivery time for all orders is 30 minutes.

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
````sql
SELECT 
    runner_id,
    order_id,
    ROUND((distance / duration) * 60, 2) AS speed_kmh
FROM t_runner_orders
WHERE duration IS NOT NULL AND distance IS NOT NULL
ORDER BY runner_id, order_id;
````

#### Steps:
- Apply a **WHERE** clause to filter out incomplete records by keeping only rows where both `duration IS NOT NULL` and `distance IS NOT NULL`.
- Divide the `distance` by `duration` to calculate kilometers per minute, and multiply by 60 to convert it into kilometers per hour (km/h).
- (Optional) Order the final dataset in ascending sequence by `runner_id` and `order_id` for structured presentation.

#### Answer:
| runner_id | order_id | speed_kmh |
| --------- | -------- | --------- |
| 1         | 1        | 37.50     |
| 1         | 2        | 44.44     |
| 1         | 3        | 40.20     |
| 1         | 10       | 60.00     |
| 2         | 4        | 35.10     |
| 2         | 7        | 60.00     |
| 2         | 8        | 93.60     |
| 3         | 5        | 40.00     |

- Runner 1’s average speed goes from 37.5 km/h to 60 km/h.
- Runner 2’s average speed goes from 35.1 km/h to 93.6 km/h.
- Runner 3’s average speed is 40 km/h.

### 7. What is the successful delivery percentage for each runner?
```sql
SELECT 
    runner_id,
    ROUND(100.0 * SUM(CASE 
        WHEN cancellation IS NULL THEN 1 
        ELSE 0 
    END) / COUNT(*), 2) AS successful_delivery_percentage
FROM t_runner_orders
GROUP BY runner_id
ORDER BY runner_id;
````

#### Steps:
- Apply a **CASE** statement inside a **SUM** aggregate function to count successful deliveries, assigning a value of 1 when `cancellation IS NULL` and 0 otherwise.
- Multiply the sum of successful deliveries by 100.0 to force floating-point arithmetic and prevent integer truncation.
- Divide using **COUNT** to calculate the proportion of successful deliveries out of the total orders assigned to each runner.
- (Optional) Order the final dataset in ascending sequence by `runner_id` for structured presentation.

#### Answer:
| runner_id | successful_delivery_percentage |
| --------- | ------------------------------ |
| 1         | 100.00                         |
| 2         | 75.00                          |
| 3         | 50.00                          |

- Runner 1 has 100% successful delivery rate.
- Runner 2 has 75% successful delivery rate.
- Runner 3 has 50% successful delivery rate.


## C. Ingredient Optimisation

### 1. What are the standard ingredients for each pizza?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`toppings`) to process the `pizza_recipes` table.
- Select `pizza_id` and use **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to split the comma-delimited toppings string into individual rows.
- Query the CTE alongside the `pizza_toppings` table performing an **INNER JOIN** on matching `topping_id` values.
- Apply **STRING_AGG** to concatenate the ingredient names back into a comma-separated list.
- (Optional) Order the final dataset in ascending sequence by `pizza_id` for structured presentation.

#### Answer:
| pizza_id | standard_ingredients                                                  |
| -------- | --------------------------------------------------------------------- |
| 1        | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2        | Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes            |

### 2. What was the most commonly added extra?
````sql
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
````

#### Steps:
- Use a **LATERAL** join paired with **REGEXP_SPLIT_TO_TABLE** to split the comma-delimited `extras` string column row-by-row into individual values.
- Perform an **INNER JOIN** with the `pizza_toppings` table casting the split string value to an integer to match on `topping_id`.
- Apply a **WHERE** clause to filter out missing records by keeping only rows where `extras IS NOT NULL`.
- Sort the results in descending order by `times_added` and use **LIMIT 1** to isolate the single most frequently added extra.

#### Answer:
| topping_name | times_added |
| ------------ | ----------- |
| Bacon        | 4           |

- Bacon, added 4 times, is the most commonly added extra.

### 3. What was the most common exclusion?
````sql
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
````

#### Steps:
- Exactly the same as the previous exercise but swapping out `extras` for `exclusions`.

#### Answer:
| topping_name | times_removed |
| ------------ | ------------- |
| Cheese       | 4             |

- Cheese, removed 4 times, is the common exclusion.

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
````sql
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
````

#### Steps:
- Define a Common Table Expression (`numbered_orders`) to process the `customer_orders` table using **ROW_NUMBER() OVER ()** to assign a unique anchor ID to every single line item.
- Build an exclusions translation CTE (`exclusions`) referencing `numbered_orders`.
- Use **LATERAL REGEXP_SPLIT_TO_TABLE** to swap `topping_id` for `topping_name`, and aggregate them back together using **STRING_AGG** sorted alphabetically grouped by `record_id`.
- Build an additions translation CTE (`additions`) similarly to the previous one using `extras` instead of `exclusions` .
- Perform an **INNER JOIN** against `pizza_names` to fetch the base `pizza_name`, and **LEFT JOIN** both translation CTEs using `record_id`.
- Apply string formatting by concatenating the `pizza_name` with **COALESCE** statements to dynamically append modifications only when they exist.
- (Optional) Order the final dataset in ascending sequence by `record_id` to keep the original table order.

#### Answer:
| order_id | order_item                                                      |
| -------- | --------------------------------------------------------------- |
| 1 	   | Meatlovers                                                      |
| 2 	   | Meatlovers                                                      |
| 3 	   | Meatlovers                                                      |
| 3 	   | Vegetarian                                                      |
| 4 	   | Meatlovers - Exclude Cheese                                     |
| 4 	   | Meatlovers - Exclude Cheese                                     |
| 4 	   | Vegetarian - Exclude Cheese                                     |
| 5 	   | Meatlovers - Extra Bacon                                        |
| 6 	   | Vegetarian                                                      |
| 7 	   | Vegetarian - Extra Bacon                                        |
| 8 	   | Meatlovers                                                      |
| 9 	   | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
| 10 	   | Meatlovers                                                      |
| 10 	   | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ..., Salami"
````sql
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
````

#### Steps:
- Define a Common Table Expression (`numbered_orders`) to process the `customer_orders` table using **ROW_NUMBER() OVER ()** to assign a unique anchor ID to every single line item.
- Define a Common Table Expression (`base_ingredients`) that joins `numbered_orders` to `pizza_recipes`.
- Use **LATERAL REGEXP_SPLIT_TO_TABLE** to unnest `toppings` into individual rows with their corresponding record_id.
- Define a Common Table Expression (`extra_ingredients`) that unnests any non-null `extras` from `numbered_orders` into separate rows mapped to the same record_id.
- Define a Common Table Expression (`combined_ingredients`) that combines `base_ingredients` and `extra_ingredients` using **UNION ALL**, then subtract out any unnested exclusions using **EXCEPT ALL**.
- Define a Common Table Expression (`ingredient_counts`) that group `combined_ingredients` by `record_id` and `topping_id` to get a total count for each ingredient per order line.
- Define a Common Table Expression (`final_order_ingredients`) that joins `ingredient_counts` to `pizza_toppings`,
- Use **STRING_AGG** and a **CASE** statement to prepend multipliers when an ingredient count exceeds 1, while sorting alphabetically by **LOWER**.
- Join `pizza_names` to `final_order_ingredients` on `pizza_id` for the base pizza name, then join `final_order_ingredients` on `record_id` to generate the complete formatted string.
- (Optional) Order the final dataset in ascending sequence by `record_id` to keep the original table order.

#### Answer:
| order_id | order_item                                                                          |
| -------- | ----------------------------------------------------------------------------------- |
| 1 	   | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 2 	   | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 3 	   | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 3 	   | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 4 	   | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
| 4 	   | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
| 4 	   | Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                      |
| 5 	   | Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 6 	   | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 7 	   | Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes       |
| 8 	   | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 9 	   | Meatlovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami       |
| 10 	   | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 10 	   | Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami                     |

### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
````sql
WITH numbered_orders AS (
    SELECT
        ROW_NUMBER() OVER () AS record_id,
        co.order_id,
        co.pizza_id,
  		co.extras,
        co.exclusions
    FROM t_customer_orders co
  	INNER JOIN t_runner_orders ro
		ON co.order_id = ro.order_id
  		AND ro.cancellation IS NULL
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
)

SELECT
    pt.topping_name,
    COUNT(*) AS quantity
FROM combined_ingredients ci
INNER JOIN pizza_toppings pt
	ON ci.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY quantity DESC;
````

#### Steps:
- Define a Common Table Expression (`numbered_orders`) to process the `customer_orders` table using **ROW_NUMBER() OVER ()** to assign a unique anchor ID to every single line item.
- Apply a filter condition within the join (`cancellation IS NULL`) to exclude cancelled orders.
- Define `base_ingredients`, `extra_ingredients`, and `combined_ingredients` exactly like in the previous exercise.
- Query `combined_ingredients` alongside the `pizza_toppings` table performing an **INNER JOIN** on matching `topping_id` values.
- Use the **COUNT** aggregate function to tally the total number of toppings using an alias (`quantity`).
- Order the final dataset in descending sequence by `quantity` for structured presentation.

#### Answer:
| topping_name | quantity |
| ------------ | -------- |
| Bacon	       | 12       |
| Mushrooms	   | 11       |
| Cheese	   | 10       |
| Pepperoni	   | 9        |
| Chicken	   | 9        |
| Salami	   | 9        |
| Beef	       | 9        |
| BBQ Sauce	   | 8        |
| Tomato Sauce | 3        |
| Onions	   | 3        |
| Tomatoes	   | 3        |
| Peppers	   | 3        |


## D. Pricing and Ratings

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
````sql
SELECT
    SUM(CASE
    	WHEN co.pizza_id = 1 THEN 12
        ELSE 10
    END) AS revenue
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
	AND ro.cancellation IS NULL
````

#### Steps:
- Use a conditional **CASE** statement to map each pizza type to its respective price.
- Apply the **COUNT** aggregate function to calculate the grand total of incoming sales.
- Apply a filter condition within the join (`cancellation IS NULL`) to exclude cancelled orders.
- (Optional) Assign the alias `revenue` to the resulting column for clear presentation in the final output report.

#### Answer:
| revenue |
| ------- |
| 138     |

- Pizza Runner has made $138 so far.

### 2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra
````sql

````

#### Steps:
-

#### Answer:


- 

### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
````sql

````

#### Steps:
-

#### Answer:


- 

### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas
````sql

````

#### Steps:
-

#### Answer:


- 

### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
````sql

````

#### Steps:
-

#### Answer:


- 

## Data Cleaning & Transformation

This case study asks us to investigate the data, mentioning that we may want to do something with some of those `null` values and data types in the `customer_orders` and `runner_orders` tables!

### Table: customer_orders

Looking at the `customer_orders` table, we can see that there are missing and null values in the `exclusions` and `extras` columns. So we will create a temporary table that:
- Replace empty strings ('') or null strings ('null') with `NULL` in the `exclusions` column.
- Replace empty strings ('') or null strings ('null') with `NULL` in the `extras` column.

````sql
CREATE TEMP TABLE t_customer_orders AS
SELECT
    order_id,
    customer_id,
    pizza_id,
    NULLIF(NULLIF(exclusions, 'null'), '') AS exclusions,
    NULLIF(NULLIF(extras, 'null'), '') AS extras,
    order_time
FROM customer_orders;
`````

### Table: runner_orders

Our course of action to clean the `runner_orders` table will be create a temporary table that:
- Replace empty strings ('') or null strings ('null') with `NULL` in the `pickup_time` column.
- Cast the `pickup_time` column as **TIMESTAMP**.
- Replace empty strings ('') or null strings ('null') with `NULL` and any trailing string such as 'km' in the `distance` column.
- Cast the `distance` column as **NUMERIC**.
- Replace empty strings ('') or null strings ('null') with `NULL` and any trailing string such as "minutes", "minute", or "mins" in the `duration` column.
- Cast the `duration` column as **INTEGER**.
- Replace empty strings ('') or null strings ('null') with `NULL` in the `cancellation` column.

````sql
CREATE TEMP TABLE t_runner_orders AS
SELECT
    order_id,
    runner_id,
    NULLIF(NULLIF(pickup_time, 'null'), '')::TIMESTAMP AS pickup_time,
    NULLIF(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g'), '')::NUMERIC AS distance,
    NULLIF(REGEXP_REPLACE(duration, '[^0-9]', '', 'g'), '')::INTEGER AS duration,
    NULLIF(NULLIF(cancellation, 'null'), '') AS cancellation
FROM runner_orders;
````

**NOTE:** I have added both temp tables to `schema.sql` to run the solution easily.


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
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders.
- Group the filtered records by `runner_id` to aggregate delivery metrics per individual runner.
- Use the **COUNT** aggregate function to tally the total number of successful orders delivered per runner.

#### Answer:
| runner_id | successful_orders |
| --------- | ----------------- |
| 1         | 4                 |
| 2         | 3                 |
| 3         | 1                 |

### 4. How many of each type of pizza was delivered?
````sql
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
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Use an **INNER JOIN** on `pizza_id` to connect the `t_customer_orders` and `pizza_names` tables.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders.
- Group the filtered records by `pizza_name` to aggregate delivery metrics per individual pizza type.
- Use the **COUNT** aggregate function to tally the total volume of pizzas delivered for each pizza type.
- (Optional) Order the final dataset in ascending sequence by `pizza_name` for structured presentation.

#### Answer:
| pizza_name | pizzas_delivered |
| ---------- | ---------------- |
| Meatlovers | 9                |
| Vegetarian | 3                |

### 5. How many Vegetarian and Meatlovers were ordered by each customer?
````sql
SELECT
	customer_id,
    SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS meat_lovers,
    SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM t_customer_orders
GROUP BY customer_id
ORDER BY customer_id;
````

#### Steps:
- Apply a **CASE** statement inside the **SUM()** function to evaluate the total volume of Meatlovers pizzas ordered.
- Apply a **CASE** statement inside the **SUM()** function to evaluate the total volume of Vegetarian pizzas ordered.
- Group the records by `customer_id` to break down order totals per individual customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | meat_lovers | vegetarian |
| ----------- | ----------- | ---------- |
| 101         | 2           | 1          |
| 102         | 2           | 1          |
| 103         | 3           | 1          |
| 104         | 3           | 0          |
| 105         | 0           | 1          |

### 6. What was the maximum number of pizzas delivered in a single order?
````sql
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
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders.
- Group the filtered records by `order_id` to break down delivered pizzas per individual order.
- Use the **COUNT** aggregate function to tally the total volume of pizzas delivered per order.
- Sort the aggregated results in descending order by `pizzas_delivered` to keep the highest number on top.
- Apply **LIMIT** to isolate the single order with the maximum number of delivered pizzas.

#### Answer:
| order_id | pizzas_delivered |
| -------- | ---------------- |
| 4        | 3                |

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
````sql
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
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders and isolate delivered pizzas.
- Group the filtered records by `customer_id` to calculate the metrics per customer.
- Use the **SUM** aggregate function with a **CASE** statement counting those pizzas with at least one modification and assigning the alias `change`.
- Use the **SUM** aggregate function with a **CASE** statement counting those pizzas that had no modifications whatsoever assigning the alias `no_change`.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | change | no_change |
| ----------- | ------ | --------- |
| 101         | 0      | 2         |
| 102         | 0      | 3         |
| 103         | 3      | 0         |
| 104         | 2      | 1         |
| 105         | 1      | 0         |

### 8. How many pizzas were delivered that had both exclusions and extras?
````sql
SELECT
    SUM(CASE WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 1 ELSE 0 END) AS changed_pizza
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders.
- Use the **SUM** aggregate function with a **CASE** statement to tally pizzas that contain both exclusions and extras.

#### Answer:
| changed_pizza |
| ------------- |
| 1             |

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
- Group the records by `order_hour` to calculate the metrics for each hour of the day.
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

### 10. What was the volume of orders for each day of the week?
````sql
SELECT
    TO_CHAR(order_time, 'FMDay') AS day_of_week,
    COUNT(DISTINCT order_id) AS total_orders
FROM t_customer_orders
GROUP BY TO_CHAR(order_time, 'FMDay'), EXTRACT(ISODOW FROM order_time)
ORDER BY EXTRACT(ISODOW FROM order_time);
````

#### Steps:
- Use the **TO_CHAR** function to extract and format `order_time` into the full name of the day of the week.
- Apply the **COUNT DISTINCT** aggregate function to tally the total volume of unique orders per day rather than individual pizza line items.
- Group the records by `day_of_week` and `order_time` to enable proper chronological sorting.
- (Optional) Order the final dataset in ascending sequence by `order_time` using the **EXTRACT(ISODOW FROM)** function to present days chronologically rather than alphabetically.

#### Answer:
| day_of_week | total_orders |
| ----------- | ------------ |
| Monday      | 2            |
| Friday      | 5            |
| Saturday    | 2            |
| Sunday      | 1            |


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
- Divide the elapsed days by 7 and apply **FLOOR()** with integer casting.
- Add 1 to create sequential 1-week period buckets starting cleanly at 1, assigning the alias `registration_week`.
- Group the records by `registration_week` to calculate the metrics per week.
- Apply the **COUNT** aggregate function to tally the total volume of runner signups within each weekly period.
- (Optional) Order the final output by `registration_week` in ascending sequence for clean chronological reporting.

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
  	WHERE ro.cancellation IS NULL
  	GROUP BY co.order_id, ro.runner_id, co.order_time, ro.pickup_time
)

SELECT
	runner_id,
    ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60)::NUMERIC, 2) AS average_time
FROM order_time
GROUP BY runner_id
ORDER BY runner_id;
````

#### Steps:
- Define a Common Table Expression (`order_time`) that joins the `t_customer_orders` and `t_runner_orders` tables on `order_id`.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders.
- Group the joined records by `order_id`, `runner_id`, `order_time`, and `pickup_time` to ensure a unique grain per order transaction.
- Calculate the time interval between `order_time` and `pickup_time` by subtracting them, convert it to seconds using **EXTRACT(EPOCH FROM ...)**, and divide by 60 to transform the value into minutes.
- Apply the **AVG** aggregate function, grouping the records by `runner_id` to calculate the metric per runner.
- Cast the resulting floating-point average to **NUMERIC** to avoid errors.
- Wrap it in **ROUND** to present clean metrics rounded to two decimal places.
- (Optional) Order the final output in ascending sequence by `runner_id` for structured presentation.

#### Answer:
| runner_id | average_time |
| --------- | ------------ |
| 1         | 14.33        |
| 2         | 20.01        |
| 3         | 10.47        |

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
````

#### Steps:
- Define a Common Table Expression (`order_time`) that joins the `t_customer_orders` and `t_runner_orders` tables on `order_id`.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders.
- Use the **COUNT** aggregate function to tally the total volume of pizzas for each order.
- Group the CTE records by `order_id`, `order_time`, and `pickup_time` to establish a unique transaction grain per order.
- Calculate the time interval between `order_time` and `pickup_time` by subtracting them, convert it to seconds using **EXTRACT(EPOCH FROM ...)**, and divide by 60 to transform the value into minutes.
- Apply the **AVG** aggregate function to compute `average_time` per pizza count group.
- Cast the resulting floating-point average to **NUMERIC** to avoid errors.
- Divide the `average_time` by `num_pizzas` to compute `average_time_per_pizza` for direct efficiency comparison.
- Group and order the final output by `num_pizzas`.

#### Answer:
| num_pizzas | average_time | average_time_per_pizza |
| ---------- | ------------ | ---------------------- |
| 1          | 12.36        | 12.36                  |
| 2          | 18.38        | 9.19                   |
| 3          | 29.28        | 9.76                   |

- Yes, there is a relationship between the number of pizzas ordered and how long the order takes to prepare.
- Ordering two pizzas seems to be the most efficient option whereas ordering just one pizza is the less efficient.

### 4. What was the average distance travelled for each customer?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`order_distances`) that joins the `t_customer_orders` and `t_runner_orders` tables on `order_id`.
- Apply a **WHERE** clause (`distance IS NOT NULL`) to exclude cancelled orders.
- Apply **DISTINCT** to collapse duplicate rows caused by joining the pizza-level detail table to the order-level runner table, ensuring each trip distance is represented uniquely per customer.
- Group the filtered records by `customer_id` to calculate the metrics per customer.
- Apply the **AVG** aggregate function to the `distance` column to compute the average for each customer.
- Wrap it in **ROUND** to present clean metrics rounded to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | average_distance |
| ----------- | ---------------- |
| 101         | 20.00            |
| 102         | 18.40            |
| 103         | 23.40            |
| 104         | 10.00            |
| 105         | 25.00            |

### 5. What was the difference between the longest and shortest delivery times for all orders?
````sql
SELECT
    MAX(duration) AS longest_delivery,
	MIN(duration) AS shortest_delivery,
	MAX(duration) - MIN(duration) AS difference
FROM t_runner_orders
WHERE duration IS NOT NULL;
````

#### Steps:
- Apply a **WHERE** clause (`duration IS NOT NULL`) to exclude cancelled orders.
- Apply the **MAX** aggregate function to calculate the longest delivery time as `longest_delivery`.
- Apply the **MIN** aggregate function to calculate the shortest delivery time as `shortest_delivery`.
- Subtract `shortest_delivery` from `longest_delivery` to calculate the variance between the fastest and slowest deliveries.

#### Answer:
| longest_delivery | shortest_delivery | difference |
| ---------------- | ----------------- | ---------- |
| 40               | 10                | 30         |

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
````sql
SELECT
    runner_id,
    order_id,
    pickup_time,
    ROUND((distance / duration) * 60, 2) AS speed_kmh
FROM t_runner_orders
WHERE duration IS NOT NULL AND distance IS NOT NULL
ORDER BY runner_id, pickup_time;
````

#### Steps:
- Apply a **WHERE** clause (`duration IS NOT NULL` and `distance IS NOT NULL`) to filter out incomplete or cancelled records.
- Divide `distance` by `duration` to calculate kilometres per minute, multiply by 60 to convert it into kilometres per hour (km/h).
- (Optional) Order the final dataset in ascending sequence by `runner_id` and `pickup_time` for structured chronological presentation per runner.

#### Answer:
| runner_id | order_id | pickup_time         | speed_kmh |
| --------- | -------- | ------------------- | --------- |
| 1         | 1        | 2021-01-01 18:15:34 | 37.50     |
| 1         | 2        | 2021-01-01 19:10:54 | 44.44     |
| 1         | 3        | 2021-01-03 00:12:37 | 40.20     |
| 1         | 10       | 2021-01-11 18:50:20 | 60.00     |
| 2         | 4        | 2021-01-04 13:53:03 | 35.10     |
| 2         | 7        | 2021-01-08 21:30:45 | 60.00     |
| 2         | 8        | 2021-01-10 00:15:02 | 93.60     |
| 3         | 5        | 2021-01-08 21:10:57 | 40.00     |

- There's an apparent upward trend — both runners with multiple deliveries (1 and 2) get faster over successive orders, most dramatically Runner 2 (35 → 60 → 93.6 km/h).
- But with only 3-4 deliveries per runner, this sample is too small to draw a confident conclusion.

### 7. What is the successful delivery percentage for each runner?
```sql
SELECT 
    runner_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE cancellation IS NULL) / COUNT(*), 2) AS successful_delivery_percentage
FROM t_runner_orders
GROUP BY runner_id
ORDER BY runner_id;
````

#### Steps:
- Group by `runner_id` to compute the success percentage individually for each runner.
- Apply conditional aggregation using **COUNT** and **FILTER (WHERE ...)** to isolate the count of successful deliveries per runner.
- Divide using **COUNT** to calculate the proportion of successful deliveries out of all assigned orders.
- Multiply the number of successful deliveries by 100.0 to convert the ratio into a percentage.
- Wrap the calculation in **ROUND** to format the result to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `runner_id` for structured presentation.

#### Answer:
| runner_id | successful_delivery_percentage |
| --------- | ------------------------------ |
| 1         | 100.00                         |
| 2         | 75.00                          |
| 3         | 50.00                          |


## C. Ingredient Optimisation

### 1. What are the standard ingredients for each pizza?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`toppings`) that joins the `pizza_recipes` and `pizza_names` tables on `pizza_id`.
- Apply **CROSS JOIN LATERAL** with **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest comma-delimited topping IDs into individual rows for each pizza.
- Cast the split values to **INTEGER** to enable clean relational joining.
- Use an **INNER JOIN** on `topping_id` to connect the `toppings` CTE and the `pizza_toppings` table.
- Apply **STRING_AGG** ordered by `topping_id` to concatenate the ingredient names back into a comma-separated list.
- Group and order the final output by `pizza_name`.

#### Answer:
| pizza_name | standard_ingredients                                                  |
| ---------- | --------------------------------------------------------------------- |
| Meatlovers | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes            |

### 2. What was the most commonly added extra?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`extras`) to process the `t_customer_orders` table.
- Apply a **WHERE** clause (`extras IS NOT NULL`) to filter out records without modifications prior to unnesting.
- Use **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest comma-delimited extra topping IDs into individual rows.
- Cast the split values to **INTEGER** to enable clean relational joining.
- Use an **INNER JOIN** on `topping_id` to connect the `extras` CTE and the `pizza_toppings` table.
- Group the records by `topping_name` and apply the **COUNT** aggregate function to tally how many times each topping was added as an extra.
- Sort the results in descending order by `times_added` and use **LIMIT 1** to isolate the single most frequently added extra topping.

#### Answer:
| topping_name | times_added |
| ------------ | ----------- |
| Bacon        | 4           |

### 3. What was the most common exclusion?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`exclusions`) to process the `t_customer_orders` table.
- Apply a **WHERE** clause (`exclusions IS NOT NULL`) to filter out records without modifications prior to unnesting.
- Use **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to split the comma-delimited `exclusions` string into individual rows.
- Cast the split values to **INTEGER** to enable clean relational joining.
- Use an **INNER JOIN** on `topping_id` to connect the `exclusions` CTE and the `pizza_toppings` table.
- Group the records by `topping_name` and apply the **COUNT** aggregate function to tally how many times each topping was removed.
- Sort the aggregated results in descending order by `times_removed` and use **LIMIT 1** to isolate the single most frequently excluded topping.

#### Answer:
| topping_name | times_removed |
| ------------ | ------------- |
| Cheese       | 4             |

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
````sql
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
````

#### Steps:
- Define a Common Table Expression (`ordered_pizzas`) to process the `t_customer_orders` table.
- Use **ROW_NUMBER() OVER ()** to assign a unique key (`record_id`) to every pizza line item in the `t_customer_orders` table.
- Define a Common Table Expression (`exclusions`) that joins the `ordered_pizzas` CTE and the `pizza_toppings` table on `topping_id`.
- Apply a **WHERE** clause (`exclusions IS NOT NULL`) to filter out missing records.
- Apply **CROSS JOIN LATERAL** with **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to split comma-delimited `exclusions` strings into individual rows for each pizza.
- Cast split values to **INTEGER** and apply **STRING_AGG** sorted by `topping_id` and grouped by `record_id` to rebuild an ordered, comma-separated text list.
- Define a Common Table Expression (`additions`) applying the same unnesting, integer casting, filtering, and **STRING_AGG** re-aggregation logic to `extras`.
- Perform an **INNER JOIN** against `pizza_names` on `pizza_id`, and **LEFT JOIN** both modification CTEs back to `ordered_pizzas` on `record_id`.
- Apply string concatenation (||) combined with **COALESCE** to dynamically append ` - Exclude ...` and ` - Extra ...` label strings only when modifications are present.
- (Optional) Order the final output by `record_id` in ascending sequence to preserve the original transaction order.

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
````

#### Steps:
- Define a Common Table Expression (`ordered_pizzas`) to process the `customer_orders` table.
- Use **ROW_NUMBER() OVER ()** sorting by `order_id` to assign a unique key (`record_id`) to every pizza line item in the `t_customer_orders` table.
- Define a Common Table Expression (`ingredient_list`) that unrolls base recipe toppings and extra toppings and subtracts unnested exclusions:
	- Use an **INNER JOIN** on `pizza_id` to connect the `ordered_pizzas` CTE and the `pizza_recipes` table.
	- Apply **CROSS JOIN LATERAL** with **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest base recipe toppings, and casting split values to **INTEGER**.
	- Apply a **WHERE** clause (`extras IS NOT NULL`) to filter out missing records.
	- Apply **CROSS JOIN LATERAL** with **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest extra toppings, and casting split values to **INTEGER**.
	- Merge them using **UNION ALL**.
	- Apply a **WHERE** clause (`exclusions IS NOT NULL	`) to filter out missing records.
	- Apply **CROSS JOIN LATERAL** with **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest exclusions toppings, and casting split values to **INTEGER**.
	- Subtracts unnested exclusions using **EXCEPT ALL**.
- Define a Common Table Expression (`ingredient_list`) to process the `combined_ingredients` CTE.
- Use an **INNER JOIN** on `topping_id` to connect the `ingredient_list` CTE and the `pizza_toppings` table.
- Group the records by `record_id` and `topping_name` and apply the **COUNT** aggregate function to compute individual topping quantities.
- Use an **INNER JOIN** from `ingredient_counts` to `ordered_pizzas` on `record_id` and to `pizza_names` on `pizza_id`.
- Group the main query results by `record_id`, `order_id` and `pizza_name`.
- Apply string concatenation (||) combined with **STRING_AGG** and a **CASE** statement to dynamically prepend quantity multipliers (2x) when an ingredient count exceeds 1, sorting by `topping_name` using **LOWER**.
- (Optional) Order the final output by `record_id` in ascending sequence to preserve the original transaction order.

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
````

#### Steps:
- Define a Common Table Expression (`delivered_pizzas`) that joins the `t_customer_orders` and `t_runner_orders` tables on `order_id`.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders and isolate delivered pizzas.
- Use **ROW_NUMBER() OVER ()** sorting by `order_id` to assign a unique key (`record_id`) to every pizza line item in the `t_customer_orders` table.
- Define a Common Table Expression (`ingredient_list`) that unrolls base recipe toppings and extra toppings and subtracts unnested exclusions:
	- Use an **INNER JOIN** on `pizza_id` to connect the `ordered_pizzas` CTE and the `pizza_recipes` table.
	- Apply **CROSS JOIN LATERAL** with **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest base recipe toppings, and casting split values to **INTEGER**.
	- Apply a **WHERE** clause (`extras IS NOT NULL`) to filter out missing records.
	- Apply **CROSS JOIN LATERAL** with **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest extra toppings, and casting split values to **INTEGER**.
	- Merge them using **UNION ALL**.
	- Apply a **WHERE** clause (`exclusions IS NOT NULL	`) to filter out missing records.
	- Apply **CROSS JOIN LATERAL** with **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest exclusions toppings, and casting split values to **INTEGER**.
	- Subtracts unnested exclusions using **EXCEPT ALL**.
- Use an **INNER JOIN** on `topping_id` to connect the `ingredient_list` CTE and the `pizza_toppings` table.
- Group the records by `topping_name` and apply the **COUNT** to tally the total volume of each topping consumed across all delivered pizzas, aliasing the aggregate as `quantity`.
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
	SUM(CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END) AS revenue
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
    ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders and isolate delivered pizzas.
- Use a conditional **CASE** statement to assign prices based on pizza type ($12 for Meatlovers, $10 for Vegetarian).
- Apply the **SUM** aggregate function to compute total gross revenue as `revenue`.

#### Answer:
| revenue |
| ------- |
| 138     |

### 2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra
````sql
WITH delivered_pizzas AS (
    SELECT
		co.pizza_id,
		(SELECT COUNT(*) FROM REGEXP_SPLIT_TO_TABLE(co.extras, '[,\s]+')) AS num_extras
    FROM t_customer_orders co
    INNER JOIN t_runner_orders ro
        ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL
)

SELECT
	SUM(
		CASE WHEN pizza_id = 1 THEN 12 ELSE 10 END
		+ num_extras
    ) AS revenue
FROM delivered_pizzas
````

#### Steps:
- Define a Common Table Expression (`delivered_pizzas`) that joins the `t_customer_orders` and `t_runner_orders` tables on `order_id`.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders and isolate delivered pizzas.
- Use a correlated scalar subquery with **COUNT** aggregate function over **REGEXP_SPLIT_TO_TABLE** with the delimiter pattern [,\s]+ to unnest and count extra toppings for each order line item.
- Use a conditional **CASE** statement to assign prices based on pizza type ($12 for Meatlovers, $10 for Vegetarian).
- Apply the **SUM** aggregate function to compute total gross revenue as `revenue`.

#### Answer:
| revenue |
| ------- |
| 142     |

### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
````sql
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
    order_id INTEGER PRIMARY KEY,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5)
);
INSERT INTO runner_ratings
	(order_id, rating)
VALUES
	(1, 5),
	(2, 4),
	(3, 5),
	(4, 3),
	(5, 5),
	(7, 4),
	(8, 5),
	(10, 2);
````

#### Steps:
- Use **DROP TABLE IF EXISTS** to safely remove any pre-existing `runner_ratings` table, ensuring the schema setup script can be rerun without throw-errors.
- Use **CREATE TABLE** to create the `runner_ratings` table structure.
- Set `order_id` as **PRIMARY KEY** to ensure each order maps uniquely to a single rating and prevent duplicate entries.
- Apply a **NOT NULL** and **CHECK** constraints on the `rating` column to enforce domain integrity and restrict scores strictly to the valid 1–5 range.
- Use **INSERT INTO** statements to populate the table.

#### Answer:
- There is no output for this query.
- The query will be added to `schema.sql` to run the next questions easily.

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
    COUNT(co.pizza_id) AS total_pizzas
FROM t_customer_orders co
INNER JOIN t_runner_orders ro
	ON co.order_id = ro.order_id
INNER JOIN runner_ratings rr
	ON co.order_id = rr.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id, co.order_id, ro.runner_id, rr.rating, co.order_time, ro.pickup_time, ro.duration, ro.distance
ORDER BY co.order_id;
````

#### Steps:
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `t_runner_orders` tables.
- Use an **INNER JOIN** on `order_id` to connect the `t_customer_orders` and `runner_ratings` tables.
- Apply a filter condition within the join (`cancellation IS NULL`) to exclude cancelled orders.
- Group the joined records by all order and delivery attributes to collapse pizza-level line items into a single order grain.
- Calculate pickup delay in minutes using **EXTRACT(EPOCH FROM ...)**, divide it by 60, wrapping in **ROUND** and casting to **INTEGER** as `time_difference`.
- Calculate average delivery speed in km/h by dividing `distance` by `duration` and multiply by 60 rounded to two decimal places as `average_speed`.
- Apply **COUNT** to tally the total volume of pizzas ordered per delivery as `total_pizzas`.
- (Optional) Order the final dataset in ascending sequence by `order_id` for structured presentation.

#### Answer:
| customer_id | order_id | runner_id | rating | order_time          | pickup_time         | time_difference | duration | average_speed | total_pizzas |
| ----------- | -------- | --------- | ------ | ------------------- | ------------------- | --------------- | -------- | ------------- | ------------ |
| 101         | 1        | 1         | 5      | 2021-01-01 18:05:02 | 2021-01-01 18:15:34 | 11              | 32       | 37.50         | 1            |
| 101         | 2        | 1         | 4      | 2021-01-01 19:00:52 | 2021-01-01 19:10:54 | 10              | 27       | 44.44         | 1            |
| 102         | 3        | 1         | 5      | 2021-01-02 23:51:23 | 2021-01-03 00:12:37 | 21              | 20       | 40.20         | 2            |
| 103         | 4        | 2         | 3      | 2021-01-04 13:23:46 | 2021-01-04 13:53:03 | 29              | 40       | 35.10         | 3            |
| 104         | 5        | 3         | 5      | 2021-01-08 21:00:29 | 2021-01-08 21:10:57 | 10              | 15       | 40.00         | 1            |
| 105         | 7        | 2         | 4      | 2021-01-08 21:20:29 | 2021-01-08 21:30:45 | 10              | 25       | 60.00         | 1            |
| 102         | 8        | 2         | 5      | 2021-01-09 23:54:33 | 2021-01-10 00:15:02 | 20              | 15       | 93.60         | 1            |
| 104         | 10       | 1         | 2      | 2021-01-11 18:34:49 | 2021-01-11 18:50:20 | 16              | 10       | 60.00         | 2            |

### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre travelled - how much money does Pizza Runner have left over after these deliveries?
````sql
WITH total_payouts AS (
    SELECT
		SUM(distance) * 0.30 AS payout
    FROM t_runner_orders
    WHERE cancellation IS NULL
),
total_revenue AS (
	SELECT
		SUM(CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END) AS revenue
	FROM t_customer_orders co
	INNER JOIN t_runner_orders ro
		ON co.order_id = ro.order_id
	WHERE ro.cancellation IS NULL
)

SELECT
    ROUND((tr.revenue - tp.payout), 2) AS net_profit
FROM total_revenue tr, total_payouts tp;
````

#### Steps:
- Define a Common Table Expression (`total_payouts`) to process the `t_runner_orders` table.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders and isolate delivered pizzas.
- Use the **SUM** aggregate function to compute total distance covered and multiply by $0.30 per kilometer to compute total runner delivery payouts as `payout`.
- Define a Common Table Expression (`total_revenue`) that joins the `t_customer_orders` and `t_runner_orders` tables on `order_id`.
- Apply a **WHERE** clause (`cancellation IS NULL`) to exclude cancelled orders and isolate delivered pizzas.
- Use a conditional **CASE** statement to assign prices based on pizza type ($12 for Meatlovers, $10 for Vegetarian).
- Apply the **SUM** aggregate function to compute total gross revenue as `revenue`.
- Combine both single-row CTEs via an implicit cross join.
- Subtract total runner payouts from gross revenue, , wrapping the result in **ROUND** to calculate final earnings formatted to two decimal places as `net_profit`.

#### Answer:
| net_profit |
| ---------- |
| 94.44      |


## E. Bonus Questions

### 1. If Danny wants to expand his range of pizzas - how would this impact the existing data design?
Relational databases are built for data expansion; the schema structure itself doesn't need to change at all. Expanding the range of pizzas only requires data updates (inserts) rather than a design redesign.

One weakness would be that `toppings` stores topping IDs as a delimited string rather than a normalized junction table, which required string-parsing techniques for every ingredient-related query.
A `pizza_recipe_toppings(pizza_id, topping_id)` table would have avoided this entirely.

### 2. Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
````sql
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
````

#### Steps:
- Use **INSERT INTO** statements to populate `pizza_names` and `pizza_recipes` tables.

#### Answer:
- There is no output for this query.

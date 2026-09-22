## A. Customer Journey

### Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
````sql
SELECT
	s.customer_id,
    p.plan_id,
	p.plan_name,
	s.start_date
FROM subscriptions s
JOIN plans p
	ON s.plan_id = p.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
ORDER BY s.customer_id, s.start_date;
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `plans` and `subscriptions` tables.
- Apply a **WHERE** clause (`customer_id IN (1,2,11,13,15,16,18,19)`) to include the 8 sample customers provided.
- Order the final dataset in ascending sequence by `customer_id` and `start_date` to chronologically trace each customer's onboarding and plan transitions.

#### Answer:
| customer_id | plan_id | plan_name     | start_date |
| ----------- | ------- | ------------- | ---------- |
| 1           | 0       | trial         | 2020-08-01 |
| 1           | 1       | basic monthly | 2020-08-08 |
| 2           | 0       | trial         | 2020-09-20 |
| 2           | 3       | pro annual    | 2020-09-27 |
| 11          | 0       | trial         | 2020-11-19 |
| 11          | 4       | churn         | 2020-11-26 |
| 13          | 0       | trial         | 2020-12-15 |
| 13          | 1       | basic monthly | 2020-12-22 |
| 13          | 2       | pro monthly   | 2021-03-29 |
| 15          | 0       | trial         | 2020-03-17 |
| 15          | 2       | pro monthly   | 2020-03-24 |
| 15          | 4       | churn         | 2020-04-29 |
| 16          | 0       | trial         | 2020-05-31 |
| 16          | 1       | basic monthly | 2020-06-07 |
| 16          | 3       | pro annual    | 2020-10-21 |
| 18          | 0       | trial         | 2020-07-06 |
| 18          | 2       | pro monthly   | 2020-07-13 |
| 19          | 0       | trial         | 2020-06-22 |
| 19          | 2       | pro monthly   | 2020-06-29 |
| 19          | 3       | pro annual    | 2020-08-29 |

- Every customer starts on a 7-day free trial, so the second row is the plan they converted to when it ended.
- Customers 2, 18 and 19 went straight to a pro plan.
- Customers 1, 13 and 16 started on basic, and 13 and 16 later upgraded.
- Customers 11 and 15 churned, 11 immediately after the trial and 15 after five weeks on pro monthly.


## B. Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?
````sql
SELECT
	COUNT(DISTINCT customer_id) AS customers
FROM subscriptions;
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique customers, ensuring customers with multiple plans are tallied as a single customer.
- (Optional) Assign the alias `customers` to the resulting column for clear presentation in the final output report.

#### Answer:
| customers |
| --------- |
| 1000      |

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
````sql
SELECT 
    TO_CHAR(DATE_TRUNC('month', s.start_date), 'FMMonth') AS month_name,
    COUNT(*) AS trials
FROM subscriptions s
INNER JOIN plans p
	ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY month_name, DATE_TRUNC('month', s.start_date)
ORDER BY DATE_TRUNC('month', s.start_date);
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `subscriptions` and `plans` tables.
- Apply a **WHERE** clause (`plan_name = 'trial'`) to isolate trial plan subscriptions.
- Use **DATE_TRUNC('month', ...)** to truncate start dates to the first of the month.
- USe **TO_CHAR(..., 'FMMonth')** to format truncated dates as full month names.
- Group the filtered records by `month_name` and `DATE_TRUNC('month', start_date)` to aggregate trial signups by month while preserving date sorting capabilities.
- Apply the **COUNT** aggregate function to calculate the total volume of trial start events per month.
- Order the final output chronologically by truncated dates for structured presentation.

#### Answer:
| month_name | trials |
| ---------- | ------ |
| January    | 88     |
| February   | 68     |
| March      | 94     |
| April      | 81     |
| May        | 88     |
| June       | 79     |
| July       | 89     |
| August     | 88     |
| September  | 87     |
| October    | 79     |
| November   | 75     |
| December   | 84     |

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
````sql
SELECT
    p.plan_id,
    p.plan_name,
    COUNT(*) AS events
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `subscriptions` and `plans` tables.
- Apply a **WHERE** clause (`start_date >= '2021-01-01'`) to isolate subscription events occurring on or after 1st of January 2021.
- Group the filtered records by `plan_id` and `plan_name` to aggregate activity metrics per subscription plan.
- Apply the **COUNT** aggregate function to calculate total subscription events for each plan.
- (Optional) Order the final dataset in ascending sequence by `plan_id` for structured presentation.

#### Answer:
| plan_id | plan_name     | events | 
| ------- | ------------- |------- |
| 1       | basic monthly | 8      |
| 2       | pro monthly   | 60     |
| 3       | pro annual    | 63     |
| 4       | churn         | 71     |

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
````sql
SELECT
    COUNT(DISTINCT customer_id) FILTER (WHERE plan_id = 4) AS churned_customers,
    ROUND(
        100.0 * COUNT(DISTINCT customer_id) FILTER (WHERE plan_id = 4)
        / COUNT(DISTINCT customer_id),
        1
    ) AS churn_percentage
FROM subscriptions;
````

#### Steps:
- Apply conditional aggregation using **COUNT** and **FILTER (WHERE ...)** to count unique customers who cancelled their service.
- Divide using **COUNT** with **DISTINCT** to calculate the proportion of churned customers out of the total distinct customer count.
- Multiply the number of successful deliveries by 100.0 to convert the ratio to a percentage and force floating-point numeric precision.
- Wrap the calculation in **ROUND** to format the result to one decimal places.

#### Answer:
| churned_customers | churn_percentage | 
| ----------------- |----------------- |
| 307               | 30.7             |

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
````sql
WITH ordered_plans AS (
	SELECT
  		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_sequence,
  		customer_id,
  		plan_id
	FROM subscriptions
)

SELECT
    COUNT(DISTINCT customer_id) AS customers_count,
    ROUND(
        100.0 * COUNT(DISTINCT customer_id) / 
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
        0
    ) AS churn_percentage
FROM ordered_plans
WHERE plan_id = 4 AND plan_sequence = 2;
````

#### Steps:
- Define a Common Table Expression (`ordered_plans`) to process the `subscriptions` table.
- Use **ROW_NUMBER() OVER ()** to chronologically sequence each customer's plan transitions.
- Apply a **WHERE** clause (`plan_id = 4` and `plan_sequence = 2`) to isolate customers whose second subscription event was a churn, capturing cancellations immediately following an initial free trial.
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the unique volume of customers fitting this exact conversion path, aliasing the aggregate as `customers_count`.
- Divide `customers_count` by total distinct customers retrieved via a scalar subquery, multiplying by 100.0 to convert the ratio to a percentage and force floating-point numeric precision.
- Wrap the calculation in **ROUND** to format the result to zero decimal places.

#### Answer:
| customers_count | churn_percentage | 
| --------------- |----------------- |
| 92              | 9                |

### 6. What is the number and percentage of customer plans after their initial free trial?
````sql
WITH ordered_plans AS (
	SELECT
  		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_sequence,
  		customer_id,
  		plan_id
	FROM subscriptions
)

SELECT
    p.plan_name,
    COUNT(DISTINCT op.customer_id) AS customers_count,
    ROUND(
        100.0 * COUNT(DISTINCT op.customer_id) / 
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
        1
    ) AS plan_percentage
FROM ordered_plans op
INNER JOIN plans p
    ON op.plan_id = p.plan_id
WHERE op.plan_sequence = 2
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;
````

#### Steps:
- Define a Common Table Expression (`ordered_plans`) to process the `subscriptions` table.
- Use **ROW_NUMBER() OVER ()** to chronologically sequence each customer's plan transitions.
- Use an **INNER JOIN** on `plan_id` to connect the `ordered_plans` CTE and the `plans` tables.
- Apply a **WHERE** clause (`plan_sequence = 2`) to isolate each customer's second plan transition (the plan immediately following their initial trial).
- Group the filtered records by `plan_id` and `plan_name` to aggregate conversion metrics per plan.
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the unique volume of customers converting to each target plan, aliasing the aggregate as `customers_count`.
- Divide `customers_count` by total distinct customers retrieved via a scalar subquery, multiplying by 100.0 to convert the ratio to a percentage and force floating-point numeric precision.
- Wrap the calculation in **ROUND** to format the result to one decimal places.
- (Optional) Order the final dataset in ascending sequence by `plan_id` for structured presentation.

#### Answer:
| plan_name     | customers_count | plan_percentage | 
| ------------- | --------------- |---------------- |
| basic monthly | 546             | 54.6            |
| pro monthly   | 325             | 32.5            |
| pro annual    | 37              | 3.7             |
| churn         | 92              | 9.2             |

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
````sql
WITH ordered_plans AS (
	SELECT
  		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS plan_sequence,
  		customer_id,
  		plan_id
	FROM subscriptions
  	WHERE start_date <= '2020-12-31'
)

SELECT
    p.plan_name,
    COUNT(DISTINCT op.customer_id) AS customers_count,
    ROUND(
		100.0 * COUNT(DISTINCT op.customer_id)
		/ (SELECT COUNT(*) FROM ordered_plans WHERE plan_sequence = 1),
		1
    ) AS plan_percentage
FROM ordered_plans op
INNER JOIN plans p
    ON op.plan_id = p.plan_id
WHERE op.plan_sequence = 1
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;
````

#### Steps:
- Define a Common Table Expression (`ordered_plans`) to process the `subscriptions` table.
- Use **ROW_NUMBER() OVER ()** to rank each customer's plan transitions in reverse chronological order.
- Apply a **WHERE** clause (`start_date <= '2020-12-31`) to isolate each customer's latest active plan as of 31st December 2020.
- Use an **INNER JOIN** on `plan_id` to connect the `ordered_plans` CTE and the `plans` tables.
- Apply a **WHERE** clause (`plan_sequence = 1`) to isolate each customer's latest active plan as of 31st December 2020.
- Group the filtered records by `plan_id` and `plan_name` to aggregate conversion metrics per plan.
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the unique volume of customers on each plan at year-end 2020, aliasing the aggregate as `customers_count`.
- Divide `customers_count` by the total count of active customers as of 31st December 2020 retrieved via a scalar subquery, multiplying by 100.0 to convert the ratio to a percentage and force floating-point numeric precision.
- Wrap the calculation in **ROUND** to format the result to one decimal places.
- (Optional) Order the final dataset in ascending sequence by `plan_id` for structured presentation.

#### Answer:
| plan_name     | customers_count | plan_percentage | 
| ------------- | --------------- |---------------- |
| trial         | 19              | 1.9             |
| basic monthly | 224             | 22.4            |
| pro monthly   | 326             | 32.6            |
| pro annual    | 195             | 19.5            |
| churn         | 236             | 23.6            |

### 8. How many customers have upgraded to an annual plan in 2020?
````sql
SELECT
    COUNT(DISTINCT s.customer_id) AS annual_plan_customers
FROM subscriptions s
INNER JOIN plans p
	ON s.plan_id = p.plan_id
WHERE s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
	AND p.plan_name = 'pro annual';
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `subscriptions` and `plans` tables.
- Apply a **WHERE** clause (`start_date BETWEEN '2020-01-01' AND '2020-12-31'` and `plan_name = 'pro annual'`) to isolate annual plan subscriptions starting between 1st January 2020 and 31st December 2020.
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the volume of unique customers who purchased or upgraded to a pro annual plan during 2020.

#### Answer:
| annual_plan_customers |
| --------------------- |
| 195                   |

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
````sql
WITH trial_plan_dates AS (
	SELECT 
		customer_id, 
		start_date AS trial_date
	FROM subscriptions
	WHERE plan_id = 0
),
annual_plan_dates AS (
	SELECT 
		customer_id, 
		start_date AS annual_date
	FROM subscriptions
	WHERE plan_id = 3
)

SELECT 
	ROUND(AVG(apd.annual_date - tpd.trial_date))::INTEGER AS average_days
FROM trial_plan_dates tpd
INNER JOIN annual_plan_dates apd
	ON tpd.customer_id = apd.customer_id;
````

#### Steps:
- Define a Common Table Expression (`trial_plan_dates`) to process the `subscriptions` table.
- Apply a **WHERE** clause (`plan_id = 0`) to extract each customer's trial start date as `trial_date`.
- Define a Common Table Expression (`annual_plan_dates`) to process the `subscriptions` table.
- Apply a **WHERE** clause (`plan_id = 3`) to extract each customer's annual plan start date as `annual_date`.
- Use an **INNER JOIN** on `customer_id` to connect the `trial_plan_dates` and `annual_plan_dates` CTEs.
- Subtract `trial_date` from `annual_date` to calculate the elapsed time in days between trial start and annual plan conversion per customer.
- Apply the **AVG** aggregate function across the calculated date differences to compute the mean conversion timeframe across all converting customers.
- Wrap the calculation in **ROUND** and cast the result to **INTEGER** to return a clean, rounded whole-number metric.

#### Answer:
| average_days |
| ------------ |
| 105          |

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
````sql
WITH trial_plan_dates AS (
	SELECT
		customer_id,
		start_date AS trial_date
	FROM subscriptions
	WHERE plan_id = 0
),
annual_plan_dates AS (
	SELECT
		customer_id,
		start_date AS annual_date
	FROM subscriptions
	WHERE plan_id = 3
),
customer_durations AS (
    SELECT
        WIDTH_BUCKET(apd.annual_date - tpd.trial_date, 1, 181, 6) AS bucket
	FROM trial_plan_dates tpd
	INNER JOIN annual_plan_dates apd
		ON tpd.customer_id = apd.customer_id
)

SELECT
    CASE
        WHEN bucket = 1 THEN '0-30 days'
		WHEN bucket <= 6 THEN (bucket - 1) * 30 + 1 || '-' || bucket * 30 || ' days'
        ELSE '181+ days'
    END AS period,
    COUNT(*) AS customers
FROM customer_durations
GROUP BY bucket
ORDER BY bucket;
````

#### Steps:
- Define a Common Table Expression (`trial_plan_dates`) to process the `subscriptions` table.
- Apply a **WHERE** clause (`plan_id = 0`) to extract each customer's trial start date as `trial_date`.
- Define a Common Table Expression (`annual_plan_dates`) to process the `subscriptions` table.
- Apply a **WHERE** clause (`plan_id = 3`) to extract each customer's annual plan start date as `annual_date`.
- Define a Common Table Expression (`customer_durations`) that joins the `trial_plan_dates` and `annual_plan_dates` CTEs on `customer_id`.
- Use **WIDTH_BUCKET()** on the date difference across the range 1 to 181 into 6 equal intervals to assign each conversion to a numeric `bucket`.
- Apply a **CASE** statement in the main query to to dynamically map bucket numbers to formatted duration strings.
- Group the records by `bucket` and apply **COUNT** to aggregate the total volume of converted customers within each duration bracket.
- Order the final output sequentially by `bucket` to present the duration brackets in logical chronological sequence.

#### Answer:

| period       | customers |
| -------------| --------- |
| 0-30 days    | 49        |
| 31-60 days   | 24        |
| 61-90 days   | 34        |
| 91-120 days  | 35        |
| 121-150 days | 42        |
| 151-180 days | 36        |
| 181+ days    | 38        |

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
````sql
WITH customer_plans AS (
	SELECT
		customer_id,
		plan_id,
		LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id,
		LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_date
	FROM subscriptions
)

SELECT
	COUNT(DISTINCT customer_id) AS customers_downgraded
FROM customer_plans
WHERE plan_id = 2
	AND next_plan_id = 1
    AND next_plan_date BETWEEN '2020-01-01' AND '2020-12-31';
````

#### Steps:
- Define a Common Table Expression (`customer_plans`) to process the `subscriptions` table.
- Use **LEAD() OVER ()** partitioned by `customer_id` and ordered by `start_date` to capture each customer's subsequent plan (`next_plan_id`) and start date (`next_plan_date`).
- Apply a **WHERE** clause (`plan_id = 2`, `next_plan_id = 1` and `next_plan_date BETWEEN '2020-01-01' AND '2020-12-31'`) to isolate customers that downgraded from a pro monthly to a basic monthly plan in 2020.
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the unique volume of customers who completed this downgrade.

#### Answer:
| customers_downgraded |
| -------------------- |
| 0                    |

- In 2020, there were no customers who downgraded from a pro monthly to a basic monthly plan.


## C. Runner and Customer Experience

### The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments
````sql
CREATE TABLE payments AS
WITH customer_plans AS (
	SELECT
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date,
		LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan_date,
		LAG(s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS previous_plan_id,
		p.price AS amount
	FROM subscriptions s
	INNER JOIN plans p
		ON s.plan_id = p.plan_id
	WHERE s.plan_id <> 0
),
generated_payments AS (
	SELECT
		customer_id,
		plan_id,
		plan_name,
		previous_plan_id,
		amount,
		generate_series(
			start_date,
			LEAST(next_plan_date - INTERVAL '1 day', '2020-12-31'::DATE),
			CASE WHEN plan_id IN (1, 2) THEN INTERVAL '1 month' ELSE INTERVAL '1 year' END
		)::DATE AS payment_date
	FROM customer_plans
	WHERE plan_id <> 4
)

SELECT
    customer_id,
	plan_id,
	plan_name,
	payment_date,
    CASE
		WHEN previous_plan_id = 1 AND ROW_NUMBER() OVER (PARTITION BY customer_id, plan_id, previous_plan_id ORDER BY payment_date) = 1 THEN amount - 9.90
		ELSE amount
	END AS amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS payment_order
FROM generated_payments
ORDER BY customer_id, payment_date;
````

#### Steps:
- Use **CREATE TABLE AS** to add the resulting query output into a new table named `payments`.
- Define a Common Table Expression (`customer_plans`) that joins the `subscriptions` and `plans` tables on `plan_id`.
- Apply a **WHERE** clause (`plan_id <> 0`) to exclude initial trial periods.
- Use the **LEAD() OVER ()** window function partitioned by `customer_id` and ordered by `start_date` to capture each customer's subsequent plan start date (`next_plan_date`).
- Use the **LAG() OVER ()** window function partitioned by `customer_id` and ordered by `start_date` to capture each customer's previous plan ID (`previous_plan_id`).
- Define a Common Table Expression (`generated_payments`) to process the `customer_plans` CTE.
- Apply a **WHERE** clause (`plan_id <> 4`) to exclude churn events so recurring payment schedules end upon cancellation.
- Apply **generate_series()** to generate billing schedules.
- Use **LEAST()** to cap billing dates at the day prior to a plan transition or 31st December 2020, whichever occurs first.
- Use a **CASE** statement to dynamically set payment intervals based on plan type.
- Calculate the adjusted payment amount in the main query using a **CASE** statement that deducts a $9.90 credit on the first payment when upgrading from basic monthly.
- Use the **ROW_NUMBER() OVER ()** to compute a chronological sequential `payment_order` per customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` and `payment_date` to output a structured chronological payment ledger.

#### Answer:
| customer_id | plan_id | plan_name     | payment_date | amount | payment_order |
| ----------- | ------- | ------------- | ------------ | ------ | ------------- |
| 1           | 1       | basic monthly | 2020-08-08   | 9.90   | 1             |
| 1           | 1       | basic monthly | 2020-09-08   | 9.90   | 2             |
| 1           | 1       | basic monthly | 2020-10-08   | 9.90   | 3             |
| 1           | 1       | basic monthly | 2020-11-08   | 9.90   | 4             |
| 1           | 1       | basic monthly | 2020-12-08   | 9.90   | 5             |
| 2           | 3       | pro annual    | 2020-09-27   | 199.00 | 1             |
| 13          | 1       | basic monthly | 2020-12-22   | 9.90   | 1             |
| 15          | 2       | pro monthly   | 2020-03-24   | 19.90  | 1             |
| 15          | 2       | pro monthly   | 2020-04-24   | 19.90  | 2             |
| 16          | 1       | basic monthly | 2020-06-07   | 9.90   | 1             |
| 16          | 1       | basic monthly | 2020-07-07   | 9.90   | 2             |
| 16          | 1       | basic monthly | 2020-08-07   | 9.90   | 3             |
| 16          | 1       | basic monthly | 2020-09-07   | 9.90   | 4             |
| 16          | 1       | basic monthly | 2020-10-07   | 9.90   | 5             |
| 16          | 3       | pro annual    | 2020-10-21   | 189.10 | 6             |
| 18          | 2       | pro monthly   | 2020-07-13   | 19.90  | 1             |
| 18          | 2       | pro monthly   | 2020-08-13   | 19.90  | 2             |
| 18          | 2       | pro monthly   | 2020-09-13   | 19.90  | 3             |
| 18          | 2       | pro monthly   | 2020-10-13   | 19.90  | 4             |
| 18          | 2       | pro monthly   | 2020-11-13   | 19.90  | 5             |
| 18          | 2       | pro monthly   | 2020-12-13   | 19.90  | 6             |
| 19          | 2       | pro monthly   | 2020-06-29   | 19.90  | 1             |
| 19          | 2       | pro monthly   | 2020-07-29   | 19.90  | 2             |
| 19          | 3       | pro annual    | 2020-08-29   | 199.00 | 3             |

This is the output using the following query to show the 8 customers provided in the sample:
````sql
SELECT * FROM payments
WHERE customer_id IN (1,2,11,13,15,16,18,19)
ORDER BY customer_id, payment_date
````

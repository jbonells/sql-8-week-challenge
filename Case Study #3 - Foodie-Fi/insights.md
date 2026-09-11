## A. Customer Journey

### Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
````sql
SELECT
	s.customer_id,
	p.plan_id,
    p.plan_name,
	s.start_date
FROM plans p
JOIN subscriptions s
	ON p.plan_id = s.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
ORDER BY s.customer_id, p.plan_id;
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `plans` and `subscriptions` tables.
- (Optional) Order the final dataset in ascending sequence by `customer_id` and `plan_id` for structured presentation.
Note: I have added `plan_name` event thought it is not present in the sample from the subscriptions table, this way it is clearer for the analysis.

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

- Customer 1: they started the free trial on 1 Aug 2020. After the trial period ended, on 8 Aug 2020, they subscribed to the basic monthly plan.
- Customer 2: they started the free trial on 20 Sep 2020. After the trial period ended, on 27 Sep 2020, they subscribed to the pro annual plan.
- Customer 11: they started the free trial on 19 Nov 2020. After the trial period ended, on 26 Nov 2020, they unsubscribed.
- Customer 13: they started the free trial on 15 Dec 2020. After the trial period ended, on 22 Dec 2020, they subscribed to the basic monthly plan. After three months, on 29 Mar 2021, they upgraded to the pro monthly plan.
- Customer 15: they started the free trial on 17 Mar 2020. After the trial period ended, on 24 Mar 2020, they upgraded to the pro monthly plan. However, the following month, on 29 Apr 2020, tthey unsubscribed.
- Customer 16: they started the free trial on 31 May 2020. After the trial period ended, on 7 Jun 2020, they subscribed to the basic monthly plan. After four months, on 21 Oct 2020, they upgraded to the pro annual plan.
- Customer 18: they started the free trial on 6 Jul 2020. After the trial period ended, on 13 Jul 2020, they subscribed to the pro monthly plan.
- Customer 19: they started the free trial on 22 Jun 2020. After the trial period ended, on 29 Jun 2020, they subscribed to the pro monthly plan. After two months, on 29 Aug 2020, they upgraded to the pro annual plan.


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

- Foodie-Fi has had 1,000 customers.

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
````sql
SELECT 
    TO_CHAR(start_date, 'Month') AS month_name,
    COUNT(*) AS distribution
FROM subscriptions
WHERE plan_id = 0 -- Trial plan ID is 0
GROUP BY EXTRACT(MONTH FROM start_date), TO_CHAR(start_date, 'Month')
ORDER BY EXTRACT(MONTH FROM start_date);
````

#### Steps:
- Use the **TO_CHART** function to pull the month component from the `start_date` column, assigning the alias `month_name`.
- Apply the **COUNT** aggregate function to tally the total trial plans.
- Apply a filter condition (`plan_id = 0`) to include trial plans only.
- (Optional) Order the final dataset in ascending sequence by month for structured presentation.

#### Answer:
| month_name | distribution |
| ---------- | ------------ |
| January    | 88           |
| February   | 68           |
| March      | 94           |
| April      | 81           |
| May        | 88           |
| June       | 79           |
| July       | 89           |
| August     | 88           |
| September  | 87           |
| October    | 79           |
| November   | 75           |
| December   | 84           |

- March has the highest number of trial plans whilst February has the lowest number of them.

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
````sql
SELECT
    s.plan_id,
    p.plan_name,
    COUNT(*) AS event_count
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY s.plan_id, p.plan_name
ORDER BY s.plan_id;
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `subscriptions` and `plans` tables.
- Apply a filter condition within the join to only include `start_date` values occur after the year 2020.
- (Optional) Order the final dataset in ascending sequence by `plan_id` for structured presentation.

#### Answer:
| plan_id | plan_name     | event_count | 
| ------- | ------------- |------------ |
| 1       | pro annual    | 63          |
| 2       | churn         | 71          |
| 3       | pro monthly   | 60          |
| 4       | basic monthly | 8           |

- There are 63 pro annual plans in 2021.
- There are 60 pro monthly plans in 2021.
- There are 8 basic monthly plans in 2021.
- There are 71 customers who have churned in 2021.

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
````sql
SELECT
	p.plan_name,
    COUNT(DISTINCT s.customer_id) AS customers_count,
    ROUND(
        100.0 * COUNT(DISTINCT s.customer_id) / 
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 
        1
    ) AS churn_percentage
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.plan_id = 4 -- Churn plan ID is 4
GROUP BY p.plan_name;
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `subscriptions` and `plans` tables.
- Apply a filter condition (`plan_id = 4`) to include customers who have churned.
- Apply the **COUNT** aggregate function with **DISTINCT** to count those specific customers.
- Apply the **ROUND** function combined with multiplication by 100.0 and division by the total customer count from a subquery to calculate the churn percentage, specifying 1 decimal place.

#### Answer:
| plan_name | customers_count | churn_percentage | 
| --------- | --------------- |----------------- |
| churn     | 307             | 30.7             |

- There are 307 customers who have churned which is 30.7% of the total customers.

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
	p.plan_name,
    COUNT(DISTINCT op.customer_id) AS customers_count,
    ROUND(
        100.0 * COUNT(DISTINCT op.customer_id) / 
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
        0
    ) AS churn_percentage
FROM ordered_plans op
INNER JOIN plans p
    ON op.plan_id = p.plan_id
WHERE op.plan_id = 4 AND op.plan_sequence = 2
GROUP BY p.plan_name;
````

#### Steps:
- Define a Common Table Expression (`ordered_plans`) to process the `subscriptions` table.
- Use **ROW_NUMBER() OVER ()** to assign a chronological sequence to each customer's plans.
- Use an **INNER JOIN** on `plan_id` to connect the `subscriptions` and `plans` tables.
- Apply filter conditions (`plan_id = 4` and `plan_sequence = 2`) to isolate customers who churned straight after their initial free trial.
- Apply the **COUNT** aggregate function with **DISTINCT** to count those specific customers.
- Apply the **ROUND** function combined with multiplication by 100.0 and division by the total customer count from a subquery to calculate the churn percentage, specifying 0 decimal place.

#### Answer:
| plan_name | customers_count | churn_percentage | 
| --------- | --------------- |----------------- |
| churn     | 92              | 9                |

- There are 92 customers who have churned straight after their initial free trial which is 9% of the total customers.

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
GROUP BY p.plan_name;
````

#### Steps:
- Same as the previous exercise with two differences:
	- Remove filter conditions (`plan_id = 4`) to include all customers regardless their plan.
	- Apply the **ROUND** function specifying 1 decimal place.

#### Answer:
| plan_name     | customers_count | plan_percentage | 
| ------------- | --------------- |---------------- |
| basic monthly | 546             | 54.6            |
| churn         | 92              | 9.2             |
| pro annual    | 37              | 3.7             |
| pro monthly   | 325             | 32.5            |

- There are 546 customers who have moved to basic monthly after their initial free trial which is 54.6% of the total customers.
- There are 92 customers who have churned straight after their initial free trial which is 9.2% of the total customers.
- There are 37 customers who have moved to pro annual after their initial free trial which is 3.7% of the total customers.
- There are 325 customers who have moved to pro monthly after their initial free trial which is 32.5% of the total customers.

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
````sql
WITH ordered_plans AS (
	SELECT
  		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS plan_sequence,
  		customer_id,
  		plan_id,
  		start_date
	FROM subscriptions
  	WHERE start_date <= '2020-12-31'
)

SELECT
    p.plan_name,
    COUNT(DISTINCT op.customer_id) AS customers_count,
    ROUND(
        100.0 * COUNT(DISTINCT op.customer_id) / 
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions WHERE start_date <= '2020-12-31'),
        1
    ) AS plan_percentage
FROM ordered_plans op
INNER JOIN plans p
    ON op.plan_id = p.plan_id
WHERE op.plan_sequence = 1
GROUP BY p.plan_name;
````

#### Steps:
- Again, same as the previous exercise with two differences:
	- Use **ROW_NUMBER() OVER ()** to assign a descending sequence to each customer's plans.
	- Apply filter conditions (`start_date <= '2020-12-31` and `plan_sequence = 1`) to isolate customers and plan names until 31st of December 2020.
- Note that the filter condition (`start_date <= '2020-12-31`) is added twice, in the CTE and the subquery.

#### Answer:
| plan_name     | customers_count | plan_percentage | 
| ------------- | --------------- |---------------- |
| basic monthly | 224             | 22.4            |
| churn         | 236             | 23.6            |
| pro annual    | 195             | 19.5            |
| pro monthly   | 326             | 32.6            |
| trial         | 19              | 1.9             |

- There are 224 customers on basic monthly plan which is 22.4% of the total customers.
- There are 236 customers who have churned which is 23.6% of the total customers.
- There are 195 customers on pro annual plan which is 19.5% of the total customers.
- There are 326 customers on pro monthly plan which is 32.6% of the total customers.
- There are 19 customers on free trial which is 1.9% of the total customers.

### 8. How many customers have upgraded to an annual plan in 2020?
````sql
SELECT
    COUNT(DISTINCT customer_id) AS annual_plan_customers
FROM subscriptions
WHERE plan_id = 3 AND start_date <= '2020-12-31';
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique customers, ensuring customers with multiple plans are tallied as a single customer.
- Apply filter conditions (`start_date <= '2020-12-31` and `plan_id = 3`) to isolate customers on an annual plan until 31st of December 2020.

#### Answer:
| annual_plan_customers |
| --------------------- |
| 195                   |

- There are 195 customers that have upgraded to an annual plan in 2020.

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
- Apply a filter condition in the **WHERE** clause (`plan_id = 0`) to include customers who have started a trial.
- Define a Common Table Expression (`annual_plan_dates`) to process the `subscriptions` table.
- Apply a filter condition in the **WHERE** clause (`plan_id = 3`) to include customers who have joined an annual plan.
- Use an **INNER JOIN** on `customer_id` to connect the `trial_plan_dates` and `annual_plan_dates` CTEs.
- Apply the **AVG** aggregate function to the difference between dates, wrap it in **ROUND**, and cast it to an integer to produce a clean whole-number metric.

#### Answer:
| average_days |
| ------------ |
| 105          |

- It takes around 105 days for a customer to upgrade to an annual plan from the day they join Foodie-Fi.

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
		tpd.customer_id,
		(apd.annual_date - tpd.trial_date) AS days_to_annual
	FROM trial_plan_dates tpd
	INNER JOIN annual_plan_dates apd
		ON tpd.customer_id = apd.customer_id
)

SELECT
	CASE 
		WHEN days_to_annual BETWEEN 0 AND 30 THEN '0-30 days'
		WHEN days_to_annual BETWEEN 31 AND 60 THEN '31-60 days'
		WHEN days_to_annual BETWEEN 61 AND 90 THEN '61-90 days'
		WHEN days_to_annual BETWEEN 91 AND 120 THEN '91-120 days'
		WHEN days_to_annual BETWEEN 121 AND 150 THEN '121-150 days'
		WHEN days_to_annual BETWEEN 151 AND 180 THEN '151-180 days'
		ELSE '181+ days'
	END AS period,
	COUNT(customer_id) AS customers
FROM customer_durations
GROUP BY period
ORDER BY MIN(days_to_annual);
````

#### Steps:
- Define two Common Table Expression (`trial_plan_dates` and `annual_plan_dates`) to process the `subscriptions` table exactly like in the previous exercise.
- Define a Common Table Expression (`customer_durations`) to calculate the difference between dates.
- Use an **INNER JOIN** on `customer_id` to connect the `trial_plan_dates` and `annual_plan_dates` CTEs.
- Apply a **CASE** statement to breakdown the average value into 30 day periods.
- Apply the **COUNT** aggregate function to count the customers per each period.

#### Answer:

| period       | customers_count |
| -------------| --------------- |
| 0-30 days    | 49              |
| 31-60 days   | 24              |
| 61-90 days   | 34              |
| 91-120 days  | 35              |
| 121-150 days | 42              |
| 151-180 days | 36              |
| 181+ days    | 38              |

- There are 49 customers that took between 0 and 30 days to upgrade to an annual plan.
- There are 24 customers that took between 31 and 60 days to upgrade to an annual plan.
- There are 34 customers that took between 61 and 90 days to upgrade to an annual plan.
- There are 35 customers that took between 91 and 120 days to upgrade to an annual plan.
- There are 42 customers that took between 121 and 150 days to upgrade to an annual plan.
- There are 36 customers that took between 151 and 180 days to upgrade to an annual plan.
- There are 38 customers that took more than 180 days to upgrade to an annual plan.

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
````sql
WITH customer_plans AS (
	SELECT
		customer_id,
		plan_id,
		LEAD(plan_id) OVER (
			PARTITION BY customer_id
			ORDER BY start_date
		) AS next_plan_id,
		LEAD(start_date) OVER (
			PARTITION BY customer_id
			ORDER BY start_date
		) AS next_plan_date
	FROM subscriptions
)

SELECT
	COUNT(customer_id) AS customers_downgraded
FROM customer_plans
WHERE plan_id = 2
	AND next_plan_id = 1
    AND next_plan_date BETWEEN '2020-01-01' AND '2020-12-31';
````

#### Steps:
- Define a Common Table Expression (`customer_plans`) to process the `subscriptions` table.
- Use **LEAD() OVER ()** to get the next plan the customer purchased and the date it was purchased.
- Use the **COUNT** aggregate function to tally the total number of customers.
- Apply filter conditions (`plan_id = 2`, `next_plan_id = 1` and `next_plan_date BETWEEN '2020-01-01' AND '2020-12-31'`) to isolate customers that downgraded from a pro monthly to a basic monthly plan in 2020.

#### Answer:
| customers_downgraded |
| -------------------- |
| 0                    |

- There were no customers who downgraded from a pro monthly to a basic monthly plan in 2020


## C. Runner and Customer Experience

### The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments
````sql
WITH customer_plans AS (
    SELECT
        s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date,
        LEAD(s.start_date) OVER (
            PARTITION BY s.customer_id
            ORDER BY s.start_date
        ) AS next_plan_date,
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
        generate_series(
            start_date,
            LEAST(next_plan_date - INTERVAL '1 day', '2020-12-31'::DATE),
            CASE
                WHEN plan_id IN (1, 2) THEN INTERVAL '1 month'
                WHEN plan_id = 3 THEN INTERVAL '1 year'
            END
        )::DATE AS payment_date,
        amount
    FROM customer_plans
    WHERE plan_id <> 4
)
SELECT
    customer_id,
    plan_id,
    plan_name,
    payment_date,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY payment_date
    ) AS payment_order
FROM generated_payments
ORDER BY customer_id, payment_date;
````

#### Steps:
- Define a Common Table Expression (`customer_plans`) to process the `subscriptions` table.
- Use **LEAD() OVER ()** to get the next plan date when there is a change of plan.
- Use an **INNER JOIN** on `plan_id` to connect the `subscriptions` and `plans` tables.
- Apply a filter condition (`plan_id <> 0`) to exclude customer's initial free trial.
- Define a Common Table Expression (`generated_payments`) to process the `customer_plans` CTE.
- Use **generate_series()** to construct the payment schedule, while using a **CASE** statement to dynamically adjusting intervals for monthly versus annual plans.
- Use **LEAST()** for capping the series at either the `next_plan_date` minus one day or 31 of December 2020.
- Apply a filter condition (`plan_id <> 4`) to exclude churned customer so payments will stop.
- Run the final query using **ROW_NUMBER() OVER ()** to assign a chronological sequence to each customer's payment.

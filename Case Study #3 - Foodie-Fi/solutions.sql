/* --------------------
   Case Study Questions
   --------------------*/

-- A. Customer Journey

-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
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


-- B. Data Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?
SELECT
	COUNT(DISTINCT customer_id) AS customers
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT 
    TO_CHAR(DATE_TRUNC('month', s.start_date), 'FMMonth') AS month_name,
    COUNT(*) AS trials
FROM subscriptions s
INNER JOIN plans p
	ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY month_name, DATE_TRUNC('month', s.start_date)
ORDER BY DATE_TRUNC('month', s.start_date);

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
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

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
    COUNT(DISTINCT customer_id) FILTER (WHERE plan_id = 4) AS churned_customers,
    ROUND(
        100.0 * COUNT(DISTINCT customer_id) FILTER (WHERE plan_id = 4)
        / COUNT(DISTINCT customer_id),
        1
    ) AS churn_percentage
FROM subscriptions;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
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

-- 6. What is the number and percentage of customer plans after their initial free trial?
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

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
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

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT
    COUNT(DISTINCT s.customer_id) AS annual_plan_customers
FROM subscriptions s
INNER JOIN plans p
	ON s.plan_id = p.plan_id
WHERE s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
	AND p.plan_name = 'pro annual';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
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

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
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

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
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


-- C. Runner and Customer Experience

-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
--  - monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
--  - upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
--  - upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
--  - once a customer churns they will no longer make payments
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

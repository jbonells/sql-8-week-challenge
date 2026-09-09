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
FROM plans p
JOIN subscriptions s
	ON p.plan_id = s.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
ORDER BY s.customer_id, p.plan_id;


-- B. Data Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?
SELECT
	COUNT(DISTINCT customer_id) AS customers
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT 
    TO_CHAR(start_date, 'Month') AS month_name,
    COUNT(*) AS distribution
FROM subscriptions
WHERE plan_id = 0 -- Trial plan ID is 0
GROUP BY EXTRACT(MONTH FROM start_date), TO_CHAR(start_date, 'Month')
ORDER BY EXTRACT(MONTH FROM start_date);

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
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

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
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

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
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

-- 6. What is the number and percentage of customer plans after their initial free trial?
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
    COUNT(DISTINCT customer_id) AS annual_plan_customers
FROM subscriptions
WHERE plan_id = 3 AND start_date <= '2020-12-31';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
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

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
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


-- C. Runner and Customer Experience

-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
--  - monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
--  - upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
--  - upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
--  - once a customer churns they will no longer make payments

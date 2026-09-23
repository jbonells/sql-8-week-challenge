/* --------------------
   Case Study Questions
   --------------------*/

-- A. Customer Nodes Exploration

-- 1. How many unique nodes are there on the Data Bank system?
SELECT
	COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT
	r.region_name,
    COUNT(DISTINCT cn.node_id) AS unique_nodes
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
SELECT 
    ROUND(AVG(end_date - start_date), 2) AS avg_node_reallocation_days
FROM customer_nodes
WHERE end_date <> '9999-12-31';

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT 
    r.region_name,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY cn.end_date - cn.start_date) AS median,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY cn.end_date - cn.start_date) AS percentile_80,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY cn.end_date - cn.start_date) AS percentile_95
FROM customer_nodes cn
INNER JOIN regions r
	ON cn.region_id = r.region_id
WHERE cn.end_date <> '9999-12-31'
GROUP BY r.region_name
ORDER BY r.region_name;


-- B. Customer Transactions

-- 1. What is the unique count and total amount for each transaction type?
SELECT 
    txn_type,
    COUNT(*) AS transaction_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH customer_deposits AS (
    SELECT
        customer_id,
        COUNT(*) AS deposit_count,
        SUM(txn_amount) AS deposit_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)

SELECT
    ROUND(AVG(deposit_count), 2) AS avg_deposit_count,
    ROUND(AVG(deposit_amount), 2) AS avg_deposit_amount
FROM customer_deposits;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_activity AS(
	SELECT
		customer_id,
		EXTRACT(MONTH FROM txn_date) AS month,
		COUNT(*) FILTER (WHERE txn_type = 'deposit') AS deposit_count,
        COUNT(*) FILTER (WHERE txn_type = 'purchase') AS purchase_count,
        COUNT(*) FILTER (WHERE txn_type = 'withdrawal') AS withdrawal_count
	FROM customer_transactions
	GROUP BY customer_id, month
)

SELECT
	month,
    COUNT(DISTINCT customer_id) AS customers
FROM monthly_activity
WHERE deposit_count > 1 AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY month
ORDER BY month;

-- 4. What is the closing balance for each customer at the end of the month?
WITH monthly_activity AS (
	SELECT
		customer_id,
		DATE_TRUNC('month', txn_date)::DATE AS month,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
	FROM customer_transactions
	GROUP BY customer_id, month
),
full_calendar AS (
	SELECT
		c.customer_id,
		m.month
	FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
	CROSS JOIN (SELECT DISTINCT DATE_TRUNC('month', txn_date)::DATE AS month FROM customer_transactions) m
)

SELECT
	fc.customer_id,
	EXTRACT(MONTH FROM fc.month) AS month,
	SUM(COALESCE(ma.net_change, 0)) OVER (
		PARTITION BY fc.customer_id ORDER BY fc.month
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) AS closing_balance
FROM full_calendar fc
LEFT JOIN monthly_activity ma
	ON ma.customer_id = fc.customer_id
	AND ma.month = fc.month
ORDER BY fc.customer_id, fc.month;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH monthly_activity AS (
	SELECT
		customer_id,
		DATE_TRUNC('month', txn_date)::DATE AS month,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
	FROM customer_transactions
	GROUP BY customer_id, month
),
full_calendar AS (
	SELECT
		c.customer_id,
		m.month
	FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
	CROSS JOIN (SELECT DISTINCT DATE_TRUNC('month', txn_date)::DATE AS month FROM customer_transactions) m
),
closing_balances AS (
	SELECT
		fc.customer_id,
		fc.month,
		SUM(COALESCE(ma.net_change, 0)) OVER (
			PARTITION BY fc.customer_id ORDER BY fc.month
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		) AS closing_balance
	FROM full_calendar fc
	LEFT JOIN monthly_activity ma
		ON ma.customer_id = fc.customer_id
		AND ma.month = fc.month
),
balance_comparison AS (
	SELECT DISTINCT
		customer_id,
		FIRST_VALUE(closing_balance) OVER (
			PARTITION BY customer_id ORDER BY month
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) AS first_balance,
		LAST_VALUE(closing_balance) OVER (
			PARTITION BY customer_id ORDER BY month
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS last_balance
	FROM closing_balances
),
customer_change AS (
SELECT
	customer_id,
    ROUND(100.0 * (last_balance - first_balance) / ABS(first_balance), 2) AS pct_change
FROM balance_comparison
)

SELECT
    ROUND(100.0 * COUNT(*) FILTER (WHERE pct_change > 5) / COUNT(*), 2) AS pct_customers_over_5_percent
FROM customer_change;


-- C. Data Allocation Challenge

-- Option 1: data is allocated based off the amount of money at the end of the previous month
WITH transaction_impacts AS (
    SELECT
        customer_id,
        txn_date AS date,
        EXTRACT(MONTH FROM txn_date) AS month,
        txn_type AS transaction,
        CASE
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE -txn_amount
        END AS amount
    FROM customer_transactions
),
running_balances AS (
    SELECT
        customer_id,
        date,
        month,
        transaction,
        amount,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM transaction_impacts
),
monthly_endpoints AS (
    SELECT DISTINCT
        customer_id,
        month,
        LAST_VALUE(running_balance) OVER (
            PARTITION BY customer_id, month
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS end_of_month_balance
    FROM running_balances
),
end_of_month_allocation AS (
    SELECT
        customer_id,
        month,
		end_of_month_balance,
        LAG(end_of_month_balance, 1, 0::BIGINT) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS data_allocation
    FROM monthly_endpoints
)

SELECT
    rb.customer_id,
    rb.date,
    rb.month,
    rb.transaction,
    rb.amount,
    rb.running_balance,
    eom.end_of_month_balance,
    MIN(rb.running_balance) OVER(PARTITION BY rb.customer_id, rb.month) AS min_balance,
    ROUND(AVG(rb.running_balance) OVER(PARTITION BY rb.customer_id, rb.month), 2) AS avg_balance,
    MAX(rb.running_balance) OVER(PARTITION BY rb.customer_id, rb.month) AS max_balance,
    eom.data_allocation
FROM running_balances rb
INNER JOIN end_of_month_allocation eom
	ON rb.customer_id = eom.customer_id
	AND rb.month = eom.month
ORDER BY rb.customer_id, rb.date;

-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
WITH transaction_impacts AS (
    SELECT
        customer_id,
        txn_date AS date,
        EXTRACT(MONTH FROM txn_date) AS month,
        txn_type AS transaction,
        CASE
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE -txn_amount
        END AS amount
    FROM customer_transactions
),
running_balances AS (
    SELECT
        customer_id,
        date,
        month,
        transaction,
        amount,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM transaction_impacts
),
rolling_30day_avg AS (
    SELECT
        customer_id,
        date,
        month,
        AVG(running_balance) OVER (
            PARTITION BY customer_id
            ORDER BY date
            RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
        ) AS avg_balance_prior_30_days
    FROM running_balances
),
monthly_rolling_avg_endpoints AS (
    SELECT DISTINCT
        customer_id,
        month,
        LAST_VALUE(avg_balance_prior_30_days) OVER (
            PARTITION BY customer_id, month
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS end_of_month_avg_balance
    FROM rolling_30day_avg
),
previous_30_days_allocation AS (
    SELECT
        customer_id,
        month,
        end_of_month_avg_balance,
        LAG(end_of_month_avg_balance, 1, 0::NUMERIC) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS data_allocation
    FROM monthly_rolling_avg_endpoints
)

SELECT
    rb.customer_id,
    rb.date,
    rb.month,
    rb.transaction,
    rb.amount,
    rb.running_balance,
    ROUND(pd.end_of_month_avg_balance, 2) AS end_of_month_balance,
    MIN(rb.running_balance) OVER(PARTITION BY rb.customer_id, rb.month) AS min_balance,
    ROUND(AVG(rb.running_balance) OVER(PARTITION BY rb.customer_id, rb.month), 2) AS avg_balance,
    MAX(rb.running_balance) OVER(PARTITION BY rb.customer_id, rb.month) AS max_balance,
	ROUND(pd.data_allocation, 2) AS data_allocation
FROM running_balances rb
INNER JOIN previous_30_days_allocation pd
	ON rb.customer_id = pd.customer_id
	AND rb.month = pd.month
ORDER BY rb.customer_id, rb.date;

-- Option 3: data is updated real-time
WITH transaction_impacts AS (
    SELECT
        customer_id,
        txn_date AS date,
        EXTRACT(MONTH FROM txn_date) AS month,
        txn_type AS transaction,
        CASE
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE -txn_amount
        END AS amount
    FROM customer_transactions
),
running_balances AS (
    SELECT
        customer_id,
        date,
        month,
        transaction,
        amount,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM transaction_impacts
),
real_time_allocation AS (
    SELECT
        customer_id,
        date,
        month,
        transaction,
        amount,
		running_balance,
        GREATEST(running_balance, 0) AS data_allocation
    FROM running_balances
)

SELECT
    customer_id,
    date,
    month,
    transaction,
    amount,
    running_balance,
    LAST_VALUE(running_balance) OVER (
		PARTITION BY customer_id, month 
		ORDER BY date 
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS end_of_month_balance,
    MIN(running_balance) OVER(PARTITION BY customer_id, month) AS min_balance,
    ROUND(AVG(running_balance) OVER(PARTITION BY customer_id, month), 2) AS avg_balance,
    MAX(running_balance) OVER(PARTITION BY customer_id, month) AS max_balance,
	data_allocation
FROM real_time_allocation
ORDER BY customer_id, date;


-- D. Extra Challenge

-- Part 1: Simple Interest (Non-Compounding)
WITH RECURSIVE customer_date_grid AS (
    SELECT
		c.customer_id,
		d.date
	FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
	CROSS JOIN (
      	SELECT generate_series(MIN(txn_date), MAX(txn_date), INTERVAL '1 day')::date AS date
        FROM customer_transactions
    ) d
),
daily_net AS (
    SELECT
        customer_id,
        txn_date AS date,
		SUM(
			CASE
				WHEN txn_type = 'deposit' THEN txn_amount
				ELSE -txn_amount
			END
		) AS net_amount
    FROM customer_transactions
	GROUP BY customer_id, date
),
daily_grid AS (
    SELECT
		g.customer_id,
		g.date,
		COALESCE(dn.net_amount, 0) AS net_amount
    FROM customer_date_grid g
    LEFT JOIN daily_net dn
		ON g.customer_id = dn.customer_id
		AND g.date = dn.date
),
daily_balance AS (
    SELECT
	customer_id,
	date,
	ROUND(net_amount::NUMERIC, 2) AS balance
    FROM daily_grid
    WHERE date = (SELECT MIN(date) FROM daily_grid)

    UNION ALL

    SELECT
		g.customer_id,
		g.date,
		ROUND(GREATEST(db.balance, 0) * (1 + 0.06/365.0) + g.net_amount, 2) AS balance
    FROM daily_grid g
    INNER JOIN daily_balance db
		ON g.customer_id = db.customer_id
		AND g.date = db.date + INTERVAL '1 day'
),
monthly_endpoints AS (
    SELECT DISTINCT
        customer_id,
        EXTRACT(MONTH FROM date) AS month,
        LAST_VALUE(balance) OVER (
            PARTITION BY customer_id, EXTRACT(MONTH FROM date)
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS end_of_month_balance
    FROM daily_balance
)

SELECT
    month,
    TO_CHAR(SUM(GREATEST(end_of_month_balance, 0)), 'FM999,999,999.99') AS data_required
FROM monthly_endpoints
GROUP BY month
ORDER BY month;

--Part 2: Daily Compounding Interest
WITH customer_date_grid AS (
    SELECT
		c.customer_id,
		d.date
	FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
	CROSS JOIN (
      	SELECT generate_series(MIN(txn_date), MAX(txn_date), INTERVAL '1 day')::date AS date
        FROM customer_transactions
    ) d
),
daily_net AS (
    SELECT
        customer_id,
        txn_date AS date,
		SUM(
			CASE
				WHEN txn_type = 'deposit' THEN txn_amount
				ELSE -txn_amount
			END
		) AS net_amount
    FROM customer_transactions
	GROUP BY customer_id, date
),
daily_grid AS (
    SELECT
		g.customer_id,
		g.date,
		COALESCE(dn.net_amount, 0) AS net_amount
    FROM customer_date_grid g
    LEFT JOIN daily_net dn
		ON g.customer_id = dn.customer_id
		AND g.date = dn.date
),
daily_running_balance AS (
    SELECT
        customer_id,
		date,
        SUM(net_amount) OVER (
            PARTITION BY customer_id ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS raw_balance
    FROM daily_grid
),
daily_simple_interest AS (
    SELECT
        customer_id,
		date,
		raw_balance,
        GREATEST(raw_balance, 0) * (0.06/365.0) AS daily_interest
    FROM daily_running_balance
),
daily_balance_simple AS (
    SELECT
        customer_id,
		date,
        raw_balance + SUM(daily_interest) OVER (
            PARTITION BY customer_id ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS balance_with_simple_interest
    FROM daily_simple_interest
),
monthly_endpoints AS (
    SELECT DISTINCT
        EXTRACT(MONTH FROM date) AS month,
        LAST_VALUE(balance_with_simple_interest) OVER (
            PARTITION BY customer_id, EXTRACT(MONTH FROM date)
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS end_of_month_balance
    FROM daily_balance_simple
)

SELECT
    month,
	TO_CHAR(SUM(GREATEST(end_of_month_balance, 0)), 'FM999,999,999.99') AS data_required
FROM monthly_endpoints
GROUP BY month
ORDER BY month;

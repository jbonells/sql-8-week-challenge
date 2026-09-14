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
FROM data_bank.customer_nodes
WHERE end_date != '9999-12-31';

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT 
    r.region_name,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY cn.end_date - cn.start_date) AS median,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY cn.end_date - cn.start_date) AS percentile_80,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY cn.end_date - cn.start_date) AS percentile_95
FROM customer_nodes cn
INNER JOIN regions r
	ON cn.region_id = r.region_id
WHERE cn.end_date != '9999-12-31'
GROUP BY r.region_name
ORDER BY r.region_name;


-- B. Customer Transactions

-- 1. What is the unique count and total amount for each transaction type?
SELECT 
    txn_type,
    COUNT(DISTINCT customer_id) AS unique_customers,
    TO_CHAR(SUM(txn_amount), 'FM999,999,999') AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH customer_deposit_summary AS (
    SELECT
        COUNT(txn_amount) AS deposit_count,
        SUM(txn_amount) AS total_deposit_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT 
    ROUND(AVG(deposit_count), 2) AS avg_deposit_count,
    ROUND(AVG(total_deposit_amount), 2) AS avg_deposit_amount
FROM customer_deposit_summary;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH customer_monthly_activity AS(
	SELECT
		customer_id,
		EXTRACT(MONTH FROM txn_date) AS month_number,
		TO_CHAR(txn_date, 'Month') AS month,
		COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
		COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
		COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
	FROM customer_transactions
	GROUP BY customer_id, month_number, month
)

SELECT
	month,
    COUNT(customer_id) AS customers
FROM customer_monthly_activity
WHERE deposit_count > 1 AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY month_number, month
ORDER BY month_number;

-- 4. What is the closing balance for each customer at the end of the month?
WITH monthly_activity AS (
    SELECT
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month_number,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            ELSE -txn_amount 
        END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month_number
),
dense_calendar AS (
    SELECT
        c.customer_id,
        m.month_number,
  		TO_CHAR(TO_DATE(m.month_number::text, 'MM'), 'Month') AS month,
        COALESCE(a.net_change, 0) AS monthly_change
    FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
    CROSS JOIN (SELECT DISTINCT EXTRACT(MONTH FROM txn_date) AS month_number FROM customer_transactions) m
    LEFT JOIN monthly_activity a
		ON c.customer_id = a.customer_id 
		AND m.month_number = a.month_number
)

SELECT
	customer_id,
    month,
	SUM(monthly_change) OVER (
		PARTITION BY customer_id 
		ORDER BY month_number
	) AS closing_balance
FROM dense_calendar
ORDER BY customer_id, month_number;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH monthly_activity AS (
    SELECT
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            ELSE -txn_amount 
        END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month
),
dense_calendar AS (
    SELECT
        c.customer_id,
        m.month,
  		COALESCE(a.net_change, 0) AS monthly_change
    FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
    CROSS JOIN (SELECT DISTINCT EXTRACT(MONTH FROM txn_date) AS month FROM customer_transactions) m
    LEFT JOIN monthly_activity a
		ON c.customer_id = a.customer_id 
		AND m.month = a.month
),
closing_balances AS (
	SELECT
		customer_id,
  		month,
		SUM(monthly_change) OVER (
			PARTITION BY customer_id 
			ORDER BY month
		) AS closing_balance
	FROM dense_calendar
),
balance_comparison AS (
	SELECT
		customer_id,
		MAX(CASE WHEN month = 1 THEN closing_balance END) AS first_balance,
		MAX(CASE WHEN month = 4 THEN closing_balance END) AS last_balance    
	FROM closing_balances
	GROUP BY customer_id
)

SELECT 
    ROUND(
        100.0 * SUM(CASE WHEN last_balance > first_balance * 1.05 THEN 1 ELSE 0 END) 
        / COUNT(*),
        2
    ) AS pct_customers_over_5_percent
FROM balance_comparison;


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


--Part 2: Daily Compounding Interest

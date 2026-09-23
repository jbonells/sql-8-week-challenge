## A. Customer Nodes Exploration

### 1. How many unique nodes are there on the Data Bank system?
````sql
SELECT
	COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and calculate the total number of unique nodes across the system.
- (Optional) Assign the alias `unique_nodes` to the resulting column for clear presentation in the final output report.

#### Answer:
| unique_nodes |
| ------------ |
| 5            |

### 2. What is the number of nodes per region?
````sql
SELECT
	r.region_name,
    COUNT(DISTINCT cn.node_id) AS unique_nodes
FROM customer_nodes cn
INNER JOIN regions r
	ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
````

#### Steps:
- Use an **INNER JOIN** on `region_name` to connect the `customer_nodes` and `regions` tables.
- Group the joined records by `region_name` to aggregate node metrics per region.
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the volume of unique nodes within each region.
- (Optional) Order the final dataset in ascending sequence by `region_name` for structured presentation.

#### Answer:
| region_name | unique_nodes |
| ----------- | ------------ |
| Africa      | 5            |
| America     | 5            |
| Asia        | 5            |
| Australia   | 5            |
| Europe      | 5            |

### 3. How many customers are allocated to each region?
````sql
SELECT
	r.region_name,
    COUNT(DISTINCT cn.customer_id) AS customers
FROM customer_nodes cn
INNER JOIN regions r
	ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
````

#### Steps:
- Use an **INNER JOIN** on `region_name` to connect the `customer_nodes` and `regions` tables.
- Group the joined records by `region_name` to aggregate customer metrics per region.
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the volume of unique customers within each region.
- (Optional) Order the final dataset in ascending sequence by `region_name` for structured presentation.

#### Answer:
| region_name | customers |
| ----------- | --------- |
| Africa      | 102       |
| America     | 105       |
| Asia        | 95        |
| Australia   | 110       |
| Europe      | 88        |

### 4. How many days on average are customers reallocated to a different node?
````sql
SELECT 
    ROUND(AVG(end_date - start_date), 2) AS avg_node_reallocation_days
FROM customer_nodes
WHERE end_date <> '9999-12-31';
````

#### Steps:
- Apply a **WHERE** clause (`end_date <> '9999-12-31'`) to isolate completed node reallocations, excluding ongoing placeholder dates that would distort the average.
- Subtract `start_date` from `end_date` to calculate the duration in days spent at each assigned node.
- Apply the **AVG** aggregate function to calculate the mean reallocation timeframe.
- Wrap the calculation in **ROUND** to format the final average duration to 2 decimal places.

#### Answer:
| avg_node_reallocation_days |
| -------------------------- |
| 14.63                      |

### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
````sql
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
````

#### Steps:
- Use an **INNER JOIN** on `region_name` to connect the `customer_nodes` and `regions` tables.
- Apply a **WHERE** clause (`end_date <> '9999-12-31'`) to isolate completed node reallocations, excluding ongoing placeholder dates that would distort the average.
- Use **PERCENTILE_CONT(...) WITHIN GROUP (ORDER BY ...)** to calculate the 50th percentile (median), 80th percentile, and 95th percentile of node reallocation durations in days for each region.
- (Optional) Order the final dataset in ascending sequence by `region_name` for structured presentation.

#### Answer:
| region_name | median | percentile_80 | percentile_95 |
| ----------- | ------ | ------------- | ------------- |
| Africa      | 15     | 24            | 28            |
| America     | 15     | 23            | 28            |
| Asia        | 15     | 23            | 28            |
| Australia   | 15     | 23            | 28            |
| Europe      | 15     | 24            | 28            |


## B. Customer Transactions

### 1. What is the unique count and total amount for each transaction type?
````sql
SELECT 
    txn_type,
    COUNT(*) AS transaction_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;
````

#### Steps:
- Group the records by `txn_type` to aggregate transaction activity by type.
- Apply the **COUNT** aggregate function to calculate the total volume of transactions per type.
- Use the **SUM** aggregate function to calculate the cumulative monetary value for each transaction type.
- (Optional) Order the final dataset in ascending sequence by `txn_type` for structured presentation.

#### Answer:
| txn_type   | transaction_count | total_amount |
| ---------- | ----------------- | ------------ |
| deposit    | 2671              | 1359168      |
| purchase   | 1617              | 806537       |
| withdrawal | 1580              | 793003       |

### 2. What is the average total historical deposit counts and amounts for all customers?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`customer_deposit_summary`) querying the `customer_transactions` table.
- Apply a **WHERE** clause (`txn_type = 'deposit'`) to isolate deposit records.
- Group the records by `customer_id` to aggregate deposit activity at the customer level.
- Apply the **COUNT** aggregate function to calculate each customer's total deposit frequency.
- Use the **SUM** aggregate function to calculate each customer's cumulative deposited value.
- Apply the **AVG** aggregate function across both aggregated fields in the main query to calculate the overall mean deposit count and mean deposit amount per customer.
- Wrap both calculations in **ROUND** to format the final average metrics to 2 decimal places.

#### Answer:
| avg_deposit_count | avg_deposit_amount |
| ----------------- | ------------------ |
| 5.34              | 2718.34            |

### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`monthly_activity`) querying the `customer_transactions` table.
- Use **EXTRACT()** to derive the numeric month as `month`.
- Apply conditional aggregation using **COUNT() FILTER (WHERE ...)** grouped by `customer_id` and `month` to compute monthly transaction totals for deposits, purchases, and withdrawals per customer.
- Apply a **WHERE** clause (`deposit_count > 1 AND (purchase_count >= 1 OR withdrawal_count >= 1)`) in the main query to isolate customer months meeting the active engagement criteria.
- Group the filtered records by `month` to aggregate activity metrics per calendar month.
- Apply the **COUNT** aggregate function with **DISTINCT** to aggregate activity metrics per calendar month.
- (Optional) Order the final dataset sequentially by `month` for structured presentation.

#### Answer:
| month | customers |
| ----- | --------- |
| 1     | 168       |
| 2     | 181       |
| 3     | 192       |
| 4     | 70        |

### 4. What is the closing balance for each customer at the end of the month?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`monthly_activity`) querying the `customer_transactions` table.
- Use **DATE_TRUNC** to truncate transaction dates to first-of-the-month dates.
- Group records by `customer_id` and `month` to aggregate transaction activity per individual customer for each distinct calendar month.
- Apply a **CASE** statement inside a **SUM** aggregate function to calculate monthly net cash flow by assigning positive values to deposits and negative values to withdrawals and purchases.
- Define a Common Table Expression (`full_calendar`) that take **DISTINCT** `customer_id` from a sub-query and **CROSS JOIN** them with unique numeric months from `customer_transactions` table.
- Use a **LEFT JOIN** on `customer_id` and `month_number` between `full_calendar` and `monthly_activity` CTEs to ensure inactive months with zero transactions are preserved.
- Use **EXTRACT(MONTH FROM ...)** to extract the numeric calendar month.
- Wrap `net_change` in **COALESCE** to replace `NULL` values with 0 for inactive months.
- Use the window function **SUM() OVER ()** with partition by `customer_id` and order by `month_number` to compute each customer's running balance over time.
- (Optional) Order the final dataset in ascending sequence by `customer_id` and `month` for structured presentation.

#### Answer:
| customer_id | month | closing_balance |
| ----------- | ------| --------------- |
| 1           | 1     | 312             |
| 1           | 2     | 312             |
| 1           | 3     | -640            |
| 1           | 4     | -640            |
| 2           | 1     | 549             |
| 2           | 2     | 549             |
| 2           | 3     | 610             |
| 2           | 4     | 610             |
| 3           | 1     | 144             |
| 3           | 2     | -821            |
| 3           | 3     | -1222           |
| 3           | 4     | -729            |

- I am only showing the first 3 customers for reference.

### 5. What is the percentage of customers who increase their closing balance by more than 5%?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`monthly_activity`) querying the `customer_transactions` table.
- Use **DATE_TRUNC** to truncate transaction dates to first-of-the-month dates.
- Group records by `customer_id` and `month` to aggregate transaction activity per individual customer for each distinct calendar month.
- Apply a **CASE** statement inside a **SUM** aggregate function to calculate monthly net cash flow by assigning positive values to deposits and negative values to withdrawals and purchases.
- Define a Common Table Expression (`full_calendar`) that take **DISTINCT** `customer_id` from a sub-query and **CROSS JOIN** them with unique numeric months from `customer_transactions` table.
- Define a Common Table Expression (`closing_balances`) querying the `full_calendar` CTE.
- Use a **LEFT JOIN** on `customer_id` and `month_number` between `full_calendar` and `monthly_activity` CTEs to ensure inactive months with zero transactions are preserved.
- Wrap `net_change` in **COALESCE** to replace `NULL` values with 0 for inactive months.
- Use the window function **SUM() OVER ()** with partition by `customer_id` and order by `month_number` to compute each customer's running balance over time.
- Define a Common Table Expression (`balance_comparison`) querying the `closing_balances` CTE using **SELECT DISTINCT** to extract one record per customer.
- Apply **FIRST_VALUE()** and **LAST_VALUE()** window functions partitioned by `customer_id` and ordered by `month` to capture each customer's initial and final balance respectively.
- Define a Common Table Expression (`customer_change`) querying the `balance_comparison` CTE to calculate each customer's percentage growth.
- Apply conditional aggregation using **COUNT() FILTER (WHERE ...)** multiplied by 100.0 to calculate the proportion of qualifying customers.
- Use **COUNT()** to divide by the total customer count.
- Wrap the calculation with **ROUND** to present the result as a percentage rounded to two decimal places.

#### Answer:
| pct_customers_over_5_percent |
| ---------------------------- |
| 33.20                        |


## C. Data Allocation Challenge

To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time

For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
- running customer balance column that includes the impact each transaction
- customer balance at the end of each month
- minimum, average and maximum values of the running balance for each customer

Using all of the data available - how much data would have been required for each option on a monthly basis?

### Option 1: data is allocated based off the amount of money at the end of the previous month
````sql
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
````

#### Steps:
- Phase 1: Standardise Transaction Impacts
	- Define a Common Table Expression (`transaction_impacts`) querying the `customer_transactions` table.
	- Use **EXTRACT()** to pull a numeric month value from the date for chronological grouping.
	- Apply a **CASE** statement to standardise the financial impact, keeping deposits positive and converting withdrawals/purchases into negative values.
- Phase 2: Calculate Transaction-Level Balances
	- Define a Common Table Expression (`running_balances`) querying the `transaction_impacts` CTE.
	- Use the window function **SUM() OVER ()** partitioned by `customer_id` and order by `date` to aggregate the standardised amounts into a continuous running balance.
- Phase 3: Isolate Month-End Snapshots
	- Define a Common Table Expression (`monthly_endpoints`) querying the `running_balances` CTE.
	- Use the window function **LAST_VALUE() OVER ()** partitioned by `customer_id` and `month`, and order by `date` to capture the final running balance recorded for each customer within a given month.
- Phase 4: Apply Option 1 Business Logic
	- Define a Common Table Expression (`end_of_month_allocation`) querying the `monthly_endpoints` CTE.
	- Use the window function **LAG() OVER ()** partitioned by `customer_id` and order by `month` to look exactly one row back and retrieve the previous month's ending balance to serve as the data allocation limit.
	- Include a default fallback of 0 within the function to properly handle a customer's very first month of activity.
- Phase 5: Compile Final Monthly Metrics (Main Query)
	- Use an **INNER JOIN** on `customer_id` and `month` to connect the `running_balances` and `end_of_month_allocation` CTEs.
	- Generate the requested summary metrics by applying **MIN()**, **AVG()**, and **MAX()** window functions to the running balances, partitioned by `customer_id` and `month`.
	- Wrap the average metric in a **ROUND** function to cleanly format the output to two decimal places.
	- Order the final dataset chronologically by `customer_id` and `date` for structured presentation.

### Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
````sql
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
````

#### Steps:
- Phase 1: Standardise Transaction Impacts
	- Define a Common Table Expression (`transaction_impacts`) querying the `customer_transactions` table.
	- Use **EXTRACT()** to pull a numeric month value from the date for chronological grouping.
	- Apply a **CASE** statement to standardise the financial impact, keeping deposits positive and converting withdrawals/purchases into negative values.
- Phase 2: Calculate Transaction-Level Balances
	- Define a Common Table Expression (`running_balances`) querying the `transaction_impacts` CTE.
	- Use the window function **SUM() OVER ()** partitioned by `customer_id` and order by `date` to aggregate the standardised amounts into a continuous running balance.
- Phase 3: Generate the Rolling Time Window
	- Define a Common Table Expression (`rolling_30day_avg`) querying the `running_balances` CTE.
	- Use the window function **AVG() OVER ()** to the transaction running balances partitioned by `customer_id` and order by `date`.
	- Use the `RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW` window frame to evaluate the average of the balances specifically tied to transaction dates occurring within the 30 days leading up to the current row.
- Phase 4: Isolate Month-End Averages
	- Define a Common Table Expression (`monthly_rolling_avg_endpoints`) querying the `rolling_30day_avg` CTE.
	- Use the window function **LAST_VALUE() OVER ()** partitioned by `customer_id` and `month`, and order by `date` to capture the final 30-day average calculation recorded for each customer before the month ends.
- Phase 5: Apply Option 2 Business Logic
	- Define a Common Table Expression (`previous_30_days_allocation`) querying the `monthly_rolling_avg_endpoints` CTE.
	- Use the window function **LAG() OVER ()** partitioned by `customer_id` and order by `month` to look exactly one row back and retrieve the previous month's final rolling average to serve as the new month's data allocation.
	- Include a default fallback of 0 within the function to correctly handle a customer's very first active month.
- Phase 6: Compile Final Monthly Metrics
	- Use an **INNER JOIN** on `customer_id` and `month` to connect the `running_balances` and `end_of_month_allocation` CTEs.
	- Generate the requested summary metrics by applying **MIN()**, **AVG()**, and **MAX()** window functions to the running balances, partitioned by `customer_id` and `month`.
	- Wrap the average metric, `end_of_month_avg_balance`, and `data_allocation` in a **ROUND** function to cleanly format the output to two decimal places.
	- Order the final dataset chronologically by `customer_id` and `date` for structured presentation.

### Option 3: data is updated real-time
````sql
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
````

#### Steps:
- Phase 1: Standardise Transaction Impacts
	- Define a Common Table Expression (`transaction_impacts`) querying the `customer_transactions` table.
	- Use **EXTRACT()** to pull a numeric month value from the date for chronological grouping.
	- Apply a **CASE** statement to standardise the financial impact, keeping deposits positive and converting withdrawals/purchases into negative values.
- Phase 2: Calculate Transaction-Level Balances
	- Define a Common Table Expression (`running_balances`) querying the `transaction_impacts` CTE.
	- Use the window function **SUM() OVER ()** partitioned by `customer_id` and order by `date` to aggregate the standardised amounts into a continuous running balance.
- Phase 3: Apply Option 3 Business Logic
	- Define a Common Table Expression (`real_time_allocation`) querying the `running_balances` CTE.
	- Use the **GREATEST()** function to establish the real-time data allocation, comparing the current running balance against 0 to ensure the provisioned data never falls below zero.
- Phase 4: Compile Final Monthly Metrics
	- Use the window function **LAST_VALUE() OVER ()** partitioned by `customer_id` and `month`, and order by `date` to capture the final running balance recorded for each customer within a given month.
	- Generate the requested summary metrics by applying **MIN()**, **AVG()**, and **MAX()** window functions to the running balances, partitioned by `customer_id` and `month`.
	- Wrap the average metric in a **ROUND** function to cleanly format the output to two decimal places.
	- Order the final dataset chronologically by `customer_id` and `date` for structured presentation.


## D. Extra Challenge

### Part 1: Simple Interest (Non-Compounding)
````sql
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
````

#### Steps:
- Phase 1: Generate a Continuous Global Calendar (customer_date_grid)
	- Define a **RECURSIVE** Common Table Expression (`customer_date_grid`) to generate a Global Calendar.
	- Use a subquery to find the absolute minimum and maximum transaction dates across the entire database.
	- Use the **generate_series()** function to create a continuous, uninterrupted chronological timeline.
    - Apply a **CROSS JOIN** to pair every distinct `customer_id` with every single `date` in the timeline, ensuring there are no gaps in any customer's calendar.
- Phase 2: Standardise and Condense Daily Impacts
	- Define a Common Table Expression (`daily_net`) querying the `customer_transactions` table.
	- Apply a **CASE** statement to standardise the financial impact, keeping deposits positive and converting withdrawals/purchases into negative values.
	- Use **SUM()** to condense multiple same-day transactions into a single net financial impact per customer per day.
- Phase 3: Map Impacts to the Continuous Grid
	- Define a Common Table Expression (`daily_grid`) querying the `customer_date_grid` CTE.
	- Use a **LEFT JOIN** on `customer_id` and `date` to connect the `customer_date_grid` and `daily_net` CTEs.
	- Use the **COALESCE()** function to systematically convert days with no transaction activity from NULL into a net impact of 0.
- Phase 4: Calculate Compound Interest via Recursion
	- Define a Common Table Expression (`daily_balance`) querying the `daily_grid` CTE.
	- Define the anchor member of the recursive CTE by querying the absolute first date of the grid to establish the baseline balance.
	- Construct the recursive member by using an **INNER JOIN** on `customer_id` and `date` to the previous day using `INTERVAL '1 day'`.
	- Apply the daily compound interest formula `(1 + 0.06/365.0)`.
	- Use the **GREATEST()** function to ensure interest is only awarded to positive balances, and then add the current day's `net_amount`.
- Phase 5: Isolate Month-End Snapshots
	- Define a Common Table Expression (`monthly_endpoints`) querying the `daily_balance` CTE.
    - Use **EXTRACT()** to pull a numeric month value from the date for chronological grouping.
	- Use the window function **LAST_VALUE() OVER ()** partitioned by `customer_id` and `month`, and order by `date` to capture the final calculated interest-bearing balance for each customer on the last day of each month.
- Phase 6: Compile Final Monthly Network Requirements
	- Use **SUM()** to add the month-end balances across all customers, grouped by month.
	- Apply a **GREATEST()** constraint to act as a floor, ensuring that overdrawn accounts contribute 0 to the total data requirement rather than subtracting from it.
	- (Optional) Wrap the final aggregated metric in a **TO_CHAR()** function with a format mask (`'FM999,999,999.99'`) to output clean, comma-separated values rounded to two decimal places.

#### Answer:
| month | data_required |
| ------| ------------- |
| 1     | 257,192.29    |
| 2     | 340,813.04    |
| 3     | 400,654.18    |
| 4     | 429,606.56    |


### Part 2: Daily Compounding Interest
````sql
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
````

#### Steps:
- Phase 1: Generate a Continuous Global Calendar (customer_date_grid)
	- Define a Common Table Expression (`customer_date_grid`) to generate a Global Calendar.
	- Use a subquery to find the absolute minimum and maximum transaction dates across the entire database.
	- Use the **generate_series()** function to create a continuous, uninterrupted chronological timeline.
    - Apply a **CROSS JOIN** to pair every distinct `customer_id` with every single `date` in the timeline, ensuring there are no gaps in any customer's calendar.
- Phase 2: Standardise and Condense Daily Impacts
	- Define a Common Table Expression (`daily_net`) querying the `customer_transactions` table.
	- Apply a **CASE** statement to standardise the financial impact, keeping deposits positive and converting withdrawals/purchases into negative values.
	- Use **SUM()** to condense multiple same-day transactions into a single net financial impact per customer per day.
- Phase 3: Map Impacts to the Continuous Grid
	- Define a Common Table Expression (`daily_grid`) querying the `customer_date_grid` CTE.
	- Use a **LEFT JOIN** on `customer_id` and `date` to connect the `customer_date_grid` and `daily_net` CTEs.
	- Use the **COALESCE()** function to systematically convert days with no transaction activity from NULL into a net impact of 0.
- Phase 4: Calculate Daily Running Balances
	- Define a Common Table Expression (`daily_running_balance`) querying the `daily_grid` CTE.
	- Use the **SUM() OVER()** window function partitioned by `customer_id` and order by `date` to calculate a continuous `raw_balance` based purely on transaction activity.
- Phase 5: Calculate Daily Simple Interest
	- Define a Common Table Expression (`daily_simple_interest`) querying the `daily_running_balance` CTE.
	- Apply the daily interest rate `(0.06/365.0)` directly to the `raw_balance`.
	- Use the **GREATEST()** function to ensure interest is only awarded to positive balances, ignoring any overdrawn days.
- Phase 6: Apply Accumulated Interest
	- Define a Common Table Expression (`daily_balance_simple`) querying the `daily_simple_interest` CTE.
    - Use the **SUM() OVER()** window function partitioned by `customer_id` and order by `date` to maintain a running total of the daily interest accrued over the life of the account.
	- Add this running total of accrued interest back to the `raw_balance` to finalise the balance_with_simple_interest.
- Phase 7: Isolate Month-End Snapshots
	- Define a Common Table Expression (`monthly_endpoints`) querying the `daily_balance_simple` CTE.
    - Use **EXTRACT()** to define the grouping for the reporting periods.
	- Use the window function **LAST_VALUE() OVER ()** partitioned by `customer_id` and `month`, and order by `date` to capture the final calculated interest-bearing balance for each customer on the last day of each month.
- Phase 8: Compile Final Monthly Network Requirements
	- Use **SUM()** to add the month-end balances across all customers, grouped by month.
	- Apply a **GREATEST()** constraint to act as a floor, ensuring that overdrawn accounts contribute 0 to the total data requirement rather than subtracting from it.
	- (Optional) Wrap the final aggregated metric in a **TO_CHAR()** function with a format mask (`'FM999,999,999.99'`) to output clean, comma-separated values rounded to two decimal places.

#### Answer:
| month | data_required |
| ------| ------------- |
| 1     | 236,184.43    |
| 2     | 263,089.56    |
| 3     | 263,535.67    |
| 4     | 268,442.79    |
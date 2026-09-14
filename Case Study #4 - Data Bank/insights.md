## A. Customer Nodes Exploration

### 1. How many unique nodes are there on the Data Bank system?
````sql
SELECT
	COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique nodes.
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
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique nodes.
- (Optional) Assign the alias `unique_nodes` to the resulting column for clear presentation in the final output report.

#### Answer:
| region_name | unique_nodes |
| ----------- | ------------ |
| Africa      | 5            |
| America     | 5            |
| Asia        | 5            |
| Australia   | 5            |
| Europe      | 5            |

- There are 5 unique nodes on each region.

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
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique customers.
- (Optional) Assign the alias `nodes` to the resulting column for clear presentation in the final output report.

#### Answer:
| region_name | customers |
| ----------- | --------- |
| Africa      | 102       |
| America     | 105       |
| Asia        | 95        |
| Australia   | 110       |
| Europe      | 88        |

- There are 500 customers distributed amongst the 5 regions as seen in the table above.

### 4. How many days on average are customers reallocated to a different node?
````sql
SELECT 
    ROUND(AVG(end_date - start_date), 2) AS avg_node_reallocation_days
FROM data_bank.customer_nodes
WHERE end_date != '9999-12-31';
````

#### Steps:
- Apply the **AVG** aggregate function to the difference between dates to get the number of days spent in each individual node allocation.
- Wrap the result in **ROUND** to present a clean summary rounded to two decimal places.
- Apply a filter condition in the **WHERE** clause (`end_date != '9999-12-31'`) to exclude open allocations that haven't ended yet, preventing extreme date outliers from distorting the average.

#### Answer:
| avg_node_reallocation_days |
| -------------------------- |
| 14.63                      |

- On average, customers reallocated to a different node every 14.63 days.

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
WHERE cn.end_date != '9999-12-31'
GROUP BY r.region_name
ORDER BY r.region_name;
````

#### Steps:
- Use an **INNER JOIN** on `region_name` to connect the `customer_nodes` and `regions` tables.
- Use **PERCENTILE_CONT(fraction) WITHIN GROUP (ORDER BY cn.end_date - cn.start_date)** to compute the 50th percentile (median), 80th percentile, and 95th percentile of reallocation days for each region group.
- Apply a filter condition in the **WHERE** clause (`end_date != '9999-12-31'`) to exclude open allocations that haven't ended yet, preventing extreme date outliers from distorting the average.

#### Answer:
| region_name | median | percentile_80 | percentile_95 |
| ----------- | ------ | ------------- | ------------- |
| Africa      | 15     | 24            | 28            |
| America     | 15     | 23            | 28            |
| Asia        | 15     | 23            | 28            |
| Australia   | 15     | 23            | 28            |
| Europe      | 15     | 24            | 28            |

- Exactly 50% of customer node allocations in each region lasted 15 days or fewer, and 50% lasted longer.
- 80% of node allocations in a region were completed within 23 to 24 days, with only 20% exceeding this duration.
- 95% of all allocations lasted 28 days or fewer, isolating the top 5% longest allocations in the system.


## B. Customer Transactions

### 1. What is the unique count and total amount for each transaction type?
````sql
SELECT 
    txn_type,
    COUNT(DISTINCT customer_id) AS unique_customers,
    TO_CHAR(SUM(txn_amount), 'FM999,999,999') AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique customers.
- Use the **SUM** aggregate function counting all individual transaction values for each specific transaction type group.
- (Optional) Use **TO_CHAR()** to convert the aggregated sum into a formatted text string.

#### Answer:
| txn_type   | unique_customers | total_amount |
| ---------- | ---------------- | ------------ |
| deposit    | 500              | 1,359,168    |
| purchase   | 448              | 806,537      |
| withdrawal | 439              | 793,003      |

### 2. What is the average total historical deposit counts and amounts for all customers?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`customer_deposit_summary`) querying the `customer_transactions` table.
- Apply the **COUNT** aggregate function to tally each customer's total number of deposit transactions.
- Use the **SUM** aggregate function to calculate each customer's total historical deposited amount.
- Apply a filter condition in the **WHERE** clause (`txn_type = 'deposit'`) to isolate deposit records.
- Apply the **AVG** aggregate function to both `deposit_count` and `total_deposit_amount` to compute the overall averages across all customers.
- Wrap the calculations with **ROUND** to present clean metrics rounded to two decimal places.

#### Answer:
| avg_deposit_count | avg_deposit_amount |
| ----------------- | ------------------ |
| 5.34              | 2718.34            |

### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`customer_monthly_activity`) querying the `customer_transactions` table.
- Use **EXTRACT()** to retain a numeric month value for chronological sorting.
- Use the **TO_CHART** function to pull the month component from the `txn_date` column, assigning the alias `month`.
- Apply **COUNT** with a **CASE** statement for each transaction type (deposit, purchase, withdrawal) to compute separate event totals per customer for each month.
- Apply a filter condition in the **WHERE** clause (`deposit_count > 1 AND (purchase_count >= 1 OR withdrawal_count >= 1)`) to isolate customers meeting the active activity criteria.

#### Answer:
| month     | customers |
| --------- | --------- |
| January   | 168       |
| February  | 181       |
| March     | 192       |
| April     | 70        |

### 4. What is the closing balance for each customer at the end of the month?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`monthly_activity`) querying the `customer_transactions` table.
- Use **EXTRACT()** to retain a numeric month value for chronological sorting.
- Apply a **CASE** statement inside a **SUM** aggregate function to assign positive values to deposits and negative values to withdrawals/purchases, summing them into a single metric.
- Define a Common Table Expression (`dense_calendar`) that take unique `customer_id` from a sub-query and **CROSS JOIN** them with unique numeric months from `customer_transactions` table.
- Use a **LEFT JOIN** on `customer_id` and `month_number` to connect the `monthly_activity` CTE.
- Wrap `net_change` in **COALESCE** to ensure inactive months return 0 instead of NULL.
- Use the window function **SUM() OVER ()** with partition by `customer_id` and order by `month_number` to calculate the total `monthly_change` for each customer and month.

#### Answer:
| customer_id | month     | closing_balance |
| ----------- | --------- | --------------- |
| 1           | January   | 312             |
| 1           | February  | 312             |
| 1           | March     | -640            |
| 1           | April     | -640            |
| 2           | January   | 549             |
| 2           | February  | 549             |
| 2           | March     | 610             |
| 2           | April     | 610             |
| 3           | January   | 144             |
| 3           | February  | -821            |
| 3           | March     | -1222           |
| 3           | April     | -729            |

- I am only showing the first 3 customers for reference.

### 5. What is the percentage of customers who increase their closing balance by more than 5%?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`monthly_activity`) exactly like in the previous exercise.
- Define a Common Table Expression (`dense_calendar`) exactly like in the previous exercise.
- Define a Common Table Expression (`closing_balances`) using the outer **SELECT** from the previous exercise.
- Define a Common Table Expression (`balance_comparison`) to pivot each customer's first (`month = 1`) and last (`month = 4`) closing balances using conditional aggregation.
- Apply a **CASE** statement inside a **SUM** aggregate function to calculate the percentage of qualifying customers whose balance grew by more than 5%.
- Use **COUNT()** to divide by the total customer count.
- Wrap the calculations with **ROUND** to present clean metrics rounded to two decimal places.

#### Answer:
| pct_customers_over_5_percent |
| ---------------------------- |
| 34.00                        |

- Amongst all the customers, 34% experienced an increase of their closing balance by more than 5%.


## C. Data Allocation Challenge

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
````

#### Steps:
-

### Part 2: Daily Compounding Interest
````sql
````

#### Steps:
-

-- D. Extra Challenge

-- Part 1: Simple Interest (Non-Compounding)
WITH RECURSIVE date_grid AS (
    -- Generate all dates from min to max transaction dates
    SELECT
		MIN(txn_date) AS calendar_date,
		MAX(txn_date) AS max_date 
    FROM customer_transactions
	
    UNION ALL
	
    SELECT
		(calendar_date + INTERVAL '1 day')::date, max_date
    FROM date_grid
    WHERE calendar_date < max_date
),
customer_daily_balances AS (
    -- Get running closing balance for every customer for every day
    SELECT
        c.customer_id,
        g.calendar_date,
        EXTRACT(MONTH FROM g.calendar_date) AS month,
        COALESCE(
            (
                SELECT
					SUM(CASE
						WHEN txn_type = 'deposit' THEN txn_amount
						ELSE -txn_amount
					END)
                FROM customer_transactions t
                WHERE t.customer_id = c.customer_id AND t.txn_date <= g.calendar_date
            ), 0
        ) AS daily_balance
    FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
    CROSS JOIN date_grid g
)
SELECT
    month,
    ROUND(
        SUM(GREATEST(daily_balance, 0) * (0.06 / 365)), 
        2
    ) AS total_data_required_simple_interest
FROM customer_daily_balances
GROUP BY month
ORDER BY month;

Part 2: Daily Compounding Interest
WITH RECURSIVE date_series AS (
    SELECT
		DISTINCT txn_date AS calendar_date 
    FROM customer_transactions 
    ORDER BY calendar_date
),
daily_net_changes AS (
    -- Net transaction change per customer per day
    SELECT
        customer_id,
        txn_date AS calendar_date,
        SUM(CASE
			WHEN txn_type = 'deposit' THEN txn_amount
			ELSE -txn_amount
		END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, txn_date
),
customer_dates AS (
    SELECT c.customer_id, d.calendar_date,
		ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY d.calendar_date) AS day_seq
    FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
    CROSS JOIN date_series d
),
compounded_balances AS (
    -- Base case: Day 1
    SELECT
		cd.customer_id,
		cd.calendar_date,
		cd.day_seq,
		COALESCE(dn.net_change, 0) AS net_change,
		GREATEST(COALESCE(dn.net_change, 0), 0) * (1 + 0.06 / 365) AS ending_balance,
		GREATEST(COALESCE(dn.net_change, 0), 0) * (0.06 / 365) AS daily_interest
    FROM customer_dates cd
    LEFT JOIN daily_net_changes dn 
		ON cd.customer_id = dn.customer_id
		AND cd.calendar_date = dn.calendar_date
    WHERE cd.day_seq = 1

    UNION ALL

    -- Recursive case: Days 2+
    SELECT
        cd.customer_id,
        cd.calendar_date,
        cd.day_seq,
        COALESCE(dn.net_change, 0) AS net_change,
        GREATEST(cb.ending_balance + COALESCE(dn.net_change, 0), 0) * (1 + 0.06 / 365) AS ending_balance,
        GREATEST(cb.ending_balance + COALESCE(dn.net_change, 0), 0) * (0.06 / 365) AS daily_interest
    FROM customer_dates cd
    JOIN compounded_balances cb 
		ON cd.customer_id = cb.customer_id
		AND cd.day_seq = cb.day_seq + 1
    LEFT JOIN daily_net_changes dn 
		ON cd.customer_id = dn.customer_id
		AND cd.calendar_date = dn.calendar_date
)
SELECT
    EXTRACT(MONTH FROM calendar_date) AS month,
    ROUND(SUM(daily_interest)::numeric, 2) AS total_data_required_compounded
FROM compounded_balances
GROUP BY EXTRACT(MONTH FROM calendar_date)
ORDER BY month;
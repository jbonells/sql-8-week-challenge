/* --------------------
   Case Study Questions
   --------------------*/

-- A. Data Cleansing Steps

-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
-- - Convert the week_date to a DATE format
-- - Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-- - Add a month_number with the calendar month for each week_date value as the 3rd column
-- - Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-- - Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
-- - Add a new demographic column using the following mapping for the first letter in the segment values
-- - Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-- - Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales AS
WITH formatted_dates AS (
  	SELECT
  		*,
  	TO_DATE(week_date, 'DD/MM/YY') AS parsed_date
  	FROM weekly_sales
)
SELECT
	parsed_date AS week_date,
	((EXTRACT(DOY FROM parsed_date)::INTEGER - 1) / 7) + 1 AS week_number,
	EXTRACT(MONTH FROM parsed_date)::INTEGER AS month_number,
	EXTRACT(YEAR FROM parsed_date)::INTEGER AS calendar_year,
	region,
	platform,
	COALESCE(NULLIF(segment, 'null'), 'unknown') AS segment,
	CASE
		WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
		WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
		WHEN RIGHT(segment, 1) in ('3','4') THEN 'Retirees'
		ELSE 'unknown'
	END AS age_band,
	CASE
		WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
		WHEN LEFT(segment, 1) = 'F' THEN 'Families'
		ELSE 'unknown'
	END AS demographic,
	customer_type,
	transactions,
	sales,
	ROUND(sales::NUMERIC / NULLIF(transactions, 0), 2) AS avg_transaction
FROM formatted_dates;

-- NOTE: I have added the new table to schema.sql to run the solution easily.


-- B. Data Exploration

-- 1. What day of the week is used for each week_date value?
SELECT
    DISTINCT TO_CHAR(week_date, 'FMDay') AS week_day
FROM clean_weekly_sales;

-- 2. What range of week numbers are missing from the dataset?
WITH weeks_per_year AS (
    SELECT GENERATE_SERIES(1, 52) AS week_number
),
missing_weeks AS (
    SELECT
		wpy.week_number
    FROM weeks_per_year wpy
	WHERE NOT EXISTS (
		SELECT * FROM clean_weekly_sales cws
		WHERE cws.week_number = wpy.week_number
	)
),
week_groups AS (
    SELECT 
        week_number,
        week_number - ROW_NUMBER() OVER (ORDER BY week_number) AS groups
    FROM missing_weeks
),
date_ranges AS (
    SELECT 
        MIN(week_number) AS start_week,
        MAX(week_number) AS end_week
    FROM week_groups
    GROUP BY groups
)

SELECT 
    CASE 
        WHEN start_week = end_week THEN start_week::TEXT
        ELSE start_week || ' - ' || end_week
    END AS missing_week_range
FROM date_ranges
ORDER BY start_week;

-- 3. How many total transactions were there for each year in the dataset?
SELECT
	calendar_year,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;

-- 4. What is the total sales for each region for each month?
SELECT
	region,
    month_number AS month,
    SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month
ORDER BY region, month;

-- 5. What is the total count of transactions for each platform
SELECT
	platform,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform
ORDER BY total_transactions DESC;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
SELECT
	calendar_year AS year,
    month_number AS month,
    ROUND(100 * SUM(sales) FILTER (WHERE platform = 'Retail')::NUMERIC / SUM(sales), 2) AS retail_percentage,
	ROUND(100 * SUM(sales) FILTER (WHERE platform = 'Shopify')::NUMERIC / SUM(sales), 2) AS shopify_percentage
FROM clean_weekly_sales
GROUP BY year, month
ORDER BY year, month;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
SELECT
    calendar_year AS year,
    demographic,
    ROUND(100 * SUM(sales)::NUMERIC / SUM(SUM(sales)) OVER (PARTITION BY calendar_year), 2) AS sales_percentage
FROM clean_weekly_sales
GROUP BY year, demographic
ORDER BY year, demographic;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
-- This question can be read two ways: ranking `age_band` and `demographic` independently, or ranking their combinations.

-- Option 1: ranking `age_band` and `demographic` independently
SELECT
	'age_band' AS dimension,
	age_band AS value,
	SUM(sales) AS retail_sales,
    ROUND(100 * SUM(sales)::NUMERIC / SUM(SUM(sales)) OVER (), 2) AS pct_of_retail_sales
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band

UNION ALL

SELECT
	'demographic' AS dimension,
	demographic AS value,
	SUM(sales) AS retail_sales,
    ROUND(100 * SUM(sales)::NUMERIC / SUM(SUM(sales)) OVER (), 2) AS pct_of_retail_sales
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY demographic
ORDER BY dimension, retail_sales DESC;

-- Option 2: ranking `age_band` and `demographic` combinations
SELECT
    age_band,
    demographic,
    SUM(sales) AS retail_sales,
    ROUND(100 * SUM(sales)::NUMERIC / SUM(SUM(sales)) OVER (), 2) AS pct_of_retail_sales
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY retail_sales DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT
	calendar_year AS year,
    platform,
	ROUND(AVG(avg_transaction), 2) AS avg_of_avg_transaction,
    ROUND(SUM(sales)::NUMERIC / SUM(transactions), 2) AS average_transaction,
    ROUND(AVG(avg_transaction) - SUM(sales)::NUMERIC / SUM(transactions), 2) AS difference
FROM clean_weekly_sales
GROUP BY year, platform
ORDER BY year, platform;


-- C. Before & After Analysis
-- This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
-- Using this analysis approach - answer the following questions:

-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
WITH period AS (
	SELECT
		SUM(sales) FILTER (
			WHERE week_date >= DATE '2020-06-15' - INTERVAL '4 weeks'
				AND week_date <  DATE '2020-06-15'
		) AS sales_before,
		SUM(sales) FILTER (
			WHERE week_date >= DATE '2020-06-15'
				AND week_date <  DATE '2020-06-15' + INTERVAL '4 weeks'
		) AS sales_after
	FROM clean_weekly_sales
)

SELECT
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_change
FROM period;

-- 2. What about the entire 12 weeks before and after?
WITH period AS (
	SELECT
		SUM(sales) FILTER (
			WHERE week_date >= DATE '2020-06-15' - INTERVAL '12 weeks'
				AND week_date <  DATE '2020-06-15'
		) AS sales_before,
		SUM(sales) FILTER (
			WHERE week_date >= DATE '2020-06-15'
				AND week_date <  DATE '2020-06-15' + INTERVAL '12 weeks'
		) AS sales_after
	FROM clean_weekly_sales
)

SELECT
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_change
FROM period;

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
WITH baseline AS (
    SELECT
		DISTINCT week_number AS baseline_week
    FROM clean_weekly_sales
    WHERE week_date = DATE '2020-06-15'
),
period AS (
	SELECT
		calendar_year AS year,
		SUM(sales) FILTER (WHERE week_number BETWEEN baseline_week - 4 AND baseline_week - 1) AS four_week_sales_before,
		SUM(sales) FILTER (WHERE week_number BETWEEN baseline_week AND baseline_week + 3) AS four_week_sales_after,
		SUM(sales) FILTER (WHERE week_number BETWEEN baseline_week - 12 AND baseline_week - 1) AS twelve_week_sales_before,
		SUM(sales) FILTER (WHERE week_number BETWEEN baseline_week AND baseline_week + 11) AS twelve_week_sales_after
	FROM clean_weekly_sales
	CROSS JOIN baseline
	GROUP BY year
)

SELECT
	year,
	four_week_sales_before,
	four_week_sales_after,
    (four_week_sales_after - four_week_sales_before) AS four_week_sales_change,
    ROUND(100 * (four_week_sales_after - four_week_sales_before)::NUMERIC / four_week_sales_before, 2) AS four_week_percentage_change,
	twelve_week_sales_before,
	twelve_week_sales_after,
    (twelve_week_sales_after - twelve_week_sales_before) AS twelve_week_sales_change,
    ROUND(100 * (twelve_week_sales_after - twelve_week_sales_before)::NUMERIC / twelve_week_sales_before, 2) AS twelve_week_percentage_change
FROM period
ORDER BY year;


-- D. Bonus Question
-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
-- - region
-- - platform
-- - age_band
-- - demographic
-- - customer_type
WITH baseline AS (
    SELECT
		DISTINCT week_number AS baseline_week
    FROM clean_weekly_sales
    WHERE week_date = DATE '2020-06-15'
),
period_sales AS (
	SELECT
		dim.area,
		dim.value,
		SUM(sales) FILTER (WHERE week_number BETWEEN baseline_week - 12 AND baseline_week - 1) AS sales_before,
		SUM(sales) FILTER (WHERE week_number BETWEEN baseline_week AND baseline_week + 11) AS sales_after
	FROM clean_weekly_sales
  	CROSS JOIN baseline
	CROSS JOIN LATERAL (
		VALUES
			('region', region),
			('platform', platform),
			('age_band', age_band),
			('demographic', demographic),
			('customer_type', customer_type)
    ) AS dim(area, value)
	WHERE week_number BETWEEN baseline_week - 12
		AND baseline_week + 11
		AND calendar_year = 2020
	GROUP BY area, value
)

SELECT
	area,
	value,
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_change
FROM period_sales
ORDER BY area, value;

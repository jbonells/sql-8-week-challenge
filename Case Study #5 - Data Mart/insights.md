## A. Data Cleansing Steps

### In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
- Convert the week_date to a DATE format
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a month_number with the calendar month for each week_date value as the 3rd column
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value:

| segment | age_band     |
| ------- | ------------ |
| 1       | Young Adults |
| 2       | Middle Aged  |
| 3 or 4  | Retirees     |
- Add a new demographic column using the following mapping for the first letter in the segment values:

| segment | demographic |
| ------- | ----------- |
| C       | Couples     |
| F       | Families    |
- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

````sql
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
	((EXTRACT(DOY FROM parsed_date)::integer - 1) / 7) + 1 AS week_number,
	EXTRACT(MONTH FROM parsed_date) AS month_number,
	EXTRACT(YEAR FROM parsed_date) AS calendar_year,
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
	ROUND(sales::NUMERIC / transactions, 2) AS avg_transaction
FROM formatted_dates;
````

#### Steps:
- Define a Common Table Expression (`customer_deposit_summary`) querying the `weekly_sales` table.
- Use **TO_DATE()** to convert the `week_date` string ('DD/MM/YY') into a standardised date format.
- Use **EXTRACT()** to retain the month and year components, and apply custom day-of-year math to calculate the `week_number`.
- Apply **COALESCE()** and **NULLIF()** to the `segment` column to replace literal 'null' strings with 'unknown'.
- Use **CASE** statements combined with **RIGHT()** and **LEFT()** functions to evaluate the `segment` codes and categorise the `age_band` and `demographic` dimensions.
- Apply the **ROUND()** function, casting `sales` to numeric, to compute the `avg_transaction` metric.
- Use **DROP TABLE IF EXISTS** and **CREATE TABLE AS** to to create the `clean_weekly_sales` table with the results of the query.

**NOTE:** I have added the new table to `schema.sql` to run the solution easily.


## B. Data Exploration

### 1. What day of the week is used for each week_date value?
````sql
SELECT
    DISTINCT TO_CHAR(week_date, 'FMDay') AS week_day
FROM clean_weekly_sales;
````

#### Steps:
- Apply the **TO_CHAR** function with **DISTINCT** to isolate and retrieve the day name used.
- (Optional) Assign the alias `week_day` to the resulting column for clear presentation in the final output report.

#### Answer:
| week_day |
| -------- |
| Monday   |

### 2. What range of week numbers are missing from the dataset?
````sql
WITH weeks_per_year AS (
    SELECT GENERATE_SERIES(1, 52) AS week_number
),
missing_weeks AS (
    SELECT wpy.week_number
    FROM weeks_per_year wpy
    LEFT JOIN clean_weekly_sales cws
        ON wpy.week_number = cws.week_number
    WHERE cws.week_number IS NULL
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
FROM date_ranges;
````

#### Steps:
- Define a Common Table Expression (`weeks_per_year`) using **GENERATE_SERIES(1, 52)** to generate a complete sequence of all 52 weeks.
- Define a Common Table Expression (`missing_weeks`) querying the `weeks_per_year` CTE.
- Use a **LEFT JOIN** on `week_number` to connect the `clean_weekly_sales` table applying a filter condition in the **WHERE** clause (`week_number IS NULL'`) to isolate missing individual weeks.
- Define a Common Table Expression (`week_groups`) querying the `missing_weeks` CTE.
- Apply the **ROW_NUMBER()** window function ordered by `week_number` to flag and group consecutive missing numbers.
- Define a Common Table Expression (`date_ranges`) querying the `week_groups` CTE.
- Use **MIN()** and **MAX()** functions to extract the start and end boundaries of each continuous block of missing weeks.
- Apply a **CASE** statement combined with string concatenation to format the output cleanly into ranges or single numbers when only an isolated week is missing.

#### Answer:
| missing_week_range |
| ------------------ |
| 1 - 11             |
| 37 - 52            |

### 3. How many total transactions were there for each year in the dataset?
````sql
SELECT
	calendar_year,
    TO_CHAR(SUM(transactions), 'FM999,999,999') AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
````

#### Steps:
- Use the **SUM** aggregate function adding all individual transaction values for each year.
- (Optional) Use **TO_CHAR()** to convert the aggregated sum into a formatted text string.

#### Answer:
| calendar_year | total_transactions |
| ------------- | ------------------ |
| 2018          | 346,406,460        |
| 2019          | 365,639,285        |
| 2020          | 375,813,651        |

### 4. What is the total sales for each region for each month?
````sql
SELECT
	region,
    month_number AS month,
    TO_CHAR(SUM(sales), 'FM999,999,999,999') AS total_sales
FROM clean_weekly_sales
GROUP BY region, month
ORDER BY region, month;
````

#### Steps:
- Use the **SUM** aggregate function adding all individual sales values for each region and month.
- (Optional) Use **TO_CHAR()** to convert the aggregated sum into a formatted text string.

#### Answer:
| region | month | total_sales   |
| ------ | ----- | ------------- |
| AFRICA | 3     | 567,767,480   |
| AFRICA | 4     | 1,911,783,504 |
| AFRICA | 5     | 1,647,244,738 |
| AFRICA | 6     | 1,767,559,760 |
| AFRICA | 7     | 1,960,219,710 |
| AFRICA | 8     | 1,809,596,890 |
| AFRICA | 9     | 276,320,987   |

- I'm only showing the results for Africa.

### 5. What is the total count of transactions for each platform
````sql
SELECT
	platform,
    TO_CHAR(SUM(transactions), 'FM999,999,999,999') AS total_transactions
FROM clean_weekly_sales
GROUP BY platform
ORDER BY platform;
````

#### Steps:
- Use the **SUM** aggregate function adding all individual transaction values for each platform.
- (Optional) Use **TO_CHAR()** to convert the aggregated sum into a formatted text string.

#### Answer:
| platform | total_transactions |
| -------- | ------------------ |
| Retail   | 1,081,934,227      |
| Shopify  | 5,925,169          |

### 6. What is the percentage of sales for Retail vs Shopify for each month?
````sql
SELECT
	calendar_year AS year,
    month_number AS month,
    ROUND(100 * SUM(sales) FILTER (WHERE platform = 'Retail')::NUMERIC / SUM(sales), 2) AS retail_percentage,
	ROUND(100 * SUM(sales) FILTER (WHERE platform = 'Shopify')::NUMERIC / SUM(sales), 2) AS shopify_percentage
FROM clean_weekly_sales
GROUP BY year, month
ORDER BY year, month;
````

#### Steps:
- Use the **SUM** aggregate function to calculate the total sales.
- Apply the **FILTER (WHERE ...)** clause to dynamically isolate total sales for each distinct platforms ('Retail' and 'Shopify').
- Use the **NUMERIC** type cast on the numerator to prevent integer truncation and ensure precise division.
- Divide each platform's total sales by the overall `SUM(sales)` for that year and month.
- Apply the **ROUND()** function to format the final percentage metrics to two decimal places.

#### Answer:
| year | month | retail_percentage | shopify_percentage |
| ---- | ----- | ----------------- | ------------------ | 
| 2018 | 3     | 97.92             | 2.08               |
| 2018 | 4     | 97.93             | 2.07               |
| 2018 | 5     | 97.73             | 2.27               |
| 2018 | 6     | 97.76             | 2.24               |
| 2018 | 7     | 97.75             | 2.25               |
| 2018 | 8     | 97.71             | 2.29               |
| 2018 | 9     | 97.68             | 2.32               |

- I'm only showing the results for 2018.

### 7. What is the percentage of sales by demographic for each year in the dataset?
````sql
SELECT
    calendar_year AS year,
    ROUND(100 * SUM(sales) FILTER (WHERE demographic = 'Couples')::NUMERIC / SUM(sales), 2) AS couples_percentage,
    ROUND(100 * SUM(sales) FILTER (WHERE demographic = 'Families')::NUMERIC / SUM(sales), 2) AS families_percentage,
    ROUND(100 * SUM(sales) FILTER (WHERE demographic = 'unknown')::NUMERIC / SUM(sales), 2) AS unknown_percentage
FROM clean_weekly_sales
GROUP BY year
ORDER BY year;
````

#### Steps:
- Use the **SUM** aggregate function to calculate the total sales.
- Apply the **FILTER (WHERE ...)** clause to dynamically isolate total sales for each distinct demographic category ('Couples', 'Families', and 'unknown').
- Use the **NUMERIC** type cast on the numerator to prevent integer truncation and ensure precise division.
- Divide each demographic's total sales by the overall `SUM(sales)` for that year.
- Apply the **ROUND()** function to format the final percentage metrics to two decimal places.

#### Answer:
| year | couples_percentage | families_percentage | unknown_percentage |
| ---- | ------------------ | ------------------- | ------------------ | 
| 2018 | 26.38              | 31.99               | 41.63              |
| 2019 | 27.28              | 32.47               | 40.25              |
| 2020 | 28.72              | 32.73               | 38.55              |

### 8. Which age_band and demographic values contribute the most to Retail sales?
````sql
SELECT
    age_band,
    demographic,
    TO_CHAR(SUM(sales), 'FM999,999,999,999') AS retail_sales,
    ROUND(100 * SUM(sales)::NUMERIC / SUM(SUM(sales)) OVER (), 2) AS pct_of_retail_sales
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY SUM(sales) DESC;
````

#### Steps:
- Use the **SUM** aggregate function grouped by `age_band` and `demographic` to calculate total sales per category.
- Use the window function **SUM() OVER ()** combined with **SUM()** to compute the overall total retail sales denominator.
- Use the **NUMERIC** type cast on the numerator to prevent integer truncation and ensure precise division.
- Apply the **ROUND()** function to format the final percentage metrics to two decimal places.
- Apply a filter condition in the **WHERE** clause (`platform = 'Retail''`) to include only retail sales.
- (Optional) Use **TO_CHAR()** to convert the aggregated sum into a formatted text string.

#### Answer:
| age_band     | demographic | retail_sales   | pct_of_retail_sales |
| ------------ | ----------- | -------------- | ------------------- | 
| unknown      | unknown     | 16,067,285,533 | 40.52               |
| Retirees     | Families    | 6,634,686,916  | 16.73               |
| Retirees     | Couples     | 6,370,580,014  | 16.07               |
| Middle Aged  | Families    | 4,354,091,554  | 10.98               |
| Young Adults | Couples     | 2,602,922,797  | 6.56                |
| Middle Aged  | Couples     | 1,854,160,330  | 4.68                |
| Young Adults | Families    | 1,770,889,293  | 4.47                |

**Note:** this question is ambiguous giving two different options (one groups by `age_band` and `demographic` separately; the other groups by (`age_band`, `demographic`) jointly), I have assumed the latter.

### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
````sql
SELECT
	calendar_year AS year,
    platform,
	ROUND(AVG(avg_transaction), 2) AS avg_transactio_column,
    ROUND(SUM(sales)::NUMERIC / SUM(transactions), 2) AS average_transaction,
    ROUND(AVG(avg_transaction) - SUM(sales)::NUMERIC / SUM(transactions), 2) AS difference
FROM clean_weekly_sales
GROUP BY year, platform
ORDER BY year, platform;
````

#### Steps:
- Use the **AVG()** aggregate function on the pre-calculated `avg_transaction` column.
- Use the **SUM()** aggregate function for both `sales` and `transactions`, casting sales to calculate the weighted average transaction size.
- Compute the mathematical difference between the simple average of averages and the weighted average to highlight the variance.
- Apply the **ROUND()** function to format all metric outputs to two decimal places.

#### Answer:
| year | platform | avg_transactio_column | average_transaction | difference |
| ---- | -------- | --------------------- | ------------------- | ---------- |
| 2018 | Retail   | 42.91                 | 36.56               | 6.34       |
| 2018 | Shopify  | 188.28                | 192.48              | -4.20      |
| 2019 | Retail   | 41.97                 | 36.83               | 5.13       |
| 2019 | Shopify  | 177.56                | 183.36              | -5.80      |
| 2020 | Retail   | 40.64                 | 36.56               | 4.08       |
| 2020 | Shopify  | 174.87                | 179.03              | -4.16      |

- The `avg_transaction` column is computed per-row, so a plain **AVG()** over it gives an unweighted "average of averages".
- The correct approach is a weighted average (`average_transaction`), which properly weights each row by its actual transaction volume.


## C. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the `week_date` value of `2020-06-15` as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all `week_date` values `for 2020-06-15` as the start of the period after the change and the previous `week_date` values would be before.

Before we start, we could determine the `week_nember` corresponding to `2020-06-15` to simplify our filters during the analysis.
````sql
SELECT
	DISTINCT week_number
FROM clean_weekly_sales
WHERE week_date = '2020-06-15'
	AND calendar_year = 2020;
````

| week_number |
| ----------- |
| 24          |

- The week_number is 24.
- Note that we did not need to filter by `calendar_year = 2020` but I added it here for clarity as it will be used later on.

### 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
````sql
WITH period AS (
	SELECT
		week_number,
  		SUM(sales) AS total_sales
	FROM clean_weekly_sales
	WHERE week_number BETWEEN 20 AND 28
		AND calendar_year = 2020
  	GROUP BY week_number
),
split_period AS (
	SELECT
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 20 AND 23) AS sales_before,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 28) AS sales_after
	FROM period
)

SELECT
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_rate
FROM split_period;
````

#### Steps:
- Define a Common Table Expression (`period`) querying the `clean_weekly_sales` table.
- Use the **SUM** aggregate function to calculate the total sales.
- Apply a filter condition in the **WHERE** clause (`week_number BETWEEN 20 AND 28` and `calendar_year = 2020`) to isolate `sales` for calendar year 2020 across weeks 20 to 28.
- Define a Common Table Expression (`split_period`) querying the `period` CTE.
- Use the **SUM** aggregate function to calculate the total sales.
- Apply the **FILTER (WHERE ...)** clause to dynamically isolate total sales for each distinct period (weeks 20–23 and weeks 25–28).
- Calculate the absolute value difference (`sales_change`) between the after and before sales figures.
- Use the **ROUND()** function combined with percentage math to compute the growth or reduction rate (`percentage_rate`) rounded to two decimal places.

#### Answer:
| sales_before | sales_after | sales_change | percentage_rate |
| ------------ | ----------- | ------------ | --------------- |
| 2345878357   | 2334905223  | -10973134    | -0.47           |

- Following the change, total sales decreased by $10,973,134 over the four-week period, representing a 0.47% drop in overall sales volume.

### 2. What about the entire 12 weeks before and after?
````sql
WITH period AS (
	SELECT
		week_number,
  		SUM(sales) AS total_sales
	FROM clean_weekly_sales
	WHERE week_number BETWEEN 12 AND 36
		AND calendar_year = 2020
  	GROUP BY week_number
),
split_period AS (
	SELECT
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 12 AND 23) AS sales_before,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 36) AS sales_after
	FROM period
)

SELECT
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_rate
FROM split_period;
````

#### Steps:
- Same as previous exercise changing the `week_number` range to `week_number BETWEEN 12 AND 36`.

#### Answer:
| sales_before | sales_after | sales_change | percentage_rate |
| ------------ | ----------- | ------------ | --------------- |
| 7126273147   | 6403922405  | -722350742   | -10.14          |

- Following the change, total sales decreased by $722,350,742 over the twelve-week period, representing a 10.14% drop in overall sales volume.

### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
````sql
WITH period AS (
	SELECT
		calendar_year AS year,
		week_number,
  		SUM(sales) AS total_sales
	FROM clean_weekly_sales
	WHERE week_number BETWEEN 12 AND 36
  	GROUP BY calendar_year, week_number
),
split_period AS (
	SELECT
		year,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 20 AND 23) AS four_week_sales_before,
        SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 28) AS four_week_sales_after,
        SUM(total_sales) FILTER (WHERE week_number BETWEEN 12 AND 23) AS twelve_week_sales_before,
        SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 36) AS twelve_week_sales_after
	FROM period
	GROUP BY year
)

SELECT
	year,
	four_week_sales_before,
	four_week_sales_after,
    (four_week_sales_after - four_week_sales_before) AS four_week_sales_change,
    ROUND(100 * (four_week_sales_after - four_week_sales_before) / four_week_sales_before, 2) AS four_week_percentage_rate,
	twelve_week_sales_before,
	twelve_week_sales_after,
    (twelve_week_sales_after - twelve_week_sales_before) AS twelve_week_sales_change,
    ROUND(100 * (twelve_week_sales_after - twelve_week_sales_before)::NUMERIC / twelve_week_sales_before, 2) AS twelve_week_percentage_rate
FROM split_period
ORDER BY year;
````

#### Steps:
- Same as previous exercise but including the four-week period and `calendar_year`.

#### Answer:
| year | four_week_sales_before | four_week_sales_after | four_week_sales_change | four_week_percentage_rate | twelve_week_sales_before | twelve_week_sales_after | twelve_week_sales_change | twelve_week_percentage_rate |
| ---- | ---------------------- | --------------------- | ---------------------- | ------------------------- | ------------------------ | ----------------------- | ------------------------ | --------------------------- |
| 2018 | 2119669585             | 2129242914            | 9573329                | 0.45                      | 5863302538               | 6500818510              | 637515972                | 10.87                       |
| 2019 | 2249989796             | 2264499542            | 14509746               | 0.64                      | 6883386397               | 6303557285              | -579829112               | -8.42                       |
| 2020 | 2345878357             | 2334905223            | -10973134              | -0.47                     | 7126273147               | 6403922405              | -722350742               | -10.14                      |


## D. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- region
- platform
- age_band
- demographic
- customer_type

Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
````sql
WITH region_period AS (
	SELECT
		region,
		week_number,
  		SUM(sales) AS total_sales
	FROM clean_weekly_sales
	WHERE week_number BETWEEN 12 AND 36
		AND calendar_year = 2020
  	GROUP BY region, week_number
),
region_split AS (
	SELECT
		region,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 12 AND 23) AS sales_before,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 36) AS sales_after
	FROM region_period
	GROUP BY region
),
platform_period AS (
	SELECT
		platform,
		week_number,
  		SUM(sales) AS total_sales
	FROM clean_weekly_sales
	WHERE week_number BETWEEN 12 AND 36
		AND calendar_year = 2020
  	GROUP BY platform, week_number
),
platform_split AS (
	SELECT
		platform,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 12 AND 23) AS sales_before,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 36) AS sales_after
	FROM platform_period
	GROUP BY platform
),
age_band_period AS (
	SELECT
		age_band,
		week_number,
  		SUM(sales) AS total_sales
	FROM clean_weekly_sales
	WHERE week_number BETWEEN 12 AND 36
		AND calendar_year = 2020
  	GROUP BY age_band, week_number
),
age_band_split AS (
	SELECT
		age_band,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 12 AND 23) AS sales_before,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 36) AS sales_after
	FROM age_band_period
	GROUP BY age_band
),
demographic_period AS (
	SELECT
		demographic,
		week_number,
  		SUM(sales) AS total_sales
	FROM clean_weekly_sales
	WHERE week_number BETWEEN 12 AND 36
		AND calendar_year = 2020
  	GROUP BY demographic, week_number
),
demographic_split AS (
	SELECT
		demographic,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 12 AND 23) AS sales_before,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 36) AS sales_after
	FROM demographic_period
	GROUP BY demographic
),
customer_type_period AS (
	SELECT
		customer_type,
		week_number,
  		SUM(sales) AS total_sales
	FROM clean_weekly_sales
	WHERE week_number BETWEEN 12 AND 36
		AND calendar_year = 2020
  	GROUP BY customer_type, week_number
),
customer_type_split AS (
	SELECT
		customer_type,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 12 AND 23) AS sales_before,
		SUM(total_sales) FILTER (WHERE week_number BETWEEN 25 AND 36) AS sales_after
	FROM customer_type_period
	GROUP BY customer_type
)

SELECT
	'region' AS area,
	region AS value,
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_rate
FROM region_split

UNION ALL

SELECT
	'platform' AS area,
	platform AS value,
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_rate
FROM platform_split

UNION ALL

SELECT
	'age_band' AS area,
	age_band AS value,
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_rate
FROM age_band_split

UNION ALL

SELECT
	'demographic' AS area,
	demographic AS value,
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_rate
FROM demographic_split

UNION ALL

SELECT
	'customer_type' AS area,
	customer_type AS value,
	sales_before,
	sales_after,
    (sales_after - sales_before) AS sales_change,
    ROUND(100 * (sales_after - sales_before)::NUMERIC / sales_before, 2) AS percentage_rate
FROM customer_type_split
ORDER BY area, percentage_rate;
````

#### Steps:
- Define a series of period Common Table Expressions (`region_period`, `platform_period`, `age_band_period`, `demographic_period`, and `customer_type_period`) querying the `clean_weekly_sales` table.
- Use the **SUM** aggregate function to calculate total sales grouped by each respective area and `week_number`.
- Apply a filter condition in the **WHERE** clause (`week_number BETWEEN 20 AND 28` and `calendar_year = 2020`) to isolate the analysis window.
- Define corresponding split Common Table Expressions (`region_split`, `platform_split`, `age_band_split`, `demographic_split`, and `customer_type_split`) to aggregate the period data.
- Use the **SUM** aggregate function to calculate the total sales.
- Apply the **FILTER (WHERE ...)** clause to dynamically isolate total sales for each distinct period (weeks 20–23 and weeks 25–28).
- Combine all area splits in the final query using **UNION ALL**, mapping standardised `area` and `value` metadata columns.
- Calculate the absolute value difference (`sales_change`) between the after and before sales figures.
- Use the **ROUND()** function combined with percentage math to compute the growth or reduction rate (`percentage_rate`) rounded to two decimal places.
- (Optional) Use **ORDER BY** on `area` and `percentage_rate` to organise the final multi-dimensional comparison report.

#### Answer:
| area          | value         | sales_before | sales_after | sales_change | percentage_rate |
| ------------- | ------------- | ------------ | ----------- | ------------ | --------------- |
| age_band      | unknown       | 2764354464   | 2455309572  | -309044892   | -11.18          |
| age_band      | Middle Aged   | 1164847640   | 1047640798  | -117206842   | -10.06          |
| age_band      | Retirees      | 2395264515   | 2171707896  | -223556619   | -9.33           |
| age_band      | Young Adults  | 801806528    | 729264139   | -72542389    | -9.05           |
| customer_type | Guest         | 2573436301   | 2292350880  | -281085421   | -10.92          |
| customer_type | Existing      | 3690116427   | 3308618627  | -381497800   | -10.34          |
| customer_type | New           | 862720419    | 802952898   | -59767521    | -6.93           |
| demographic   | unknown       | 2764354464   | 2455309572  | -309044892   | -11.18          |
| demographic   | Families      | 2328329040   | 2096951469  | -231377571   | -9.94           |
| demographic   | Couples       | 2033589643   | 1851661364  | -181928279   | -8.95           |
| platform      | Retail        | 6906861113   | 6188030612  | -718830501   | -10.41          |
| platform      | Shopify       | 219412034    | 215891793   | -3520241     | -1.60           |
| region        | ASIA          | 1637244466   | 1454048362  | -183196104   | -11.19          |
| region        | OCEANIA       | 2354116790   | 2096183557  | -257933233   | -10.96          |
| region        | SOUTH AMERICA | 213036207    | 191162573   | -21873634    | -10.27          |
| region        | CANADA        | 426438454    | 383469208   | -42969246    | -10.08          |
| region        | USA           | 677013558    | 611780628   | -65232930    | -9.64           |
| region        | AFRICA        | 1709537105   | 1562467704  | -147069401   | -8.60           |
| region        | EUROPE        | 108886567    | 104810373   | -4076194     | -3.74           |

- Every single value across every dimension declined — there's no positive outlier anywhere in this table, so the 12-week period genuinely saw a broad-based drop:
	- Age Band / Demographic: unknown is the single worst performer in both (-11.18%).
	- Customer Type: Guest (-10.92%) declined more than Existing (-10.34%) or New (-6.93%).
	- Platform: Retail (-10.41%) fell far more than Shopify (-1.60%).
	- Region: ASIA (-11.19%) and OCEANIA (-10.96%).

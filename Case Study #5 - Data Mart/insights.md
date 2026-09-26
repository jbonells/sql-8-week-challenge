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

```sql
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
```

#### Steps:
- Use **DROP TABLE IF EXISTS** and **CREATE TABLE AS** to create the `clean_weekly_sales` table with the results of the query.
- Define a Common Table Expression (`customer_deposit_summary`) querying the `weekly_sales` table.
- Use **TO_DATE()** to convert the `week_date` string ('DD/MM/YY') into a standardised date format.
- Use **EXTRACT()** to retain the month and year components, and apply custom day-of-year math to calculate the `week_number`.
- Apply explicit **INTEGER** type casting to the extracted date parts to ensure clean numeric data types instead of floating-point numbers.
- Apply **COALESCE()** and **NULLIF()** to the `segment` column to replace literal 'null' strings with 'unknown'.
- Use **CASE** statements combined with **RIGHT()** and **LEFT()** functions to evaluate the `segment` codes and categorise the `age_band` and `demographic` dimensions.
- Wrap the calculation in **ROUND()** casting `sales` to **NUMERIC** and handling zero-division with **NULLIF()**, to compute the `avg_transaction` metric.

**NOTE:** I have added the new table to `schema.sql` to run the solution easily.


## B. Data Exploration

### 1. What day of the week is used for each week_date value?
```sql
SELECT
    DISTINCT TO_CHAR(week_date, 'FMDay') AS week_day
FROM clean_weekly_sales;
```

#### Steps:
- Apply the **TO_CHAR()** function with **DISTINCT** to isolate and retrieve the day name used.
- (Optional) Assign the alias `week_day` to the resulting column for clear presentation in the final output report.

#### Answer:
| week_day |
| -------- |
| Monday   |

### 2. What range of week numbers are missing from the dataset?
```sql
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
```

#### Steps:
- Define a Common Table Expression (`weeks_per_year`) using **GENERATE_SERIES(1, 52)** to produce a sequence of all 52 calendar weeks.
- Define a Common Table Expression (`missing_weeks`) querying the `weeks_per_year` CTE.
- Apply a **WHERE NOT EXISTS** subquery against `clean_weekly_sales` to isolate unrecorded week numbers.
- Define a Common Table Expression (`week_groups`) querying the `missing_weeks` CTE.
- Apply the **ROW_NUMBER() OVER()** window function ordered by `week_number` to assign a constant identifier to consecutive sequence blocks.
- Define a Common Table Expression (`date_ranges`) querying the `week_groups` CTE.
- Group records by `groups` alongside **MIN()** and **MAX()** functions to establish the start and end week boundaries for each block.
- Apply a **CASE** statement with string concatenation (||) and text casting to format output as single numbers or ranges.
- Order the final dataset in ascending sequence by `start_week` to display the missing week ranges in chronological order.

#### Answer:
| missing_week_range |
| ------------------ |
| 1 - 11             |
| 37 - 52            |

### 3. How many total transactions were there for each year in the dataset?
```sql
SELECT
	calendar_year,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```

#### Steps:
- Group records by `calendar_year` to aggregate transaction totals for each distinct year.
- Use the **SUM()** aggregate function to add all individual `transactions` values for each year.
- (Optional) Order the final dataset in ascending sequence by `calendar_year` for structured presentation.

#### Answer:
| calendar_year | total_transactions |
| ------------- | ------------------ |
| 2018          | 346,406,460        |
| 2019          | 365,639,285        |
| 2020          | 375,813,651        |

### 4. What is the total sales for each region for each month?
```sql
SELECT
	region,
    month_number AS month,
    SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month
ORDER BY region, month;
```

#### Steps:
- Group records by `region` and `month` to aggregate sales for each region and month combination.
- Use the **SUM()** aggregate function to add all individual `sales` values for each group.
- (Optional) Order the final dataset in ascending sequence by `region` and `month` for structured presentation.

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

- **Note:** The table above displays a sample of the full result set (filtered to the AFRICA region).

### 5. What is the total count of transactions for each platform
```sql
SELECT
	platform,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform
ORDER BY total_transactions DESC;
```

#### Steps:
- Group records by `platform` to aggregate transaction totals for each platform.
- Use the **SUM()** aggregate function to add all individual `transactions` values for each platform.
- (Optional) Order the final dataset in descending sequence by `total_transactions` for structured presentation.

#### Answer:
| platform | total_transactions |
| -------- | ------------------ |
| Retail   | 1,081,934,227      |
| Shopify  | 5,925,169          |

### 6. What is the percentage of sales for Retail vs Shopify for each month?
```sql
SELECT
	calendar_year AS year,
    month_number AS month,
    ROUND(100 * SUM(sales) FILTER (WHERE platform = 'Retail')::NUMERIC / SUM(sales), 2) AS retail_percentage,
	ROUND(100 * SUM(sales) FILTER (WHERE platform = 'Shopify')::NUMERIC / SUM(sales), 2) AS shopify_percentage
FROM clean_weekly_sales
GROUP BY year, month
ORDER BY year, month;
```

#### Steps:
- Group records by `year` and `month` to aggregate sales per month.
- Use the **SUM()** aggregate function to add all individual `sales` values for each group.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`platform = 'Retail'`) to dynamically isolate total sales for Retail.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`platform = 'Shopify'`) to dynamically isolate total sales for Shopify.
- Multiply the filtered sales by 100 and apply a **NUMERIC** cast to prevent integer division before dividing by the overall monthly sales.
- Wrap the calculations in **ROUND()** to format the resulting percentage metrics to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `year` and `month` for structured presentation.

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

- **Note:** The table above displays a sample of the full result set (filtered to the 2018 year).

### 7. What is the percentage of sales by demographic for each year in the dataset?
```sql
SELECT
    calendar_year AS year,
    demographic,
    ROUND(100 * SUM(sales)::NUMERIC / SUM(SUM(sales)) OVER (PARTITION BY calendar_year), 2) AS sales_percentage
FROM clean_weekly_sales
GROUP BY year, demographic
ORDER BY year, demographic;
```

#### Steps:
- Group records by `year` and `demographic` to aggregate sales for each year and demographic combination.
- Use the **SUM()** aggregate function to add all individual `sales` values for each group.
- Apply a **SUM() OVER()** window function with partition by `calendar_year` to calculate overall annual sales across all demographics.
- Multiply the grouped sales by 100 and apply a **NUMERIC** cast to prevent integer division before dividing by overall annual sales.
- Wrap the calculation in **ROUND()** to format the final percentage metrics to two decimal places.
- Order the final dataset in ascending sequence by `year` and `demographic` for structured presentation.

#### Answer:
| year | demographic | sales_percentage |
| ---- | ----------- | ---------------- |
| 2018 | Couples     | 26.38            |
| 2018 | Families    | 31.99            |
| 2018 | unknown     | 41.63            |
| 2019 | Couples     | 27.28            |
| 2019 | Families    | 32.47            |
| 2019 | unknown     | 40.25            |
| 2020 | Couples     | 28.72            |
| 2020 | Families    | 32.73            |
| 2020 | unknown     | 38.55            |

### 8. Which age_band and demographic values contribute the most to Retail sales?
- This question can be read two ways: ranking `age_band` and `demographic` independently, or ranking their combinations.
- I have taken Option 2 as the main interpretation.

#### Option 1: ranking `age_band` and `demographic` independently
```sql
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
```

#### Steps:
- Apply a **WHERE** clause (`platform = 'Retail'`) to include only retail sales.
- Add literal string labels ('age_band' as dimension) and group records by `age_band` to aggregate sales for each age band.
- Use the **SUM()** aggregate function to add all individual `sales` values for each age band.
- Apply a **SUM(SUM()) OVER ()** window function to calculate overall total retail sales across age bands.
- Multiply the grouped sales by 100 and apply a **NUMERIC** cast to prevent integer division before dividing by total retail sales.
- Wrap the calculation in **ROUND()** to format the final percentage metrics to two decimal places.
- Apply **UNION ALL** to combine the age band results with the demographic results.
- Apply a **WHERE** clause (`platform = 'Retail'`) to include only retail sales.
- Add literal string labels ('demographic' as dimension) and group records by `demographic` to aggregate sales for each demographic.
- Use the **SUM()** aggregate function to add all individual `sales` values for each demographic.
- Apply a **SUM(SUM()) OVER ()** window function to calculate overall total retail sales across demographics.
- Multiply the grouped sales by 100 and apply a **NUMERIC** cast to prevent integer division before dividing by total retail sales.
- Wrap the calculations in **ROUND()** to format the output values to two decimal places.
- (Optional) Order the final dataset ascending by `dimension` and descending by `retail_sales` for structured presentation.

#### Answer:
| dimension   | value        | retail_sales   | pct_of_retail_sales |
| ----------- | ------------ | -------------- | ------------------- |
| age_band    | unknown      | 16,067,285,533 | 40.52               |
| age_band    | Retirees     | 13,005,266,930 | 32.80               |
| age_band    | Middle Aged  | 6,208,251,884  | 15.66               |
| age_band    | Young Adults | 4,373,812,090  | 11.03               |
| demographic | unknown      | 16,067,285,533 | 40.52               |
| demographic | Families     | 12,759,667,763 | 32.18               |
| demographic | Couples      | 10,827,663,141 | 27.30               |

- Each dimension adds up to 100% on its own, because each is a different slicing of the same Retail total.
- Excluding unknown, Retirees (32.80%) is the top age band and Families (32.18%) is the top demographic.

#### Option 2: ranking `age_band` and `demographic` combinations
```sql
SELECT
    age_band,
    demographic,
    SUM(sales) AS retail_sales,
    ROUND(100 * SUM(sales)::NUMERIC / SUM(SUM(sales)) OVER (), 2) AS pct_of_retail_sales
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY retail_sales DESC;
```

#### Steps:
- Apply a **WHERE** clause (`platform = 'Retail'`) to include only retail sales.
- Group records by `age_band` and `demographic` to aggregate sales for each age band and demographic combination.
- Use the **SUM()** aggregate function to add all individual `sales` values for each group.
- Apply a **SUM(SUM()) OVER ()** window function to calculate overall total retail sales across all groups.
- Multiply the grouped sales by 100 and apply a **NUMERIC** cast to prevent integer division before dividing by total retail sales.
- Wrap the calculations in **ROUND()** to format the output values to two decimal places.
- (Optional) Order the final dataset in descending sequence by `retail_sales` for structured presentation.

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

- This option is more granular: the independent rankings from Option 1 can be derived from it, but not vice versa.
- Excluding unknown, the top combination is Retirees + Families (16.73%), followed closely by Retirees + Couples (16.07%).

### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
```sql
SELECT
	calendar_year AS year,
    platform,
	ROUND(AVG(avg_transaction), 2) AS avg_of_avg_transaction,
    ROUND(SUM(sales)::NUMERIC / SUM(transactions), 2) AS average_transaction,
    ROUND(AVG(avg_transaction) - SUM(sales)::NUMERIC / SUM(transactions), 2) AS difference
FROM clean_weekly_sales
GROUP BY year, platform
ORDER BY year, platform;
```

#### Steps:
- Group records by `year` and `platform` to aggregate transaction metrics per platform for each year.
- Apply **AVG()** aggregate function to compute the unweighted mean of average transactions.
- Use the **SUM()** aggregate function for both `sales` with a **NUMERIC** cast and `transactions` to compute the true weighted average transaction size.
- Subtract the true weighted average transaction size from the simple average to compute the metric discrepancy.
- Wrap the calculations in **ROUND()** to format the output values to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `year` and `platform` for structured presentation.

#### Answer:
| year | platform | avg_of_avg_transaction | average_transaction | difference |
| ---- | -------- | ---------------------- | ------------------- | ---------- |
| 2018 | Retail   | 42.91                  | 36.56               | 6.34       |
| 2018 | Shopify  | 188.28                 | 192.48              | -4.20      |
| 2019 | Retail   | 41.97                  | 36.83               | 5.13       |
| 2019 | Shopify  | 177.56                 | 183.36              | -5.80      |
| 2020 | Retail   | 40.64                  | 36.56               | 4.08       |
| 2020 | Shopify  | 174.87                 | 179.03              | -4.16      |

- Each `avg_transaction` value is already an average for one row (one week, region, platform, segment and customer type).
- Averaging those values gives an average of averages, which treats a row with 100 transactions the same as a row with 500,000.
- The correct approach is a weighted average (`average_transaction`), which weights each row by its number of transactions.
- The `avg_of_avg_transaction` is shown only for comparison.


## C. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the `week_date` value of `2020-06-15` as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all `week_date` values `for 2020-06-15` as the start of the period after the change and the previous `week_date` values would be before.

Using this analysis approach - answer the following questions:

### 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
```sql
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
```

#### Steps:
- Define a Common Table Expression (`period`) querying the `clean_weekly_sales` table.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_date >= DATE '2020-06-15' - INTERVAL '4 weeks' AND week_date <  DATE '2020-06-15'`) to calculate total sales during the 4 weeks prior to 15 of June 2020.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_date >= DATE '2020-06-15' AND week_date <  DATE '2020-06-15' + INTERVAL '4 weeks'`) to calculate total sales during the 4 weeks following June 2020.
- Subtract `sales_before` from `sales_after` to compute the net sales difference.
- Multiply the net sales difference by 100, cast to **NUMERIC**, divide by `sales_before`, and apply **ROUND()** to compute the percentage sales change rounded to two decimal places.

#### Answer:
| sales_before  | sales_after   | sales_change | percentage_rate |
| ------------- | ------------- | ------------ | --------------- |
| 2,345,878,357 | 2,318,994,169 | -26,884,188  | -1.15           |

### 2. What about the entire 12 weeks before and after?
```sql
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
```

#### Steps:
- Define a Common Table Expression (`period`) querying the `clean_weekly_sales` table.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_date >= DATE '2020-06-15' - INTERVAL '12 weeks' AND week_date <  DATE '2020-06-15'`) to calculate total sales during the 12 weeks prior to 15 of June 2020.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_date >= DATE '2020-06-15' AND week_date <  DATE '2020-06-15' + INTERVAL '12 weeks'`) to calculate total sales during the 12 weeks following June 2020.
- Subtract `sales_before` from `sales_after` to compute the net sales difference.
- Multiply the net sales difference by 100, cast to **NUMERIC**, divide by `sales_before`, and apply **ROUND()** to compute the percentage sales change rounded to two decimal places.

#### Answer:
| sales_before  | sales_after   | sales_change | percentage_rate |
| ------------- | ------------- | ------------ | --------------- |
| 7,126,273,147 | 6,973,947,753 | -152,325,394 | -2.14           |

### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
```sql
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
```

#### Steps:
- Define a Common Table Expression (`baseline`) querying the `clean_weekly_sales` table.
- Use **DISTINCT** to extract the unique `week_number` corresponding to 15 of June 2020.
- Define a Common Table Expression (`period`) cross-joining `clean_weekly_sales` with `baseline`, grouping by `year` to aggregate sales across multi-week windows.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_number BETWEEN baseline_week - 4 AND baseline_week - 1`) to calculate 4-week pre-baseline sales.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_number BETWEEN baseline_week AND baseline_week + 3`) to calculate 4-week post-baseline sales.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_number BETWEEN baseline_week - 12 AND baseline_week - 1`) to calculate 12-week pre-baseline sales.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_number BETWEEN baseline_week AND baseline_week + 11`) to calculate 12-week post-baseline sales.
- Subtract the respective "before" sales from "after" sales to compute the net sales difference.
- Multiply changes by 100, cast to **NUMERIC**, divide by the corresponding "before" totals, and apply **ROUND()** to compute relative impact metrics to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `year` for structured presentation.

#### Answer:
| year | four_week_sales_before | four_week_sales_after | four_week_sales_change | four_week_percentage_change | twelve_week_sales_before | twelve_week_sales_after | twelve_week_sales_change | twelve_week_percentage_change |
| ---- | ---------------------- | --------------------- | ---------------------- | --------------------------- | ------------------------ | ----------------------- | ------------------------ | ----------------------------- |
| 2018 | 2,119,669,585          | 2,115,732,898         | -3,936,687             | -0.19                       | 5,863,302,538            | 6,481,106,927           | 617,804,389              | 10.54                         |
| 2019 | 2,249,989,796          | 2,252,326,390         | 2,336,594              | 0.10                        | 6,883,386,397            | 6,862,646,103           | -20,740,294              | -0.30                         |
| 2020 | 2,345,878,357          | 2,318,994,169         | -26,884,188            | -1.15                       | 7,126,273,147            | 6,973,947,753           | -152,325,394             | -2.14                         |


## D. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- region
- platform
- age_band
- demographic
- customer_type

Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
```sql
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
```

#### Steps:
- Define a Common Table Expression (`baseline`) querying the `clean_weekly_sales` table.
- Use **DISTINCT** to extract the unique `week_number` corresponding to 15 of June 2020.
- Define a Common Table Expression (`period_sales`) cross-joining between `clean_weekly_sales` with `baseline`.
- Apply a **CROSS JOIN LATERAL (VALUES ...)** clause to unpivot the dimension columns (`region`, `platform`, `age_band`, `demographic`, `customer_type`) into standard `area` and `value` key-value pairs.
- Apply a **WHERE** clause (`week_number BETWEEN baseline_week - 12 AND baseline_week + 11 AND calendar_year = 2020`) to restrict records to the 12-week pre/post window for the year 2020.
- Group records by `area` and `value` to aggregate metrics per unpivoted dimension.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_number BETWEEN baseline_week - 12 AND baseline_week - 1`) to calculate 12-week pre-baseline sales.
- Apply conditional aggregations using **SUM()** with a **FILTER (WHERE ...)** clause (`week_number BETWEEN baseline_week AND baseline_week + 11`) to calculate 12-week post-baseline sales.
- Subtract `sales_before` from `sales_after` to compute the net sales difference.
- Multiply the net sales difference by 100, cast to **NUMERIC**, divide by `sales_before`, and apply **ROUND()** to compute the percentage changerounded to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `area` and `value` for structured presentation.

#### Answer:
| area          | value         | sales_before  | sales_after   | sales_change | percentage_change |
| ------------- | ------------- | ------------- | ------------- | ------------ | ----------------- |
| age_band      | Middle Aged   | 1,164,847,640 | 1,141,853,348 | -22,994,292  | -1.97             |
| age_band      | Retirees      | 2,395,264,515 | 2,365,714,994 | -29,549,521  | -1.23             |
| age_band      | Young Adults  | 801,806,528   | 794,417,968   | -7,388,560   | -0.92             |
| age_band      | unknown       | 2,764,354,464 | 2,671,961,443 | -92,393,021  | -3.34             |
| customer_type | Existing      | 3,690,116,427 | 3,606,243,454 | -83,872,973  | -2.27             |
| customer_type | Guest         | 2,573,436,301 | 2,496,233,635 | -77,202,666  | -3.00             |
| customer_type | New           | 862,720,419   | 871,470,664   | 8,750,245    | 1.01              |
| demographic   | Couples       | 2,033,589,643 | 2,015,977,285 | -17,612,358  | -0.87             |
| demographic   | Families      | 2,328,329,040 | 2,286,009,025 | -42,320,015  | -1.82             |
| demographic   | unknown       | 2,764,354,464 | 2,671,961,443 | -92,393,021  | -3.34             |
| platform      | Retail        | 6,906,861,113 | 6,738,777,279 | -168,083,834 | -2.43             |
| platform      | Shopify       | 219,412,034   | 235,170,474   | 15,758,440   | 7.18              |
| region        | AFRICA        | 1,709,537,105 | 1,700,390,294 | -9,146,811   | -0.54             |
| region        | ASIA          | 1,637,244,466 | 1,583,807,621 | -53,436,845  | -3.26             |
| region        | CANADA        | 426,438,454   | 418,264,441   | -8,174,013   | -1.92             |
| region        | EUROPE        | 108,886,567   | 114,038,959   | 5,152,392    | 4.73              |
| region        | OCEANIA       | 2,354,116,790 | 2,282,795,690 | -71,321,100  | -3.03             |
| region        | SOUTH AMERICA | 213,036,207   | 208,452,033   | -4,584,174   | -2.15             |
| region        | USA           | 677,013,558   | 666,198,715   | -10,814,843  | -1.60             |

- Age Band / Demographic: unknown is the single worst performer in both (-3.34%).
- Customer Type: Guest (-3.00%) declined more than Existing (-2.27%).
- Retail is the biggest issue in absolute terms (-168M), because it's about 97% of sales.
- Asia (-3.26%) and Oceania (-3.03%) are the worst performers amongst regions.
- Positive: Shopify (+7.18%), Europe (+4.73%) and New customers (+1.01%) all grew.
- Recommendations for Danny's team:
	- Look into why Guest and Existing customers fell while New customers grew, since the packaging change may have affected repeat buyers differently.
	- Shopify growing while Retail shrank suggests the change landed differently online and in-store.
	- ASIA and OCEANIA are the regions to check first.
	- It would also help to fix the null segment data at source, because 40% of Retail sales can't be analysed by demographic.

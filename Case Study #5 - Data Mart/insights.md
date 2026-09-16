## 1. Data Cleansing Steps

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


## 2. Data Exploration

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

````

#### Steps:
- 

#### Answer:

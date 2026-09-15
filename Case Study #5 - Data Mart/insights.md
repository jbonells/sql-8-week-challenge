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

````

#### Steps:
- 

#### Answer:


### 2. What range of week numbers are missing from the dataset?
````sql

````

#### Steps:
- 

#### Answer:


### 3. How many total transactions were there for each year in the dataset?
````sql

````

#### Steps:
- 

#### Answer:


### 4. What is the total sales for each region for each month?
````sql

````

#### Steps:
- 

#### Answer:


### 5. What is the total count of transactions for each platform
````sql

````

#### Steps:
- 

#### Answer:


### 6. What is the percentage of sales for Retail vs Shopify for each month?
````sql

````

#### Steps:
- 

#### Answer:


### 7. What is the percentage of sales by demographic for each year in the dataset?
````sql

````

#### Steps:
- 

#### Answer:


### 8. Which age_band and demographic values contribute the most to Retail sales?
````sql

````

#### Steps:
- 

#### Answer:


### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
````sql

````

#### Steps:
- 

#### Answer:

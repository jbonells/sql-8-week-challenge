## A. Data Exploration and Cleansing

### 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
```sql
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year TYPE DATE USING TO_DATE(month_year, 'MM-YYYY');
```

#### Steps:
- Use the **ALTER TABLE** statement to target the `fresh_segments.interest_metrics` table.
- Use the **ALTER COLUMN** statement to modify the column definition for `month_year`.
- Apply a **TYPE** clause to convert its data type to **DATE**.
- Apply the **TO_DATE()** function inside the **USING** expression to parse the string format `MM-YYYY` into a valid calendar date representation.

**NOTE:** I have added these steps to `schema.sql` to run the solution easily.


### 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
```sql
SELECT
	month_year,
	COUNT(*)
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST;
```

#### Steps:
- Group records by `month_year` to aggregate interest metrics per time period.
- Apply the **COUNT()** aggregate function to calculate total record volume for each month-year pair.
- Order the dataset in ascending sequence by `month_year`, using **NULLS FIRST** to explicitly place null values first.

#### Answer:
| month_year | count |
| ---------- | ----- |
| null       | 1194  |
| 2018-07-01 | 729   |
| 2018-08-01 | 767   |
| 2018-09-01 | 780   |
| 2018-10-01 | 857   |
| 2018-11-01 | 928   |
| 2018-12-01 | 995   |
| 2019-01-01 | 973   |
| 2019-02-01 | 1121  |
| 2019-03-01 | 1136  |
| 2019-04-01 | 1099  |
| 2019-05-01 | 857   |
| 2019-06-01 | 824   |
| 2019-07-01 | 864   |
| 2019-08-01 | 1149  |

### 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
```sql

```

#### Steps:
- 

#### Answer:


### 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
```sql

```

#### Steps:
- 

#### Answer:


### 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
```sql

```

#### Steps:
- 

#### Answer:


### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
```sql

```

#### Steps:
- 

#### Answer:


### 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
```sql

```

#### Steps:
- 

#### Answer:



## B. Interest Analysis


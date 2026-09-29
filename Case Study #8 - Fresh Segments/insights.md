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
DELETE FROM interest_metrics
WHERE month_year IS NULL;
```

#### Steps:
- Use the **DELETE FROM** statement to target the `interest_metrics` table.
- Apply a **WHERE** clause (`month_year IS NULL`) to isolate and remove records with missing date values.

**NOTE:** I have added these steps to `schema.sql` to run the solution easily.

#### Answer:
- There are 1,194 NULL rows, 1,193 of them are missing `_month`, `_year`, `month_year`, and `interest_id` — essentially orphan rows with no interest attached and no time period attached.
- Only one of them has a valid `interest_id` (21246, "Readers of El Salvadoran Content") but still no month_year.
- All 1,194 do have `composition`, `index_value`, `ranking`, and `percentile_ranking` populated.
- That is about 8.4% of the 14,273 total rows.
- **Decision:** delete them, since they cannot be tied to an interest or a time period and would distort any time-based or interest-level analysis later on.

### 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
```sql
SELECT
	COUNT(DISTINCT met.interest_id) AS in_metrics_not_map
FROM interest_metrics met
LEFT JOIN interest_map map
	ON met.interest_id::INTEGER = map.id
WHERE map.id IS NULL;

SELECT
	COUNT(DISTINCT map.id) AS in_map_not_metrics
FROM interest_map map
LEFT JOIN interest_metrics met
	ON map.id = met.interest_id::INTEGER
WHERE met.interest_id IS NULL;
```

#### Steps:
- Query 1: Unmapped Metrics Identification
	- Use a **LEFT JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
	- Apply a **WHERE** clause (`id IS NULL`) to isolate metric records that do not exist in the interest map.
	- Use **COUNT DISTINCT** to calculate the total unique unmapped interest IDs.
- Query 2: Unused Map Interest Identification
	- Use a **LEFT JOIN** on `map.id = met.interest_id` , casting `interest_id` to **INTEGER** to connect the `interest_map` and `interest_metrics` tables.
	- Apply a **WHERE** clause (`interest_id IS NULL`) to isolate map records that have no corresponding metrics activity.
	- Use **COUNT DISTINCT** to calculate the total unique unused interest IDs.

#### Answer:
| in_metrics_not_map |
| ------------------ |
| 0                  |

| in_map_not_metrics |
| ------------------ |
| 7                  |

- Every metrics interest has a map entry, and 7 map interests never appear in the metrics.

### 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
```sql
SELECT
	COUNT(id) AS total_records
FROM interest_map;
```

#### Steps:
- Apply the **COUNT()** aggregate function to calculate total records.
- (Optional) Assign the alias `total_records` to the resulting column for clear presentation in the final output report.

#### Answer:
| total_records |
| ------------- |
| 1209          |

### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
```sql
SELECT
	met.*,
	map.interest_name,
	map.interest_summary,
	map.created_at,
	map.last_modified
FROM interest_metrics met
INNER JOIN interest_map map
	ON met.interest_id::INTEGER = map.id
WHERE met.interest_id = '21246';
```

#### Steps:
- Use an **INNER JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
- Apply a **WHERE** clause (`interest_id = '21246'`) to isolate records matching interest ID 21246 for join logic validation.
- Select all attributes from `interest_metrics` (`met.*`) and explicitly select `interest_name`, `interest_summary`, `created_at`, and `last_modified` from `interest_map`, intentionally omitting `map.id`.

#### Answer:
| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking | interest_name                    | interest_summary                                      | created_at          | last_modified       |
| ------ | ----- | ---------- | ----------- | ----------- | ----------- | ------- | ------------------ | -------------------------------- | ----------------------------------------------------- | ------------------- | ------------------- |
| 4      | 2019  | 2019-04-01 | 21246       | 1.58        | 0.63        | 1092    | 0.64               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 3      | 2019  | 2019-03-01 | 21246       | 1.75        | 0.67        | 1123    | 1.14               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 2      | 2019  | 2019-02-01 | 21246       | 1.84        | 0.68        | 1109    | 1.07               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 1      | 2019  | 2019-01-01 | 21246       | 2.05        | 0.76        | 954     | 1.95               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 12     | 2018  | 2018-12-01 | 21246       | 1.97        | 0.7         | 983     | 1.21               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 11     | 2018  | 2018-11-01 | 21246       | 2.25        | 0.78        | 908     | 2.16               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 10     | 2018  | 2018-10-01 | 21246       | 1.74        | 0.58        | 855     | 0.23               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 9      | 2018  | 2018-09-01 | 21246       | 2.06        | 0.61        | 774     | 0.77               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 8      | 2018  | 2018-08-01 | 21246       | 2.13        | 0.59        | 765     | 0.26               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 7      | 2018  | 2018-07-01 | 21246       | 2.26        | 0.65        | 722     | 0.96               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |

- An **INNER JOIN** (or equivalently **LEFT JOIN** starting from `interest_metrics`), joining on `met.interest_id::INTEGER = map.id`.
- Every `interest_id` in `interest_metrics` has a matching `id` in `interest_map` (no orphans that direction), whilst seven ids in `interest_map` have no matching metrics.
- An **INNER JOIN** keeps all 13,079 usable metrics rows and drops those seven entries, which would otherwise appear as rows with every metrics column `NULL` and be useless for any analysis.

### 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
```sql
SELECT
	COUNT(*) AS total_records_before_created,
	COUNT(DISTINCT met.interest_id) AS distinct_interests_affected
FROM interest_metrics met
INNER JOIN interest_map map
	ON met.interest_id::INTEGER = map.id
WHERE met.month_year < map.created_at::DATE;

SELECT
	met.interest_id,
	met.month_year,
	map.created_at,
	DATE_TRUNC('month', map.created_at) = met.month_year AS same_month
FROM interest_metrics met
INNER JOIN interest_map map
	ON met.interest_id::INTEGER = map.id
WHERE met.month_year < map.created_at::DATE;

SELECT
	COUNT(*) FILTER (WHERE DATE_TRUNC('month', map.created_at) != met.month_year) AS different_month_count
FROM interest_metrics met
INNER JOIN interest_map map ON
	met.interest_id::INTEGER = map.id
WHERE met.month_year < map.created_at::DATE;
```

#### Steps:
- Query 1: Summary of Metrics
	- Use an **INNER JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
	- Apply a **WHERE** clause (`met.month_year < map.created_at`), casting `created_at` to **DATE** to isolate records where metrics were logged before the interest record was created.
	- Use the **COUNT()** aggregate function to calculate total affected records.
	- Use **COUNT DISTINCT** to calculate total unique interest IDs impacted.
- Query 2: Detailed Metrics for Specific Interest
	- Use an **INNER JOIN** on `map.id = met.interest_id` , casting `interest_id` to **INTEGER** to connect the `interest_map` and `interest_metrics` tables.
	- Apply a **WHERE** clause (`met.month_year < map.created_at::DATE AND met.interest_id = '32701'`) to isolate records where metrics were logged before the interest record was created, specifically for interest ID 32701.
- Query 3: Same-Month Truncation Check
	- Use an **INNER JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
	- Apply a **WHERE** clause (`met.month_year < map.created_at`), casting `created_at` to **DATE** to isolate records where metrics were logged before the interest record was created.
	- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`DATE_TRUNC('month', map.created_at) != met.month_year`) to count records where the metric month differs from the creation month.

#### Answer:
| total_records_before_created | distinct_interests_affected |
| ---------------------------- | --------------------------- |
| 188                          | 188                         |

| interest_id | month_year | created_at          |
| ----------- | ---------- | ------------------- |
| 32701       | 2018-07-01 | 2018-07-06 14:35:03 |

| different_month_count |
| --------------------- |
| 0                     |

- There are 188 rows, across 188 distinct interests.
- It is due to how `month_year` was truncated to the 1st of the month.
- As seen in the second table, `created_at` is 2018-07-06 and `month_year` was initially the text string `07-2018` then truncated to the 1st of the month.
- Verified this holds across all 188 affected rows — filtering for cases where the truncated month does not match `created_at`'s month returns zero.


## B. Interest Analysis

### 1. Which interests have been present in all month_year dates in our dataset?
```sql
WITH interest AS (
	SELECT
		interest_id, 
		COUNT(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
)

SELECT
	total_months,
	COUNT(*) AS interests_count
FROM interest
GROUP BY total_months
HAVING total_months = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics);
```

#### Steps:
- Define a Common Table Expression (`interest`) querying the `interest_metrics` table.
- Group records by `interest_id` to aggregate monthly activity per interest.
- Use **COUNT DISTINCT** to calculate the total unique active months per interest.
- Group records by `total_months` to aggregate interests by their active duration.
- Apply a **HAVING** clause using a scalar subquery to isolate interests present across all available reporting months.
- Apply the **COUNT()** aggregate function to compute the total number of fully present interests.

#### Answer:
| total_months | interests_count |
| ------------ | --------------- |
| 14           | 480             |

### 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
```sql

```

#### Steps:
- 

#### Answer:


### 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
```sql

```

#### Steps:
- 

#### Answer:


### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
```sql

```

#### Steps:
- 

#### Answer:


### 5. After removing these interests - how many unique interests are there for each month?
```sql

```

#### Steps:
- 

#### Answer:

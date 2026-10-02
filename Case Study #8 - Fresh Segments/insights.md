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
WITH interest_months AS (
	SELECT
		interest_id, 
		COUNT(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
)

SELECT
	total_months,
	COUNT(*) AS interests_count
FROM interest_months
GROUP BY total_months
HAVING total_months = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics);
```

#### Steps:
- Define a Common Table Expression (`interest_months`) querying the `interest_metrics` table.
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
WITH interest_months AS (
	SELECT
		interest_id, 
		COUNT(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
),
interest_count AS (
	SELECT
		total_months,
		COUNT(*) AS interests_count
	FROM interest_months
	GROUP BY total_months
)

SELECT
	total_months,
	interests_count,
	SUM(interests_count) OVER (ORDER BY total_months DESC) AS cumulative_count,
	ROUND(
		100.0 * SUM(interests_count) OVER (ORDER BY total_months DESC)
		/ SUM(interests_count) OVER (),
		2
	) AS cumulative_percentage
FROM interest_count
ORDER BY total_months DESC;
```

#### Steps:
- Define a Common Table Expression (`interest_months`) querying the `interest_metrics` table.
- Group records by `interest_id` to aggregate monthly activity per interest.
- Use **COUNT DISTINCT** to calculate the total unique active months per interest.
- Define a Common Table Expression (`interest_count`) querying the `interest_months` CTE.
- Group records by `total_months` to aggregate interests sharing the same active duration.
- Apply the **COUNT()** aggregate function to calculate the number of interests per active month duration.
- Apply a **SUM() OVER ()** window function ordered by `total_months` descending to compute a running cumulative total of interests.
- Apply a **SUM() OVER ()** window function ordered by `total_months` descending to compute a running cumulative total of interests.
- Apply a **SUM() OVER ()** window function across the entire dataset to compute total interest count across all duration buckets.
- Multiply cumulative count by 100.0 and divide by total overall interest count to derive relative cumulative percentage.
- Wrap the calculation in **ROUND()** to format the result to two decimal places.
- (Optional) Order the final dataset in descending sequence by `total_months` for structured presentation.

#### Answer:
| total_months | interests_count | cumulative_count | cumulative_percentage |
| ------------ | --------------- | ---------------- | --------------------- |
| 14           | 480             | 480              | 39.93                 |
| 13           | 82              | 562              | 46.76                 |
| 12           | 65              | 627              | 52.16                 |
| 11           | 94              | 721              | 59.98                 |
| 10           | 86              | 807              | 67.14                 |
| 9            | 95              | 902              | 75.04                 |
| 8            | 67              | 969              | 80.62                 |
| 7            | 90              | 1059             | 88.10                 |
| 6            | 33              | 1092             | 90.85                 |
| 5            | 38              | 1130             | 94.01                 |
| 4            | 32              | 1162             | 96.67                 |
| 3            | 15              | 1177             | 97.92                 |
| 2            | 12              | 1189             | 98.92                 |
| 1            | 13              | 1202             | 100.00                |

- The first value where cumulative percentage passes 90% (90.85%) is **6**, moving from 14 down to 1.

### 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
```sql
WITH interest_months AS (
	SELECT
		interest_id, 
		COUNT(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
)

SELECT
	COUNT(*) AS interests_to_remove,
	SUM(total_months) AS data_points_removed
FROM interest_months
WHERE total_months < 6;
```

#### Steps:
- Define a Common Table Expression (`interest_months`) querying the `interest_metrics` table.
- Group records by `interest_id` to aggregate monthly activity per interest.
- Use **COUNT DISTINCT** to calculate the total unique active months per interest.
- Apply a **WHERE** clause (`total_months < 6`) to isolate interests present in fewer than 6 reporting months.
- Apply the **COUNT()** aggregate function to calculate how many interests fall below the threshold.
- Apply the **SUM()** aggregate function to compute the number of data points (rows) those interests contribute.

#### Answer:
| interests_to_remove | data_points_removed |
| ------------------- | ------------------- |
| 110                 | 400                 |

### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
```sql
SELECT
	map.interest_name,
	met.month_year,
	met.composition,
	met.ranking,
	met.percentile_ranking
FROM interest_metrics met
INNER JOIN interest_map map
	ON map.id = met.interest_id::INTEGER
WHERE map.interest_name IN ('Nutrition Conscious Eaters', 'Big Box Shoppers')
ORDER BY map.interest_name, met.month_year;
```

#### Steps:
- Use an **INNER JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
- Apply a **WHERE** clause (`interest_name IN ('Nutrition Conscious Eaters', 'Big Box Shoppers')`) to isolate sample interest segments.
- (Optional) Order the final dataset in ascending sequence by `interest_name` and `month_year` for structured presentation.

#### Answer:
| interest_name              | month_year | composition | ranking | percentile_ranking |
| -------------------------- | ---------- | ----------- | ------- | ------------------ |
| Big Box Shoppers           | 2019-08-01 | 2.6         | 437     | 61.97              |
| Nutrition Conscious Eaters | 2018-07-01 | 10.77       | 5       | 99.31              |
| Nutrition Conscious Eaters | 2018-08-01 | 3.59        | 100     | 86.96              |
| Nutrition Conscious Eaters | 2018-09-01 | 2.4         | 235     | 69.87              |
| Nutrition Conscious Eaters | 2018-10-01 | 3.32        | 155     | 81.91              |
| Nutrition Conscious Eaters | 2018-11-01 | 2.88        | 141     | 84.81              |
| Nutrition Conscious Eaters | 2018-12-01 | 3.08        | 98      | 90.15              |
| Nutrition Conscious Eaters | 2019-01-01 | 2.48        | 177     | 81.81              |
| Nutrition Conscious Eaters | 2019-02-01 | 3.25        | 173     | 84.57              |
| Nutrition Conscious Eaters | 2019-03-01 | 2.95        | 190     | 83.27              |
| Nutrition Conscious Eaters | 2019-04-01 | 2.59        | 202     | 81.62              |
| Nutrition Conscious Eaters | 2019-05-01 | 1.93        | 251     | 70.71              |
| Nutrition Conscious Eaters | 2019-06-01 | 1.63        | 568     | 31.07              |
| Nutrition Conscious Eaters | 2019-07-01 | 1.96        | 591     | 31.6               |
| Nutrition Conscious Eaters | 2019-08-01 | 2.99        | 315     | 72.58              |

- Big Box Shoppers has a single data point. There iss no way to tell if it is a new segment, a temporary tracking gap, or a one-off — no trend can be drawn from one month.
- Nutrition Conscious Eaters shows a real trend across all 14 months. That kind of movement is what a segments business actually sells: growth, decline, seasonality.
- This supports removing interests with fewer than 6 months of history: without enough data points, an interest cannot support the kind of trend analysis the segments data is meant for.

### 5. After removing these interests - how many unique interests are there for each month?
```sql
WITH interest_months AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) >= 6
)
SELECT
	met.month_year,
	COUNT(DISTINCT met.interest_id) AS unique_interests
FROM interest_metrics met
INNER JOIN interest_months im
	ON met.interest_id = im.interest_id
GROUP BY met.month_year
ORDER BY met.month_year;
```

#### Steps:
- Define a Common Table Expression (`interest_months`) querying the `interest_metrics` table.
- Group records by `interest_id` to aggregate monthly activity per interest.
- Use **COUNT DISTINCT** to calculate the total unique active months per interest.
- Apply a **HAVING** clause (`COUNT(DISTINCT month_year) >= 6`) to isolate qualified interests active across at least 6 reporting months.
- Use an **INNER JOIN** on `interest_id` to connect the `interest_metrics` table and the `interest_months` CTE.
- Group the joined records by `month_year` to aggregate active interests per reporting time period.
- Use **COUNT DISTINCT** to calculate total unique qualified interests per month,
- (Optional) Order the final dataset in ascending sequence by `month_year` for structured presentation.

#### Answer:
| month_year | unique_interests |
| ---------- | ---------------- |
| 2018-07-01 | 709              |
| 2018-08-01 | 752              |
| 2018-09-01 | 774              |
| 2018-10-01 | 853              |
| 2018-11-01 | 925              |
| 2018-12-01 | 986              |
| 2019-01-01 | 966              |
| 2019-02-01 | 1072             |
| 2019-03-01 | 1078             |
| 2019-04-01 | 1035             |
| 2019-05-01 | 827              |
| 2019-06-01 | 804              |
| 2019-07-01 | 836              |
| 2019-08-01 | 1062             |


## C. Segment Analysis

### 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
```sql
-- Top 10 Interests
WITH interest_months AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) >= 6
),
max_composition AS (
	SELECT
		DISTINCT ON (met.interest_id)
		met.interest_id,
		met.month_year,
		met.composition
	FROM interest_metrics met
	INNER JOIN interest_months im
		ON met.interest_id = im.interest_id
	ORDER BY met.interest_id, met.composition DESC
)

SELECT
	map.interest_name,
	mc.month_year,
	mc.composition
FROM max_composition mc
INNER JOIN interest_map map
	ON map.id = mc.interest_id::INTEGER
ORDER BY mc.composition DESC
LIMIT 10;

-- Bottom 10 Interests
WITH interest_months AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) AS total_months
	FROM interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) >= 6
),
max_composition AS (
	SELECT
		DISTINCT ON (met.interest_id)
		met.interest_id,
		met.month_year,
		met.composition
	FROM interest_metrics met
	INNER JOIN interest_months im
		ON met.interest_id = im.interest_id
	ORDER BY met.interest_id, met.composition DESC
)

SELECT
	map.interest_name,
	mc.month_year,
	mc.composition
FROM max_composition mc
INNER JOIN interest_map map
	ON map.id = mc.interest_id::INTEGER
ORDER BY mc.composition ASC
LIMIT 10;
```

#### Steps:
- Define a Common Table Expression (`interest_months`) querying the `interest_metrics` table.
- Group records by `interest_id` to aggregate monthly activity per interest.
- Use **COUNT DISTINCT** to calculate the total unique active months per interest.
- Apply a **HAVING** clause (`COUNT(DISTINCT month_year) >= 6`) to isolate qualified interests active across at least 6 reporting months.
- Define a Common Table Expression (`max_composition`) that joins the `interest_metrics` table and the `interest_months` CTE on `interest_id`.
- Use **DISTINCT ON** combined with an **ORDER BY** to isolate the single maximum composition value and its corresponding `month_year` for each interest.
- Use an **INNER JOIN** on `interest_id` to connect the `interest_metrics` table and the `interest_months` CTE.
- Use an **INNER JOIN** on `map.id = mc.interest_id`, casting `interest_id` to **INTEGER** to connect the `max_composition` CTE and the `interest_map` table.
- **Top 10 interests**: Order the final dataset by `composition` in a DESCENDING sequence and apply a **LIMIT 10** clause to return the top 10 largest composition values.
- **Bottom 10 interests**: Order the final dataset by `composition` in an ASCENDING sequence and apply a **LIMIT 10** clause to return the bottom 10 largest composition values.

#### Answer:
| interest_name                     | month_year | composition |
| --------------------------------- | ---------- | ----------- |
| Work Comes First Travelers        | 2018-12-01 | 21.2        |
| Gym Equipment Owners              | 2018-07-01 | 18.82       |
| Furniture Shoppers                | 2018-07-01 | 17.44       |
| Luxury Retail Shoppers            | 2018-07-01 | 17.19       |
| Luxury Boutique Hotel Researchers | 2018-10-01 | 15.15       |
| Luxury Bedding Shoppers           | 2018-12-01 | 15.05       |
| Shoe Shoppers                     | 2018-07-01 | 14.91       |
| Cosmetics and Beauty Shoppers     | 2018-07-01 | 14.23       |
| Luxury Hotel Guests               | 2018-07-01 | 14.1        |
| Luxury Retail Researchers         | 2018-07-01 | 13.97       |

| interest_name                     | month_year | composition |
| --------------------------------- | ---------- | ----------- |
| Astrology Enthusiasts             | 2018-08-01 | 1.88        |
| Medieval History Enthusiasts      | 2018-10-01 | 1.94        |
| Dodge Vehicle Shoppers            | 2019-03-01 | 1.97        |
| Xbox Enthusiasts                  | 2018-07-01 | 2.05        |
| Camaro Enthusiasts                | 2018-10-01 | 2.08        |
| League of Legends Video Game Fans | 2019-01-01 | 2.09        |
| Budget Mobile Phone Researchers   | 2019-08-01 | 2.09        |
| Super Mario Bros Fans             | 2018-07-01 | 2.12        |
| Oakland Raiders Fans              | 2019-08-01 | 2.14        |
| Budget Wireless Shoppers          | 2018-07-01 | 2.18        |

### 2. Which 5 interests had the lowest average ranking value?
```sql
SELECT
	map.interest_name,
	ROUND(AVG(met.ranking), 2) AS average_ranking
FROM interest_metrics met
INNER JOIN interest_map map
	ON map.id = met.interest_id::INTEGER
GROUP BY map.interest_name
ORDER BY average_ranking ASC
LIMIT 5;
```

#### Steps:
- Use an **INNER JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
- Group the joined records by `interest_name` to aggregate the ranking data for each distinct interest.
- Use the **AVG()** aggregate function to calculate the average ranking per interest.
- Wrap it in the **ROUND()** function to format the result to two decimal places.
- Order the final dataset in ascending sequence by `average_ranking` to bring the best-ranking interests to the top.
- Apply a **LIMIT 5** clause to restrict the final output to only the top 5 interests.

#### Answer:
| interest_name                  | average_ranking |
| ------------------------------ | --------------- |
| Winter Apparel Shoppers        | 1.00            |
| Fitness Activity Tracker Users | 4.11            |
| Mens Shoe Shoppers             | 5.93            |
| Elite Cycling Gear Shoppers    | 7.80            |
| Shoe Shoppers                  | 9.36            |

### 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
```sql
SELECT
	map.interest_name,
	ROUND(STDDEV_SAMP(met.percentile_ranking)::NUMERIC, 2) AS std_dev_ranking
FROM interest_metrics met
INNER JOIN interest_map map
	ON map.id = met.interest_id::INTEGER
GROUP BY map.interest_name
ORDER BY std_dev_ranking DESC NULLS LAST
LIMIT 5;
```

#### Steps:
- Use an **INNER JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
- Group the joined records by `interest_name` to aggregate the ranking data for each distinct interest.
- Use the **STDDEV_SAMP()** function to calculate the sample standard deviation of the percentile ranking for each interest.
- Cast the standard deviation to **NUMERIC**, then wrap it in the **ROUND()** function to format the result to two decimal places.
- Order the final dataset in descending sequence by `std_dev_ranking`, utilising **NULLS LAST** to ensure any null values drop to the bottom of the results.
- Apply a **LIMIT 5** clause to restrict the final output to only the top 5 interests with the highest variance in their rankings.

#### Answer:
| interest_name                          | std_dev_ranking |
| -------------------------------------- | --------------- |
| Blockbuster Movie Fans                 | 41.27           |
| Android Fans                           | 30.72           |
| TV Junkies                             | 30.36           |
| Techies                                | 30.18           |
| Entertainment Industry Decision Makers | 28.97           |

### 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
```sql
WITH std_dev_ranking AS (
	SELECT
		map.interest_name,
		ROUND(STDDEV_SAMP(met.percentile_ranking)::NUMERIC, 2) AS std_dev_ranking
	FROM interest_metrics met
	INNER JOIN interest_map map
		ON map.id = met.interest_id::INTEGER
	GROUP BY map.interest_name
	ORDER BY std_dev_ranking DESC NULLS LAST
	LIMIT 5
),
ranked_metrics AS (
	SELECT
		map.interest_name,
		met.month_year,
		met.percentile_ranking,
		RANK() OVER (PARTITION BY map.interest_name ORDER BY met.percentile_ranking ASC) AS min_rank,
		RANK() OVER (PARTITION BY map.interest_name ORDER BY met.percentile_ranking DESC) AS max_rank
	FROM interest_metrics met
	INNER JOIN interest_map map
		ON map.id = met.interest_id::INTEGER
	WHERE map.interest_name IN (SELECT interest_name FROM std_dev_ranking)
)
SELECT
	interest_name,
	MAX(CASE WHEN min_rank = 1 THEN percentile_ranking END) AS min_percentile_ranking,
	MAX(CASE WHEN min_rank = 1 THEN month_year END) AS min_month_year,
	MAX(CASE WHEN max_rank = 1 THEN percentile_ranking END) AS max_percentile_ranking,
	MAX(CASE WHEN max_rank = 1 THEN month_year END) AS max_month_year
FROM ranked_metrics
GROUP BY interest_name
ORDER BY interest_name;
```

#### Steps:
- Define a Common Table Expression (`std_dev_ranking`) that joins the `interest_metrics` and `interest_map` tables on `map.id = met.interest_id`, casting `interest_id` to **INTEGER**.
- Group the joined records by `interest_name` to aggregate the ranking data for each distinct interest.
- Use the **STDDEV_SAMP()** function to calculate the sample standard deviation of the percentile ranking for each interest.
- Cast the standard deviation to **NUMERIC**, then wrap it in the **ROUND()** function to format the result to two decimal places.
- Order the final dataset in descending sequence by `std_dev_ranking`, utilising **NULLS LAST** to ensure any null values drop to the bottom of the results.
- Apply a **LIMIT 5** clause to restrict the final output to only the top 5 interests with the highest variance in their rankings.
- Define a Common Table Expression (`ranked_metrics`) that joins the `interest_metrics` and `interest_map` tables on `map.id = met.interest_id`, casting `interest_id` to **INTEGER**.
- Apply a **WHERE** clause with a subquery to isolate the target interest segments.
- Group records by `interest_name` to aggregate the final results.
- Apply the **RANK() OVER()** window function partitioned by `interest_name` and ordered by `percentile_ranking` ascending to assign a rank where the lowest percentile gets rank 1.
- Apply the **RANK() OVER()** window function partitioned by `interest_name` and ordered by `percentile_ranking` descending to assign a rank where the highest percentile gets rank 1.
- Apply a **CASE** statement inside the **MAX()** aggregate function to extract the `percentile_ranking` where `min_rank = 1`, pivoting it into a single row.
- Apply a **CASE** statement inside the **MAX()** aggregate function to extract the `month_year` where `min_rank = 1`, pivoting it into a single row.
- Apply a **CASE** statement inside the **MAX()** aggregate function to extract the `percentile_ranking` where `max_rank = 1`, pivoting it into a single row.
- Apply a **CASE** statement inside the **MAX()** aggregate function to extract the `month_year` where `max_rank = 1`, pivoting it into a single row.
- (Optional) Order the final dataset in ascending sequence by `interest_name` for structured presentation.

#### Answer:
| interest_name                          | min_percentile_ranking | min_month_year | max_percentile_ranking | max_month_year |
| -------------------------------------- | ---------------------- | -------------- | ---------------------- | -------------- |
| Android Fans                           | 4.84                   | 2019-03-01     | 75.03                  | 2018-07-01     |
| Blockbuster Movie Fans                 | 2.26                   | 2019-08-01     | 60.63                  | 2018-07-01     |
| Entertainment Industry Decision Makers | 11.23                  | 2019-08-01     | 86.15                  | 2018-07-01     |
| TV Junkies                             | 10.01                  | 2019-08-01     | 93.28                  | 2018-07-01     |
| Techies                                | 7.92                   | 2019-08-01     | 86.69                  | 2018-07-01     |

- Each interest's highest percentile ranking occurs in its earliest recorded month (2018-07), which is also the most densely-populated month in the dataset overall.
- Their lowest percentile rankings occur later, in 2019, after several months with no recorded data at all.
- This pattern most likely reflects these interests having too few, too volatile data points to represent a stable underlying trend.

### 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?
- This segment skews toward an active, style-conscious, premium-spending customer base — combining strong, consistently top-ranked interest in performance/athletic categories with high composition in luxury retail, boutique hospitality, and beauty/self-care.
- **Show:** premium/performance athletic gear, seasonal sportswear, luxury retail and boutique hospitality offerings, beauty and premium home goods — framed around quality and performance rather than price.
- **Avoid:** budget-framed messaging, mainstream gaming/pop-culture fandom campaigns, and economy-tier vehicle marketing — none of which this segment shows notable affinity for.


## D. Index Analysis
- The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
- Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

### 1. What is the top 10 interests by the average composition for each month?
```sql
WITH monthly_avg_composition AS (
    SELECT
        interest_id,
        month_year,
        ROUND((composition / index_value)::NUMERIC, 2) AS average_composition
    FROM interest_metrics
),
ranked_interests AS (
    SELECT
        interest_id,
        month_year,
        average_composition,
        ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY average_composition DESC) AS ranking
    FROM monthly_avg_composition
)

SELECT
    map.interest_name,
    ri.month_year,
    ri.average_composition
FROM ranked_interests ri
INNER JOIN interest_map map
	ON ri.interest_id::INTEGER = map.id
WHERE ri.ranking <= 10
ORDER BY ri.month_year, ri.ranking;
```

#### Steps:
- Define a Common Table Expression (`monthly_avg_composition`) querying the `interest_metrics` table.
- Divide `composition` by `index_value`, casting it to **NUMERIC**.
- Wrap the calculation in the **ROUND()** function to format the result to two decimal places, aliasing it as `average_composition`.
- Define a Common Table Expression (`ranked_interests`) querying the `monthly_avg_composition` CTE.
- Apply the **ROW_NUMBER() OVER()** window function partitioned by `month_year` and ordered by `average_composition` descending to assign a rank to each interest per month.
- Apply a **WHERE** clause (`ranking <= 10`) to filter the dataset, isolating only the top 10 average composition values for each month.
- Use an **INNER JOIN** on `r.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `ranked_interests` CTE and the `interest_map` table.
- Order the final dataset in ascending sequence by `month_year` and `ranking` to present the top 10 lists chronologically and by rank.

#### Answer:
| interest_name                 | month_year | average_composition |
| ----------------------------- | ---------- | ------------------- |
| Las Vegas Trip Planners       | 2018-07-01 | 7.36                |
| Gym Equipment Owners          | 2018-07-01 | 6.94                |
| Cosmetics and Beauty Shoppers | 2018-07-01 | 6.78                |
| Luxury Retail Shoppers        | 2018-07-01 | 6.61                |
| Furniture Shoppers            | 2018-07-01 | 6.51                |
| Asian Food Enthusiasts        | 2018-07-01 | 6.10                |
| Recently Retired Individuals  | 2018-07-01 | 5.72                |
| Family Adventures Travelers   | 2018-07-01 | 4.85                |
| Work Comes First Travelers    | 2018-07-01 | 4.80                |
| HDTV Researchers              | 2018-07-01 | 4.71                |

- The query returns the top 10 interests by `average_composition` for all 14 months (140 rows total). Only 2018-07-01 is shown here for brevity.

### 2. For all of these top 10 interests - which interest appears the most often?
```sql
WITH monthly_avg_composition AS (
    SELECT
        interest_id,
        month_year,
        ROUND((composition / index_value)::NUMERIC, 2) AS average_composition
    FROM interest_metrics
),
ranked_interests AS (
    SELECT
        interest_id,
        month_year,
        average_composition,
        ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY average_composition DESC) AS ranking
    FROM monthly_avg_composition
),
interest_ranking AS(
	SELECT
		map.interest_name,
		ri.month_year,
		ri.average_composition
	FROM ranked_interests ri
	INNER JOIN interest_map map
		ON map.id = ri.interest_id::INTEGER
	WHERE ri.ranking <= 10
),
counts AS (
	SELECT
		interest_name,
		COUNT(interest_name) AS count,
		RANK() OVER (ORDER BY COUNT(interest_name) DESC) AS overall_rank
	FROM interest_ranking
	GROUP BY interest_name
)

SELECT
	interest_name,
	count
FROM counts
WHERE overall_rank = 1;
```

#### Steps:
- Define a Common Table Expression (`monthly_avg_composition`) querying the `interest_metrics` table.
- Divide `composition` by `index_value`, casting it to **NUMERIC**.
- Wrap the calculation in the **ROUND()** function to format the result to two decimal places, aliasing it as `average_composition`.
- Define a Common Table Expression (`ranked_interests`) querying the `monthly_avg_composition` CTE.
- Apply the **ROW_NUMBER() OVER()** window function partitioned by `month_year` and ordered by `average_composition` descending to assign a rank to each interest per month.
- Define a Common Table Expression (`interest_ranking`) that joins the `ranked_interests` CTE and the `interest_map` table on `map.id = r.interest_id`, casting `interest_id` to **INTEGER**.
- Apply a **WHERE** clause (`ranking <= 10`) to filter the dataset, isolating only the top 10 average composition values for each month.
- Define a Common Table Expression (`counts`) querying the `interest_ranking` CTE.
- Group records by `interest_name` to aggregate the appearances for each distinct interest.
- Apply the **COUNT()** aggregate function to calculate the total number of months each interest appeared in a top 10 list.
- Apply the **RANK() OVER()** window function ordered by count descending to assign an overall rank to each interest based on its appearance frequency.
- Apply a **WHERE** clause (`overall_rank = 1`) to isolate the interest(s) that appeared most frequently across all the monthly top 10 lists.

#### Answer:
| interest_name            | count |
| ------------------------ | ----- |
| Solar Energy Researchers | 10    |
| Luxury Bedding Shoppers  | 10    |
| Alabama Trip Planners    | 10    |

### 3. What is the average of the average composition for the top 10 interests for each month?
```sql
WITH monthly_avg_composition AS (
    SELECT
        interest_id,
        month_year,
        ROUND((composition / index_value)::NUMERIC, 2) AS average_composition
    FROM interest_metrics
),
ranked_interests AS (
    SELECT
        interest_id,
        month_year,
        average_composition,
        ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY average_composition DESC) AS ranking
    FROM monthly_avg_composition
)

SELECT
    month_year,
    ROUND(AVG(average_composition), 2) AS average_top_10_composition
FROM ranked_interests
WHERE ranking <= 10
GROUP BY month_year
ORDER BY month_year;
```

#### Steps:
- Define a Common Table Expression (`monthly_avg_composition`) querying the `interest_metrics` table.
- Divide `composition` by `index_value`, casting it to **NUMERIC**.
- Wrap the calculation in the **ROUND()** function to format the result to two decimal places, aliasing it as `average_composition`.
- Define a Common Table Expression (`ranked_interests`) querying the `monthly_avg_composition` CTE.
- Apply the **ROW_NUMBER() OVER()** window function partitioned by `month_year` and ordered by `average_composition` descending to assign a rank to each interest per month.
- Apply a **WHERE** clause (`ranking <= 10`) to filter the dataset, isolating only the top 10 average composition values for each month.
- Group the filtered records by `month_year` to aggregate the appearances for each month.
- Use the **AVG()** aggregate function to calculate the average composition per month.
- Wrap the calculation in the **ROUND()** function to format the result to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `month_year` for structured presentation.

#### Answer:
| month_year | average_top_10_composition |
| ---------- | -------------------------- |
| 2018-07-01 | 6.04                       |
| 2018-08-01 | 5.95                       |
| 2018-09-01 | 6.90                       |
| 2018-10-01 | 7.07                       |
| 2018-11-01 | 6.62                       |
| 2018-12-01 | 6.65                       |
| 2019-01-01 | 6.40                       |
| 2019-02-01 | 6.58                       |
| 2019-03-01 | 6.17                       |
| 2019-04-01 | 5.75                       |
| 2019-05-01 | 3.54                       |
| 2019-06-01 | 2.43                       |
| 2019-07-01 | 2.77                       |
| 2019-08-01 | 2.63                       |

### 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
```sql
WITH monthly_avg_composition AS (
	SELECT 
		interest_id, 
		month_year, 
		ROUND((composition / index_value)::NUMERIC, 2) AS average_composition
	FROM interest_metrics
	WHERE month_year IS NOT NULL
),
monthly_max_ranked AS (
	SELECT 
		interest_id, 
		month_year, 
		average_composition,
		ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY average_composition DESC) AS ranking
	FROM monthly_avg_composition
),
top_monthly_interest AS (
	SELECT 
		ri.month_year, 
		map.interest_name, 
		ri.average_composition AS max_index_composition
	FROM monthly_max_ranked ri
	INNER JOIN interest_map map
	ON ri.interest_id::INTEGER = map.id
	WHERE ri.ranking = 1
),
rolling_metrics AS (
	SELECT 
		month_year,
		interest_name,
		max_index_composition,
		ROUND(
			AVG(max_index_composition) OVER (
				ORDER BY month_year
				ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
			)
			, 2
		) AS rolling_3_month_avg,
		LAG(interest_name, 1) OVER (ORDER BY month_year) AS previous_1_month_interest,
		LAG(interest_name, 2) OVER (ORDER BY month_year) AS previous_2_month_interest
	FROM top_monthly_interest
)

SELECT 
    month_year,
    interest_name,
    max_index_composition,
    rolling_3_month_avg AS "3_month_moving_avg",
    previous_1_month_interest AS "1_month_ago",
    previous_2_month_interest AS "2_month_ago"
FROM rolling_metrics
WHERE month_year >= '2018-09-01' AND month_year <= '2019-08-31'
ORDER BY month_year;
```

#### Steps:
- Define a Common Table Expression (`monthly_avg_composition`) querying the `interest_metrics` table.
- Divide `composition` by `index_value`, casting it to **NUMERIC**.
- Wrap the calculation in the **ROUND()** function to format the result to two decimal places, aliasing it as `average_composition`.
- Define a Common Table Expression (`monthly_max_ranked`) querying the `monthly_avg_composition` CTE.
- Apply the **ROW_NUMBER() OVER()** window function partitioned by `month_year` and ordered by `average_composition` descending to assign a rank to each interest per month.
- Define a Common Table Expression (`top_monthly_interest`) that joins the `monthly_max_ranked` CTE and the `interest_map` table on `map.id = ri.interest_id`, casting `interest_id` to **INTEGER**.
- Apply a **WHERE** clause (`ranking = 1`) to filter the dataset, isolating only the top 1 average composition values for each month.
- Define a Common Table Expression (`rolling_metrics`) querying the `top_monthly_interest` CTE.
- Apply the **AVG() OVER()** window function ordered by `month_year`.
- Use `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` to calculate a 3-month moving average.
- Wrap this moving average calculation in the **ROUND()** function to format the result to two decimal places.
- Apply the **LAG() OVER()** window function ordered by `month_year` with an offset of 1 to fetch the `interest_name` from the previous month.
- Apply the **LAG() OVER()** window function ordered by `month_year` with an offset of 2 to fetch the `interest_name` from two months prior.
- Apply a **WHERE** clause (`month_year >= '2018-09-01' AND month_year <= '2019-08-31'`) to filter the dataset strictly to the date range between '2018-09-01' and '2019-08-31'.
- (Optional) Order the final dataset in ascending sequence by `month_year` for structured presentation.

#### Answer:
| month_year | interest_name                 | max_index_composition | 3_month_moving_avg | 1_month_ago                | 2_month_ago                 |
| ---------- | ----------------------------- | --------------------- | ------------------ | -------------------------- | --------------------------- |
| 2018-09-01 | Work Comes First Travelers    | 8.26                  | 7.61               | Las Vegas Trip Planners    | Las Vegas Trip Planners     |
| 2018-10-01 | Work Comes First Travelers    | 9.14                  | 8.20               | Work Comes First Travelers | Las Vegas Trip Planners     |
| 2018-11-01 | Work Comes First Travelers    | 8.28                  | 8.56               | Work Comes First Travelers | Work Comes First Travelers  |
| 2018-12-01 | Work Comes First Travelers    | 8.31                  | 8.58               | Work Comes First Travelers | Work Comes First Travelers  |
| 2019-01-01 | Work Comes First Travelers    | 7.66                  | 8.08               | Work Comes First Travelers | Work Comes First Travelers  |
| 2019-02-01 | Work Comes First Travelers    | 7.66                  | 7.88               | Work Comes First Travelers | Work Comes First Travelers  |
| 2019-03-01 | Alabama Trip Planners         | 6.54                  | 7.29               | Work Comes First Travelers | Work Comes First Travelers  |
| 2019-04-01 | Solar Energy Researchers      | 6.28                  | 6.83               | Alabama Trip Planners      | Work Comes First Travelers  |
| 2019-05-01 | Readers of Honduran Content   | 4.41                  | 5.74               | Solar Energy Researchers   | Alabama Trip Planners       |
| 2019-06-01 | Las Vegas Trip Planners       | 2.77                  | 4.49               | Readers of Honduran Content| Solar Energy Researchers    |
| 2019-07-01 | Las Vegas Trip Planners       | 2.82                  | 3.33               | Las Vegas Trip Planners    | Readers of Honduran Content |
| 2019-08-01 | Cosmetics and Beauty Shoppers | 2.73                  | 2.77               | Las Vegas Trip Planners    | Las Vegas Trip Planners     |

### 5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
- Significant month-to-month fluctuations in the max average composition suggest the underlying data pool is highly volatile.
- This signals potential risks to the Fresh Segments business model:
	- **Sample Instability:** The data samples used to define these interest segments might be too inconsistent to build reliable, long-term behavioural profiles.
	- **Client Churn:** Rapid client turnover or the addition of massive, short-term clients can cause the dominant user base to change drastically each month.
	- **Calibration Issues:** The baseline `index_value` might be poorly calibrated, making normal seasonal shifts appear as extreme anomalies.
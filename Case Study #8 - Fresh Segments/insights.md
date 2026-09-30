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
JOIN interest_map map
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
JOIN interest_map map
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
JOIN interest_map map
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
	ROUND(AVG(met.ranking), 2) AS avg_ranking
FROM interest_metrics met
JOIN interest_map map
	ON map.id = met.interest_id::INTEGER
GROUP BY map.interest_name
ORDER BY avg_ranking ASC
LIMIT 5;
```

#### Steps:
- Use an **INNER JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
- Group the joined records by `interest_name` to aggregate the ranking data for each distinct interest.
- Use the **AVG()** aggregate function to calculate the average ranking per interest
- Wrap it in the **ROUND()** function to limit the result to 2 decimal places.
- Order the final dataset in ascending sequence by `avg_ranking` to bring the best-ranking interests to the top.
- Apply a **LIMIT 5** clause to restrict the final output to only the top 5 interests.

#### Answer:
| interest_name                  | avg_ranking |
| ------------------------------ | ----------- |
| Winter Apparel Shoppers        | 1.00        |
| Fitness Activity Tracker Users | 4.11        |
| Mens Shoe Shoppers             | 5.93        |
| Elite Cycling Gear Shoppers    | 7.80        |
| Shoe Shoppers                  | 9.36        |

### 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
```sql
SELECT
	map.interest_name,
	ROUND(STDDEV_SAMP(met.percentile_ranking)::NUMERIC, 2) AS std_dev_ranking
FROM interest_metrics met
JOIN interest_map map
	ON map.id = met.interest_id::INTEGER
GROUP BY map.interest_name
ORDER BY std_dev_ranking DESC NULLS LAST
LIMIT 5;
```

#### Steps:
- Use an **INNER JOIN** on `met.interest_id = map.id`, casting `interest_id` to **INTEGER** to connect the `interest_metrics` and `interest_map` tables.
- Group the joined records by `interest_name` to aggregate the ranking data for each distinct interest.
- Use the **STDDEV_SAMP()** function to calculate the sample standard deviation of the percentile ranking for each interest.
- Cast the standard deviation to **NUMERIC**, then wrap it in the **ROUND()** function to limit the result to 2 decimal places.
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

```

#### Steps:
- 

#### Answer:


### 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?
```sql

```

#### Steps:
- 

#### Answer:



## D. Index Analysis
- The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
- Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

### 1. What is the top 10 interests by the average composition for each month?
```sql

```

#### Steps:
- 

#### Answer:


### 2. For all of these top 10 interests - which interest appears the most often?
```sql

```

#### Steps:
- 

#### Answer:


### 3. What is the average of the average composition for the top 10 interests for each month?
```sql

```

#### Steps:
- 

#### Answer:


### 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
```sql

```

#### Steps:
- 

#### Answer:


### 5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
```sql

```

#### Steps:
- 

#### Answer:

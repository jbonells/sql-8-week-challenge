/* --------------------
   Case Study Questions
   --------------------*/

-- A. Data Exploration and Cleansing

-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year TYPE DATE USING TO_DATE(month_year, 'MM-YYYY');

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT
	month_year,
	COUNT(*)
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
DELETE FROM interest_metrics
WHERE month_year IS NULL;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
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

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT
	COUNT(id) AS total_records
FROM interest_map;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
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

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
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


-- B. Interest Analysis

-- 1. Which interests have been present in all month_year dates in our dataset?
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

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
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

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
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

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
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

-- 5. After removing these interests - how many unique interests are there for each month?
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


-- C. Segment Analysis

-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
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

-- 2. Which 5 interests had the lowest average ranking value?
SELECT
	map.interest_name,
	ROUND(AVG(met.ranking), 2) AS average_ranking
FROM interest_metrics met
INNER JOIN interest_map map
	ON map.id = met.interest_id::INTEGER
GROUP BY map.interest_name
ORDER BY average_ranking ASC
LIMIT 5;

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
SELECT
	map.interest_name,
	ROUND(STDDEV_SAMP(met.percentile_ranking)::NUMERIC, 2) AS std_dev_ranking
FROM interest_metrics met
INNER JOIN interest_map map
	ON map.id = met.interest_id::INTEGER
GROUP BY map.interest_name
ORDER BY std_dev_ranking DESC NULLS LAST
LIMIT 5;

-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
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


-- D. Index Analysis
-- The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
-- Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

-- 1. What is the top 10 interests by the average composition for each month?
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

-- 2. For all of these top 10 interests - which interest appears the most often?
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

-- 3. What is the average of the average composition for the top 10 interests for each month?
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

-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
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

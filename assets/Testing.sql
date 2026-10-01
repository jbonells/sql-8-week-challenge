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
		ri.average_composition AS max_average_composition
	FROM monthly_max_ranked ri
	INNER JOIN interest_map map
	ON ri.interest_id::INTEGER = map.id
	WHERE ri.ranking = 1
),
rolling_metrics AS (
	SELECT 
		month_year,
		interest_name,
		max_average_composition,
		ROUND(
			AVG(max_average_composition) OVER (
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
    max_average_composition,
    rolling_3_month_avg AS "3_month_moving_avg",
    previous_1_month_interest AS "1_month_ago",
    previous_2_month_interest AS "2_month_ago"
FROM rolling_metrics
WHERE month_year >= '2018-09-01' AND month_year <= '2019-08-31'
ORDER BY month_year;
## A. Digital Analysis

### 1. How many users are there?
```sql
SELECT
	COUNT(DISTINCT user_id) AS users
FROM users;
```

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the total number of unique users.
- (Optional) Assign the alias `unique_users` to the resulting column for clear presentation in the final output report.

#### Answer:
| users |
| ----- |
| 500   |

### 2. How many cookies does each user have on average?
```sql
WITH cookies AS(
	SELECT
		user_id,
		COUNT(cookie_id) AS cookie_id_count
	FROM users
	GROUP BY user_id
)

SELECT
	ROUND(AVG(cookie_id_count), 0) AS avg_cookies
FROM cookies
```

#### Steps:
- Define a Common Table Expression (`cookies`) querying the `users` table.
- Group the records by `user_id` to aggregate cookies per user.
- Apply the **COUNT** aggregate function to calculate the total number of cookies for each user.
- Apply the **AVG** aggregate function to calculate the average number of cookies per user across the aggregated CTE.
- Wrap the calculation in **ROUND** to format the average to 0 decimal places.

#### Answer:
| avg_cookies |
| ----------- |
| 4           |

### 3. What is the unique number of visits by all users per month?
```sql
SELECT
	EXTRACT(MONTH FROM e.event_time) AS month,
    COUNT(DISTINCT e.visit_id) AS visits
FROM users u
INNER JOIN events e
	ON u.cookie_id = e.cookie_id
GROUP BY month
ORDER BY month;
```

#### Steps:
- Use an **INNER JOIN** on `cookie_id` to connect the `users` and `events` tables.
- Use **EXTRACT(MONTH FROM ...)** to isolate the numerical month value from the event timestamps.
- Group records by `month` to aggregate visit counts for each calendar month.
- Apply the **COUNT** aggregate function with **DISTINCT** to calculate the unique volume of `visits` per month.
- (Optional) Order the final dataset in ascending sequence by `month` for structured presentation.

#### Answer:
| month | visits |
| ----- | ------ |
| 1     | 876    |
| 2     | 1488   |
| 3     | 916    |
| 4     | 248    |
| 5     | 36     |

### 4. What is the number of events for each event type?
```sql
SELECT
	ei.event_name,
    COUNT(*) AS event_count
FROM events e
INNER JOIN event_identifier ei
	ON e.event_type = ei.event_type
GROUP BY ei.event_name
ORDER BY event_count DESC;
```

#### Steps:
- Use an **INNER JOIN** on `event_type` to connect the `events` and `event_identifier` tables.
- Group records by `event_name` to aggregate metrics for each distinct event type.
- Apply the **COUNT** aggregate function to calculate the total volume of events per group.
- (Optional) Order the final dataset in descending sequence by `event_count` for structured presentation.

#### Answer:
| event_name    | event_count |
| ------------- | ----------- |
| Page View     | 20928       |
| Add to Cart   | 8451        |
| Purchase      | 1777        |
| Ad Impression | 876         |
| Ad Click      | 702         |

### 5. What is the percentage of visits which have a purchase event?
```sql
SELECT
	ROUND(
		100.0 * COUNT(DISTINCT visit_id) FILTER (WHERE event_type = 3)
		/ COUNT(DISTINCT visit_id),
		2
	) AS purchase_percentage
FROM events;
```

#### Steps:
- Apply conditional aggregation using **COUNT() FILTER (WHERE ...)** multiplied by 100.0 to calculate unique purchase visits and promote the calculation to a decimal value.
- Use **COUNT()** to divide the purchase visits by the total count of unique visits.
- Wrap the calculation with **ROUND** to present the result as a percentage rounded to two decimal places.

#### Answer:
| purchase_percentage |
| ------------------- |
| 49.86               |

### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
```sql
WITH visit_flags AS (
	SELECT 
		visit_id,
		COUNT(DISTINCT visit_id) FILTER (WHERE event_type = 1 AND page_id = 12) AS checkout,
		COUNT(DISTINCT visit_id) FILTER (WHERE event_type = 3) AS purchase
	FROM events
	GROUP BY visit_id
)

SELECT
	ROUND(
		100.0 * COUNT(DISTINCT visit_id) FILTER (WHERE checkout = 1 AND purchase = 0)
		/ COUNT(DISTINCT visit_id) FILTER (WHERE checkout = 1),
		2
	) AS percentage_checkout_no_purchase
FROM visit_flags;
```

#### Steps:
- Define a Common Table Expression (`visit_flags`) querying the `events` table.
- Group records by `visit_id` to evaluate activity per visit.
- Apply conditional aggregation using **COUNT() FILTER (WHERE ...)** to flag visits reaching the checkout page.
- Apply conditional aggregation using **COUNT() FILTER (WHERE ...)** to flag visits completing a purchase.
- Apply conditional aggregation using **COUNT() FILTER (WHERE ...)** multiplied by 100.0 to calculate abandoned checkout visits and promote the calculation to a decimal value.
- Use **COUNT()** to divide abandoned checkout visits by total checkout visits.
- Wrap the calculation with **ROUND** to present the result as a percentage rounded to two decimal places.

#### Answer:
| percentage_checkout_no_purchase |
| ------------------------------- |
| 15.50                           |

### 7. What are the top 3 pages by number of views?
```sql
SELECT
	ph.page_name,
	COUNT(*) AS visits
FROM events e
INNER JOIN page_hierarchy ph
	ON e.page_id = ph.page_id
WHERE e.event_type = 1
GROUP BY ph.page_name
ORDER BY visits DESC
LIMIT 3;
```

#### Steps:
- Use an **INNER JOIN** on `page_id` to connect the `events` and `page_hierarchy` tables.
- Apply a **WHERE** clause (`event_type = 1`) to isolate page view events.
- Group records by `page_name` to aggregate metrics for each distinct page.
- Use the **COUNT** aggregate function to tally the total volume of visits per page.
- Order the aggregated results in descending sequence by `visits` to highlight the top pages.
- Apply **LIMIT** clause to restrict the output to the top 3 most visited pages.

#### Answer:
| page_name    | visits |
| ------------ | ------ |
| All Products | 3174   |
| Checkout     | 2103   |
| Home Page    | 1782   |

### 8. What is the number of views and cart adds for each product category?
```sql
SELECT
	ph.product_category,
	COUNT(*) FILTER (WHERE e.event_type = 1) AS views,
	COUNT(*) FILTER (WHERE e.event_type = 2) AS cart_adds
FROM events e
INNER JOIN page_hierarchy ph
	ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY ph.product_category;
```

#### Steps:
- Use an **INNER JOIN** on `page_id` to connect the `events` and `page_hierarchy` tables.
- Apply a **WHERE** clause (`product_category IS NOT NULL`) to exclude non-product page records.
- Group records by `product_category` to aggregate metrics for each distinct category.
- Apply conditional aggregation using **COUNT() FILTER (WHERE ...)** to calculate total page views for each category.
- Apply conditional aggregation using **COUNT() FILTER (WHERE ...)** to calculate total cart additions for each category.
- (Optional) Order the final dataset in ascending sequence by `product_category` for structured presentation.

#### Answer:
| product_category | views | cart_adds |
| ---------------- | ----- | --------- |
| Fish             | 4633  | 2789      |
| Luxury           | 3032  | 1870      |
| Shellfish        | 6204  | 3792      |

### 9. What are the top 3 products by purchases?
```sql
WITH purchase_visits AS (
	SELECT
		DISTINCT visit_id
	FROM events
	WHERE event_type = 3
),
product_cart_adds AS (
	SELECT
		e.visit_id,
        ph.page_name
	FROM events e
	INNER JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
	WHERE ph.product_category IS NOT NULL
		AND e.event_type = 2
)

SELECT
	pca.page_name AS product,
	COUNT(*) AS purchases
FROM product_cart_adds pca
INNER JOIN purchase_visits pv
	ON pca.visit_id = pv.visit_id
GROUP BY pca.page_name
ORDER BY purchases DESC
LIMIT 3;
```

#### Steps:
- Define a Common Table Expression (`purchase_visits`) querying the `events` table.
- Use **SELECT DISTINCT** with a **WHERE** clause (`event_type = 3`) to isolate unique purchase visits.
- Define a Common Table Expression (`product_cart_adds`) that joins the `events` and `page_hierarchy` tables on `page_id`.
- Apply a **WHERE** clause (`product_category IS NOT NULL AND event_type = 2`) to isolate product cart additions.
- Use an **INNER JOIN** on `visit_id` to connect the `product_cart_adds` and `purchase_visits` CTEs.
- Group records by `page_name` to aggregate metrics for each distinct product.
- Use the **COUNT** aggregate function to tally total successful purchases per product.
- Order the aggregated results in descending sequence by `purchases` to highlight top products.
- Apply **LIMIT** clause to restrict the output to the top 3 most purchased products.

#### Answer:
| product | purchases |
| ------- | --------- |
| Lobster | 754       |
| Oyster  | 726       |
| Crab    | 719       |


## B. Product Funnel Analysis

### Using a single SQL query - create a new output table which has the following details:
- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?
```sql
CREATE VIEW product_funnel AS
WITH product_info AS (
    SELECT
        e.visit_id,
        e.event_type,
        ph.page_name
    FROM events e
    INNER JOIN page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE ph.product_category IS NOT NULL
),
purchase_visits AS (
	SELECT
		DISTINCT visit_id
	FROM events
	WHERE event_type = 3
)

SELECT
    pi.page_name AS product,
    COUNT(*) FILTER (WHERE pi.event_type = 1) AS views,
    COUNT(*) FILTER (WHERE pi.event_type = 2) AS cart_adds,
    COUNT(*) FILTER (WHERE pi.event_type = 2 AND pv.visit_id IS NULL) AS abandoned,
    COUNT(*) FILTER (WHERE pi.event_type = 2 AND pv.visit_id IS NOT NULL) AS purchases
FROM product_info pi
LEFT JOIN purchase_visits pv
	ON pi.visit_id = pv.visit_id
GROUP BY product
ORDER BY product;
```

#### Steps:
- Use **CREATE VIEW** to create a view named `product_funnel` to store the output of the funnel transformation.
- Define a Common Table Expression (`product_info`) that joins the `events` and `page_hierarchy` tables on `page_id`.
- Apply a **WHERE** clause (`product_category IS NOT NULL`) to isolate product-related events.
- Define a Common Table Expression (`purchase_visits`) querying the `events` table.
- Use **SELECT DISTINCT** with a **WHERE** clause (`event_type = 3`) to isolate unique purchase visits.
- Use a **LEFT JOIN** on `visit_id` to connect the `product_info` and `purchase_visits` CTEs.
- Group records by `product` to aggregate metrics per product.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 1`) to tally total product page views.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 2`) to tally total product cart additions.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 2 AND visit_id IS NULL`) to tally cart additions that were abandoned.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 2 AND visit_id IS NOT NULL`) to tally cart additions that resulted in a completed purchase.
- (Optional) Order the final dataset in ascending sequence by `product` for structured presentation.

#### Answer:
| product        | views | cart_adds | abandoned | purchases |
| -------------- | ----- | --------- | --------- | --------- |
| Abalone        | 1525  | 932       | 233       | 699       |
| Black Truffle  | 1469  | 924       | 217       | 707       |
| Crab           | 1564  | 949       | 230       | 719       |
| Kingfish       | 1559  | 920       | 213       | 707       |
| Lobster        | 1547  | 968       | 214       | 754       |
| Oyster         | 1568  | 943       | 217       | 726       |
| Russian Caviar | 1563  | 946       | 249       | 697       |
| Salmon         | 1559  | 938       | 227       | 711       |
| Tuna           | 1515  | 931       | 234       | 697       |

### Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
```sql
CREATE VIEW category_funnel AS
WITH product_info AS (
    SELECT
        e.visit_id,
        e.event_type,
        ph.product_category
    FROM events e
    INNER JOIN page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE ph.product_category IS NOT NULL
),
purchase_visits AS (
	SELECT
		DISTINCT visit_id
	FROM events
	WHERE event_type = 3
)

SELECT
    pi.product_category,
    COUNT(*) FILTER (WHERE pi.event_type = 1) AS views,
    COUNT(*) FILTER (WHERE pi.event_type = 2) AS cart_adds,
    COUNT(*) FILTER (WHERE pi.event_type = 2 AND pv.visit_id IS NULL) AS abandoned,
    COUNT(*) FILTER (WHERE pi.event_type = 2 AND pv.visit_id IS NOT NULL) AS purchases
FROM product_info pi
LEFT JOIN purchase_visits pv
	ON pi.visit_id = pv.visit_id
GROUP BY product_category
ORDER BY product_category;
```

#### Steps:
- Use **CREATE VIEW** to create a view named `category_funnel` to store the output of the funnel transformation.
- Define a Common Table Expression (`product_info`) that joins the `events` and `page_hierarchy` tables on `page_id`.
- Apply a **WHERE** clause (`product_category IS NOT NULL`) to isolate product-related events.
- Define a Common Table Expression (`purchase_visits`) querying the `events` table.
- Use **SELECT DISTINCT** with a **WHERE** clause (`event_type = 3`) to isolate unique purchase visits.
- Use a **LEFT JOIN** on `visit_id` to connect the `product_info` and `purchase_visits` CTEs.
- Group records by `product_category` to aggregate metrics per product category.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 1`) to tally total product page views for each category.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 2`) to tally total product cart additions for each category.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 2 AND visit_id IS NULL`) to tally cart additions that were abandoned.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 2 AND visit_id IS NOT NULL`) to tally cart additions that resulted in a completed purchase.
- (Optional) Order the final dataset in ascending sequence by `product_category` for structured presentation.

#### Answer:
| product_category | views | cart_adds | abandoned | purchases |
| ---------------- | ----- | --------- | --------- | --------- |
| Fish             | 4633  | 2789      | 674       | 2115      |
| Luxury           | 3032  | 1870      | 466       | 1404      |
| Shellfish        | 6204  | 3792      | 894       | 2898      |

### Use your 2 new output tables - answer the following questions:
**NOTE:** I have added both views to `schema.sql` to run the solution easily.

### 1. Which product had the most views, cart adds and purchases?
```sql
SELECT * FROM (
    SELECT
		'Most Views' AS metric,
		product,
		views AS value
    FROM product_funnel
    ORDER BY views DESC
    LIMIT 1
) t1

UNION ALL

SELECT * FROM (
    SELECT
	'Most Cart Adds' AS metric,
	product,
	cart_adds AS value
    FROM product_funnel
    ORDER BY cart_adds DESC
    LIMIT 1
) t2

UNION ALL

SELECT * FROM (
    SELECT
		'Most Purchases' AS metric,
		product,
		purchases AS value
    FROM product_funnel
    ORDER BY purchases DESC
    LIMIT 1
) t3;
```

#### Steps:
- Query the `product_funnel` view to extract the top product by views, ordering by `views` DESC with a LIMIT 1 clause.
- Apply **UNION ALL** to combine the top views result with the top cart adds result.
- Query the `product_funnel` view to extract the top product by cart additions, ordering by `cart_adds` DESC with a LIMIT 1 clause.
- Apply **UNION ALL** to combine the previous results with the top purchases result.
- Query the `product_funnel` view to extract the top product by purchases, ordering by `purchases` DESC with a LIMIT 1 clause.

#### Answer:
| metric         | product | value |
| -------------- | ------- | ----- |
| Most Views     | Oyster  | 1568  |
| Most Cart Adds | Lobster | 968   |
| Most Purchases | Lobster | 754   |

### 2. Which product was most likely to be abandoned?
```sql
SELECT
	product,
	ROUND(100.0 * abandoned / cart_adds, 2) AS abandon_rate_pct
FROM product_funnel
ORDER BY abandon_rate_pct DESC
LIMIT 1;
```

#### Steps:
- Query the `product_funnel` view.
- Multiply `abandoned` by 100.0 to promote the calculation to a decimal value and divide by `cart_adds` to calculate the abandonment proportion.
- Apply **ROUND()** to format the resulting metric to two decimal places.
- Order the dataset in descending sequence by `abandon_rate_pct` to highlight the highest abandonment rate.
- Apply a **LIMIT** clause to isolate the single product with the highest cart abandonment percentage.

#### Answer:
| product        | abandon_rate_pct |
| -------------- | ---------------- |
| Russian Caviar | 26.32            |

### 3. Which product had the highest view to purchase percentage?
```sql
SELECT
	product,
	ROUND(100.0 * purchases / views, 2) AS view_to_purchase_pct
FROM product_funnel
ORDER BY view_to_purchase_pct DESC
LIMIT 1;
```

#### Steps:
- Query the `product_funnel` view.
- Multiply `purchases` by 100.0 to promote the calculation to a decimal value and divide by `views` to calculate the conversion proportion.
- Apply **ROUND()** to format the resulting conversion metric to two decimal places.
- Order the dataset in descending sequence by `view_to_purchase_pct` to highlight the highest purchase rate.
- Apply a **LIMIT** clause to isolate the single product with the highest view-to-purchase percentage.

#### Answer:
| product | view_to_purchase_pct |
| ------- | -------------------- |
| Lobster | 48.74                |

### 4. What is the average conversion rate from view to cart add?
```sql
SELECT
	ROUND(AVG(100.0 * cart_adds / views), 2) AS avg_view_to_cart_ratio
FROM product_funnel;
```

#### Steps:
- Query the `product_funnel` view.
- Multiply `cart_adds` by 100.0 to promote the calculation to a decimal value, divide by `views` per product.
- Apply **AVG()** wrapped in **ROUND()** to compute the unweighted mean view-to-cart conversion ratio rounded to two decimal places.

#### Answer:
| avg_view_to_cart_ratio |
| ---------------------- |
| 60.95                  |

- The average view-to-cart-add conversion rate is 60.95% (mean of each product's individual rate) and 60.93% (pooled rate: total cart adds ÷ total views).
- The two are nearly identical, indicating view traffic is fairly evenly distributed across products — no single product disproportionately skews the average.

### 5. What is the average conversion rate from cart add to purchase?
```sql
SELECT
	ROUND(AVG(100.0 * purchases / cart_adds), 2) AS avg_cart_to_purchase_ratio
FROM product_funnel;
```

#### Steps:
- Query the `product_funnel` view.
- Multiply `purchases` by 100.0 to promote the calculation to a decimal value, divide by `cart_adds` per product.
- Apply **AVG()** wrapped in **ROUND()** to compute the unweighted mean cart-to-purchase conversion ratio rounded to two decimal places.

#### Answer:
| avg_cart_to_purchase_ratio |
| -------------------------- |
| 75.93                      |


## C. Campaigns Analysis

### Generate a table that has 1 single row for every unique visit_id record and has the following columns:
- `user_id`
- `visit_id`
- `visit_start_time`: the earliest `event_time` for each visit
- `page_views`: count of page views for each visit
- `cart_adds`: count of product cart add events for each visit
- `purchase`: 1/0 flag if a purchase event exists for each visit
- `campaign_name`: map the visit to a campaign if the `visit_start_time` falls between the `start_date` and `end_date`
- `impression`: count of ad impressions for each visit
- `click`: count of ad clicks for each visit
- (Optional column) `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the `sequence_number`)
```sql
WITH aggregates AS(
	SELECT
		u.user_id,
		e.visit_id,
		MIN(e.event_time) AS visit_start_time,
		COUNT(*) FILTER (WHERE e.event_type = 1) AS page_views,
		COUNT(*) FILTER (WHERE e.event_type = 2) AS cart_adds,
		MAX(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchase,
		COUNT(*) FILTER (WHERE e.event_type = 4) AS impression,
		COUNT(*) FILTER (WHERE e.event_type = 5) AS click,
		STRING_AGG(ph.page_name, ', ' ORDER BY e.sequence_number) FILTER (WHERE e.event_type = 2) AS cart_products
	FROM users u
	INNER JOIN events e
		ON u.cookie_id = e.cookie_id
	LEFT JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
	GROUP BY u.user_id, e.visit_id
)

SELECT
	a.user_id,
	a.visit_id,
	a.visit_start_time,
	a.page_views,
	a.cart_adds,
	a.purchase,
	ci.campaign_name,
	a.impression,
	a.click,
    a.cart_products
FROM aggregates a
LEFT JOIN campaign_identifier ci
	ON visit_start_time::DATE BETWEEN ci.start_date AND ci.end_date
ORDER BY a.user_id;
```

#### Steps:
- Define a Common Table Expression (`aggregates`) that joins the `users` and `events` tables on `cookie_id`, with a **LEFT JOIN** to `page_hierarchy` on `page_id`.
- Group records by `user_id` and `visit_id` to aggregate visit-level user behaviour.
- Apply the **MIN()** aggregate function to extract the earliest event timestamp per visit.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 1`) to tally page views.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 2`) to tally cart additions.
- Apply a **CASE** statement inside the **MAX()** aggregate function to create a binary indicator flag for completed purchases.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 4`) to tally ad impressions.
- Apply conditional aggregations using **COUNT()** with a **FILTER (WHERE ...)** clause (`event_type = 5`) to tally ad clicks.
- Apply **STRING_AGG()** ordered by `sequence_number` with a **FILTER (WHERE ...)** clause (`event_type = 2`) to construct a comma-separated list of added products.
- Use a **LEFT JOIN** that joins the `aggregates` CTE and the `campaign_identifier` table with a **WHERE** clause (`visit_start_time::DATE BETWEEN start_date AND end_date`) to map matching marketing campaigns.
- (Optional) Order the final dataset in ascending sequence by `user_id` for structured presentation.

#### Answer:
| user_id | visit_id | visit_start_time           | page_views | cart_adds | purchase | campaign_name                     | impression | click | cart_products                                                                         |
| ------- | -------- | -------------------------- | ---------- | --------- | -------- | --------------------------------- | ---------- | ----- | ------------------------------------------------------------------------------------- |
| 1       | 02a5d5   | 2020-02-26 16:57:26.260871 | 4          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | null                                                                                  |
| 1       | 0826dc   | 2020-02-26 05:58:37.918618 | 1          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | null                                                                                  |
| 1       | 0fc437   | 2020-02-04 17:49:49.602976 | 10         | 6         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Tuna, Russian Caviar, Black Truffle, Abalone, Crab, Oyster                            |
| 1       | 30b94d   | 2020-03-15 13:12:54.023936 | 9          | 7         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Salmon, Kingfish, Tuna, Russian Caviar, Abalone, Lobster, Crab                        |
| 1       | 41355d   | 2020-03-25 00:11:17.860655 | 6          | 1         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Lobster                                                                               |
| 1       | ccf365   | 2020-02-04 19:16:09.182546 | 7          | 3         | 1        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Lobster, Crab, Oyster                                                                 |
| 1       | eaffde   | 2020-03-25 20:06:32.342989 | 10         | 8         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Salmon, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster           |
| 1       | f7c798   | 2020-03-15 02:23:26.312543 | 9          | 3         | 1        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Russian Caviar, Crab, Oyster                                                          |
| 2       | 0635fb   | 2020-02-16 06:42:42.73573  | 9          | 4         | 1        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Salmon, Kingfish, Abalone, Crab                                                       |
| 2       | 1f1198   | 2020-02-01 21:51:55.078775 | 1          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | null                                                                                  |
| 2       | 3b5871   | 2020-01-18 10:16:32.158475 | 9          | 6         | 1        | 25% Off - Living The Lux Life     | 1          | 1     | Salmon, Kingfish, Russian Caviar, Black Truffle, Lobster, Oyster                      |
| 2       | 49d73d   | 2020-02-16 06:21:27.138532 | 11         | 9         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Salmon, Kingfish, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster |
| 2       | 910d9a   | 2020-02-01 10:40:46.875968 | 8          | 1         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Abalone                                                                               |
| 2       | c5c0ee   | 2020-01-18 10:35:22.765382 | 1          | 0         | 0        | 25% Off - Living The Lux Life     | 0          | 0     | null                                                                                  |
| 2       | d58cbd   | 2020-01-18 23:40:54.761906 | 8          | 4         | 0        | 25% Off - Living The Lux Life     | 0          | 0     | Kingfish, Tuna, Abalone, Crab                                                         |
| 2       | e26a84   | 2020-01-18 16:06:40.90728  | 6          | 2         | 1        | 25% Off - Living The Lux Life     | 0          | 0     | Salmon, Oyster                                                                        |
| 3       | 25502e   | 2020-02-21 11:26:15.353389 | 1          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | null                                                                                  |
| 3       | 76ee84   | 2020-05-28 20:11:54.997406 | 7          | 3         | 1        | null                              | 0          | 0     | Salmon, Lobster, Crab                                                                 |
| 3       | 791afc   | 2020-04-29 00:37:16.741118 | 8          | 2         | 1        | null                              | 0          | 0     | Salmon, Oyster                                                                        |
| 3       | 7e89a0   | 2020-05-28 10:57:51.749847 | 9          | 6         | 0        | null                              | 1          | 1     | Salmon, Tuna, Russian Caviar, Black Truffle, Lobster, Crab                            |
| 3       | 80e2fe   | 2020-04-08 04:08:00.231658 | 10         | 5         | 1        | null                              | 0          | 0     | Salmon, Tuna, Russian Caviar, Abalone, Oyster                                         |
| 3       | 8902ad   | 2020-04-29 22:56:53.062046 | 10         | 6         | 0        | null                              | 1          | 1     | Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster                         |
| 3       | 9a2f24   | 2020-02-21 03:19:10.032455 | 6          | 2         | 1        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Kingfish, Black Truffle                                                               |
| 3       | bf200a   | 2020-03-11 04:10:26.708385 | 7          | 2         | 1        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Salmon, Crab                                                                          |
| 3       | dda9ae   | 2020-04-08 18:24:44.8597   | 10         | 8         | 1        | null                              | 1          | 1     | Salmon, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster           |
| 3       | eb13cd   | 2020-03-11 21:36:37.222763 | 1          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | null                                                                                  |

- I am only showing the first 3 users for reference.
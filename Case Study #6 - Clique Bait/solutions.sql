/* --------------------
   Case Study Questions
   --------------------*/

-- A. Digital Analysis

-- 1. How many users are there?
SELECT
	COUNT(DISTINCT user_id) AS users
FROM users;

-- 2. How many cookies does each user have on average?
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

-- 3. What is the unique number of visits by all users per month?
SELECT
	EXTRACT(MONTH FROM e.event_time) AS month,
    COUNT(DISTINCT e.visit_id) AS visits
FROM users u
INNER JOIN events e
	ON u.cookie_id = e.cookie_id
GROUP BY month
ORDER BY month;

-- 4. What is the number of events for each event type?
SELECT
	ei.event_name,
    COUNT(*) AS event_count
FROM events e
INNER JOIN event_identifier ei
	ON e.event_type = ei.event_type
GROUP BY ei.event_name
ORDER BY event_count DESC;

-- 5. What is the percentage of visits which have a purchase event?
SELECT
	ROUND(
		100.0 * COUNT(DISTINCT visit_id) FILTER (WHERE event_type = 3)
		/ COUNT(DISTINCT visit_id),
		2
	) AS purchase_percentage
FROM events;

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
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

-- 7. What are the top 3 pages by number of views?
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

-- 8. What is the number of views and cart adds for each product category?
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

-- 9. What are the top 3 products by purchases?
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


-- B. Product Funnel Analysis

-- Using a single SQL query - create a new output table which has the following details:
-- - How many times was each product viewed?
-- - How many times was each product added to cart?
-- - How many times was each product added to a cart but not purchased (abandoned)?
-- - How many times was each product purchased?
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

-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
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

-- Use your 2 new output tables - answer the following questions:

-- 1. Which product had the most views, cart adds and purchases?
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

-- 2. Which product was most likely to be abandoned?
SELECT
	product,
	ROUND(100.0 * abandoned / cart_adds, 2) AS abandon_rate_pct
FROM product_funnel
ORDER BY abandon_rate_pct DESC
LIMIT 1;

-- 3. Which product had the highest view to purchase percentage?
SELECT
	product,
	ROUND(100.0 * purchases / views, 2) AS view_to_purchase_pct
FROM product_funnel
ORDER BY view_to_purchase_pct DESC
LIMIT 1;

-- 4. What is the average conversion rate from view to cart add?
SELECT
	ROUND(AVG(100.0 * cart_adds / views), 2) AS avg_view_to_cart_ratio
FROM product_funnel;

-- 5. What is the average conversion rate from cart add to purchase?
SELECT
	ROUND(AVG(100.0 * purchases / cart_adds), 2) AS avg_cart_to_purchase_ratio
FROM product_funnel;


-- C. PCampaigns Analysis

-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:
-- - user_id
-- - visit_id
-- - visit_start_time: the earliest event_time for each visit
-- - page_views: count of page views for each visit
-- - cart_adds: count of product cart add events for each visit
-- - purchase: 1/0 flag if a purchase event exists for each visit
-- - campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- - impression: count of ad impressions for each visit
-- - click: count of ad clicks for each visit
-- - (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

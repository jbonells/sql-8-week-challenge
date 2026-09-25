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
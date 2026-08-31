/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
	SUM(m.price) AS total_sales
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id ASC;

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id, 
	COUNT(DISTINCT order_date) AS total_visits
FROM sales
GROUP BY customer_id
ORDER BY customer_id ASC;

-- 3. What was the first item from the menu purchased by each customer?
WITH ranked_sales AS (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		DENSE_RANK() OVER (
			PARTITION BY s.customer_id
			ORDER BY s.order_date ASC
		) AS rank
	FROM sales s
	INNER JOIN menu m
		ON s.product_id = m.product_id
)

SELECT DISTINCT
	customer_id,
	product_name
FROM ranked_sales
WHERE rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	m.product_name,
    COUNT(s.product_id) AS times_purchased
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH ranked_items AS (
	SELECT
		s.customer_id,
		m.product_name,
  		COUNT(s.product_id) AS order_count,
		DENSE_RANK() OVER (
			PARTITION BY s.customer_id
			ORDER BY COUNT(s.product_id) DESC
		) AS rank
	FROM sales s
	INNER JOIN menu m
		ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
)

SELECT
	customer_id,
	product_name,
    order_count
FROM ranked_items
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH ranked_sales AS (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		DENSE_RANK() OVER (
			PARTITION BY s.customer_id
			ORDER BY s.order_date ASC
		) AS rank
	FROM sales s
	INNER JOIN menu m
		ON s.product_id = m.product_id
  	INNER JOIN members mem
        ON s.customer_id = mem.customer_id
  	WHERE s.order_date >= mem.join_date
)

SELECT DISTINCT
    customer_id,
    product_name
FROM ranked_sales
WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH ranked_sales AS (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		DENSE_RANK() OVER (
			PARTITION BY s.customer_id
			ORDER BY s.order_date DESC
		) AS rank
	FROM sales s
	INNER JOIN menu m
		ON s.product_id = m.product_id
  	INNER JOIN members mem
        ON s.customer_id = mem.customer_id
  	WHERE s.order_date < mem.join_date
)

SELECT
    customer_id,
    product_name
FROM ranked_sales
WHERE rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	s.customer_id,
	COUNT(m.product_name) AS total_items,
	SUM(m.price) AS total_amount
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
INNER JOIN members mem
    ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id ASC;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points AS (
	SELECT
		s.customer_id,
		CASE
			WHEN s.product_id = 1 THEN m.price * 20
			ELSE m.price * 10
		END AS item_points
	FROM sales s
	INNER JOIN menu m
		ON s.product_id = m.product_id
)

SELECT
	customer_id,
    SUM(item_points) AS total_points
FROM points
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS (
    SELECT 
        customer_id, 
        join_date, 
        join_date + INTERVAL '6 days' AS end_week, 
        (DATE_TRUNC('month', join_date) + INTERVAL '1 month - 1 day')::DATE AS end_month
    FROM members
)
SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN s.order_date BETWEEN d.join_date AND d.end_week THEN m.price * 20
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales s
INNER JOIN menu m
    ON s.product_id = m.product_id
INNER JOIN dates d
    ON s.customer_id = d.customer_id
    AND s.order_date BETWEEN d.join_date AND d.end_month
GROUP BY s.customer_id
ORDER BY s.customer_id;

/* ---------------
   Bonus Questions
   ---------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
    	WHEN s.order_date >= mem.join_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
LEFT JOIN members mem
    ON s.customer_id = mem.customer_id
ORDER BY s.customer_id, s.order_date, m.product_name

-- 2. How many days has each customer visited the restaurant?
WITH customers AS (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		m.price,
		CASE
			WHEN s.order_date >= mem.join_date THEN 'Y'
			ELSE 'N'
		END AS member
	FROM sales s
	INNER JOIN menu m
		ON s.product_id = m.product_id
	LEFT JOIN members mem
		ON s.customer_id = mem.customer_id
)

SELECT
    customer_id,
    order_date,
    product_name,
    price,
    member,
    CASE
        WHEN member = 'N' THEN NULL
        ELSE RANK() OVER (
            PARTITION BY customer_id, member
            ORDER BY order_date ASC
        )
    END AS ranking
FROM customers
ORDER BY customer_id, order_date, product_name;
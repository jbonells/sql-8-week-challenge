# Questions and Solutions

### 1. What is the total amount each customer spent at the restaurant?

````sql
SELECT
	s.customer_id,
	SUM(m.price) AS total_sales
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id ASC;
````

#### Steps:
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Apply the **SUM()** aggregate function to `price` on the `menu` table to add the total amount each customer spent at the restaurant.
- Group the aggregated results by `customer_id` and order the final output in ascending sequence by customer identifier.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Customer A spent $76.
- Customer B spent $74.
- Customer C spent $36.

### 2. How many days has each customer visited the restaurant?
````sql
SELECT
	customer_id, 
	COUNT(DISTINCT order_date) AS total_visits
FROM sales
GROUP BY customer_id
ORDER BY customer_id ASC;
````

#### Steps:
- Use **COUNT DISTINCT** to calculate the number of unique days each customer visited the restaurant.
- Group the results by `customer_id` to isolate the unique visit counts per individual customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 4           |
| B           | 6           |
| C           | 2           |

- Customer A has visited the restaurant 4 times.
- Customer B has visited the restaurant 6 times.
- Customer C has visited the restaurant 2 times.

### 3. What was the first item from the menu purchased by each customer?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`ranked_sales`) that joins the `sales` and `menu` tables.
- Apply the **DENSE_RANK()** window function partitioned by `customer_id` and ordered by `order_date` ascending to chronologically sequence each customer's purchases.
- Query the CTE to isolate the absolute earliest purchase records by filtering for `rank = 1`.
- Apply **SELECT DISTINCT** to present a clean, unique list of the products purchased on each customer's first day, accurately capturing any multi-item ties.

#### Answer:
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |

- Customer A's first order was both curry and sushi.
- Customer B's first order was curry.
- Customer C's first order was ramen.

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
````sql
SELECT
	m.product_name,
    COUNT(s.product_id) AS times_purchased
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC
LIMIT 1;
````

#### Steps:
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Apply the **COUNT()** aggregate function to `product` on the `sales` table to add the total times all customers have purchased the item.
- Group the aggregated results by `product_name` and order the final output in descending sequence by `times_purchased`.
- USE **LIMIT 1** to show the most purchased item.

#### Answer:
| product_name | times_purchased |
| ------------ | --------------- |
| ramen        | 8               |

- The most purchased item on the menu is ramen.

### 5. Which item was the most popular for each customer?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`ranked_items`) that joins the `sales` and `menu` tables, grouping by `customer_id` and `product_name` to calculate the purchase frequency (`order_count`) for each item per customer.
- Apply the **DENSE_RANK()** window function partitioned by `customer_id` and ordered by **COUNT(s.product_id)** descending to rank each customer's items from most to least purchased.
- Query the CTE to isolate and return the top-performing items for each customer by filtering for `rank = 1`.

#### Answer:
| customer_id | product_name | order_count |
| ----------- | ------------ | ----------- |
| A           | ramen        | 3           |
| B           | ramen        | 2           |
| B           | curry        | 2           |
| B           | sushi        | 2           |
| C           | ramen        | 3           |

- Customer A's most popular item is ramen.
- Customer B's most popular items are ramen, curry, and sushi.
- Customer C's most popular item is ramen.

### 6. Which item was purchased first by the customer after they became a member?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`ranked_sales`) that joins `sales`, `menu`, and `members`, filtering for transactions occurring on or after the join date (`s.order_date >= mem.join_date`).
- Apply the **DENSE_RANK()** window function partitioned by `customer_id` and ordered by `order_date` ascending to chronologically sequence post-membership purchases.
- Query the CTE to capture the absolute earliest item(s) bought after the membership start date by filtering for `rank = 1`.
- Use **SELECT DISTINCT** to ensure unique product records per customer and order.

#### Answer:
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| B           | sushi        |

- Customer A's first order as a member was curry.
- Customer B's first order as a member was sushi.
- Customer C is not a member.

### 7. Which item was purchased just before the customer became a member?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`ranked_sales`) that joins `sales`, `menu`, and `members`, filtering for transactions occurring before the join date (`s.order_date < mem.join_date`).
- Apply the **DENSE_RANK()** window function partitioned by `customer_id` and ordered by `order_date` descending to chronologically sequence post-membership purchases.
- Query the CTE to capture the absolute earliest item(s) bought after the membership start date by filtering for `rank = 1`.

#### Answer:
| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |

- Customer A's last order before becoming a member was sushi and curry.
- Customer B's last order before becoming a member was sushi.

### 8. What is the total items and amount spent for each member before they became a member?
````sql
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
````

#### Steps:
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Use an **INNER JOIN** on `customer_id` to connect the `sales` and `members` tables, filtering for transactions occurring before the join date (`s.order_date < mem.join_date`).
- Apply the **COUNT()** aggregate function to `product_name` on the `menu` table to add the total volume of pre-membership items.
- Apply **SUM()** aggregate function to `price` on the `menu` table to ad cumulative spending.
- Group the results by `customer_id` to isolate the unique individual customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_items | total_amount |
| ----------- | ----------- | ------------ |
| A           | 2           | 25           |
| B           | 3           | 40           |

- Customer A spent $25 on 2 items.
- Customer B spent $40 on 3 items.

### 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`points`) that joins `sales` and `menu` tables.
- Evaluate each individual transaction line with a **CASE** statement to award 20 points per $1 for sushi (`product_id = 1`) and 10 points per $1 for all other menu items.
- Query the CTE to sum up the individual item points with **SUM()**, grouping by `customer_id` to compute the total loyalty points earned by each customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| C           | 360          |

- Customer A has 860 points.
- Customer B has 940 points.
- Customer C has 360 points.

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
````sql
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
````

#### Steps:
- Define a Common Table Expression (`dates`) to compute each customer's 7-day promotional window (`end_week`) and month-end cutoff (`end_month`) using **DATE_TRUNC** and interval arithmetic.
- Join the `sales` and `menu` tables with the dates CTE, restricting rows to transactions occurring strictly on or after the join date up through the end of January.
- Apply a CASE statement to evaluate rewards: award 20x the price for any item purchased during the first 7 days, apply the same 20x permanent multiplier for all sushi, and fall back to standard 10x points for everything else.
- Group the calculated points by `customer_id`, apply the **SUM()** aggregate function to compute total loyalty points earned through January.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_points |
| ----------- | ------------ |
| A           | 1020         |
| B           | 320          |

- Customer A has 1020 points.
- Customer B has 320 points.
- Customer C is not a member.
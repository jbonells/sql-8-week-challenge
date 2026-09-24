# Questions and Solutions

### 1. What is the total amount each customer spent at the restaurant?
```sql
SELECT
	s.customer_id,
	SUM(m.price) AS total_sales
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

#### Steps:
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Group the joined records by `customer_id` to compute metrics at the individual customer grain.
- Apply the **SUM()** aggregate function to compute total expenditure per customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

### 2. How many days has each customer visited the restaurant?
```sql
SELECT
	customer_id, 
	COUNT(DISTINCT order_date) AS total_visits
FROM sales
GROUP BY customer_id
ORDER BY customer_id;
```

#### Steps:
- Group the records by `customer_id` to evaluate visits per individual customer.
- Use **COUNT DISTINCT** to calculate the total number of unique visit days per customer.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 4           |
| B           | 6           |
| C           | 2           |

### 3. What was the first item from the menu purchased by each customer?
```sql
WITH ranked_sales AS (
	SELECT
		s.customer_id,
		m.product_name,
		DENSE_RANK() OVER (
			PARTITION BY s.customer_id
			ORDER BY s.order_date
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
```

#### Steps:
- Define a Common Table Expression (`ranked_sales`) that joins the `sales` and `menu` tables on `product_id`.
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

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
SELECT
	m.product_name,
    COUNT(s.product_id) AS times_purchased
FROM sales s
INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC
LIMIT 1;
```

#### Steps:
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Group the joined records by `product_name` to evaluate item popularity across all customer purchases.
- Apply the **COUNT()** aggregate function to `product` on the `sales` table to add the total times all customers have purchased the item.
- Order the final output in descending sequence by `times_purchased`.
- USE **LIMIT 1** to show the most purchased item.

#### Answer:
| product_name | times_purchased |
| ------------ | --------------- |
| ramen        | 8               |

### 5. Which item was the most popular for each customer?
```sql
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
```

#### Steps:
- Define a Common Table Expression (`ranked_items`) that joins the `sales` and `menu` tables on `product_id`.
- Group the joined records by `customer_id` and `product_name` to calculate the purchase frequency (`order_count`) for each item per customer.
- Apply the **DENSE_RANK()** window function partitioned by `customer_id` and ordered by **COUNT(s.product_id)** descending to rank each customer's items from most to least purchased.
- Apply a **WHERE** clause (`rank = 1`) to isolate and return the top-performing items for each customer.

#### Answer:
| customer_id | product_name | order_count |
| ----------- | ------------ | ----------- |
| A           | ramen        | 3           |
| B           | ramen        | 2           |
| B           | curry        | 2           |
| B           | sushi        | 2           |
| C           | ramen        | 3           |

- Customer B's most popular items are ramen, curry, and sushi.

### 6. Which item was purchased first by the customer after they became a member?
```sql
WITH ranked_sales AS (
	SELECT
		s.customer_id,
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
```

#### Steps:
- Define a Common Table Expression (`ranked_sales`) that joins on `product_id` between `sales` and `menu`, and on `customer_id` between `sales` and `members`.
- Apply a **WHERE** clause (`s.order_date >= mem.join_date`) to isolate transactions occurring on or after each customer's membership join date.
- Apply the **DENSE_RANK()** window function partitioned by `customer_id` and ordered by `order_date` ascending to rank post-membership purchases chronologically in ascending order.
- Apply a **WHERE** clause (`rank = 1`) to isolate the absolute earliest item(s) purchased after joining as a member.
- Use **SELECT DISTINCT** to deduplicate product names per customer in the event multiple identical items were purchased during their first post-membership transaction.

#### Answer:
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| B           | sushi        |

- Customer C is not a member.

### 7. Which item was purchased just before the customer became a member?
```sql
WITH ranked_sales AS (
	SELECT
		s.customer_id,
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
```

#### Steps:
- Define a Common Table Expression (`ranked_sales`) that on `product_id` between `sales` and `menu`, and on `customer_id` between `sales` and `members`.
- Apply a **WHERE** clause (`s.order_date < mem.join_date`) to include transactions occurring before the join date.
- Apply the **DENSE_RANK()** window function partitioned by `customer_id` and ordered by `order_date` descending to chronologically sequence post-membership purchases.
- Apply a **WHERE** clause (`rank = 1`) to isolate the last item(s) purchased by each customer just before becoming a member.

#### Answer:
| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |

- Customer A's last order before becoming a member was sushi and curry.

### 8. What is the total items and amount spent for each member before they became a member?
```sql
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
```

#### Steps:
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Use an **INNER JOIN** on `customer_id` to connect the `sales` and `members` tables,.
- Apply a **WHERE** clause (`s.order_date < mem.join_date`) to include transactions occurring before the join date.
- Group the filtered records by `customer_id` to aggregate metrics at the individual customer grain.
- Apply the **COUNT()** aggregate function to `product_name` on the `menu` table to add the total volume of pre-membership items.
- Apply **SUM()** aggregate function to `price` on the `menu` table to ad cumulative spending.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_items | total_amount |
| ----------- | ----------- | ------------ |
| A           | 2           | 25           |
| B           | 3           | 40           |

### 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
SELECT
    s.customer_id,
    SUM(m.price * 10 * CASE WHEN m.product_name = 'sushi' THEN 2 ELSE 1 END) AS points
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

#### Steps:
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Group the filtered records by `customer_id` to aggregate point metrics at the individual customer grain.
- Apply a **CASE** statement inside the **SUM()** function to evaluate each row—multiplying the price by 20 for sushi and 10 for all other items.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| C           | 360          |

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
WITH dates AS (
    SELECT 
        customer_id, 
        join_date, 
        (join_date + INTERVAL '6 days')::DATE AS end_week, 
        (DATE_TRUNC('month', join_date) + INTERVAL '1 month - 1 day')::DATE AS end_month
    FROM members
)
SELECT
    s.customer_id,
    SUM(
		m.price * 10 *
        CASE
            WHEN s.order_date BETWEEN d.join_date AND d.end_week THEN 2
            WHEN m.product_name = 'sushi' THEN 2
            ELSE 1
        END
    ) AS total_points
FROM sales s
INNER JOIN menu m
    ON s.product_id = m.product_id
INNER JOIN dates d
    ON s.customer_id = d.customer_id
WHERE s.order_date <= d.end_month
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

#### Steps:
- Define a Common Table Expression (`dates`) to compute each customer's 7-day promotional window (`end_week`) and month-end cutoff (`end_month`) using **DATE_TRUNC** and interval arithmetic.
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Use an **INNER JOIN** on `customer_id` to connect the `sales` table and `dates` CTE.
- Apply a **WHERE** clause (`s.order_date <= d.end_month`) to include transactions occurring before the end of the month.
- Group the filtered records by `customer_id` to aggregate point metrics at the individual customer grain.
- Apply a **CASE** statement inside the **SUM()** function to evaluate each row—multiplying the price by 20 for sushi and 10 for all other items.
- (Optional) Order the final dataset in ascending sequence by `customer_id` for structured presentation.

#### Answer:
| customer_id | total_points |
| ----------- | ------------ |
| A           | 1020         |
| B           | 320          |

- Customer C is not a member.


# Bonus Questions

### Join All The Things
```sql
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
```

#### Steps:
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Use a **LEFT JOIN** on `customer_id` to connect the `sales` and `members` tables.
- Apply a **CASE** statement to evaluate membership status per order.

#### Answer:
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | ------------ | ----- | ------ |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

### Rank All The Things
```sql
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
```

#### Steps:
- Define a Common Table Expression (`customers`) to process the `sales` table.
- Use an **INNER JOIN** on `product_id` to connect the `sales` and `menu` tables.
- Use a **LEFT JOIN** on `customer_id` to connect the `sales` and `members` tables.
- Apply a **CASE** statement within the CTE to evaluate membership status per order.
- Apply conditional logic combining a **CASE** statement with the window function **RANK() OVER()** to chronologically rank post-membership purchases per member while assigning `NULL` to non-member orders.
- (Optional) Order the final dataset in ascending sequence by `customer_id`, `order_date`, and `product_name` for structured presentation.

#### Answer:
| customer_id | order_date | product_name | price | member | ranking |
| ----------- | ---------- | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01 | curry        | 15    | N      | null    |
| A           | 2021-01-01 | sushi        | 10    | N      | null    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | null    |
| B           | 2021-01-02 | curry        | 15    | N      | null    |
| B           | 2021-01-04 | sushi        | 10    | N      | null    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | null    |
| C           | 2021-01-01 | ramen        | 12    | N      | null    |
| C           | 2021-01-07 | ramen        | 12    | N      | null    |

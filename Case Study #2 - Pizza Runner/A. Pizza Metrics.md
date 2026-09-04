# A. Pizza Metrics

### 1. How many pizzas were ordered?

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
	COUNT(*) AS pizza_order_count
FROM #customer_orders;
````
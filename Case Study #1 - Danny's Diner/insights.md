# Questions and Solutions

##1. What is the total amount each customer spent at the restaurant?

````sql
SELECT
	sales.customer_id,
	SUM(menu.price) AS total_sales
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;
````

#### Steps:
- Use **JOIN** to merge `sales` and `menu` tables as `sales.customer_id` and `menu.price` are from those tables.
- Use **SUM** to calculate the total sales contributed by each customer.
- Group the aggregated results by `customer_id`.

#### Answer:
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Customer A spent $76.
- Customer B spent $74.
- Customer C spent $36.

##2. How many days has each customer visited the restaurant?
````sql

````

#### Steps:
- 

#### Answer:
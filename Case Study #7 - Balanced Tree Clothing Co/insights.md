## A. High Level Sales Analysis

### What was the total quantity sold for all products?
```sql
SELECT
	SUM(qty) AS total_quantity_sold
FROM sales;
```

#### Steps:
- Apply the **SUM()** aggregate function to calculate the total number of products sold.
- (Optional) Assign the alias `total_quantity_sold` to the resulting column for clear presentation in the final output report.

#### Answer:
| total_quantity_sold |
| ------------------- |
| 45,216              |

### 2. What is the total generated revenue for all products before discounts?
```sql
SELECT
	SUM(qty * price) AS total_revenue
FROM sales;
```

#### Steps:
- Apply the **SUM()** aggregate function to calculate the total sales revenue.
- (Optional) Assign the alias `total_quantity_sold` to the resulting column for clear presentation in the final output report.

#### Answer:
| total_revenue |
| ------------- |
| 1,289,453     |

### 3. What was the total discount amount for all products?
```sql
SELECT
	ROUND(SUM(qty * price * discount / 100.0), 2) AS total_discount
FROM sales;
```

#### Steps:
- Apply the **SUM()** aggregate function and divide by 100.0 to calculate the monetary discount amount.
- Wrap the calculation in **ROUND()** to format the result to two decimal places.

#### Answer:
| total_discount |
| -------------- |
| 156,229.14     |


## B. Transaction Analysis


### 1. How many unique transactions were there?
```sql
SELECT
	COUNT(DISTINCT txn_id) AS unique_transactions
FROM sales;
```

#### Steps:
- Use **COUNT DISTINCT** to calculate the total number of unique transactions.
- (Optional) Assign the alias `unique_transactions` to the resulting column for clear presentation in the final output report.

#### Answer:
| unique_transactions |
| ------------------- |
| 2500                |

### 2. What is the average unique products purchased in each transaction?
```sql
SELECT
	ROUND(AVG(unique_products), 2) AS average_unique_products
FROM (
	SELECT
		txn_id,
		COUNT(DISTINCT prod_id) AS unique_products
	FROM sales
	GROUP BY txn_id
) AS txn_products;
```

#### Steps:
- Define a subquery (`txn_products`) querying the `sales` table.
- Group records by `txn_id` to aggregate product counts per transaction.
- Use **COUNT DISTINCT** to calculate the number of distinct products purchased in each transaction.
- Apply the **AVG()** aggregate function to calculate the average number of unique products per transaction.
- Wrap the calculation in **ROUND()** to format the average to two decimal places.


#### Answer:
| average_unique_products |
| ----------------------- |
| 6.04                    |

### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
```sql
WITH revenue AS(
	SELECT
		txn_id,
		SUM(qty * price) AS total_revenue
	FROM sales
	GROUP BY txn_id
)

SELECT 
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue) AS percentile_25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) AS percentile_50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) AS percentile_75
FROM revenue;
```

#### Steps:
- Define a Common Table Expression (`revenue`) querying the `sales` table.
- Group records by `txn_id` to aggregate revenue per transaction.
- Apply the **SUM()** aggregate function to calculate total sales revenue per transaction.
- Use **PERCENTILE_CONT(...) WITHIN GROUP (ORDER BY ...)** to calculate the 25th percentile, 50th percentile (median), and 75th percentile revenue thresholds.

#### Answer:
| percentile_25 | percentile_50 | percentile_75 |
| ------------- | ------------- | ------------- |
| 375.75        | 509.5         | 647           |

### 4. What is the average discount value per transaction?
```sql
WITH discount AS(
	SELECT
		txn_id,
		SUM(qty * price * discount / 100.0) AS total_discount
	FROM sales
	GROUP BY txn_id
)

SELECT
	ROUND(AVG(total_discount), 2) AS average_discount
FROM discount
```

#### Steps:
- Define a Common Table Expression (`discount`) querying the `sales` table.
- Group records by `txn_id` to aggregate discount per transaction.
- Apply the **SUM()** aggregate function and divide by 100.0 to compute the total monetary discount amount per transaction.
- Apply the **AVG()** aggregate function to compute the overall average transaction discount.
- Wrap the calculation in **ROUND()** to format the average to two decimal places.

#### Answer:
| average_discount |
| ---------------- |
| 62.49            |

### 5. What is the percentage split of all transactions for members vs non-members?
```sql
WITH transactions AS(
	SELECT
		COUNT(DISTINCT txn_id) FILTER (WHERE member = 't') AS members,
		COUNT(DISTINCT txn_id) FILTER (WHERE member = 'f') AS non_members,
		COUNT(DISTINCT txn_id) AS total
	FROM sales
)

SELECT
	ROUND((100.0 * members / total), 2) AS members_percentage,
	ROUND((100.0 * non_members / total), 2) AS non_members_percentage
FROM transactions;
```

#### Steps:
- Define a Common Table Expression (`transactions`) querying the `sales` table.
- Use **COUNT DISTINCT** with a **FILTER (WHERE ...)** clause (`member = 't'`) to tally unique member transactions.
- Use **COUNT DISTINCT** with a **FILTER (WHERE ...)** clause (`member = 'f'`) to tally unique non-member transactions.
- Use **COUNT DISTINCT** to calculate total unique transactions.
- Multiply `members` by 100.0 and divide by `total`to compute the member transaction share.
- Multiply `non_members` by 100.0 and divide by `total`to compute the non-member transaction share.
- Wrap the calculations in **ROUND()** to format the results to two decimal places.

#### Answer:
| members_percentage | non_members_percentage |
| ------------------ | ---------------------- |
| 60.20              | 39.80                  |

### 6. What is the average revenue for member transactions and non-member transactions?
```sql
WITH transactions AS (
	SELECT
		txn_id,
		member,
		SUM(qty * price) AS total_revenue
	FROM sales
	GROUP BY txn_id, member
)
SELECT
	ROUND(AVG(total_revenue) FILTER (WHERE member = 't'), 2) AS average_members,
	ROUND(AVG(total_revenue) FILTER (WHERE member = 'f'), 2) AS average_non_members
FROM transactions;
```

#### Steps:
- Define a Common Table Expression (`transactions`) querying the `sales` table.
- Group records by `txn_id` and `member` to aggregate revenue per transaction and membership status.
- Apply the **SUM()** aggregate function to calculate the total sales revenue per transaction.
- Apply conditional aggregations using **AVG()** with a **FILTER (WHERE ...)** clause (`member = 't'`) to calculate the average transaction revenue for members.
- Apply conditional aggregations using **AVG()** with a **FILTER (WHERE ...)** clause (`member = 'f'`) to calculate the average transaction revenue for non-members.
- Wrap the calculations in **ROUND()** to format the results to two decimal places.

#### Answer:
| average_members | average_non_members |
| --------------- | ------------------- |
| 516.27          | 515.04              |


## C. Product Analysis

### 1. What are the top 3 products by total revenue before discount?
```sql
SELECT
	pd.product_name,
	SUM(s.qty * s.price) AS total_revenue
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY total_revenue DESC
LIMIT 3;
```

#### Steps:
- Use an **INNER JOIN** on `s.prod_id = pd.product_id` to connect the `sales` and `product_details` tables.
- Group the joined records by `product_name` to aggregate sales per product.
- Apply the **SUM()** aggregate function to calculate the overall sales revenue per product.
- Order the final output in descending sequence by `total_revenue` to rank products by revenue.
- Use **LIMIT 3** to isolate the top three products by total sales revenue.

#### Answer:
| product_name                 | total_revenue |
| ---------------------------- | ------------- |
| Blue Polo Shirt - Mens       | 217,683       |
| Grey Fashion Jacket - Womens | 209,304       |
| White Tee Shirt - Mens       | 152,000       |

### 2. What is the total quantity, revenue and discount for each segment?
```sql
SELECT
	pd.segment_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS total_discount
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.segment_name
ORDER BY pd.segment_name;
```

#### Steps:
- Use an **INNER JOIN** on `s.prod_id = pd.product_id` to connect the `sales` and `product_details` tables.
- Group the joined records by `segment_name` to aggregate sales per segment.
- Apply the **SUM()** aggregate function to calculate total units sold.
- Apply the **SUM()** aggregate function to calculate gross sales revenue.
- Apply the **SUM()** aggregate function and divide by 100.0 to calculate the overall monetary discount amount.
- Wrap the calculation in **ROUND()** to format the result to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `segment_name` for structured presentation.

#### Answer:
| segment_name | total_quantity | total_revenue | total_discount |
| ------------ | -------------- | ------------- | -------------- |
| Jacket       | 11,385         | 366,983       | 44,277.46      |
| Jeans        | 11,349         | 208,350       | 25,343.97      |
| Shirt        | 11,265         | 406,143       | 49,594.27      |
| Socks        | 11,217         | 307,977       | 37,013.44      |

### 3. What is the top selling product for each segment?
```sql
WITH top_selling AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY pd.segment_name ORDER BY SUM(s.qty) DESC) AS ranking,
		pd.segment_name,
		pd.product_name,
		SUM(s.qty) AS total_quantity    
	FROM sales s
	INNER JOIN product_details pd
		ON s.prod_id = pd.product_id
	GROUP BY pd.segment_name, pd.product_name
)

SELECT
	segment_name,
	product_name,
	total_quantity
FROM top_selling
WHERE ranking = 1
ORDER BY segment_name;
```

#### Steps:
- Define a Common Table Expression (`top_selling`) joining the `sales` and `product_details` tables on `s.prod_id = pd.product_id`.
- Group the joined records by `segment_name` and `product_name` to aggregate sales per product within each segment.
- Apply the **SUM()** aggregate function to calculate the total units sold per product.
- Apply the **ROW_NUMBER() OVER()** window function partitioned by `segment_name` and ordered by total quantity descending to rank products sold within each segment.
- Apply a **WHERE** clause (`ranking = 1`) to filter for the top-selling product in each segment.
- (Optional) Order the final dataset in ascending sequence by `segment_name` for structured presentation.

#### Answer:
| segment_name | product_name                  | total_quantity |
| ------------ | ----------------------------- | -------------- |
| Jacket       | Grey Fashion Jacket - Womens  | 3876           |
| Jeans        | Navy Oversized Jeans - Womens | 3856           |
| Shirt        | Blue Polo Shirt - Mens        | 3819           |
| Socks        | Navy Solid Socks - Mens       | 3792           |

### 4. What is the total quantity, revenue and discount for each category?
```sql
SELECT
	pd.category_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS total_discount
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;
```

#### Steps:
- Use an **INNER JOIN** on `s.prod_id = pd.product_id` to connect the `sales` and `product_details` tables.
- Group the joined records by `category_name` to aggregate sales per category.
- Apply the **SUM()** aggregate function to calculate total units sold.
- Apply the **SUM()** aggregate function to calculate gross sales revenue.
- Apply the **SUM()** aggregate function and divide by 100.0 to calculate the overall monetary discount amount.
- Wrap the calculation in **ROUND()** to format the result to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `category_name` for structured presentation.

#### Answer:
| category_name | total_quantity | total_revenue | total_discount |
| ------------- | -------------- | ------------- | -------------- |
| Mens          | 22,482         | 714,120       | 86,607.71      |
| Womens        | 22,734         | 575,333       | 69,621.43      |

### 5. What is the top selling product for each category?
```sql
WITH top_selling AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY pd.category_name ORDER BY SUM(s.qty) DESC) AS ranking,
		pd.category_name,
		pd.product_name,
		SUM(s.qty) AS total_quantity    
	FROM sales s
	INNER JOIN product_details pd
		ON s.prod_id = pd.product_id
	GROUP BY pd.category_name, pd.product_name
)

SELECT
	category_name,
	product_name,
	total_quantity
FROM top_selling
WHERE ranking = 1
ORDER BY category_name;
```

#### Steps:
- Define a Common Table Expression (`top_selling`) joining the `sales` and `product_details` tables on `s.prod_id = pd.product_id`.
- Group the joined records by `category_name` and `product_name` to aggregate sales per product within each category.
- Apply the **SUM()** aggregate function to calculate the total units sold per product.
- Apply the **ROW_NUMBER() OVER()** window function partitioned by `category_name` and ordered by total quantity descending to rank products sold within each category.
- Apply a **WHERE** clause (`ranking = 1`) to filter for the top-selling product in each category.
- (Optional) Order the final dataset in ascending sequence by `category_name` for structured presentation.

#### Answer:
| category_name | product_name                 | total_quantity |
| ------------- | ---------------------------- | -------------- |
| Mens          | Blue Polo Shirt - Mens       | 3819           |
| Womens        | Grey Fashion Jacket - Womens | 3876           |

### 6. What is the percentage split of revenue by product for each segment?
```sql
SELECT
	pd.segment_name,
	pd.product_name,
	ROUND(
		100.0 * SUM(s.qty * s.price)
		/ SUM(SUM(s.qty * s.price)) OVER (PARTITION BY pd.segment_name),
		2
	) AS revenue_percentage
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.segment_name, pd.product_name
ORDER BY pd.segment_name, revenue_percentage DESC;
```

#### Steps:
- Use an **INNER JOIN** on `s.prod_id = pd.product_id` to connect the `sales` and `product_details` tables.
- Group the joined records by `segment_name` and `product_name` to aggregate sales per product within each segment.
- Apply the **SUM()** aggregate function to calculate grouped product revenue.
- Apply a nested **SUM()** aggregate function inside a **SUM() OVER ()** window function partitioned by `segment_name` to calculate total segment revenue across all products within each segment.
- Multiply grouped product revenue by 100.0 and divide by total segment revenue to compute the relative revenue contribution per product within its segment.
- Wrap the calculation in **ROUND()** to format the result to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `segment_name` and descending sequence by `revenue_percentage` for structured presentation.

#### Answer:
| segment_name | product_name                     | revenue_percentage |
| ------------ | -------------------------------- | ------------------ |
| Jacket       | Grey Fashion Jacket - Womens     | 57.03              |
| Jacket       | Khaki Suit Jacket - Womens       | 23.51              |
| Jacket       | Indigo Rain Jacket - Womens      | 19.45              |
| Jeans        | Black Straight Jeans - Womens    | 58.15              |
| Jeans        | Navy Oversized Jeans - Womens    | 24.06              |
| Jeans        | Cream Relaxed Jeans - Womens     | 17.79              |
| Shirt        | Blue Polo Shirt - Mens           | 53.60              |
| Shirt        | White Tee Shirt - Mens           | 37.43              |
| Shirt        | Teal Button Up Shirt - Mens      | 8.98               |
| Socks        | Navy Solid Socks - Mens          | 44.33              |
| Socks        | Pink Fluro Polkadot Socks - Mens | 35.50              |
| Socks        | White Striped Socks - Mens       | 20.18              |

- Individual percentages are rounded to 2 decimal places; totals per segment deviate slightly from 100% (±0.01%) due to independent rounding of each row.

### 7. What is the percentage split of revenue by segment for each category?
```sql
SELECT
	pd.category_name,
	pd.segment_name,
	ROUND(
		100.0 * SUM(s.qty * s.price)
		/ SUM(SUM(s.qty * s.price)) OVER (PARTITION BY pd.category_name),
		2
	) AS revenue_percentage
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name, pd.segment_name
ORDER BY pd.category_name, revenue_percentage DESC;
```

#### Steps:
- Use an **INNER JOIN** on `s.prod_id = pd.product_id` to connect the `sales` and `product_details` tables.
- Group the joined records by `category_name` and `segment_name` to aggregate sales per segment within each category.
- Apply the **SUM()** aggregate function to calculate grouped segment revenue.
- Apply a nested **SUM()** aggregate function inside a **SUM() OVER ()** window function partitioned by `category_name` to calculate total category revenue across all segments within each category.
- Multiply grouped segment revenue by 100.0 and divide by total category revenue to compute relative revenue contribution per segment within its category.
- Wrap the calculation in **ROUND()** to format the result to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `category_name` and descending sequence by `revenue_percentage` for structured presentation.

#### Answer:
| category_name | segment_name | revenue_percentage |
| ------------- | ------------ | ------------------ |
| Mens          | Shirt        | 56.87              |
| Mens          | Socks        | 43.13              |
| Womens        | Jacket       | 63.79              |
| Womens        | Jeans        | 36.21              |

### 8. What is the percentage split of total revenue by category?
```sql
SELECT
	pd.category_name,
	ROUND(
		100.0 * SUM(s.qty * s.price)
		/ SUM(SUM(s.qty * s.price)) OVER (),
		2
	) AS revenue_percentage
FROM sales s
INNER JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;
```

#### Steps:
- Use an **INNER JOIN** on `s.prod_id = pd.product_id` to connect the `sales` and `product_details` tables.
- Group the joined records by `category_name` to aggregate sales per category.
- Apply the **SUM()** aggregate function calculate grouped category revenue.
- Apply a nested **SUM()** aggregate function inside a **SUM() OVER ()** window function to calculate overall total revenue across all categories.
- Multiply grouped category revenue by 100.0 and divide by overall total revenue to compute the relative revenue contribution per category.
- Wrap the calculation in **ROUND()** to format the result to two decimal places.
- (Optional) Order the final dataset in ascending sequence by `category_name` for structured presentation.

#### Answer:
| category_name | revenue_percentage |
| ------------- | ------------------ |
| Mens          | 55.38              |
| Womens        | 44.62              |

### 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
```sql
WITH product_penetration AS (
	SELECT
		DISTINCT prod_id,
		COUNT(DISTINCT txn_id) AS product_penetration
	FROM sales
	GROUP BY prod_id
),
total_transactions AS (
	SELECT
		COUNT(DISTINCT txn_id) AS total_transaction
	FROM sales
)

SELECT
	pd.product_name,
	ROUND(100.0 * pp.product_penetration / tt.total_transaction, 2) AS penetration_percentage
FROM product_penetration pp
CROSS JOIN total_transactions tt
INNER JOIN product_details pd
	ON pp.prod_id = pd.product_id
ORDER BY penetration_percentage DESC;
```

#### Steps:
- Define a Common Table Expression (`product_penetration`) querying the `sales` table.
- Group records by `prod_id` to aggregate transaction metrics per product.
- Use **COUNT DISTINCT** to calculate total unique transactions per product.
- Define a Common Table Expression (`total_transactions`) querying the `sales` table.
- Use **COUNT DISTINCT** to calculate overall total unique transactions.
- Use a **CROSS JOIN** with the `total_transactions` CTE to combine individual product transaction counts with total transaction volume.
- Use an **INNER JOIN** on `s.prod_id = pd.product_id` to connect the `product_details` table.
- Multiply `product_penetration` by 100.0 and divide by `total_transaction` to compute the relative product penetration rate.
- Wrap the calculation in **ROUND()** to format the result to two decimal places.
- (Optional) Order the final dataset in descending sequence by `penetration_percentage` for structured presentation.

#### Answer:
| product_name                     | penetration_percentage |
| -------------------------------- | ---------------------- |
| Navy Solid Socks - Mens          | 51.24                  |
| Grey Fashion Jacket - Womens     | 51.00                  |
| Navy Oversized Jeans - Womens    | 50.96                  |
| White Tee Shirt - Mens           | 50.72                  |
| Blue Polo Shirt - Mens           | 50.72                  |
| Pink Fluro Polkadot Socks - Mens | 50.32                  |
| Indigo Rain Jacket - Womens      | 50.00                  |
| Khaki Suit Jacket - Womens       | 49.88                  |
| Black Straight Jeans - Womens    | 49.84                  |
| Cream Relaxed Jeans - Womens     | 49.72                  |
| White Striped Socks - Mens       | 49.72                  |
| Teal Button Up Shirt - Mens      | 49.68                  |

### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
```sql
WITH product_transactions AS (
	SELECT
		txn_id,
		prod_id
	FROM sales
	GROUP BY txn_id, prod_id
),
all_combinations AS (
	SELECT
		pt1.txn_id,
		pt1.prod_id AS p1,
		pt2.prod_id AS p2,
		pt3.prod_id AS p3
	FROM product_transactions pt1
	INNER JOIN product_transactions pt2
		ON pt1.txn_id = pt2.txn_id
		AND pt1.prod_id < pt2.prod_id
	INNER JOIN product_transactions pt3
		ON pt2.txn_id = pt3.txn_id
		AND pt2.prod_id < pt3.prod_id
)

SELECT
    pd1.product_name AS product_1,
    pd2.product_name AS product_2,
    pd3.product_name AS product_3,
    COUNT(DISTINCT ac.txn_id) AS combinations
FROM all_combinations ac
INNER JOIN product_details pd1
	ON ac.p1 = pd1.product_id
INNER JOIN product_details pd2
	ON ac.p2 = pd2.product_id
INNER JOIN product_details pd3
	ON ac.p3 = pd3.product_id
GROUP BY pd1.product_name, pd2.product_name, pd3.product_name
ORDER BY combinations DESC
LIMIT 1;
```

#### Steps:
- Define a Common Table Expression (`product_transactions`) querying the `sales` table.
- Group records by `txn_id` and `prod_id` to isolate unique product entries per transaction.
- Define a Common Table Expression (`total_transactions`) querying the `product_transactions` CTE (`pt1`).
- Use an **INNER JOIN** with `product_transactions` (`pt2`) on `pt1.txn_id = pt2.txn_id AND pt1.prod_id < pt2.prod_id` to form unique pairs (p1, p2).
- Use an **INNER JOIN** with `product_transactions` (`pt3`) on `pt2.txn_id = pt3.txn_id AND pt2.prod_id < pt3.prod_id` to form unique triplets (p1, p2, p3).
- Query the `all_combinations` CTE.
- Use an **INNER JOIN** with `product_details` (`pd1`) on `ac.p1 = pd1.product_id` to retrieve the name of the first product.
- Use an **INNER JOIN** with `product_details` (`pd2`) on `ac.p2 = pd2.product_id` to retrieve the name of the second product.
- Use an **INNER JOIN** with `product_details` (`pd3`) on `ac.p3 = pd2.product_id` to retrieve the name of the third product.
- Use **COUNT DISTINCT** to calculate the total unique transaction volume for each three-product combination.
- Order the final dataset in descending sequence by `combinations` to rank product combinations by frequency.
- Use **LIMIT 1** to isolate the most frequently co-purchased product triplet.

#### Answer:
| product_1              | product_2                    | product_3                   | combinations |
| ---------------------- | ---------------------------- | --------------------------- | ------------ |
| White Tee Shirt - Mens | Grey Fashion Jacket - Womens | Teal Button Up Shirt - Mens | 352          |


## D. Reporting Challenge

### Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
- Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.
- He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).
- Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks.
```sql

```

#### Steps:
- 

#### Answer:



## E. Bonus Challenge

### Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
- Hint: you may want to consider using a recursive CTE to solve this problem!
```sql

```

#### Steps:
- 

#### Answer:

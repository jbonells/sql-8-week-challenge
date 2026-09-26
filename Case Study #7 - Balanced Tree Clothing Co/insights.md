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
- Apply the **SUM()** aggregate function to the product of `qty` and `price` to calculate the total sales revenue.
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
- Apply the **SUM()** aggregate function to multiply `qty`, `price`, and `discount`, divide by 100.0 to calculate the monetary discount amount.
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
	ROUND(AVG(unique_products), 2) AS avg_unique_products
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
| avg_unique_products |
| ------------------- |
| 6.04                |

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
- Apply the **SUM()** aggregate function to the product of `qty` and `price` to calculate total sales revenue per transaction.
- Use **PERCENTILE_CONT(...) WITHIN GROUP (ORDER BY ...)** to calculate the 25th percentile (median), 50th percentile (median), and 75th percentile revenue thresholds.

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
	ROUND(AVG(total_discount), 2) AS avg_discount
FROM discount
```

#### Steps:
- Define a Common Table Expression (`discount`) querying the `sales` table.
- Group records by `txn_id` to aggregate discount per transaction.
- Apply the **SUM()** aggregate function to multiply `qty`, `price`, and `discount`, divide by 100.0 to compute the total monetary discount amount per transaction.
- Apply the **SUM()** aggregate function to compute the overall average transaction discount.
- Wrap the calculation in **ROUND()** to format the average to two decimal places.

#### Answer:
| avg_discount |
| ------------ |
| 62.49        |

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
	ROUND((100.0 * members / total), 2) AS percentage_members,
	ROUND((100.0 * non_members / total), 2) AS percentage_non_members
FROM transactions;
```

#### Steps:
- Define a Common Table Expression (`transactions`) querying the `sales` table.
- Use **COUNT DISTINCT** with a **FILTER (WHERE ...)** clause (`member = 't'`) to tally unique member transactions.
- Use **COUNT DISTINCT** with a **FILTER (WHERE ...)** clause (`member = 't'`) to tally unique non-member transactions.
- Use **COUNT DISTINCT** to calculate total unique transactions.
- Multiply `members` by 100.0 and divide by `total`to compute the member transaction share.
- Multiply `non_members` by 100.0 and divide by `total`to compute the non-member transaction share.
- Wrap the calculations in **ROUND()** to format the results to two decimal places.

#### Answer:
| percentage_members | percentage_non_members |
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
	ROUND(AVG(total_revenue) FILTER (WHERE member = 't'), 2) AS members_average,
	ROUND(AVG(total_revenue) FILTER (WHERE member = 'f'), 2) AS non_members_average
FROM transactions;
```

#### Steps:
- Define a Common Table Expression (`transactions`) querying the `sales` table.
- Group by `txn_id` and `member` to aggregate revenue per transaction and membership status.
- Apply the **SUM()** aggregate function to calculate the total sales revenue per transaction.
- Apply conditional aggregations using **AVG()** with a **FILTER (WHERE ...)** clause (`member = 't'`) to calculate the average transaction revenue for members.
- Apply conditional aggregations using **AVG()** with a **FILTER (WHERE ...)** clause (`member = 't'`) to calculate the average transaction revenue for non-members.
- Wrap the calculations in **ROUND()** to format the results to two decimal places.

#### Answer:
| members_average | non_members_average |
| --------------- | ------------------- |
| 516.27          | 515.04              |

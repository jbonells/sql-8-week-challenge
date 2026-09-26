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
- Wrap the calculation in **ROUND()** to format the average to two decimal places.

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

```

#### Steps:
- 

#### Answer:


### 4. What is the average discount value per transaction?
```sql

```

#### Steps:
- 

#### Answer:


### 5. What is the percentage split of all transactions for members vs non-members?
```sql

```

#### Steps:
- 

#### Answer:


### 6. What is the average revenue for member transactions and non-member transactions?
```sql

```

#### Steps:
- 

#### Answer:

## A. Customer Nodes Exploration

### 1. How many unique nodes are there on the Data Bank system?
````sql
SELECT
	COUNT(DISTINCT node_id) AS nodes
FROM customer_nodes;
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique nodes.
- (Optional) Assign the alias `nodes` to the resulting column for clear presentation in the final output report.

#### Answer:
| nodes |
| ----- |
| 5     |

- There are 5 unique nodes on the Data Bank system.

### 2. What is the number of nodes per region?
````sql
SELECT
	r.region_name,
    COUNT(DISTINCT cn.node_id) AS nodes
FROM customer_nodes cn
INNER JOIN regions r
	ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
````

#### Steps:
- Use an **INNER JOIN** on `region_name` to connect the `customer_nodes` and `regions` tables.
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique nodes.
- (Optional) Assign the alias `nodes` to the resulting column for clear presentation in the final output report.

#### Answer:
| region_name | nodes |
| ----------- | ----- |
| Africa      | 5     |
| America     | 5     |
| Asia        | 5     |
| Australia   | 5     |
| Europe      | 5     |

- There are 5 unique nodes on each region.

### 3. How many customers are allocated to each region?
````sql
SELECT
	r.region_name,
    COUNT(DISTINCT cn.customer_id) AS customers
FROM customer_nodes cn
INNER JOIN regions r
	ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
````

#### Steps:
- Use an **INNER JOIN** on `region_name` to connect the `customer_nodes` and `regions` tables.
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique customers.
- (Optional) Assign the alias `nodes` to the resulting column for clear presentation in the final output report.

#### Answer:
| region_name | customers |
| ----------- | --------- |
| Africa      | 102       |
| America     | 105       |
| Asia        | 95        |
| Australia   | 110       |
| Europe      | 88        |

- There are 500 customers distributed as seen in the table above.

### 4. How many days on average are customers reallocated to a different node?
````sql

````

#### Steps:
- 

#### Answer:

- 

### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
````sql

````

#### Steps:
- 

#### Answer:

- 


## B. Customer Transactions


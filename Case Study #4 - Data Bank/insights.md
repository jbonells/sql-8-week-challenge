## A. Customer Nodes Exploration

### 1. How many unique nodes are there on the Data Bank system?
````sql
SELECT
	COUNT(DISTINCT node_id) AS nodes
FROM customer_nodes;
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique nodes
- (Optional) Assign the alias `nodes` to the resulting column for clear presentation in the final output report.

#### Answer:
| nodes |
| ----- |
| 5     |

- There are 5 unique nodes on the Data Bank system.

### 2. What is the number of nodes per region?
````sql

````

#### Steps:
- 

#### Answer:

- 

### 3. How many customers are allocated to each region?
````sql

````

#### Steps:
- 

#### Answer:

- 

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


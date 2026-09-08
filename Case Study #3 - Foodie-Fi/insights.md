## A. Customer Journey

### Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
````sql
SELECT
	s.customer_id,
	p.plan_id,
    p.plan_name,
	s.start_date
FROM plans p
JOIN subscriptions s
	ON p.plan_id = s.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
ORDER BY s.customer_id, p.plan_id;
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `plans` and `subscriptions` tables.
- (Optional) Order the final dataset in ascending sequence by `customer_id` and `plan_id` for structured presentation.
Note: I have added `plan_name` event thought it is not present in the sample from the subscriptions table, this way it is more clear for the analisis.

#### Answer:
| customer_id | plan_id | plan_name     | start_date |
| ----------- | ------- | ------------- | ---------- |
| 1           | 0       | trial         | 2020-08-01 |
| 1           | 1       | basic monthly | 2020-08-08 |
| 2           | 0       | trial         | 2020-09-20 |
| 2           | 3       | pro annual    | 2020-09-27 |
| 11          | 0       | trial         | 2020-11-19 |
| 11          | 4       | churn         | 2020-11-26 |
| 13          | 0       | trial         | 2020-12-15 |
| 13          | 1       | basic monthly | 2020-12-22 |
| 13          | 2       | pro monthly   | 2021-03-29 |
| 15          | 0       | trial         | 2020-03-17 |
| 15          | 2       | pro monthly   | 2020-03-24 |
| 15          | 4       | churn         | 2020-04-29 |
| 16          | 0       | trial         | 2020-05-31 |
| 16          | 1       | basic monthly | 2020-06-07 |
| 16          | 3       | pro annual    | 2020-10-21 |
| 18          | 0       | trial         | 2020-07-06 |
| 18          | 2       | pro monthly   | 2020-07-13 |
| 19          | 0       | trial         | 2020-06-22 |
| 19          | 2       | pro monthly   | 2020-06-29 |
| 19          | 3       | pro annual    | 2020-08-29 |

- Customer 1: they started the free trial on 1 Aug 2020. After the trial period ended, on 8 Aug 2020, they subscribed to the basic monthly plan.
- Customer 2: they started the free trial on 20 Sep 2020. After the trial period ended, on 27 Sep 2020, they subscribed to the pro annual plan.
- Customer 11: 
- Customer 13: The onboarding journey for this customer began with a free trial on 15 Dec 2020. Following the trial period, on 22 Dec 2020, they subscribed to the basic monthly plan. After three months, on 29 Mar 2021, they upgraded to the pro monthly plan.
- Customer 15: Initially, this customer commenced their onboarding journey with a free trial on 17 Mar 2020. Once the trial ended, on 24 Mar 2020, they upgraded to the pro monthly plan. However, the following month, on 29 Apr 2020, the customer decided to terminate their subscription and subsequently churned until the paid subscription ends.
- Customer 16: 
- Customer 18: 
- Customer 19: 

## B. Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?
````sql
SELECT
	COUNT(DISTINCT customer_id) AS customers
FROM subscriptions;
````

#### Steps:
- Apply the **COUNT** aggregate function with **DISTINCT** to isolate and count only unique customers, ensuring customers with multiple plans are tallied as a single customers.
- (Optional) Assign the alias `customers` to the resulting column for clear presentation in the final output report.

#### Answer:
| customers |
| --------- |
| 1000      |

- Foodie-Fi has had 1,000 customers.

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
````sql
SELECT 
    TO_CHAR(start_date, 'Month') AS month_name,
    COUNT(*) AS distribution
FROM subscriptions
WHERE plan_id = 0
GROUP BY EXTRACT(MONTH FROM start_date), TO_CHAR(start_date, 'Month')
ORDER BY EXTRACT(MONTH FROM start_date);
````

#### Steps:
- Use the **TO_CHART** function to pull the month component from the `start_date` column, assigning the alias `month_name`.
- Apply the **COUNT** aggregate function to tally the total trial plans.
- (Optional) Order the final dataset in ascending sequence by month for structured presentation.

#### Answer:
| month_name | distribution |
| ---------- | ------------ |
| January    | 88           |
| February   | 68           |
| March      | 94           |
| April      | 81           |
| May        | 88           |
| June       | 79           |
| July       | 89           |
| August     | 88           |
| September  | 87           |
| October    | 79           |
| November   | 75           |
| December   | 84           |

- March has the highest number of trial plans whilst February has the lowest number of them.

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
````sql
SELECT
    s.plan_id,
    p.plan_name,
    COUNT(*) AS event_count
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY s.plan_id, p.plan_name
ORDER BY s.plan_id;
````

#### Steps:
- Use an **INNER JOIN** on `plan_id` to connect the `subscriptions` and `plans` tables.
- Apply a filter condition within the join to only include `start_date` values occur after the year 2020.
- (Optional) Order the final dataset in ascending sequence by `plan_id` for structured presentation.

#### Answer:
| plan_id | plan_name     | event_count | 
| ------- | ------------- |------------ |
| 1       | pro annual    | 63          |
| 2       | churn         | 71          |
| 3       | pro monthly   | 60          |
| 4       | basic monthly | 8           |

- There are 63 pro annual plans on 2021.
- There are 60 pro monthly plans on 2021.
- There are 8 basic monthly plans on 2021.
- There are 71 customers that have unsubscribed on 2021.

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 6. What is the number and percentage of customer plans after their initial free trial?
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 8. How many customers have upgraded to an annual plan in 2020?
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

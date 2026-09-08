## A. Customer Journey

### Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
````sql
SELECT
	COUNT(*) AS pizza_order_count
FROM t_customer_orders;
````

#### Steps:
- Apply the **COUNT** aggregate function to tally all rows, representing the total volume of individual pizza orders placed.
- (Optional) Assign the alias `pizza_order_count` to the resulting column for clear presentation in the final output report.

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- Customers ordered 14 pizzas.


## B. Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
````sql

````

#### Steps:
- 

#### Answer:
| pizza_order_count |
| ----------------- |
| 14                |

- 

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

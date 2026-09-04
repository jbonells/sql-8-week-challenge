## 🧼 Data Cleaning & Transformation

This case study ask us to investigate the data, mentioning that we may want to do something with some of those `null` values and data types in the `customer_orders` and `runner_orders` tables!

### 🔨 Table: customer_orders

Looking at the `customer_orders` table, we can see that there are missing and null values in the `exclusions` and `extras` columns. So we will create a temporary table that:
- Remove empty strings ('') or null strings ('null') with **NULL** in the `exclusions` column.
- Remove empty strings ('') or null strings ('null') with **NULL** in the `extras` column.

````sql
CREATE TEMP TABLE t_customer_orders AS
SELECT
    order_id,
    customer_id,
    pizza_id,
    NULLIF(NULLIF(exclusions, 'null'), '') AS exclusions,
    NULLIF(NULLIF(extras, 'null'), '') AS extras,
    order_time
FROM customer_orders;
`````

### 🔨 Table: runner_orders

Our course of action to clean the `runner_orders` table will be create a temporary table that:
- Remove empty strings ('') or null strings ('null') with **NULL** in the `pickup_time` column.
- Cast the `pickup_time` column as **TIMESTAMP**.
- Remove empty strings ('') or null strings ('null') with **NULL** and any trailing string such as 'km' in the `distance` column.
- Cast the `distance` column as **NUMERIC**.
- Remove empty strings ('') or null strings ('null') with **NULL** and any trailing string such as "minutes", "minute", or "mins" in the `duration` column.
- Cast the  `duration` column as **INTEGER**.
- Remove empty strings ('') or null strings ('null') with **NULL** in the `cancellation` column.

````sql
CREATE TEMP TABLE t_runner_orders AS
SELECT
    order_id,
    runner_id,
    NULLIF(NULLIF(pickup_time, 'null'), '')::TIMESTAMP AS pickup_time,
    NULLIF(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g'), '')::NUMERIC AS distance,
    NULLIF(REGEXP_REPLACE(duration, '[^0-9]', '', 'g'), '')::INTEGER AS duration,
    NULLIF(NULLIF(cancellation, 'null'), '') AS cancellation
FROM runner_orders;
````

### We will add the code to `schema.sql` to be able to run the scripts in Fiddle.

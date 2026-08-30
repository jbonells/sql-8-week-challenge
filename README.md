# 🍜 8 Week SQL Challenge (PostgreSQL)

This repository contains my solutions and case study write-ups for [Danny Ma's 8 Week SQL Challenge](https://8weeksqlchallenge.com/). I am using PostgreSQL to solve complex, real-world business problems ranging from transactional data cleaning to advanced customer analytics and subscription metrics.

## 📂 Case Studies & Progress
| # | Case Study | Status | Key Focus Areas & Tech Stack |
|----|--------------------------------|-----------------|----------------------------------------------------------------------------------|
| 01 | **Danny's Diner**              | 🟢 Completed   | Basic aggregations, joins, ranking window functions (`ROW_NUMBER`, `DENSE_RANK`) |
| 02 | **Pizza Runner**               | 🟡 In Progress | Data cleansing, handling `NULL` values, string manipulation, date math           |
| 03 | **Foodie-Fi**                  | ⚪ Planned     | Subscription metrics, customer churn, customer journey tracking (`LEAD`, `LAG`)  |
| 04 | **Data Bank**                  | ⚪ Planned     | Customer transactions, data re-allocation, regional metrics                      |
| 05 | **Data Mart**                  | ⚪ Planned     | Data modification, pre/post comparative analysis                                 |
| 06 | **Clique Bait**                | ⚪ Planned     | Digital footprint analysis, funnel conversion metrics                            |
| 07 | **Balanced Tree Clothing Co.** | ⚪ Planned     | High-level product metrics, transaction analysis                                 |
| 08 | **Fresh Segments**             | ⚪ Planned     | Interest metrics, metrics aggregation                                            |

## 🛠️ Technical Environment
* **Database:** PostgreSQL
* **Tools:** DBeaver / pgAdmin / VS Code
* **Key SQL Concepts Applied:**
  * Common Table Expressions (CTEs)
  * Window Functions (`RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LEAD()`, `LAG()`)
  * Data Cleansing & Type Casting (`NULLIF`, `CASE WHEN`, `CAST`)
  * Complex Joins & Subqueries

## 🚀 How to Run the Code
1. Clone this repository to your local machine: `git clone https://github.com/jbonells/sql-8-week-challenge.git`
2. Open your preferred PostgreSQL client (e.g., pgAdmin or DBeaver).
3. Navigate to the specific case study folder (e.g., `01_dannys_diner/`) and execute the `schema.sql` file to set up the database and tables.
4. Run the queries in `solutions.sql` to explore the data and review the findings.

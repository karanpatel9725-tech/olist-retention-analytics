# Project Context

## Goal
Olist customer retention and delivery performance analytics (portfolio project for data analyst roles).
Business question: about 97% of customers buy only once. Why don't they return, and what can the business do about it?
Dataset: Olist Brazilian E-Commerce dataset (Kaggle), 99,441 orders, 2016-09-04 to 2018-10-17, 9 relational CSV files.
The ~97% one-time-buyer figure is CONFIRMED on the data (see Key findings).

## About me
- Applying for data-related roles for six months with no interview calls yet.
- Out of practice with Python, SQL, Power BI and Excel; using this project to rebuild fundamentals.
- Everything must be free of cost.
- Prefers one step at a time; tries queries first, then gets them reviewed.

## Tools
- Database: MySQL 8.0.43 (local server, Windows service); database name olist; MySQL Workbench for one-off tasks
- SQL client in VS Code: "Database Client" extension (publisher cweijan), free tier. Connection name: olist_local, host 127.0.0.1, port 3306. Connection details are stored by VS Code outside the repo.
- Python 3.11 (Anaconda) in VS Code with Jupyter: pandas, numpy, matplotlib, seaborn, scikit-learn, scipy, xgboost, sqlalchemy, pymysql, python-dotenv
- Power BI Desktop, Excel
- Git + GitHub (repo: olist-retention-analytics, user: karanpatel9725-tech)
- OS: Windows; PowerShell terminal in VS Code
- AI assistants: Claude and ChatGPT (used alternately)

## Project location
D:\VS\Olist Project\olist-retention-analytics

## Folder structure
data/raw, data/processed, sql, scripts, notebooks, dashboard, reports, images
Root files: README.md, PROJECT_CONTEXT.md, .env (git-ignored), .env.example, .gitignore, LICENSE
- sql/ holds SQL files only (numbered). scripts/ holds runnable Python files.
- Empty folders are kept in Git with .gitkeep files.
- Files so far: sql/01_create_tables.sql, 02_orphan_checks.sql, 03_add_foreign_keys.sql, 04_data_profiling.sql; scripts/test_connection.py, load_data.py; images/er_diagram.png
- Personal interview-prep notes live in a Word file OUTSIDE the repo (olist_project_notes.docx).

## Conventions
- snake_case names; SQL files numbered (01_, 02_, ...)
- Use customer_unique_id (not customer_id) to identify customers
- Credentials live in .env (never committed, never pasted into chat or code); .env variables: DB_USER, DB_PASSWORD, DB_HOST, DB_NAME (optional DB_PORT, default 3306)
- Raw data in data/raw (never edited); cleaned data in data/processed
- Database: olist (utf8mb4, collation utf8mb4_0900_ai_ci)
- Run each Git command on its own line (commit and push separately)
- In the Database Client extension, select the query before clicking Run (otherwise only one statement runs). Its "Cannot read properties of undefined" error after CREATE/ALTER is cosmetic; verify with a query.
- Avoid SQL reserved words as aliases (for example "or"); use o, c, oi, r.
- Join pattern for orphan checks: child table on the left, LEFT JOIN parent, WHERE parent column IS NULL.
- Each profiling query is followed by an INSIGHT comment with real numbers.

## Roadmap (6-8 weeks, ~1-2 hrs/day)
- Phase 0: Setup (repo, tools, database) - DONE
- Phase 1: SQL and Excel fundamentals. Load data into MySQL, 15-20 business questions, joins, CTEs, Excel pivot summary - IN PROGRESS
- Phase 2: Python cleaning and EDA. Clean analytical table, charts each ending in an insight
- Phase 3: Cohort retention, RFM segmentation, delivery impact analysis (hypothesis testing), SQL window functions
- Phase 4: Repeat-purchase prediction (logistic regression, random forest, XGBoost), feature importance, honest limitations; optional K-Means
- Phase 5: 3-page Power BI dashboard (Executive overview, Customer retention, Operations) with DAX, slicers, drill-through
- Phase 6: README case study, 1-2 page business summary, 2-3 minute video, resume and LinkedIn update

## Current status
- Current phase: Phase 1 (SQL and Excel fundamentals)
- Completed:
  - Phase 0 setup; connection test passed (MySQL 8.0.43); .env verified not tracked by Git
  - 9 CSVs in data/raw (git-ignored). Tables created (sql/01) and loaded with scripts/load_data.py; row counts verified in MySQL: customers 99,441; orders 99,441; order_items 112,650; order_payments 103,886; order_reviews 99,224; products 32,951; sellers 3,095; geolocation 1,000,163; product_category_translation 71
  - Six orphan checks, all 0 (sql/02); six foreign keys added and verified (sql/03)
  - ER diagram generated in Workbench and saved as images/er_diagram.png
  - Data profiling queries 1 to 13 with INSIGHT comments (sql/04), pushed to GitHub (latest commit 3f3c73b)
  - README updated with setup, ER diagram and key findings
- Pending: README and this file to be saved and committed (this update)

## Key decisions (with reasons)
- MySQL chosen because MySQL Workbench was already installed. Requires 8.0+ for CTEs and window functions.
- Credentials in .env so the public repo never exposes passwords.
- Tables created with explicit SQL (not pandas auto-create) to get proper types and primary keys; CSVs loaded with pandas to_sql.
- Misspelled source columns product_name_lenght and product_description_lenght are renamed to ..._length in the loader.
- order_reviews has no primary key: neither review_id nor order_id is unique.
- Raw CSVs and data/processed/*.csv are git-ignored (size, GitHub 100 MB limit, Kaggle terms). Add an explicit exception if a small processed file must be committed.
- Cohort analysis window: 2017-01 to 2018-08 (20 months). 2016 and 2018-09/10 are incomplete.
- Delivery-time and review analysis: status = 'delivered' AND order_delivered_customer_date IS NOT NULL.
- Revenue excludes canceled and unavailable orders. Handling of in-progress statuses (shipped, invoiced, processing, created, approved) and the revenue definition (payment_value vs price + freight) are still TO BE DECIDED.
- Reviews: keep one per order, the latest by review_creation_date (tie-break review_answer_timestamp); join reviews on order_id only.
- The server also holds unrelated databases (abc, atliq_tshirts, companydb, emp, mysql, parks_and_recreation, sakila, std, world). Never modify them.

## Key findings so far (all computed from the data)
- Date range 2016-09-04 21:15:19 to 2018-10-17 17:30:18. Monthly orders sum to 99,441. 2016: 4 (Sep), 324 (Oct), 1 (Dec), November missing. 2017-01: 800, rising to 7,544 in 2017-11 (peak; Black Friday is a possible but unverified explanation). 2018-01 to 2018-08 about 6,100 to 7,300 per month. 2018-09: 16, 2018-10: 4.
- Order status: delivered 96,478 (97.0%); shipped 1,107; canceled 625; unavailable 609; invoiced 314; processing 301; created 5; approved 2.
- Missing order_delivered_customer_date: 8 of 96,478 delivered orders (96,470 usable); all shipped, invoiced, processing, created, approved and unavailable orders; 619 of 625 canceled (6 canceled orders have a date, cause unknown).
- Reviews: 99,224 rows, 98,410 distinct review_id, 98,673 distinct order_id; 768 orders have no review. 547 orders have more than one review (543 with 2, 4 with 3); 202 of them have differing scores. Some review_ids are shared across orders: the top 10 each appear on 3 orders, and the one inspected belongs to one customer_unique_id (3 orders, all score 1). Total number of shared review_ids not counted.
- Customers: 99,441 customer_id, 96,096 distinct customer_unique_id. customer_id is created per order.
- Orders per person, all statuses (96,096 people): 1 order 93,099 (96.88%); 2: 2,745; 3: 203; 4: 30; 5: 8; 6: 6; 7: 3; 9: 1; 17: 1. People with 2+ orders: 2,997 (3.12%).
- Excluding canceled and unavailable (94,990 people, 98,207 orders): 1 order 92,102 (96.96%); 2: 2,652; 3: 188; 4: 29; 5: 9; 6: 5; 7: 3; 9: 1; 16: 1. People with 2+ orders: 2,888 (3.04%).
- Orphan checks: 0 for all six relationships (as reported by the user).

## Open issues
- Person with 16 orders (17 including canceled/unavailable) not investigated.
- 6 canceled orders have a delivery date; cause unknown.
- Total count of review_ids shared across orders not yet measured.
- scripts/load_data.py will fail if re-run now (foreign keys need parents loaded first, and the load order puts order_items before products and sellers). Fix before any re-run.
- Revenue definition and in-progress status handling not yet decided.
- Customers who first bought late in the window had little time to return (bias to address in the cohort analysis).

## Next task
1. Create sql/05_business_questions.sql: total orders, total revenue, average order value, orders per month, top 10 product categories (use the translation table), payment type split. Decide the revenue definition first and write it in the file header.
2. Continue with joins and CTEs (Steps 9 and 10): revenue by state and category, delivery time, % late orders, review score by delivery status, using the one-review-per-order rule.
3. Reach 15-20 commented queries, then the Excel summary (Step 11).
4. End of Phase 1: update the README (approach, findings) and the Word notes.

## Reminders
- Commit after each working step with a clear message.
- Update the README at the end of each phase.
- Update the interview-prep Word file (olist_project_notes.docx) after every step or phase and add a row to its Update log. Claude reminds at each step.
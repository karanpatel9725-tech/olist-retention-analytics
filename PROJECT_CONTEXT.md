# Project Context

## Goal
Olist customer retention and delivery performance analytics (portfolio project for data analyst roles).
Business question: about 97% of customers buy only once. Why don't they return, and what can the business do about it?
Dataset: Olist Brazilian E-Commerce dataset (Kaggle), ~100k orders, 2016-2018, 9 relational CSV files.
(The 97% figure comes from the project brief and has NOT yet been verified on the data. Verify it in Phase 1.)

## About me
- Applying for data-related roles for six months with no interview calls yet.
- Out of practice with Python, SQL, Power BI and Excel; using this project to rebuild fundamentals.
- Everything must be free of cost.

## Tools
- Database: MySQL 8.0.43 (local server, Windows service) + MySQL Workbench (optional now)
- SQL client in VS Code: "Database Client" extension (publisher cweijan), free tier (limit 3 connections, only 1 needed). Connection name: olist_local, host 127.0.0.1, port 3306. Connection details are stored by VS Code outside the repo.
- Python (Anaconda) in VS Code with Jupyter: pandas, numpy, matplotlib, seaborn, scikit-learn, scipy, xgboost, sqlalchemy, pymysql, python-dotenv
- Power BI Desktop, Excel
- Git + GitHub (repo: olist-retention-analytics, user: karanpatel9725-tech)
- OS: Windows; PowerShell terminal in VS Code
- AI assistants: Claude and ChatGPT (used alternately)

## Project location
D:\VS\Olist Project\olist-retention-analytics

## Folder structure
data/raw, data/processed, sql, notebooks, dashboard, reports, images, scripts
Root files: README.md, PROJECT_CONTEXT.md, .env (git-ignored), .env.example, .gitignore, LICENSE
- scripts/ holds runnable Python files (connection test, data loading). sql/ holds SQL files only.
- Empty folders are kept in Git with .gitkeep files.

## Conventions
- snake_case names; SQL files numbered (01_, 02_, ...)
- Use customer_unique_id (not customer_id) to identify customers
- Credentials live in .env (never committed, never pasted into chat or code); .env.example is the template
- .env variable names: DB_USER, DB_PASSWORD, DB_HOST, DB_NAME (optional DB_PORT, defaults to 3306)
- Raw data in data/raw (never edited); cleaned data in data/processed
- Database name: olist (utf8mb4, collation utf8mb4_0900_ai_ci)
- Run each Git command on its own line (commit and push separately)

## Roadmap (6-8 weeks, ~1-2 hrs/day)
- Phase 0: Setup (repo, tools, database)
- Phase 1: SQL and Excel fundamentals. Load data into MySQL, 15-20 business questions, joins, CTEs, Excel pivot summary
- Phase 2: Python cleaning and EDA. Clean analytical table, charts each ending in an insight
- Phase 3: Cohort retention, RFM segmentation, delivery impact analysis (hypothesis testing), SQL window functions
- Phase 4: Repeat-purchase prediction (logistic regression, random forest, XGBoost), feature importance, honest limitations; optional K-Means
- Phase 5: 3-page Power BI dashboard (Executive overview, Customer retention, Operations) with DAX, slicers, drill-through
- Phase 6: README case study, 1-2 page business summary, 2-3 minute video, resume and LinkedIn update

## Current status
- Current phase: Phase 0 (setup), almost complete
- Completed:
  - GitHub repo created and cloned; folder structure in the repo
  - Python libraries installed and verified
  - .env and .env.example created; verified .env is NOT tracked by Git (git ls-files) 
  - Stray env.example removed; accidental "-filesq" file (created by Git pager) deleted
  - Git pager set to "less -FRX" so short output no longer opens the pager
  - Dataset downloaded to data/raw/: 9 CSVs (customers, geolocation 58.4 MB, orders, order_items, order_payments, order_reviews, products, sellers, product_category_name_translation). CSVs are git-ignored (data/raw/*.csv).
  - README "Data source" section added; commit 11dfebe pushed to origin/main
  - MySQL 8.0.43 confirmed; olist database created and confirmed present
  - VS Code connected to MySQL via the Database Client extension
- Pending:
  - Run scripts/test_connection.py; expected output: "Connected to database: olist | MySQL version: 8.0.43". NOT yet confirmed.
  - Commit and push scripts/test_connection.py (check .env is not staged)

## Key decisions (with reasons)
- MySQL chosen as the database because MySQL Workbench was already installed. Requires MySQL 8.0+ for CTEs and window functions (we have 8.0.43).
- Credentials kept in .env so the public repo never exposes passwords.
- Large CSVs (order items, reviews, geolocation) to be loaded with pandas to_sql or LOAD DATA, not the slow Workbench wizard.
- Raw CSVs and data/processed/*.csv are git-ignored (size, GitHub 100 MB file limit, Kaggle dataset terms). If a small processed file must be committed later (for example Excel inputs), add an explicit .gitignore exception.
- Added scripts/ folder for Python scripts so sql/ stays SQL-only.
- Use VS Code (Database Client) for daily SQL work so queries live in sql/ next to the code; Workbench kept for one-off tasks such as the ER diagram (Database > Reverse Engineer).
- The MySQL server also has unrelated databases (abc, atliq_tshirts, companydb, emp, mysql, parks_and_recreation, sakila, std, world). Never modify them; this project uses only olist.

## Key findings so far
- (none yet; no analysis has been run)

## Open issues
- The ~97% one-time-buyer rate is unverified; confirm it with SQL in Phase 1 using customer_unique_id.
- Connection test result not yet confirmed (see Pending).

## Next task
1. Run python scripts\test_connection.py and confirm the expected output; then commit and push it
2. Mark Phase 0 complete in this file
3. Phase 1, Step 6: load the 9 CSVs into the olist database using pandas to_sql (script in scripts/), then define primary and foreign keys
4. Draw the ER diagram and save it in images/
5. Step 7: profile the data with basic SQL (row counts, date range, nulls, duplicates, order statuses)

## Reminders
- Commit after each working step with a clear message.
- Update the README at the end of each phase (next: end of Phase 1, adding the schema/ER diagram and first findings).
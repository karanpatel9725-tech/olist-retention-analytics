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
- Prefers one step at a time; fill-in-the-blank query templates work well, then a review. Gets confused by long query chains: prefer synthesis over more queries.
- Updates the README, this file and the Word notes once at the end of each working day.

## Tools
- Database: MySQL 8.0.43 (local server, Windows service); database name olist; MySQL Workbench for one-off tasks
- SQL client in VS Code: "Database Client" extension (publisher cweijan), free tier. Its CSV/XLSX export is a paid feature, so exports are done with a Python script. Connection name: olist_local, host 127.0.0.1, port 3306. Connection details are stored by VS Code outside the repo.
- Python 3.11 (Anaconda) in VS Code with Jupyter: pandas, numpy, matplotlib, seaborn, scikit-learn, scipy, xgboost, sqlalchemy, pymysql, python-dotenv
- Power BI Desktop, Excel
- Git + GitHub (repo: olist-retention-analytics, user: karanpatel9725-tech)
- OS: Windows; PowerShell terminal in VS Code
- AI assistants: Claude and ChatGPT (used alternately)
- Walkthrough video (Phase 6): Loom free plan chosen (screen + camera). Limits when checked: 25 videos, 5 minutes each, 720p; verify at sign-up. OBS Studio is the fallback. Teams not used (recording needs a paid subscription on a personal account, and a work account would store it on employer systems). Never show .env or passwords on screen.

## Project location
D:\VS\Olist Project\olist-retention-analytics

## Folder structure
data/raw, data/processed, sql, scripts, notebooks, dashboard, reports, images
Root files: README.md, PROJECT_CONTEXT.md, .env (git-ignored), .env.example, .gitignore, LICENSE
- sql/ holds SQL files only (numbered). scripts/ holds runnable Python files.
- Files so far: sql/01_create_tables.sql, 02_orphan_checks.sql, 03_add_foreign_keys.sql, 04_data_profiling.sql (13 queries), 05_business_questions.sql (19 queries); scripts/test_connection.py, load_data.py, export_for_excel.py; images/er_diagram.png; reports/olist_excel_summary.xlsx (sheets: summary, monthly_revenue, top_categories, review_by_lateness, repeat_by_category)
- data/processed/ holds four CSVs from export_for_excel.py (git-ignored; the script recreates them).
- Personal interview-prep notes live in a Word file OUTSIDE the repo (olist_project_notes.docx), updated 12 Oct 2026.

## Conventions
- snake_case names; SQL files numbered (01_, 02_, ...)
- Use customer_unique_id (not customer_id) to identify customers
- Credentials live in .env (never committed, never pasted into chat or code); .env variables: DB_USER, DB_PASSWORD, DB_HOST, DB_NAME (optional DB_PORT, default 3306)
- Raw data in data/raw (never edited); cleaned data in data/processed
- Database: olist (utf8mb4, collation utf8mb4_0900_ai_ci)
- Run each Git command on its own line (commit and push separately); run commands from the repo folder
- In the Database Client extension, select the whole query (for CTEs, from WITH to the final semicolon) before clicking Run. Its "Cannot read properties of undefined" error after CREATE/ALTER is cosmetic.
- Comment lines must start with "--"; check for leftover blanks before running.
- Avoid SQL reserved words as aliases (for example "or"); use o, c, oi, r.
- Orphan-check pattern: child table on the left, LEFT JOIN parent, WHERE parent column IS NULL.
- Never join order_items and order_payments directly (rows multiply); aggregate each to one row per order first.
- Each query is followed by an INSIGHT comment with real numbers; check the customer count next to every percentage.
- Close Excel before committing (its ~$ lock file); ~$* is in .gitignore.

## Roadmap (6-8 weeks, ~1-2 hrs/day)
- Phase 0: Setup - DONE
- Phase 1: SQL and Excel fundamentals - DONE (19 business queries, Excel summary workbook; pivot tables skipped because the exported results were already summarised; Query 20 on late sellers deferred to the dashboard)
- Phase 2: Python cleaning and EDA - NEXT
- Phase 3: Cohort retention, RFM segmentation, delivery impact analysis (hypothesis testing), SQL window functions
- Phase 4: Repeat-purchase prediction (logistic regression, random forest, XGBoost), feature importance, honest limitations; optional K-Means
- Phase 5: 3-page Power BI dashboard (Executive overview, Customer retention, Operations) with DAX, slicers, drill-through
- Phase 6: README case study, 1-2 page business summary, 2-3 minute video, resume and LinkedIn update

## Current status
- Current phase: Phase 1 complete; Phase 2 not started
- Pushed to GitHub (latest confirmed commit 73aaec6 "Add Excel summary workbook and export script"): Phase 0; tables created and loaded (row counts verified); six orphan checks (all 0); six foreign keys; ER diagram; profiling queries 1-13; business queries 1-19; export script and Excel workbook; README and context after business findings (2fc3172)
- Pending: README end-of-Phase-1 edits and the "~$*" line in .gitignore (commit "Update README for end of Phase 1 and ignore Excel lock files") not yet confirmed; this file's update and the Word notes (local file) to be saved

## Key decisions (with reasons)
- MySQL chosen because MySQL Workbench was already installed. Requires 8.0+ for CTEs and window functions.
- Credentials in .env so the public repo never exposes passwords.
- Tables created with explicit SQL for proper types and keys; CSVs loaded with pandas to_sql.
- Misspelled source columns product_name_lenght and product_description_lenght renamed to ..._length in the loader.
- order_reviews has no primary key: neither review_id nor order_id is unique.
- Raw CSVs and data/processed/*.csv are git-ignored (size, GitHub 100 MB limit, Kaggle terms).
- Cohort analysis window: 2017-01 to 2018-08 (20 months). 2016 and 2018-09/10 are incomplete.
- REVENUE = SUM(price + freight_value) from order_items, delivered orders only. Reason: can be split by category, seller and state; agrees with payments within 0.017%. order_payments is used only for payment-type questions.
- Delivery and review analysis: status = 'delivered' AND order_delivered_customer_date IS NOT NULL. Late = delivered after order_estimated_delivery_date (full date and time).
- Reviews: one per order, the latest by review_creation_date (tie-break review_answer_timestamp), via ROW_NUMBER() in a CTE; join reviews on order_id only.
- Repeat buyer = person (customer_unique_id) with 2+ orders excluding canceled and unavailable. "First order" = earliest such order. Category of a customer = category of the first item of the first order.
- Stopped writing business queries at 19 (diminishing returns); results synthesised in the Excel summary instead.
- Excel results are exported with scripts/export_for_excel.py (copies of Queries 7, 9, 15 and 19) because the extension's export is paid; the workbook is committed (about 51 KB).
- The server also holds unrelated databases (abc, atliq_tshirts, companydb, emp, mysql, parks_and_recreation, sakila, std, world). Never modify them.

## Key findings so far (all computed from the data)
Profiling (sql/04):
- 99,441 orders, 2016-09-04 to 2018-10-17. 2016 nearly empty (November missing); real volume from 2017-01; peak 2017-11; 2018-09/10 tiny (16 and 4).
- Status: delivered 96,478 (97.0%); shipped 1,107; canceled 625; unavailable 609; invoiced 314; processing 301; created 5; approved 2.
- 8 delivered orders have no delivery date; 6 canceled orders have one (cause unknown).
- Reviews: 99,224 rows, 98,410 distinct review_id, 98,673 distinct order_id; 768 orders without a review; 547 orders have more than one review (202 with differing scores); some review_ids shared across a customer's orders.
- customer_id is created per order: 99,441 customer_id vs 96,096 people.
- Orders per person (all statuses): 93,099 of 96,096 (96.88%) have exactly 1 order. Excluding canceled/unavailable: 92,102 of 94,990 (96.96%); 2,888 people (3.04%) ordered more than once.

Business questions (sql/05):
- Revenue (price + freight, delivered): 15,419,773.75 across 96,478 orders; average order value 159.83. Payments total 15,422,461.77 (gap 2,688.02, 0.017%). 299 of 96,477 comparable orders differ by more than 0.01; one delivered order (bfbd0f9b...) has no payment row.
- Monthly: 127,482.37 (2017-01) to peak 1,153,364.20 (2017-11, 7,289 orders); 2018-01 to 2018-08 flat at 966,168.41 to 1,132,878.93.
- Categories: health_beauty 9.2% (1,412,089.53), watches_gifts 8.2%, bed_bath_table 7.9%, sports_leisure 7.3%, computers_accessories 6.7%; top 10 = 62.4%.
- Payments: credit_card 78.5%, boleto 18.0%, voucher 2.2%, debit_card 1.4%.
- States by customer location: SP 37.4%, RJ 13.3%, MG 11.8% (62.5% together); top 10 = 87.4%.
- Delivery (96,470 orders): 12.5 days vs 24.4 promised; 8.1% late. Late share: AL 23.9%, MA 19.7%, PI 16.0%, CE 15.3%, SE 15.2%, BA 14.0%, RJ 13.5%; SP 5.9%. Small samples (RR, AP, AC, AM) unreliable.
- Review score (95,824 reviewed delivered orders): on time 4.29 (88,163); late 2.57 (7,661). By band: up to 3 days 3.59 (3,132); 4-7 days 2.10 (1,748); over 7 days 1.70 (2,781).
- Repeat rate by first-order delivery (93,291 customers): on time 3.07% (85,697); late 2.52% (7,594). 96.93% of on-time first-order customers also never returned.
- Repeat rate by first-order review score (92,683 customers): 1 star 2.92% (9,067); 2: 2.75% (2,832); 3: 2.94% (7,657); 4: 2.78% (18,362); 5: 3.14% (54,765). Range 0.39 points, no steady pattern.
- Repeat rate by state of first order (17 states with 500+ customers, 92,472 customers): RJ 3.37% (12,238), MT 3.33%, GO 3.16%, SP 3.14% (39,738), RS 3.13% ... MA 2.24%, CE 1.62% (1,300). Overall 3.04%. RJ has a high late share and the highest repeat rate, so delivery does not explain state differences.
- Repeat rate by first-item category (21 rows incl. one blank category, 84,144 customers, 1,000+ customers each): fashion_bags_accessories 5.91% (1,726), furniture_decor 4.55% (6,039), bed_bath_table 4.51% (8,847), sports_leisure 3.92% (7,326) ... electronics 1.65% (2,489), consoles_games 1.75% (1,031), cool_stuff 1.87%. Range 4.26 points. health_beauty 2.79% and watches_gifts 2.14% are below the 3.04% average.
- KEY STORY: delivery and review score barely move repeat purchase; first-purchase category moves it most; top-revenue categories are not the best retainers. All associations, none significance-tested.
- Orphan checks: all six relationships 0 (as reported by the user).

## Open issues
- Significance of all repeat-rate gaps is untested (Phase 3). Late-in-period customers had less time to return; groups may differ in timing, state and product mix.
- Reasons not known: why 299 orders differ between payments and items; why SP has lower revenue per order; the 6 canceled orders with a delivery date; the one delivered order without a payment; why categories differ in repeat rate.
- Person with 16 orders (17 including canceled/unavailable) not investigated.
- Total number of review_ids shared across orders not measured; revenue share without a category not measured.
- scripts/load_data.py will fail if re-run now (foreign keys need parents loaded first). Fix before any re-run.
- Query 20 (late sellers) deferred to the dashboard Operations page.
- Pivot tables not practised (planned Phase 1 item); could be done on order-level data in Phase 2.

## Next task
1. Confirm the README/.gitignore commit is pushed (git log); save this file and the Word notes.
2. Phase 2 step 1: create notebooks/01_cleaning_eda.ipynb; load orders, customers, order_items, order_reviews and products via SQLAlchemy using the .env settings; check each row count matches MySQL.
3. Clean: parse dates, keep delivered orders with a delivery date where needed, one review per order (latest), translate category names, document each decision in a markdown cell.
4. Build the analytical base table (one row per order, plus customer_unique_id, delivery_days, delay_days, is_late, order_value, review_score, first-order flag) and save it to data/processed/.
5. EDA with charts, each ending in a one-sentence insight; then Phase 3 (cohorts, RFM, significance tests).

## Reminders
- Commit after each working step with a clear message.
- Update the README at the end of each phase.
- Update the Word notes at the end of each working day or phase, with a new row in its Update log. Claude reminds.
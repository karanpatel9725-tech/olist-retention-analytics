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
- Prefers one step at a time; fill-in-the-blank templates work well, then a review. Gets confused by long query chains and by being told to replace several cells: say exactly WHICH cell to edit and give only that cell's code. Prefer synthesis over more queries.
- Updates the README, this file and the Word notes once at the end of each working day.

## Tools
- Database: MySQL 8.0.43 (local server, Windows service); database name olist; MySQL Workbench for one-off tasks
- SQL client in VS Code: "Database Client" extension (publisher cweijan), free tier. Its CSV/XLSX export is a paid feature, so exports are done with a Python script. Connection name: olist_local, host 127.0.0.1, port 3306. Connection details are stored by VS Code outside the repo.
- Python 3.11 (Anaconda) in VS Code with Jupyter: pandas, numpy, matplotlib, seaborn, scikit-learn, scipy, xgboost, sqlalchemy, pymysql, python-dotenv
- Power BI Desktop, Excel
- Git + GitHub (repo: olist-retention-analytics, user: karanpatel9725-tech)
- OS: Windows; PowerShell terminal in VS Code
- AI assistants: Claude and ChatGPT (used alternately). Claude has no memory between chats; this file is the only carry-over.
- Walkthrough video (Phase 6): Loom free plan chosen (screen + camera). Limits when checked: 25 videos, 5 minutes each, 720p; verify at sign-up. OBS Studio is the fallback. Teams not used. Never show .env or passwords on screen.

## Project location
D:\VS\Olist Project\olist-retention-analytics

## Folder structure
data/raw, data/processed, sql, scripts, notebooks, dashboard, reports, images
Root files: README.md, PROJECT_CONTEXT.md, .env (git-ignored), .env.example, .gitignore, LICENSE
- sql/ holds SQL files only (numbered). scripts/ holds runnable Python files.
- Files so far: sql/01_create_tables.sql, 02_orphan_checks.sql, 03_add_foreign_keys.sql, 04_data_profiling.sql (13 queries), 05_business_questions.sql (19 queries); scripts/test_connection.py, load_data.py, export_for_excel.py; notebooks/01_cleaning_eda.ipynb, notebooks/02_retention_rfm.ipynb (in progress); images/er_diagram.png; reports/olist_excel_summary.xlsx
- data/processed/ (CSVs git-ignored): the four Excel CSVs and orders_enriched.csv (99,441 rows x 18 columns, recreated by notebook 01).
- Personal interview-prep notes live in a Word file OUTSIDE the repo (olist_project_notes.docx), last updated 23 Oct 2026 (needs a new row for 26 Oct).

## Conventions
- snake_case names; SQL files numbered (01_, 02_, ...); notebooks numbered (01_, 02_, ...)
- Use customer_unique_id (not customer_id) to identify customers
- Credentials live in .env (never committed, never pasted into chat or code); .env variables: DB_USER, DB_PASSWORD, DB_HOST, DB_NAME (optional DB_PORT, default 3306)
- Raw data in data/raw (never edited); cleaned data in data/processed
- Database: olist (utf8mb4, collation utf8mb4_0900_ai_ci)
- Run each Git command on its own line (commit and push separately); run commands from the repo folder
- In the Database Client extension, select the whole query (for CTEs, from WITH to the final semicolon) before clicking Run.
- Comment lines must start with "--"; check for leftover blanks before running.
- Avoid SQL reserved words as aliases (for example "or"); use o, c, oi, r.
- Orphan-check pattern: child table on the left, LEFT JOIN parent, WHERE parent column IS NULL.
- Never join order_items and order_payments directly (rows multiply); aggregate each to one row per order first.
- In pandas, after every merge check the row count (99,441) and that order_id is unique; reconcile new numbers against the SQL results.
- ALWAYS filter order_status == 'delivered' before using is_late, delivery_days or delay_days: 6 canceled orders have a delivery date, so is_late is filled for them.
- Each query and chart is followed by an INSIGHT comment with real numbers; check the customer count next to every percentage; "slow" (days) is not "late" (after the promised date).
- Statistical tests: report the effect size next to the p-value (p of 0.0 is written "p < 0.001"); say association, not cause.
- Heatmaps: mask months that have not happened yet as NaN (not 0); keep every month column (reindex) so true zeros are not hidden.
- Close Excel before committing (its ~$ lock file); ~$* is in .gitignore.

## Roadmap (6-8 weeks, ~1-2 hrs/day)
- Phase 0: Setup - DONE
- Phase 1: SQL and Excel fundamentals - DONE (19 business queries, Excel summary; pivot tables skipped; Query 20 on late sellers deferred to the dashboard)
- Phase 2: Python cleaning and EDA - DONE (notebook 01: analysis table, five charts)
- Phase 3: Cohort retention, RFM segmentation, delivery impact analysis (hypothesis testing), SQL window functions - IN PROGRESS (Steps 16, 17 and 18a done; 18b next)
- Phase 4: Repeat-purchase prediction (logistic regression, random forest, XGBoost), feature importance, honest limitations; optional K-Means
- Phase 5: 3-page Power BI dashboard (Executive overview, Customer retention, Operations) with DAX, slicers, drill-through
- Phase 6: README case study, 1-2 page business summary, 2-3 minute video, resume and LinkedIn update

## Current status
- Current phase: Phase 3, notebook 02 (about two-thirds done)
- Done in notebook 02: Step 16 cohort retention (matrix, heatmap, insights); Step 17 RFM (table, scores, segments, summary, share chart, insights); Step 18a Mann-Whitney test and effect size on review score, on time vs late (insight cell written).
- Next in notebook 02: Step 18b chi-square test of the repeat-rate gap (template given, NOT yet run), then repeat rate by delivery experience and review score, worst states, closing summary cell.
- Pushed and confirmed earlier: Phases 0 and 1; notebook 01 up to EDA chart 3 (commit 8b5178a).
- NOT confirmed (check with git log): EDA charts 4-5 commit; the notebook 02 commits (cohort, RFM, Mann-Whitney); README end-of-Phase-2 edits; this file and the Word notes.

## Notebook 01 (notebooks/01_cleaning_eda.ipynb)
- Loads orders, customers, order_items, order_payments, order_reviews, products, sellers, product_category_translation via SQLAlchemy and .env; every row count matches MySQL.
- reviews_latest: latest review per order (sort by order_id, review_creation_date desc, review_answer_timestamp desc; keep first): 98,673 rows.
- orders_enriched (one row per order, 99,441 x 18): the 8 orders columns plus customer_unique_id, customer_state, review_score, delivery_days, delay_days (whole calendar days, like MySQL DATEDIFF), is_late (full date-time test; NaN if not delivered), order_value and n_items (NaN for orders without items), order_number and person_total_orders (canceled and unavailable orders excluded, so NaN for them).
- Reconciled with SQL: delivered with a date 96,470; average delivery 12.5 days; late 8.1%; delivered revenue 15,419,773.75; AOV 159.83; orders kept 98,207; people 94,990; repeat buyers 2,888 (3.04%).
- Charts: monthly revenue, delivery-time histogram, review-score distribution, top 10 states, top 10 categories; each with an insight cell.

## Notebook 02 (notebooks/02_retention_rfm.ipynb)
- Loads data/processed/orders_enriched.csv with dates parsed. Variables: orders; first (order_number == 1, one row per person); cohort_size; valid (98,207 orders with order_number, plus order_month, cohort_month, months_since_first); active; retention; rfm; summary; d.
- Cohorts: cohort_month = month of first valid order. Window 2017-01 to 2018-08 (20 cohorts, 94,697 people). 2016 cohorts: 2, 290 and 1 people. No cohort exists for 2018-09 or 2018-10 (cause not checked).
- Retention matrix: active people / cohort size x 100. In the retention cell, active is cut to the window, reindexed to months 0-19 (fill 0), and months that have not happened yet are set to NaN. (The raw active matrix has columns 0-17, 19, 20: month 18 is missing because nobody ordered then, and month 20 comes from 2016 cohorts; the reindex fixes both.)
- RFM: snapshot = last valid order + 1 day = 2018-09-04 09:06:57. recency_days = days since last order; frequency = orders; monetary = sum of order_value over all valid orders (includes valid orders not yet delivered). r_score and m_score are quintiles via rank(method="first") (18,998 people each; ties split by row order); f_band = 1 / 2 / 3+.
- Segment rules (my own, not a standard; first match wins): Champions = repeat buyer and r_score >= 4; Loyal = other repeat buyers; New customers = one order and r_score >= 4; At risk = one order, r_score 2-3 and m_score >= 4; About to lose = one order, r_score 2-3, lower spend; Lost = one order, r_score 1.
- Mann-Whitney: delivered orders only (order_status == 'delivered'), with review and is_late; two-sided.

## Key decisions (with reasons)
- MySQL chosen because MySQL Workbench was already installed. Requires 8.0+ for CTEs and window functions.
- Credentials in .env so the public repo never exposes passwords.
- Tables created with explicit SQL for proper types and keys; CSVs loaded with pandas to_sql.
- Misspelled source columns product_name_lenght and product_description_lenght renamed to ..._length in the loader.
- order_reviews has no primary key: neither review_id nor order_id is unique.
- Raw CSVs and data/processed/*.csv are git-ignored (size, GitHub 100 MB limit, Kaggle terms).
- Cohort analysis window: 2017-01 to 2018-08 (20 months). 2016 and 2018-09/10 are incomplete.
- REVENUE = SUM(price + freight_value) from order_items, delivered orders only. order_payments is used only for payment-type questions.
- Delivery and review analysis: status = 'delivered' AND order_delivered_customer_date IS NOT NULL. Late = delivered after order_estimated_delivery_date (full date and time).
- Reviews: one per order, the latest by review_creation_date (tie-break review_answer_timestamp); join reviews on order_id only.
- Repeat buyer = person (customer_unique_id) with 2+ orders excluding canceled and unavailable. "First order" = earliest such order. Category of a customer = category of the first item of the first order.
- order_value stays NaN (not 0) for the 775 orders without items (unavailable 603, canceled 164, created 5, invoiced 2, shipped 1; none delivered).
- Stopped writing business queries at 19; results synthesised in the Excel summary and notebook 01.
- Excel results are exported with scripts/export_for_excel.py (copies of Queries 7, 9, 15 and 19); the workbook is committed (about 51 KB).
- The server also holds unrelated databases (abc, atliq_tshirts, companydb, emp, mysql, parks_and_recreation, sakila, std, world). Never modify them.
- RFM Frequency uses fixed bands (1, 2, 3+) because 96.96% of people have one order; Recency and Monetary use quintiles. Segment rules are my own choice and are stated in the notebook.
- Mann-Whitney (not a t-test) for review scores: whole numbers 1-5, heavily piled at 5 and skewed. Effect size reported as the probability that a random on-time order scores higher than a random late one (ties as half).

## Key findings so far (all computed from the data)
Profiling (sql/04):
- 99,441 orders, 2016-09-04 to 2018-10-17. 2016 nearly empty (November missing); real volume from 2017-01; peak 2017-11; 2018-09/10 tiny (16 and 4).
- Status: delivered 96,478 (97.0%); shipped 1,107; canceled 625; unavailable 609; invoiced 314; processing 301; created 5; approved 2.
- 8 delivered orders have no delivery date; 6 canceled orders have one (confirmed again in notebook 02: 6 canceled orders with a delivery date and a review; cause unknown). In orders, order_approved_at is missing for 160 and order_delivered_carrier_date for 1,783 (not investigated, not used).
- Reviews: 99,224 rows, 98,410 distinct review_id, 98,673 distinct order_id; 768 orders without a review; 547 orders have more than one review (202 with differing scores); some review_ids shared across a customer's orders.
- customer_id is created per order: 99,441 customer_id vs 96,096 people.
- Orders per person (all statuses): 93,099 of 96,096 (96.88%) have exactly 1 order. Excluding canceled/unavailable: 92,102 of 94,990 (96.96%); 2,888 people (3.04%) ordered more than once.

Business questions (sql/05):
- Revenue (price + freight, delivered): 15,419,773.75 across 96,478 orders; AOV 159.83. Payments total 15,422,461.77 (gap 2,688.02, 0.017%). 299 of 96,477 comparable orders differ by more than 0.01; one delivered order (bfbd0f9b...) has no payment row.
- Monthly: 127,482.37 (2017-01) to peak 1,153,364.20 (2017-11, 7,289 orders); 2018-01 to 2018-08 flat at 966,168.41 to 1,132,878.93.
- Categories: health_beauty 9.2% (1,412,089.53), watches_gifts 8.2%, bed_bath_table 7.9%, sports_leisure 7.3%, computers_accessories 6.7%; top 10 = 62.4%.
- Payments: credit_card 78.5%, boleto 18.0%, voucher 2.2%, debit_card 1.4%.
- States by customer location: SP 37.4% (5,769,703.15), RJ 13.3%, MG 11.8% (62.5% together); top 10 = 87.4%.
- Delivery (96,470 orders): 12.5 days vs 24.4 promised; 8.1% late. Late share: AL 23.9%, MA 19.7%, PI 16.0%, CE 15.3%, SE 15.2%, BA 14.0%, RJ 13.5%; SP 5.9%. Small samples (RR, AP, AC, AM) unreliable.
- Review score (95,824 reviewed delivered orders): on time 4.29 (88,163); late 2.57 (7,661). By band: up to 3 days 3.59; 4-7 days 2.10; over 7 days 1.70.
- Repeat rate by first-order delivery (93,291 customers): on time 3.07% (85,697); late 2.52% (7,594). 96.93% of on-time first-order customers also never returned.
- Repeat rate by first-order review score (92,683 customers): 1 star 2.92%; 2: 2.75%; 3: 2.94%; 4: 2.78%; 5: 3.14%. Range 0.39 points.
- Repeat rate by state of first order (17 states with 500+ customers): RJ 3.37% highest, CE 1.62% lowest; overall 3.04%. RJ has a high late share and the highest repeat rate, so delivery does not explain state differences.
- Repeat rate by first-item category (21 rows, 1,000+ customers each): fashion_bags_accessories 5.91% highest, electronics 1.65% lowest; range 4.26 points. health_beauty 2.79% and watches_gifts 2.14% are below the 3.04% average.

EDA (notebook 01):
- Delivery time (96,470 delivered orders): median 10 days, mean 12.5, std 9.6, 75% within 16 days, max 210; 298 orders (about 0.3%) took more than 60 days.
- Review scores (95,832 reviewed delivered orders, average 4.16): 1 star 9.8%, 2 stars 3.0%, 3 stars 8.3%, 4 stars 19.7%, 5 stars 59.2%. (95,832 does not match the 95,824 used in SQL and notebook 02; not reconciled.)
- Top 10 states and top 10 categories match SQL Queries 11 and 8 (top 10 states 87.4%, top 10 categories 62.4%, total revenue 15,419,773.75).

Cohort retention (notebook 02):
- 94,990 people have a first valid order; 2,888 (3.04%) ordered again. 98,207 valid orders, so 3,217 repeat orders (about 1.11 per repeat buyer); 1,273 of them (39.6%) fall in the same calendar month as the first order.
- Largest cohort 2017-11 (7,190 people); 2018 cohorts between 5,920 and 6,951.
- In the window, no cell after month 0 is above 0.71% (2017-10, month 1). Month 1 is the darkest column for most cohorts; later months sit at roughly 0.1% to 0.4% with no second wave. Strongest month 1: 2017-08 0.68%, 2017-09 0.69%, 2017-10 0.71%. Weakest: 2017-12 0.22%, 2017-02 0.24%. 2018 cohorts month 1: 0.33% to 0.58%.
- Old cohorts are small, so cells beyond month 10 swing with one person (one person = 0.13 points in the 752-person 2017-01 cohort; 2017-01 shows 0.66% in month 12 and 0.00% in months 9 and 18; 2017-02 also 0.00% in month 18). Treat as noise.
- Caveat: each cell counts people active in that month, not people who ever returned, so the matrix understates total repeat buyers. Differences between cohorts not significance-tested.

RFM (notebook 02; 94,990 people; monetary total 15,735,527.03, which is 315,753.28 above delivered-only revenue; likely because it includes valid orders not yet delivered, not split by status):
- Recency: median 224 days (1 to 729). Spend per person: median 107.90, mean 165.65, max 13,664.08. 7 people have monetary 0. Most orders by one person: 16.
- Frequency bands: 1 order 92,102; 2 orders 2,652; 3+ orders 236 (2,888 repeat buyers).
- Segments (people, % of people, revenue, % of revenue):
  - New customers: 36,754 (38.69%), 6,054,703.31 (38.48%); avg recency 95.6 days, avg spend 164.74
  - At risk: 14,146 (14.89%), 4,172,943.62 (26.52%); avg recency 273.5 days, avg spend 294.99
  - Lost: 18,543 (19.52%), 2,974,811.78 (18.91%); avg recency 479.6 days, avg spend 160.43
  - About to lose: 22,659 (23.85%), 1,642,809.82 (10.44%); avg recency 273.5 days, avg spend 72.50
  - Loyal: 1,646 (1.73%), 491,200.66 (3.12%); avg recency 326.5 days, avg spend 298.42
  - Champions: 1,242 (1.31%), 399,057.84 (2.54%); avg recency 94.0 days, avg spend 321.30
- Repeat buyers (Champions + Loyal) are 3.04% of people and 5.66% of monetary value. At risk is 14.89% of people but 26.52% of value (about 1.8 times the average per person); About to lose is the reverse.
- Hypothesis (untested): At risk is the best group for a win-back experiment with a control group; About to lose is a weak target (low spend). Past spend does not mean they will return.

Delivery impact on reviews (notebook 02, Mann-Whitney, two-sided, delivered orders only; counts match SQL exactly):
- 95,824 reviewed delivered orders: on time 88,163 (mean 4.29, median 5.0); late 7,661 (mean 2.57, median 2.0). U = 524,647,305; p < 0.001. Effect size: a random on-time order scores higher than a random late one 77.7% of the time (50% = no difference; ties as half). Large association; not proof of cause.

EDA story so far: delivery strongly affects review score, but delivery and review score barely move repeat purchase (SQL: 3.07% vs 2.52%; 1 star 2.92% vs 5 stars 3.14%); first-purchase category moves repeat rate most; top-revenue categories are not the best retainers. All repeat-rate differences are associations and NOT yet significance-tested (18b pending).

## Open issues
- Significance of the repeat-rate gaps is untested (Step 18b next). Late-in-period customers had less time to return; groups may differ in timing, state and product mix.
- Reasons not known: why 299 orders differ between payments and items; why SP has lower revenue per order; the 6 canceled orders with a delivery date; the one delivered order without a payment; why categories differ in repeat rate; why no cohorts exist for 2018-09/10.
- Notebook 01 reports 95,832 reviewed delivered orders vs 95,824 in SQL and notebook 02: not reconciled.
- The 315,753.28 gap between RFM monetary and delivered revenue is not split by status.
- 7 people with monetary 0 versus 8 valid orders without items (so at least one such person has another order with a value): not checked.
- Person with 16 orders (17 including canceled/unavailable) not investigated.
- Total number of review_ids shared across orders not measured; revenue share without a category not measured.
- scripts/load_data.py will fail if re-run now (foreign keys need parents loaded first). Fix before any re-run.
- Query 20 (late sellers) deferred to the dashboard Operations page. Pivot tables not practised (can be done on orders_enriched).

## Next task
1. Run git status -sb and git log --oneline -8; confirm all notebook 02 work is committed and pushed (and the earlier EDA charts 4-5 commit). Save the Word notes (add a 26 Oct row).
2. Step 18b in notebook 02: chi-square test of the repeat-rate gap, on time vs late. Use first (order_number == 1), filtered to order_status == 'delivered' and is_late not null; repeat = person_total_orders > 1; pd.crosstab, then scipy.stats.chi2_contingency. Expected counts close to SQL (85,697 and 7,594 people; 3.07% and 2.52%). Report the effect size (difference in points) next to p; say association, not cause; mention late-in-period customers had less time to return.
3. Repeat rate by delivery experience and by review score (with significance), and the worst states for late delivery (use 500+ customer rule); add a closing summary cell with findings and recommendations.
4. Replicate pieces in SQL with window functions (LAG for time between orders, ROW_NUMBER, RANK, running totals) in sql/06_window_functions.sql.
5. End of Phase 3: update README (findings, approach), this file, and the Word notes.

## Reminders
- Commit after each working step with a clear message.
- Update the README at the end of each phase.
- Update the Word notes at the end of each working day or phase, with a new row in its Update log. Claude reminds.
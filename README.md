# Olist Customer Retention & Delivery Performance Analytics

<!-- CHANGE: Write 2-3 lines in your own words describing the project and its main result.
Fill this in LAST, once you have real findings. -->

> **Status:** Phase 0 (setup) complete. Phase 1 (SQL and Excel fundamentals) starting.

## Business Problem
Olist is a Brazilian e-commerce marketplace where about 97% of customers reportedly buy only once
(to be verified on the data in Phase 1).
This project investigates why customers don't return and what the business can do about it.

**Key questions**
1. Who are the repeat buyers, and how do they differ from one-time buyers?
2. How does delivery performance affect review scores and repeat purchases?
3. Which customer segments and regions offer the biggest retention opportunity?
<!-- CHANGE: edit or add questions as your analysis evolves -->

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle).

- About 100k orders from 2016 to 2018, across 9 relational CSV files
- The CSVs are not stored in this repo. To reproduce the project, download the dataset
  from Kaggle and extract the files into `data/raw/`
- Raw files are never edited; cleaned outputs go to `data/processed/`

## Key Findings
<!-- CHANGE: Add after Phase 3, using real numbers from YOUR analysis. Example:
- X% of customers purchased only once
- Late deliveries lowered average review score from X to Y -->
_Coming soon._

## Dashboard Preview
<!-- CHANGE: Add screenshots after Phase 5, e.g. ![Overview](images/dashboard_overview.png) -->
_Coming soon._

## Tools & Technologies
<!-- CHANGE: Keep this list accurate. Add or remove anything you actually use. -->
| Purpose | Tool |
|---|---|
| Database | MySQL 8.0 (developed on 8.0.43) |
| SQL client | VS Code "Database Client" extension; MySQL Workbench for one-off tasks (ER diagram) |
| Programming | Python 3.x (pandas, NumPy, matplotlib, seaborn, scikit-learn, SciPy, XGBoost, SQLAlchemy, PyMySQL, python-dotenv) |
| Notebooks / editor | VS Code with Jupyter |
| Dashboard | Power BI Desktop |
| Quick analysis | Microsoft Excel |
| Version control | Git, GitHub |
| AI assistants | Claude and ChatGPT, used for guidance, debugging and code review; all code was run and verified by me |

## Setup

**Requirements:** Python 3.10+ (Anaconda), MySQL 8.0+, Git. Built on Windows with PowerShell and VS Code.

1. Clone this repo and open it in VS Code.
2. Download the dataset from Kaggle (see "Data Source") into `data/raw/`.
3. Install the Python libraries listed under Tools & Technologies
   (a `requirements.txt` will be added in Phase 6).
4. Create the database in MySQL:
```sql
   CREATE DATABASE IF NOT EXISTS olist
     CHARACTER SET utf8mb4
     COLLATE utf8mb4_0900_ai_ci;
```
5. Copy `.env.example` to `.env` and fill in your own MySQL details
   (`DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_NAME`). `.env` is git-ignored and never committed.
6. Test the connection:
```powershell
   python scripts\test_connection.py
```
   Expected output: `Connected to database: olist | MySQL version: 8.x.x`

## How to Run
<!-- CHANGE: Update as scripts and notebooks are added. -->
1. Complete the Setup section above.
2. Load the raw CSVs into MySQL with the loader script in `scripts/` _(added in Phase 1)_.
3. Run the SQL files in `sql/` in numbered order.
4. Run the notebooks in `notebooks/` in numbered order.

## Project Structure
```
olist-retention-analytics/
├── data/
│   ├── raw/            # original Kaggle CSVs (not tracked)
│   └── processed/      # cleaned data (not tracked)
├── sql/                # commented SQL queries only (numbered 01_, 02_, ...)
├── scripts/            # runnable Python scripts (connection test, data loading)
├── notebooks/          # Python cleaning, EDA, analysis, modeling
├── dashboard/          # Power BI file
├── reports/            # business summary
├── images/             # screenshots and diagrams
├── PROJECT_CONTEXT.md  # running project notes
├── .env.example        # database settings template (copy to .env)
└── README.md
```

## Approach
<!-- CHANGE: Fill in as you complete each phase. Keep it short and specific. -->
1. **SQL analysis:** _in progress_
2. **Python cleaning & EDA:** _to be completed_
3. **Cohort, RFM and delivery impact analysis:** _to be completed_
4. **Predictive modeling:** _to be completed_
5. **Power BI dashboard:** _to be completed_

## Recommendations
<!-- CHANGE: Add 3-4 business recommendations with estimated impact, after your analysis. -->
_Coming soon._

## Limitations
<!-- CHANGE: Be honest, e.g. class imbalance, only two years of data, no marketing data. -->
_Coming soon._

## About Me
**Karan Patel**

**Data Analyst skilled in Python, SQL, Power BI, and Tableau, focused on data visualization, business insights, ETL, and solving real-world business problems through data.**

LinkedIn: http://www.linkedin.com/in/karan-patel-5a2462271

GitHub: [karanpatel9725-tech](https://github.com/karanpatel9725-tech)
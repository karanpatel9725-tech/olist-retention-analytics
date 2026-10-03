# Olist Customer Retention & Delivery Performance Analytics

<!-- CHANGE: Write 2-3 lines in your own words describing the project and its main result.
Fill this in LAST, once you have real findings. -->

> Status: In progress (Phase 0 of 6: setup) Phase-1 ongoing

## Business Problem
Olist is a Brazilian e-commerce marketplace where about 97% of customers buy only once.
This project investigates why customers don't return and what the business can do about it.

**Key questions**
1. Who are the repeat buyers, and how do they differ from one-time buyers?
2. How does delivery performance affect review scores and repeat purchases?
3. Which customer segments and regions offer the biggest retention opportunity?
<!-- CHANGE: edit or add questions as your analysis evolves -->

## Data source

Brazilian E-Commerce Public Dataset by Olist (Kaggle):
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

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
| Database | MySQL 8.x, MySQL Workbench |
| Programming | Python 3.x (pandas, NumPy, matplotlib, seaborn, scikit-learn, SciPy, XGBoost, SQLAlchemy) |
| Notebooks / editor | VS Code with Jupyter |
| Dashboard | Power BI Desktop |
| Quick analysis | Microsoft Excel |
| Version control | Git, GitHub |
| AI assistants | Claude and ChatGPT, used for guidance, debugging and code review; all code was run and verified by me |

## Dataset
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle), about 100k orders from 2016-2018.
The raw files are not stored in this repo. Download them from Kaggle and place them in `data/raw/`.

## Project Structure
```
olist-retention-analytics/
├── data/
│   ├── raw/            # original Kaggle CSVs (not tracked)
│   └── processed/      # cleaned data (not tracked)
├── sql/                # commented SQL queries
├── notebooks/          # Python cleaning, EDA, analysis, modeling
├── dashboard/          # Power BI file
├── reports/            # business summary
├── images/             # screenshots and diagrams
├── PROJECT_CONTEXT.md  # running project notes
├── .env.example        # database settings template
└── README.md
```

## Approach
<!-- CHANGE: Fill in as you complete each phase. Keep it short and specific. -->
1. **SQL analysis:** _to be completed_
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

## How to Run
1. Clone this repo.
2. Download the dataset from Kaggle into `data/raw/`.
3. Install dependencies: `pip install -r requirements.txt`
4. Copy `.env.example` to `.env` and enter your MySQL details.
5. Run the SQL scripts in `sql/` in numbered order, then the notebooks in `notebooks/` in order.
<!-- CHANGE: Adjust these steps to match what you actually built. -->

## About Me
<!-- CHANGE: Your name, one line about yourself, LinkedIn link, email -->
**Karan Patel**


**Data Analyst skilled in Python, SQL, Power BI, and Tableau, focused on data visualization, business insights, ETL, and solving real-world business problems through data.**

Linkdin: http://www.linkedin.com/in/karan-patel-5a2462271

GitHub: [karanpatel9725-tech](https://github.com/karanpatel9725-tech)
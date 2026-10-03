# Project Context

## Goal
Olist customer retention and delivery performance analytics (portfolio project for data analyst roles).
Business question: ~97% of customers buy only once. Why don't they return, and what can the business do?

## Tools
- Database: MySQL 8 + MySQL Workbench
- Python (Anaconda) in VS Code with Jupyter: pandas, numpy, matplotlib, seaborn, scikit-learn, scipy, xgboost, sqlalchemy, pymysql, python-dotenv
- Power BI Desktop, Excel
- Git + GitHub (repo: olist-retention-analytics)
- OS: Windows, PowerShell terminal in VS Code

## Conventions
- snake_case names; SQL files numbered (01_, 02_, ...)
- Use customer_unique_id (not customer_id) to identify customers
- Credentials live in .env (never committed); .env.example is the template
- Raw data in data/raw (never edited); cleaned data in data/processed
- Database name: olist

## Folder structure
data/raw, data/processed, sql, notebooks, dashboard, reports, images

## Current status
- Current phase: Phase 0 (setup)
- Completed: GitHub repo created and cloned, folder structure created, Python libraries installed and verified, .env and .env.example created

## Key decisions (with reasons)
- (none yet)

## Key findings so far
- (none yet)

## Open issues
- (none yet)

## Next task
1. Commit and push the README and this file
2. Download the Olist dataset from Kaggle into data/raw/
3. Create the `olist` database in MySQL Workbench and test the connection from Python
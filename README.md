# Dynamic Summary Reporting System

A PostgreSQL solution using functions, triggers, and procedures to generate dynamic summary reports from transactional data.

## 🗂️ Overview

Built on the publicly available DVD Rental sample database from Neon Tech, this solution automates the creation of summary-level insights from detailed rental records. It identifies the top 5 films from different genres most frequently co-rented with each category, highlighting cross-category viewing patterns by store. The project demonstrates advanced SQL techniques and automation workflows in PostgreSQL.

## 🔍 Problem Solved

Organizations often need quick access to summarized insights across multiple categories or locations. This project addresses that need by:

- Creating a **transformation function** to simplify store ID data.
- Building a **detailed table** to consolidate transactional data from multiple source tables.
- Constructing a **summary table** to highlight the top 5 films most frequently co-rented by customers alongside each category, per store.
- Using a **trigger and stored procedure** to automatically regenerate the summary when new data is inserted.

## 🛠️ Tools & Technologies

- PostgreSQL (PL/pgSQL)
- SQL window functions (`ROW_NUMBER`)
- Triggers and stored procedures
- Neon Tech PostgreSQL environment

## 📁 Files

- [📄 View SQL Script](https://github.com/Not-Your-Mother/dynamic-summary-reporting/blob/main/dynamic-summary-reporting.sql)  
  Contains table definitions, transformation function, trigger, and procedure logic used to automate the summary reporting process.

## ✅ Key Features

- Dynamic summary generation via trigger and procedure
- Readable ranking of films by category and store
- Clean schema design with reusable transformation logic
- Easily extensible for additional stores or categories

## 👤 Author

**Kimberly D.**  
Aspiring Data Analyst | BSCS Candidate @ WGU | [LinkedIn](https://www.linkedin.com/in/kimberly-d/)  

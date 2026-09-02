# Minor_Project_3

# 🚩 RedFlag: Fraud Detection Using SQL

## 📌 Project Overview

**RedFlag: The Fraud Files** is a SQL-based fraud detection project focused on identifying suspicious transaction patterns from a dataset containing **200,000 transactions**.

The project demonstrates how pure SQL can be used to analyze transactional behavior, detect anomalies, and flag potentially fraudulent users and merchants — without using Machine Learning or Python.

---

## 🎯 Objective

To build a rule-based fraud detection engine using SQL queries that identify different types of suspicious transaction behavior.

The analysis focuses on detecting anomalies based on:

- Transaction frequency
- Transaction amounts
- Failed transactions
- Refund patterns
- Credit and debit behavior
- Merchant activity
- Monthly transaction spikes
- Geographic inconsistencies

---

## 🔍 Fraud Detection Patterns

The project analyzes **12 different fraud patterns**, including:

1. **Velocity Fraud** – Identifying users with unusually high numbers of transactions in a single day.
2. **Transaction Amount Anomalies** – Detecting suspicious transaction amount patterns.
3. **Failed Transaction Spikes** – Identifying users with abnormal numbers of failed transactions.
4. **Time-Based Anomalies** – Detecting suspicious transaction activity based on timing patterns.
5. **Refund Abuse** – Identifying unusual or excessive refund behavior.
6. **Credit-Debit Imbalance** – Detecting suspicious imbalances between credit and debit transactions.
7. **Threshold Amount Abuse** – Identifying repeated transactions around suspicious amount thresholds.
8. **Merchant Collusion** – Detecting merchants where a small group of users accounts for a disproportionately large percentage of transaction volume.
9. **Merchant Activity Analysis** – Identifying suspicious patterns associated with merchant transactions.
10. **High-Risk Transaction Patterns** – Detecting abnormal transactional behavior using aggregated analysis.
11. **Monthly Transaction Spike** – Identifying users whose transaction activity in a single month is significantly higher than their average monthly activity.
12. **Impossible Travel** – Detecting users making transactions from geographically inconsistent locations within unrealistic timeframes.

---

## 🛠️ SQL Concepts Used

This project applies several SQL techniques, including:

- Common Table Expressions (CTEs)
- Window Functions
- `ROW_NUMBER()`
- `LAG()`
- Aggregate Functions
- `SUM()`, `COUNT()`, `AVG()`, `MAX()`
- `GROUP BY`
- `HAVING`
- `CASE` Statements
- Date and Time Functions
- Ranking and Partitioning
- Joins
- Subqueries

---

## 📊 Key Findings

The analysis successfully identified suspicious users and merchants across multiple fraud patterns.

Some patterns detected high transaction velocity, abnormal monthly activity, excessive transaction concentration among a small group of users, and geographically inconsistent transaction behavior. The results demonstrate how SQL-based rule detection can effectively identify anomalies that may require further investigation.

---

## 💻 Tools Used

- **MySQL**
- **MySQL Workbench**
- **SQL**

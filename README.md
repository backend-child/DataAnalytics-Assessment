### Question 1: High-Value Customers with Multiple Products

**Objective**:  
Identify customers who have both a funded savings plan and a funded investment plan, sorted by their total deposits.

---

**My Approach**:
1. I used two Common Table Expressions (CTEs) to separately calculate:
   - Number of funded savings plans and total deposits for each user
   - Number of funded investment plans and total deposits for each user

2. In each CTE:
   - I defined "funded" as a `new_balance > 0` (for savings) and `amount > 0` (for investments).
   - This definition was a challenge — it was not directly stated, so I made a reasonable assumption based on typical financial practices.

3. Finally, I joined the two CTEs with the main `users_customuser` table to:
   - Get the user's full name
   - Combine their savings and investment totals
   - Sort them by their total deposit value

---

**Challenges & Considerations**:
- Initially, I was unsure what "funded" meant in the context of a plan. I resolved this by assuming that any account or plan with a positive balance or amount was funded.
- Some column and table names in the provided schema were unclear or misspelled, so I corrected them based on typical naming conventions (`savings_savingsaccount`, `plans_plan`).
- I chose to use `COALESCE` to handle cases where users might not have both `first_name` and `last_name`.

---

**Result**:
This query returns a list of users who have cross-product activity (savings + investment), sorted by how much total money they have in the system.

### QUESTION 2 >> Transaction Frequency Analysis — SQL Solution

## 📌 Objective
The finance team wanted to segment customers based on how frequently they perform transactions monthly. The categories were:

- **High Frequency**: ≥ 10 transactions/month
- **Medium Frequency**: 3–9 transactions/month
- **Low Frequency**: ≤ 2 transactions/month

## 🧠 Approach

To achieve this, I used a single SQL query with three Common Table Expressions (CTEs):

---

### 1️⃣ MonthlyTransactionCounts

- I grouped all transactions by customer (`owner_id`) and by month using `DATE_FORMAT(transaction_date, '%Y-%m')`.
- I used `COUNT(*)` to calculate how many times each customer transacted per month.

---

### 2️⃣ CustomerMonthlyAverages

- From the first step, I calculated the **average monthly transactions** for each customer using `AVG(monthly_tx_count)`.

---

### 3️⃣ FrequencyCategorized

- Based on the average per customer, I applied a `CASE` statement to label them into:
  - **High Frequency** (≥10)
  - **Medium Frequency** (3–9)
  - **Low Frequency** (≤2)

---

### ✅ Final Aggregation

- I grouped by frequency category and returned:
  - `customer_count`: Total users in each group.
  - `avg_transactions_per_month`: Average of averages (rounded to 1 decimal place).
- I ordered the result using `FIELD()` to keep the expected order (High, Medium, Low).

---

## ⚠️ Problems I Encountered & Solved

| Problem | How I Solved It |
|--------|------------------|
| Incorrect join to `plans_plan` table  | I realized `plans_plan` wasn't needed to compute transaction frequency. |
| Wrong date formatting | I used `DATE_FORMAT(transaction_date, '%Y-%m')` to group monthly. |
| Grouping logic | Initially grouped by full datetime, which gave wrong counts. Fixed by grouping per month. |
| Decimal issues | Used `ROUND(..., 1)` for clean numeric presentation. |


### QUESTION 3 >>  🛑 Account Inactivity Alert - SQL Analysis
## 🧠 Scenario
The ops team requested an analysis to **flag all inactive account** that haven't had any **inflow transactions for over 365 days**. The idea was to help the business identify dormant users and potentially re-engage them.

At first, this sounded straightforward — just “check for inactive accounts,” right? But once I got into the actual structure of the data and what “inactivity” really means in this context, it required a lot more careful thinking.

---

## 🎯 Goal (As I Understood It)

Write a **single SQL query** that:
- Joins relevant tables to get all savings and investment plans.
- Checks for **confirmed inflows only**.
- Returns plans where **no inflow has occurred in over a year**.
- Includes even those plans that have **never had any inflow**.

The main challenge was not just writing a query that works, but one that works **accurately** across all edge cases (e.g., no transactions at all, only withdrawals, wrongly marked plan types, etc.).

---

## 🧩 What I Found in the Schema

After checking the database schema, here’s what I worked with:

### 📘 Table: `plans_plan`
- `id`: Unique ID for the plan.
- `owner_id`: Refers to the user who owns the plan.
- `is_regular_savings`: Boolean flag — 1 if it’s a savings plan.
- `is_fixed_investment`: Boolean flag — 1 if it’s an investment.

At first, I thought I’d use `plan_type_id`, but after inspecting more data, I realized that was less reliable and **switched to using these boolean flags** — they were much clearer for classifying plan types.

### 📘 Table: `savings_savingsaccount`
- `savings_id`: FK back to `plans_plan`.
- `transaction_date`: Date the inflow occurred.
- `confirmed_amount`: The actual inflow amount. I noticed this was in **kobo**, but for the purpose of checking inactivity, I only cared whether it's **greater than 0**.

---

## 🛠️ My Thought Process & Steps

### 1. **Understand what "no transaction in the last 365 days" really means**  
I realized that this wasn’t just about the last transaction — it had to be:
- Only **confirmed inflow** transactions
- Measured from today (`CURDATE()`)
- Including **plans with no transactions at all** (which could easily be missed with an INNER JOIN)

### 2. **Plan Type Filtering**  
Originally, I thought of using `plan_type_id`, but then found `is_regular_savings` and `is_fixed_investment`. These were **much more explicit**, and I could now clearly label each row as either "Savings" or "Investment".

### 3. **The Join Strategy**  
I used a `LEFT JOIN` between `plans_plan` and `savings_savingsaccount` because:
- I wanted to **preserve all plans**, even those without any transaction.
- If I had used an `INNER JOIN`, I would’ve unintentionally removed plans with zero transactions — **exactly the kind of plans I needed to flag**.

### 4. **Handling Inflow Transactions**  
I filtered the join using `confirmed_amount > 0` to ensure I’m only looking at **confirmed inflow** transactions — not withdrawals, not failed attempts.

### 5. **Finding the Last Inflow**  
To determine when the last inflow happened per plan, I used `MAX(transaction_date)`. This also helped me catch plans with no inflow — since `MAX(...)` would return `NULL`, I could then calculate inactivity from there.

### 6. **Final Filtering (HAVING Clause)**  
Here’s where it got a bit tricky:
- For plans with **no inflow at all**, `MAX(...)` is `NULL` — so I had to check for that.
- For plans that had inflows but **nothing in the last 365 days**, I used `DATEDIFF(CURDATE(), MAX(transaction_date)) > 365`.

This dual condition inside the `HAVING` clause finally gave me what I needed.
## ⚠️ Challenges I Faced

1. **Mistaking Plan Classification**  
Initially went with `plan_type_id`, but didn’t fully understand what each value represented. Switched to using boolean flags like `is_regular_savings`, which felt safer and clearer.

2. **Missed Edge Cases in Join**  
My first attempt used an `INNER JOIN` and missed all plans with no inflow. Took me a while to realize these were excluded and that I needed a `LEFT JOIN` to bring them back.

3. **NULL Logic in HAVING Clause**  
This tripped me up — I was filtering `DATEDIFF()` without considering that `MAX(...)` could be `NULL`. Had to explicitly account for both `NULL` and `> 365` conditions.

4. **Time Formatting**  
Checked the date format of `transaction_date` and `created_on` to ensure consistent comparison using `DATEDIFF(CURDATE(), ...)`.

### QUESTION 4>>> 🧮 Customer Lifetime Value (CLV) Estimation - SQL Analysis
## 📘 Scenario

The marketing team wanted a simple but reliable way to estimate **Customer Lifetime Value (CLV)**.  
The goal was to calculate how valuable each customer has been based on their transaction history and how long they’ve been active.

I was asked to:
- Calculate how many months a customer has had their account
- Sum all their inflow transactions
- Apply a given CLV formula to estimate value
- Present this in a single SQL query, ordered by highest CLV

---

## 🎯 Objective

The CLV formula I was given looked like this:

CLV = (total_transactions / tenure_months) * 12 * avg_profit_per_transaction



Where:
- `total_transactions` is the sum of all **confirmed inflow** amounts
- `tenure_months` is the number of months since the user signed up
- `avg_profit_per_transaction` was given as 0.1%, or `0.001`

---

## 🔍 Tables Used

### `users_customuser`
- `id` → User ID
- `first_name`, `last_name` → Used to build full name
- `date_joined` → Used to calculate how long the account has been active

### `savings_savingsaccount`
- `owner_id` → Foreign key that links to `users_customuser.id`
- `confirmed_amount` → Transaction inflow (in **kobo**)
- `transaction_date` → When the transaction happened (not needed for this query)

---

## 🛠 Thought Process & Challenges

### 🧠 Understanding the Metric

At first, I had to sit with the CLV formula for a bit to fully understand it.  
It was mixing **time** and **money**, which made me pause and break it down in plain English.

I realized I needed to:
- Get the customer’s **account tenure in months**, using `DATEDIFF` between today and `date_joined`, and then dividing by 30.
- **Sum up all confirmed inflow amounts** — but not in kobo! I had to convert it to **naira** to make sense for real-world use.

```sql
SUM(s.confirmed_amount) / 100


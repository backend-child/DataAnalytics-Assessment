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

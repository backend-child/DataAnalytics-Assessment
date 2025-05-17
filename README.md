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

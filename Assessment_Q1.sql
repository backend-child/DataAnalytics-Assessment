-- Q1: Identify high-value customers with both a funded savings and investment plan

-- Step 1: Create a summary for users who have at least one "funded" savings plan
WITH UserFundedSavingsSummary AS (
    SELECT
        sa.owner_id,
        COUNT(DISTINCT sa.plan_id) AS num_funded_savings_plans,
        
        -- Convert total savings from kobo to naira
        ROUND(SUM(sa.new_balance) / 100.0, 2) AS total_savings_deposits
    FROM
        savings_savingsaccount sa
    WHERE
        sa.new_balance > 0  -- Considered funded if new_balance is greater than zero
    GROUP BY
        sa.owner_id
),

-- Step 2: Create a summary for users with at least one "funded" investment plan
UserFundedInvestmentsSummary AS (
    SELECT
        pa.owner_id,
        COUNT(DISTINCT pa.id) AS num_funded_investment_plans,
        
        -- Convert total investment amount from kobo to naira
        ROUND(SUM(pa.amount) / 100.0, 2) AS total_investment_deposits
    FROM
        plans_plan pa
    WHERE
        pa.amount > 0  -- Considered funded if amount is greater than zero
    GROUP BY
        pa.owner_id
)

-- Step 3: Join users with both funded savings and investment plans
SELECT
    u.id AS owner_id,
    CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) AS name,
    
    ufs.num_funded_savings_plans AS savings_count,
    ufi.num_funded_investment_plans AS investment_count,

    -- Sum total deposits in naira (already converted above)
    ROUND((ufs.total_savings_deposits + ufi.total_investment_deposits), 2) AS total_deposits
FROM
    users_customuser u
INNER JOIN
    UserFundedSavingsSummary ufs ON u.id = ufs.owner_id
INNER JOIN
    UserFundedInvestmentsSummary ufi ON u.id = ufi.owner_id
ORDER BY
    total_deposits DESC;

-- The goal is to find all active plans (Savings or Investment) 
-- that have had NO inflow transactions in the last 365 days.

SELECT
    p.id AS plan_id,                          -- ID of the plan
    p.owner_id,                               -- Owner of the plan (FK to users)
    
    -- Determine if it's a Savings or Investment plan
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_fixed_investment = 1 THEN 'Investment'
        ELSE 'Unknown'
    END AS type,

    -- Get the most recent inflow transaction for this plan
    MAX(s.transaction_date) AS last_transaction_date,

    -- Calculate number of days since the last transaction
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days

FROM
    plans_plan p

-- Left join to include plans with no transactions at all
LEFT JOIN savings_savingsaccount s
    ON p.id = s.savings_id
    AND s.confirmed_amount > 0   -- Only consider confirmed inflow transactions

WHERE
    -- Focus only on Savings and Investment plans
    (p.is_regular_savings = 1 OR p.is_fixed_investment = 1)

GROUP BY
    p.id, p.owner_id, p.is_regular_savings, p.is_fixed_investment

HAVING
    -- Only include plans that have been inactive for over 365 days
    (MAX(s.transaction_date) IS NULL OR DATEDIFF(CURDATE(), MAX(s.transaction_date)) > 365);

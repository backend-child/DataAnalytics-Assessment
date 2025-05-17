SELECT 
    p.id AS plan_id,                        -- Unique identifier for each plan
    p.owner_id,                            -- The user who owns the plan
    CASE                                   -- Determine the type of plan based on plan_type_id
        WHEN p.plan_type_id = 1 THEN 'Savings'
        WHEN p.plan_type_id = 2 THEN 'Investment'
        ELSE 'Unknown'
    END AS type,
    MAX(s.transaction_date) AS last_transaction_date,   -- Get the latest inflow transaction date for each plan
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days  -- Calculate days since last transaction
FROM 
    plans_plan p
LEFT JOIN 
    savings_savingsaccount s 
    ON s.savings_id = p.id 
    AND s.confirmed_amount > 0             -- Only consider inflow transactions (confirmed_amount > 0)
GROUP BY 
    p.id, p.owner_id, p.plan_type_id       -- Group by unique plan and owner to aggregate by plan
HAVING 
    last_transaction_date IS NULL          -- Case 1: No inflow transaction exists at all
    OR DATEDIFF(CURDATE(), last_transaction_date) > 365  -- Case 2: Last inflow is older than 365 days

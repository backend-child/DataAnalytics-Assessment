SELECT 
    u.id AS customer_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,

    -- Step 1: Calculate account tenure in full months since signup
    FLOOR(DATEDIFF(CURDATE(), u.date_joined) / 30) AS tenure_months,

    -- Step 2: Total transaction volume per customer (in naira since confirmed_amount is in kobo)
    ROUND(SUM(s.confirmed_amount) / 100, 2) AS total_transactions,

    -- Step 3: Estimate CLV using the formula: 
    -- (total_transactions / tenure_months) * 12 * 0.001
    -- Assumes avg profit per transaction = 0.1% = 0.001
    ROUND(
        (
            (SUM(s.confirmed_amount) / 100) / 
            NULLIF(FLOOR(DATEDIFF(CURDATE(), u.date_joined) / 30), 0)
        ) * 12 * 0.001,
        2
    ) AS estimated_clv

FROM users_customuser u

-- Join savings transactions to users by user ID
LEFT JOIN savings_savingsaccount s
    ON u.id = s.owner_id

-- Only consider confirmed inflow transactions
WHERE s.confirmed_amount > 0

GROUP BY u.id, u.first_name, u.last_name, u.date_joined

-- Order by highest estimated customer lifetime value
ORDER BY estimated_clv DESC;

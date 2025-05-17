-- Step 1: Calculate monthly transaction count for each customer
WITH MonthlyTransactionCounts AS (
    SELECT 
        owner_id,  -- Customer identifier
        DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,  -- Extract year and month from datetime
        COUNT(*) AS monthly_tx_count  -- Count number of transactions for that month
    FROM 
        savings_savingsaccount
    WHERE 
        transaction_date IS NOT NULL  -- Avoid null transaction dates
    GROUP BY 
        owner_id, transaction_month
),

-- Step 2: Calculate average monthly transactions per customer
CustomerMonthlyAverages AS (
    SELECT 
        owner_id,
        AVG(monthly_tx_count) AS avg_transactions_per_month  -- Compute customer's average monthly transaction count
    FROM 
        MonthlyTransactionCounts
    GROUP BY 
        owner_id
),

-- Step 3: Classify customers based on frequency thresholds
FrequencyCategorized AS (
    SELECT
        owner_id,
        avg_transactions_per_month,
        CASE 
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'  -- 10 or more transactions
            WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'  -- 3 to 9 transactions
            ELSE 'Low Frequency'  -- 2 or fewer transactions
        END AS frequency_category
    FROM 
        CustomerMonthlyAverages
)

-- Step 4: Aggregate and produce final result
SELECT 
    frequency_category,  -- Final label (High/Medium/Low)
    COUNT(*) AS customer_count,  -- Total number of customers in each group
    ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month  -- Average across the group
FROM 
    FrequencyCategorized
GROUP BY 
    frequency_category
ORDER BY 
    FIELD(frequency_category, 'High Frequency', 'Medium Frequency', 'Low Frequency');  -- Custom sort order

-- ============================================================
-- RedFlag - Fraud Detection Submission
-- Student: Aparna Krishnan | Batch: DS-1
-- ============================================================


USE redflag;

-- ============================================================
-- PATTERN 1 · VELOCITY FRAUD
-- What I'm looking for: users with 30+ transactions in a single day
-- Expected suspects: ~50
-- ============================================================
SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(*) AS daily_txn_count
FROM transactions
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY daily_txn_count DESC;

-- Findings: 50 suspects found.There are 30 seeded fraudsters plus ~15-25 
-- legitimate power users who occasionally hit the threshold 
-- this false-positive rate is realistic.

-- ============================================================
-- PATTERN 2 - ROUND-AMOUNT CLUSTERING
-- Looking for users who repeatedly make transactions involving
-- suspiciously frequent round amounts.

-- ============================================================

SELECT
    user_id,
    COUNT(*) AS round_txn_count
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_txn_count DESC;

-- Findings: 25 suspects


-- ============================================================
-- PATTERN 3 · CARD TESTING
-- What I'm looking for: users with 30+ transactions under ₹10
-- in a single day
-- Expected suspects: Exactly 20 (all seeded)
-- ============================================================

SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(*) AS tiny_txn_count
FROM transactions
WHERE amount < 10
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY tiny_txn_count DESC;

-- Findings: 20 suspects.


-- ============================================================
-- PATTERN 4 · FAILED-THEN-SUCCEEDED
-- What I'm looking for: users with 20+ FAILED transactions,
-- or advanced: 20+ FAILED→SUCCESS pairs of the same amount
-- within 2 minutes
-- Expected suspects: Exactly 25 (all seeded)
-- ============================================================

SELECT
    f.user_id,
    COUNT(*) AS failed_then_success_pairs
FROM transactions AS f
WHERE f.status = 'FAILED'
  AND EXISTS (
      SELECT 1
      FROM transactions AS s
      WHERE s.user_id = f.user_id
        AND s.status = 'SUCCESS'
        AND s.amount = f.amount
        AND s.txn_time > f.txn_time
        AND s.txn_time <= f.txn_time + INTERVAL 2 MINUTE
  )
GROUP BY f.user_id
HAVING COUNT(*) >= 20
ORDER BY failed_then_success_pairs DESC;

-- Findings: 25 suspects.


-- ============================================================
-- PATTERN 5 · ODD-HOUR CONCENTRATION
-- What I'm looking for: users with 80%+ of their transactions
-- occurring between 02:00 and 04:59, with at least 30 total
-- transactions
-- Expected suspects: Exactly 20 (all seeded)
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS total_txns,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) AS odd_hour_txns,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS odd_hour_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND SUM(
       CASE
           WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
           ELSE 0
       END
   ) / COUNT(*) >= 0.80
ORDER BY odd_hour_percentage DESC;

-- Findings: 20 suspects.


-- ============================================================
-- PATTERN 6 · MULE ACCOUNTS
-- What I'm looking for: users with at least 5 CREDIT transactions
-- followed within 30 minutes by a DEBIT worth at least 70%
-- of the CREDIT amount
-- Expected suspects: Exactly 30 (all seeded)
-- ============================================================

SELECT
    c.user_id,
    COUNT(*) AS credit_to_debit_instances
FROM transactions AS c
WHERE c.txn_type = 'CREDIT'
  AND EXISTS (
      SELECT 1
      FROM transactions AS d
      WHERE d.user_id = c.user_id
        AND d.txn_type = 'DEBIT'
        AND d.txn_time > c.txn_time
        AND d.txn_time <= c.txn_time + INTERVAL 30 MINUTE
        AND d.amount >= 0.70 * c.amount
  )
GROUP BY c.user_id
HAVING COUNT(*) >= 5
ORDER BY credit_to_debit_instances DESC;

-- Findings: 30 suspects.


-- ============================================================
-- PATTERN 7 · REFUND ABUSE
-- What I'm looking for: users with at least 20 transactions where
-- more than 40% of their transactions are REFUND transactions
-- Expected suspects: ~24–25
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS total_txns,
    SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) AS refund_txns,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN txn_type = 'REFUND' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS refund_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND SUM(
       CASE
           WHEN txn_type = 'REFUND' THEN 1
           ELSE 0
       END
   ) / COUNT(*) > 0.40
ORDER BY refund_percentage DESC;

-- Findings: 24 suspects.


-- ============================================================
-- PATTERN 8 · MERCHANT COLLUSION
-- What I'm looking for: merchants where the top 5 users account
-- for more than 60% of the merchant's total transaction value
-- Expected suspects: Exactly 15 merchants (all seeded)
-- ============================================================

WITH user_merchant_volume AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_volume
    FROM transactions
    GROUP BY merchant_id, user_id
),
ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_volume,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_volume DESC
        ) AS user_rank
    FROM user_merchant_volume
),
merchant_totals AS (
    SELECT
        merchant_id,
        SUM(user_volume) AS merchant_volume
    FROM user_merchant_volume
    GROUP BY merchant_id
),
top_five AS (
    SELECT
        merchant_id,
        SUM(user_volume) AS top_five_volume
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY merchant_id
)
SELECT
    t.merchant_id,
    t.top_five_volume,
    m.merchant_volume,
    ROUND(
        100.0 * t.top_five_volume / m.merchant_volume,
        2
    ) AS top_five_percentage
FROM top_five AS t
JOIN merchant_totals AS m
    ON t.merchant_id = m.merchant_id
WHERE t.top_five_volume / m.merchant_volume > 0.60
ORDER BY top_five_percentage DESC;

-- Findings: 15 merchants were flagged for potential collusion.
-- For these merchants, just five users accounted for more than 60% of the total
-- transaction value, indicating an unusually high concentration of activity.


-- ============================================================
-- PATTERN 9 · THRESHOLD AMOUNT ABUSE
-- What I'm looking for: users with repeated transactions at the
-- suspicious threshold amount of ₹9999
-- Expected suspects: Seeded users repeatedly exploiting the threshold
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS threshold_txn_count
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_txn_count DESC;

-- Findings: 20 suspects.


-- ============================================================
-- PATTERN 10 · DORMANT ACCOUNT REACTIVATION
-- What I'm looking for: users who suddenly become highly active after
-- a long period of inactivity
-- Expected suspects: Users with 15+ transactions after a significant gap
-- ============================================================

WITH ordered_txns AS (
    SELECT
        user_id,
        txn_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
),
dormant_gaps AS (
    SELECT
        user_id,
        txn_time AS restart_time,
        previous_txn_time,
        TIMESTAMPDIFF(DAY, previous_txn_time, txn_time) AS gap_days
    FROM ordered_txns
    WHERE previous_txn_time IS NOT NULL
      AND TIMESTAMPDIFF(DAY, previous_txn_time, txn_time) >= 90
),
post_gap_activity AS (
    SELECT
        g.user_id,
        g.restart_time,
        g.gap_days,
        COUNT(t.txn_id) AS post_gap_txns
    FROM dormant_gaps AS g
    JOIN transactions AS t
        ON t.user_id = g.user_id
       AND t.txn_time > g.restart_time
    GROUP BY g.user_id, g.restart_time, g.gap_days
)
SELECT
    user_id,
    restart_time,
    gap_days,
    post_gap_txns
FROM post_gap_activity
WHERE post_gap_txns >= 15
ORDER BY post_gap_txns DESC;

-- Findings: 26 suspects.


-- ============================================================
-- PATTERN 11 · MONTHLY TRANSACTION SPIKE
-- What I'm looking for: users whose transaction activity in one month
-- is more than 5 times their average monthly activity
-- Expected suspects: Exactly 3 users with extreme monthly spikes
-- ============================================================

WITH monthly_counts AS (
    SELECT
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS txn_month,
        COUNT(*) AS monthly_txns
    FROM transactions
    GROUP BY
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m')
),
user_stats AS (
    SELECT
        user_id,
        MAX(monthly_txns) AS peak_monthly_txns,
        AVG(monthly_txns) AS average_monthly_txns
    FROM monthly_counts
    GROUP BY user_id
)
SELECT
    user_id,
    ROUND(average_monthly_txns, 2) AS average_monthly_txns,
    peak_monthly_txns,
    ROUND(
        peak_monthly_txns / average_monthly_txns,
        2
    ) AS peak_to_average_ratio
FROM user_stats
WHERE peak_monthly_txns >= 20
    AND peak_monthly_txns / average_monthly_txns > 5
ORDER BY peak_to_average_ratio DESC;

-- Findings: 3 users were flagged with extreme monthly spikes.
-- User 14517 had 41 peak monthly transactions compared with an
-- average of 8.00, giving a ratio of 5.13.


-- ============================================================
-- PATTERN 12 · IMPOSSIBLE TRAVEL
-- What I'm looking for: users making transactions from locations that
-- suggest unrealistic travel between consecutive transactions
-- Expected suspects: Users with multiple impossible travel events
-- ============================================================

WITH ordered_txns AS (
    SELECT
        user_id,
        txn_id,
        txn_time,
        city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_city
    FROM transactions
),
impossible_travel AS (
    SELECT
        user_id,
        txn_id,
        txn_time,
        city,
        previous_txn_time,
        previous_city
    FROM ordered_txns
    WHERE previous_city IS NOT NULL
        AND city <> previous_city
        AND TIMESTAMPDIFF(
            MINUTE,
            previous_txn_time,
            txn_time
        ) <= 60
)
SELECT
    user_id,
    COUNT(*) AS impossible_travel_events
FROM impossible_travel
GROUP BY user_id
ORDER BY impossible_travel_events DESC;

-- Findings: 15 users were flagged for suspicious travel patterns.
-- User 14755 had 8 impossible travel events, while users 14756
-- and 14746 had 7 events each.
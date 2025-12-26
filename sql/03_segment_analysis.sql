-- ==============================
-- 03_segment_analysis.sql
-- Purpose: Identify HIGH-RISK segments + actionable target lists
-- ==============================

-- 1) Build a risk segmentation view (rule-based, business-friendly)
WITH scored AS (
  SELECT
    *,
    -- Risk flags (simple and explainable)
    CASE WHEN last_login_days_ago >= 14 THEN 1 ELSE 0 END AS f_inactive,
    CASE WHEN monthly_logins <= 8 THEN 1 ELSE 0 END AS f_low_logins,
    CASE WHEN weekly_active_days <= 2 THEN 1 ELSE 0 END AS f_low_weekly_activity,
    CASE WHEN payment_failures >= 2 THEN 1 ELSE 0 END AS f_payment_risk,
    CASE WHEN support_tickets >= 3 THEN 1 ELSE 0 END AS f_support_risk,
    CASE WHEN csat_score <= 3.0 THEN 1 ELSE 0 END AS f_low_csat,
    CASE WHEN escalations >= 1 THEN 1 ELSE 0 END AS f_escalated,
    CASE WHEN usage_growth_rate < 0 THEN 1 ELSE 0 END AS f_declining_usage,
    CASE WHEN price_increase_last_3m = TRUE THEN 1 ELSE 0 END AS f_price_increase
  FROM customers
),
risked AS (
  SELECT
    *,
    (f_inactive + f_low_logins + f_low_weekly_activity + f_payment_risk + f_support_risk + f_low_csat + f_escalated + f_declining_usage + f_price_increase) AS risk_score,
    CASE
      WHEN (f_inactive + f_low_logins + f_low_weekly_activity + f_payment_risk + f_support_risk + f_low_csat + f_escalated + f_declining_usage + f_price_increase) >= 5 THEN 'High'
      WHEN (f_inactive + f_low_logins + f_low_weekly_activity + f_payment_risk + f_support_risk + f_low_csat + f_escalated + f_declining_usage + f_price_increase) >= 3 THEN 'Medium'
      ELSE 'Low'
    END AS risk_bucket
  FROM scored
)
SELECT
  risk_bucket,
  COUNT(*) AS customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct,
  ROUND(AVG(monthly_fee), 2) AS avg_monthly_fee,
  ROUND(SUM(monthly_fee), 2) AS total_monthly_fee
FROM risked
GROUP BY risk_bucket
ORDER BY churn_rate_pct DESC;

-- 2) Top high-risk combinations (what’s driving churn the most)
WITH risked AS (
  SELECT
    *,
    CASE
      WHEN tenure_months < 6 THEN '0-5 months'
      WHEN tenure_months < 12 THEN '6-11 months'
      WHEN tenure_months < 24 THEN '12-23 months'
      ELSE '24+ months'
    END AS tenure_bucket,
    CASE
      WHEN monthly_logins <= 8 THEN 'Low Logins'
      WHEN monthly_logins <= 20 THEN 'Medium Logins'
      ELSE 'High Logins'
    END AS login_bucket,
    CASE
      WHEN last_login_days_ago >= 14 THEN 'Inactive 14+ days'
      WHEN last_login_days_ago >= 7 THEN 'Inactive 7-13 days'
      ELSE 'Active <7 days'
    END AS recency_bucket
  FROM customers
)
SELECT
  tenure_bucket,
  login_bucket,
  recency_bucket,
  contract_type,
  COUNT(*) AS customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct,
  ROUND(SUM(monthly_fee), 2) AS monthly_fee_sum
FROM risked
GROUP BY tenure_bucket, login_bucket, recency_bucket, contract_type
HAVING COUNT(*) >= 50
ORDER BY churn_rate_pct DESC, customers DESC
LIMIT 20;

-- 3) Target list: customers likely to churn (actionable outreach list)
-- NOTE: In a real company you’d export this list to CRM / email campaigns.
WITH risked AS (
  SELECT
    *,
    CASE
      WHEN (last_login_days_ago >= 14) THEN 1 ELSE 0 END AS f_inactive,
    CASE
      WHEN (monthly_logins <= 8) THEN 1 ELSE 0 END AS f_low_logins,
    CASE
      WHEN (payment_failures >= 2) THEN 1 ELSE 0 END AS f_payment_risk,
    CASE
      WHEN (support_tickets >= 3 OR escalations >= 1 OR csat_score <= 3.0) THEN 1 ELSE 0 END AS f_support_risk
  FROM customers
),
targets AS (
  SELECT
    customer_id,
    country,
    city,
    customer_segment,
    contract_type,
    signup_channel,
    tenure_months,
    monthly_fee,
    total_revenue,
    payment_failures,
    support_tickets,
    csat_score,
    escalations,
    monthly_logins,
    last_login_days_ago,
    (f_inactive + f_low_logins + f_payment_risk + f_support_risk) AS simple_risk_score
  FROM risked
)
SELECT *
FROM targets
WHERE simple_risk_score >= 3
ORDER BY simple_risk_score DESC, total_revenue DESC
LIMIT 200;

-- 4) “What to do” mapping (business recommendations by driver)
WITH base AS (
  SELECT
    *,
    CASE
      WHEN payment_failures >= 2 THEN 'Billing/Payment'
      WHEN (support_tickets >= 3 OR escalations >= 1 OR csat_score <= 3.0) THEN 'Support Experience'
      WHEN last_login_days_ago >= 14 THEN 'Low Engagement'
      WHEN usage_growth_rate < 0 THEN 'Declining Usage'
      WHEN price_increase_last_3m = TRUE THEN 'Pricing Sensitivity'
      ELSE 'Other'
    END AS primary_driver
  FROM customers
)
SELECT
  primary_driver,
  COUNT(*) AS customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct,
  ROUND(SUM(monthly_fee), 2) AS monthly_revenue_in_segment
FROM base
GROUP BY primary_driver
ORDER BY churn_rate_pct DESC;

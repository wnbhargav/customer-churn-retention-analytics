-- ==============================
-- 02_kpi_metrics.sql
-- Purpose: Core churn KPIs + churn drivers + revenue at risk
-- ==============================

-- 1) Overall KPIs
SELECT
  COUNT(*) AS total_customers,
  SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct,
  ROUND(AVG(monthly_fee), 2) AS avg_monthly_fee,
  ROUND(AVG(total_revenue), 2) AS avg_total_revenue
FROM customers;

-- 2) Revenue at risk (simple + readable)
SELECT
  ROUND(SUM(CASE WHEN churn = 1 THEN monthly_fee ELSE 0 END), 2) AS monthly_revenue_at_risk,
  ROUND(SUM(CASE WHEN churn = 1 THEN total_revenue ELSE 0 END), 2) AS total_revenue_at_risk,
  ROUND(AVG(CASE WHEN churn = 1 THEN monthly_fee END), 2) AS avg_monthly_fee_churned
FROM customers;

-- 3) Churn by contract type
SELECT
  contract_type,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN churn=1 THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY contract_type
ORDER BY churn_rate_pct DESC;

-- 4) Churn by signup channel
SELECT
  signup_channel,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN churn=1 THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY signup_channel
ORDER BY churn_rate_pct DESC;

-- 5) Churn by customer segment
SELECT
  customer_segment,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN churn=1 THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY customer_segment
ORDER BY churn_rate_pct DESC;

-- 6) Tenure buckets (early churn is common in subscription businesses)
WITH base AS (
  SELECT
    *,
    CASE
      WHEN tenure_months < 6 THEN '0-5 months'
      WHEN tenure_months < 12 THEN '6-11 months'
      WHEN tenure_months < 24 THEN '12-23 months'
      WHEN tenure_months < 48 THEN '24-47 months'
      ELSE '48+ months'
    END AS tenure_bucket
  FROM customers
)
SELECT
  tenure_bucket,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN churn=1 THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct,
  ROUND(AVG(monthly_fee), 2) AS avg_monthly_fee
FROM base
GROUP BY tenure_bucket
ORDER BY
  CASE tenure_bucket
    WHEN '0-5 months' THEN 1
    WHEN '6-11 months' THEN 2
    WHEN '12-23 months' THEN 3
    WHEN '24-47 months' THEN 4
    ELSE 5
  END;

-- 7) Usage / engagement drivers (activity + recency)
WITH base AS (
  SELECT
    *,
    CASE
      WHEN monthly_logins <= 5 THEN 'Very Low'
      WHEN monthly_logins <= 12 THEN 'Low'
      WHEN monthly_logins <= 25 THEN 'Medium'
      ELSE 'High'
    END AS login_bucket,
    CASE
      WHEN last_login_days_ago <= 3 THEN '0-3 days'
      WHEN last_login_days_ago <= 7 THEN '4-7 days'
      WHEN last_login_days_ago <= 14 THEN '8-14 days'
      ELSE '15+ days'
    END AS recency_bucket
  FROM customers
)
SELECT
  login_bucket,
  recency_bucket,
  COUNT(*) AS customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct
FROM base
GROUP BY login_bucket, recency_bucket
ORDER BY churn_rate_pct DESC, customers DESC;

-- 8) Billing & payment risk
SELECT
  payment_method,
  COUNT(*) AS total_customers,
  ROUND(AVG(payment_failures), 2) AS avg_payment_failures,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- 9) Price increase + discount impact
SELECT
  price_increase_last_3m,
  discount_applied,
  COUNT(*) AS customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct,
  ROUND(AVG(monthly_fee), 2) AS avg_monthly_fee
FROM customers
GROUP BY price_increase_last_3m, discount_applied
ORDER BY churn_rate_pct DESC;

-- 10) Support drivers (tickets, CSAT, escalations, resolution time)
WITH base AS (
  SELECT
    *,
    CASE
      WHEN support_tickets = 0 THEN '0'
      WHEN support_tickets <= 2 THEN '1-2'
      WHEN support_tickets <= 5 THEN '3-5'
      ELSE '6+'
    END AS ticket_bucket,
    CASE
      WHEN csat_score >= 4.5 THEN '4.5-5.0'
      WHEN csat_score >= 3.5 THEN '3.5-4.49'
      WHEN csat_score >= 2.5 THEN '2.5-3.49'
      ELSE '<2.5'
    END AS csat_bucket
  FROM customers
)
SELECT
  ticket_bucket,
  csat_bucket,
  COUNT(*) AS customers,
  ROUND(AVG(churn) * 100, 2) AS churn_rate_pct,
  ROUND(AVG(avg_resolution_time), 2) AS avg_resolution_time
FROM base
GROUP BY ticket_bucket, csat_bucket
ORDER BY churn_rate_pct DESC, customers DESC;

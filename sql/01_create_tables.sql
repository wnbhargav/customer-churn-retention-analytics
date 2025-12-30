
-- 01_create_tables.sql
-- Robust loader for mixed boolean/string columns


DROP TABLE IF EXISTS customers_stg;
DROP TABLE IF EXISTS customers;

-- 1) Stage: let DuckDB infer types from CSV
CREATE TABLE customers_stg AS
SELECT *
FROM read_csv_auto('data/customer_churn_business_dataset.csv', header=true);

-- 2) Final: creating a clean table with consistent types
CREATE TABLE customers AS
SELECT
  CAST(customer_id AS VARCHAR)            AS customer_id,
  CAST(gender AS VARCHAR)                 AS gender,
  CAST(age AS INTEGER)                    AS age,
  CAST(country AS VARCHAR)                AS country,
  CAST(city AS VARCHAR)                   AS city,
  CAST(customer_segment AS VARCHAR)       AS customer_segment,
  CAST(tenure_months AS INTEGER)          AS tenure_months,
  CAST(signup_channel AS VARCHAR)         AS signup_channel,
  CAST(contract_type AS VARCHAR)          AS contract_type,

  CAST(monthly_logins AS INTEGER)         AS monthly_logins,
  CAST(weekly_active_days AS INTEGER)     AS weekly_active_days,
  CAST(avg_session_time AS DOUBLE)        AS avg_session_time,
  CAST(features_used AS INTEGER)          AS features_used,
  CAST(usage_growth_rate AS DOUBLE)       AS usage_growth_rate,
  CAST(last_login_days_ago AS INTEGER)    AS last_login_days_ago,

  CAST(monthly_fee AS DOUBLE)             AS monthly_fee,
  CAST(total_revenue AS DOUBLE)           AS total_revenue,

  CAST(payment_method AS VARCHAR)         AS payment_method,
  CAST(payment_failures AS INTEGER)       AS payment_failures,

  --  Boolean casting: works for true/false AND yes/no/1/0
  CASE
    WHEN lower(CAST(discount_applied AS VARCHAR)) IN ('true','t','1','yes','y') THEN TRUE
    WHEN lower(CAST(discount_applied AS VARCHAR)) IN ('false','f','0','no','n') THEN FALSE
    ELSE NULL
  END AS discount_applied,

  CASE
    WHEN lower(CAST(price_increase_last_3m AS VARCHAR)) IN ('true','t','1','yes','y') THEN TRUE
    WHEN lower(CAST(price_increase_last_3m AS VARCHAR)) IN ('false','f','0','no','n') THEN FALSE
    ELSE NULL
  END AS price_increase_last_3m,

  CAST(support_tickets AS INTEGER)        AS support_tickets,
  CAST(avg_resolution_time AS DOUBLE)     AS avg_resolution_time,
  CAST(complaint_type AS VARCHAR)         AS complaint_type,
  CAST(csat_score AS DOUBLE)              AS csat_score,
  CAST(escalations AS INTEGER)            AS escalations,

  CAST(email_open_rate AS DOUBLE)         AS email_open_rate,
  CAST(marketing_click_rate AS DOUBLE)    AS marketing_click_rate,
  CAST(nps_score AS INTEGER)              AS nps_score,
  CAST(survey_response AS VARCHAR)        AS survey_response,
  CAST(referral_count AS INTEGER)         AS referral_count,

  CAST(churn AS INTEGER)                  AS churn
FROM customers_stg;

-- 3) Sanity checks (optional)
SELECT COUNT(*) AS total_rows FROM customers;
SELECT ROUND(AVG(churn) * 100, 2) AS churn_rate_pct FROM customers;

-- 04_cohort_retention.sql | Monthly cohort retention for identified customers.
-- CAVEAT: the file starts in Dec 2009, so "first purchase month" means "first seen in this data".
-- The Dec 2009 cohort mixes true new customers with existing ones. Excluded from headline numbers.

CREATE OR REPLACE TABLE customer_months AS
SELECT DISTINCT customer_id, DATE_TRUNC('month', invoice_date) AS m
FROM lines WHERE line_type = 'sale' AND customer_id IS NOT NULL;

CREATE OR REPLACE TABLE cohorts AS
SELECT customer_id, MIN(m) AS cohort_month FROM customer_months GROUP BY 1;

CREATE OR REPLACE TABLE retention AS
SELECT c.cohort_month,
       DATE_DIFF('month', c.cohort_month, cm.m) AS month_n,
       COUNT(DISTINCT cm.customer_id)           AS active_customers
FROM cohorts c JOIN customer_months cm USING (customer_id)
GROUP BY 1, 2;

-- Retention % = active in month N / cohort size. Cohorts Jan 2010 - Nov 2010 (>= 12 months of follow-up).
SELECT r.cohort_month, r.month_n, r.active_customers,
       ROUND(100.0 * r.active_customers / s.active_customers, 1) AS retention_pct
FROM retention r JOIN retention s ON s.cohort_month = r.cohort_month AND s.month_n = 0
WHERE r.cohort_month BETWEEN DATE '2010-01-01' AND DATE '2010-11-01'
ORDER BY 1, 2;

-- Share of each cohort that ordered again at least once within 12 months of the first month.
SELECT ROUND(100.0 * COUNT(DISTINCT CASE WHEN cm.m > c.cohort_month
                                          AND cm.m <= c.cohort_month + INTERVAL 12 MONTH
                                     THEN c.customer_id END) / COUNT(DISTINCT c.customer_id), 1) AS repeat_within_12m_pct,
       COUNT(DISTINCT c.customer_id) AS customers_in_cohorts
FROM cohorts c JOIN customer_months cm USING (customer_id)
WHERE c.cohort_month BETWEEN DATE '2010-01-01' AND DATE '2010-11-01';

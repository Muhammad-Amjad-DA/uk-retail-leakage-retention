-- 05_rfm_segments.sql | Recency / Frequency / Monetary segmentation of identified customers.
-- Snapshot date = day after the last invoice in the file.

CREATE OR REPLACE TABLE rfm_base AS
SELECT customer_id,
       DATE_DIFF('day', MAX(invoice_date), DATE '2011-12-10') AS recency_days,
       COUNT(DISTINCT invoice)                                AS frequency,
       SUM(line_value)                                        AS monetary
FROM lines WHERE line_type IN ('sale','return') AND customer_id IS NOT NULL
GROUP BY 1 HAVING SUM(line_value) > 0;

CREATE OR REPLACE TABLE rfm AS
SELECT *,
       NTILE(5) OVER (ORDER BY recency_days DESC) AS r,   -- 5 = most recent
       NTILE(5) OVER (ORDER BY frequency)         AS f,
       NTILE(5) OVER (ORDER BY monetary)          AS m
FROM rfm_base;

CREATE OR REPLACE TABLE rfm_segments AS
SELECT *,
       CASE
         WHEN r >= 4 AND f >= 4                 THEN '1 Champions'
         WHEN f >= 4 AND r <= 2                 THEN '2 At risk (high value)'
         WHEN r >= 4 AND f <= 2                 THEN '3 New / recent'
         WHEN r <= 2 AND f <= 2                 THEN '5 Lost'
         ELSE                                         '4 Core'
       END AS segment
FROM rfm;

SELECT segment,
       COUNT(*)                                                AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)      AS pct_customers,
       ROUND(SUM(monetary), 0)                                 AS net_revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
       ROUND(AVG(monetary), 0)                                 AS avg_net_revenue,
       ROUND(MEDIAN(recency_days), 0)                          AS median_recency_days
FROM rfm_segments GROUP BY 1 ORDER BY 1;

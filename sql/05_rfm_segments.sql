-- 05_rfm_segments.sql | Recency / Frequency / Monetary segmentation of identified customers.
-- Snapshot date = day after the last invoice in the file.

CREATE OR REPLACE TABLE rfm_base AS
SELECT customer_id,
       DATE_DIFF('day', MAX(invoice_date), DATE '2011-12-10') AS recency_days,
       COUNT(DISTINCT invoice)                                AS frequency,
       ROUND(SUM(line_value), 2)                              AS monetary
FROM lines WHERE line_type IN ('sale','return') AND customer_id IS NOT NULL
GROUP BY 1 HAVING ROUND(SUM(line_value), 2) > 0;

-- Scores 1 to 5 by percentile of the customer base. CUME_DIST keeps customers with the SAME value in the SAME score.
-- (NTILE splits ties arbitrarily, which made the segment sizes change from run to run.)
CREATE OR REPLACE TABLE rfm AS
SELECT *,
       CEIL(5 * CUME_DIST() OVER (ORDER BY recency_days DESC))::INT AS r,   -- 5 = most recent
       CEIL(5 * CUME_DIST() OVER (ORDER BY frequency))::INT         AS f,
       CEIL(5 * CUME_DIST() OVER (ORDER BY monetary))::INT          AS m
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

-- Profile of the "At risk (high value)" segment: when did they last order, and did they buy in the 2010 peak season?
SELECT COUNT(*)                                                     AS at_risk_customers,
       ROUND(SUM(s.monetary), 0)                                    AS lifetime_net_revenue,
       ROUND(AVG(s.monetary), 0)                                    AS avg_net_revenue_24m,
       ROUND(MEDIAN(s.recency_days), 0)                             AS median_days_since_last_order,
       ROUND(100.0 * COUNT(DISTINCT p.customer_id) / COUNT(*), 1)   AS pct_bought_oct_dec_2010,
       MAX(l.last_order)                                            AS latest_last_order
FROM rfm_segments s
JOIN (SELECT customer_id, MAX(invoice_date)::DATE AS last_order FROM lines WHERE line_type IN ('sale','return') GROUP BY 1) l USING (customer_id)
LEFT JOIN (SELECT DISTINCT customer_id FROM lines WHERE line_type = 'sale' AND invoice_date >= TIMESTAMP '2010-10-01' AND invoice_date < TIMESTAMP '2011-01-01') p USING (customer_id)
WHERE s.segment = '2 At risk (high value)';

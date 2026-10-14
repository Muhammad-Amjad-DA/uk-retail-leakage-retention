-- 06_tieout_tests.sql | Every row must return PASS. A FAIL means a KPI is not trustworthy.

SELECT 'bridge: net = gross + returns' AS test,
  CASE WHEN ABS((SELECT SUM(line_value) FROM lines WHERE line_type='sale')
              + (SELECT SUM(line_value) FROM lines WHERE line_type='return')
              - (SELECT SUM(line_value) FROM lines WHERE line_type IN ('sale','return'))) < 0.01
       THEN 'PASS' ELSE 'FAIL' END AS result
UNION ALL
SELECT 'every line has exactly one line_type',
  CASE WHEN (SELECT COUNT(*) FROM lines) = (SELECT COUNT(*) FROM dedup) AND
            (SELECT COUNT(*) FROM lines WHERE line_type IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'no exact duplicate rows remain after cleaning',
  CASE WHEN (SELECT COUNT(*) FROM dedup) = (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM dedup)) THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'no sale line has non-positive qty or price',
  CASE WHEN (SELECT COUNT(*) FROM lines WHERE line_type='sale' AND (qty <= 0 OR unit_price <= 0)) = 0
       THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'RFM revenue + excluded net-negative customers = total identified net revenue',
  CASE WHEN ABS((SELECT SUM(monetary) FROM rfm_base)
              + (SELECT COALESCE(SUM(net), 0) FROM (SELECT customer_id, SUM(line_value) AS net FROM lines
                   WHERE line_type IN ('sale','return') AND customer_id IS NOT NULL GROUP BY 1 HAVING SUM(line_value) <= 0))
              - (SELECT SUM(line_value) FROM lines WHERE line_type IN ('sale','return') AND customer_id IS NOT NULL)) < 0.01
       THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'cohort sizes sum to distinct buying customers',
  CASE WHEN (SELECT SUM(active_customers) FROM retention WHERE month_n = 0)
          = (SELECT COUNT(DISTINCT customer_id) FROM customer_months) THEN 'PASS' ELSE 'FAIL' END;

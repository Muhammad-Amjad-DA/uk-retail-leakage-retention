-- 02_revenue_bridge.sql | Why three plausible "revenue" numbers disagree, step by step.

-- Naive revenue: SUM(Quantity * Price) over the raw file, as most tutorials do it.
SELECT 'A. Naive (raw file, all rows)'                       AS step, ROUND(SUM(Quantity * Price), 0) AS gbp FROM raw
UNION ALL
SELECT 'B. After removing exact duplicates',                      ROUND(SUM(Quantity * Price), 0) FROM dedup
UNION ALL
SELECT 'C. After removing fees/adjustments (postage, bank, Amazon fees)', ROUND(SUM(line_value), 0)
FROM lines WHERE line_type <> 'fee_or_adjustment'
UNION ALL
SELECT 'D. Gross product sales (sale lines only)',                ROUND(SUM(line_value), 0) FROM lines WHERE line_type IN ('sale', 'order_error') AND qty > 0
UNION ALL
SELECT 'D2. ...of which sales later reversed as order errors',    ROUND(SUM(line_value), 0) FROM lines WHERE line_type = 'order_error' AND qty > 0
UNION ALL
SELECT 'E. Returns (credit notes)',                               ROUND(SUM(line_value), 0) FROM lines WHERE line_type IN ('return', 'order_error') AND qty < 0
UNION ALL
SELECT 'E2. ...of which order-and-cancel errors (not customer returns)', ROUND(SUM(line_value), 0) FROM lines WHERE line_type = 'order_error' AND qty < 0
UNION ALL
SELECT 'F. Net product revenue (D + E, unchanged by errors)',     ROUND(SUM(line_value), 0) FROM lines WHERE line_type IN ('sale', 'return', 'order_error');

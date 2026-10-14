-- 03_returns_leakage.sql | Where does revenue leak through returns?

-- Return rate by value, by year: the headline number vs. the number after removing order-and-cancel errors.
SELECT EXTRACT(year FROM invoice_date) AS yr,
       ROUND(-SUM(CASE WHEN qty < 0 AND line_type IN ('return','order_error') THEN line_value END), 0)  AS returns_headline,
       ROUND(SUM(CASE WHEN qty > 0 AND line_type IN ('sale','order_error')   THEN line_value END), 0)  AS gross_headline,
       ROUND(100.0 * -SUM(CASE WHEN qty < 0 AND line_type IN ('return','order_error') THEN line_value END)
             / SUM(CASE WHEN qty > 0 AND line_type IN ('sale','order_error') THEN line_value END), 2)   AS return_rate_headline_pct,
       ROUND(-SUM(CASE WHEN line_type = 'return' THEN line_value END), 0)                               AS returns_genuine,
       ROUND(SUM(CASE WHEN line_type = 'sale' THEN line_value END), 0)                                  AS gross_genuine,
       ROUND(100.0 * -SUM(CASE WHEN line_type = 'return' THEN line_value END)
             / SUM(CASE WHEN line_type = 'sale' THEN line_value END), 2)                                AS return_rate_genuine_pct
FROM lines GROUP BY 1 ORDER BY 1;

-- Return concentration: how much of returned value comes from the top 20 customers?
WITH r AS (
    SELECT customer_id, -SUM(line_value) AS returned
    FROM lines WHERE line_type = 'return' AND customer_id IS NOT NULL
    GROUP BY 1
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY returned DESC) AS rk,
           SUM(returned) OVER () AS total
    FROM r
)
SELECT ROUND(100.0 * SUM(returned) / MAX(total), 1) AS top20_customers_share_of_returns_pct
FROM ranked WHERE rk <= 20;

-- Products with the highest returned value (min. 50 sold units to avoid noise).
WITH p AS (
    SELECT stock_code, MAX(description) AS description,
           SUM(CASE WHEN line_type='sale'   THEN qty END)         AS units_sold,
           -SUM(CASE WHEN line_type='return' THEN qty END)        AS units_returned,
           -SUM(CASE WHEN line_type='return' THEN line_value END) AS returned_value
    FROM lines WHERE line_type IN ('sale','return') GROUP BY 1
)
SELECT stock_code, description, units_sold, units_returned,
       ROUND(100.0 * units_returned / NULLIF(units_sold, 0), 1) AS return_rate_pct,
       ROUND(returned_value, 0) AS returned_value
FROM p WHERE units_sold >= 50 ORDER BY returned_value DESC LIMIT 15;

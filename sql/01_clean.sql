-- 01_clean.sql  | Load raw lines, classify them, build the clean fact table.
-- Engine: DuckDB (PostgreSQL-compatible syntax). Every rule is logged in docs/data_quality_log.md.

CREATE OR REPLACE TABLE raw AS
SELECT * FROM read_csv_auto('data/online_retail_ii.csv',
       types = {'Invoice': 'VARCHAR', 'StockCode': 'VARCHAR'});

-- Rule 1: drop exact duplicate rows (the two source sheets overlap in Dec 2010).
CREATE OR REPLACE TABLE dedup AS SELECT DISTINCT * FROM raw;

-- Rule 2: classify every line. Product codes start with 5 digits; everything else
-- (POST, DOT, M, BANK CHARGES, AMAZONFEE, ...) is a fee/adjustment, not merchandise.
CREATE OR REPLACE TABLE lines_base AS
SELECT
    ROW_NUMBER() OVER ()              AS line_id,
    Invoice                           AS invoice,
    StockCode                         AS stock_code,
    Description                       AS description,
    Quantity                          AS qty,
    InvoiceDate                       AS invoice_ts,
    CAST(InvoiceDate AS DATE)         AS invoice_date,
    Price                             AS unit_price,
    CAST("Customer ID" AS INTEGER)    AS customer_id,
    Country                           AS country,
    Quantity * Price                  AS line_value,
    CASE
        WHEN NOT regexp_matches(StockCode, '^[0-9]{5}')          THEN 'fee_or_adjustment'
        WHEN Invoice LIKE 'C%'                                   THEN 'return'
        WHEN Price <= 0                                          THEN 'zero_price'
        WHEN Quantity < 0                                        THEN 'stock_write_off'
        ELSE 'sale'
    END AS line_type
FROM dedup;

-- Rule 3: order-and-cancel errors. A credit note > GBP 5,000 that exactly reverses a sale
-- (same customer, same product, same quantity) in the previous 7 days is an entry error, not a customer return.
-- Both sides are tagged 'order_error' so they distort neither gross sales nor the return rate.
CREATE OR REPLACE TABLE order_error_pairs AS
SELECT r.line_id AS return_line_id, s.line_id AS sale_line_id
FROM lines_base r
JOIN lines_base s
  ON s.line_type = 'sale' AND s.customer_id = r.customer_id AND s.stock_code = r.stock_code
 AND s.qty = -r.qty AND s.invoice_ts BETWEEN r.invoice_ts - INTERVAL 7 DAY AND r.invoice_ts
WHERE r.line_type = 'return' AND -r.line_value > 5000;

CREATE OR REPLACE TABLE order_error_ids AS
SELECT return_line_id AS line_id FROM order_error_pairs
UNION
SELECT sale_line_id FROM order_error_pairs;

CREATE OR REPLACE TABLE lines AS
SELECT * EXCLUDE (line_type),
       CASE WHEN line_id IN (SELECT line_id FROM order_error_ids) THEN 'order_error' ELSE line_type END AS line_type
FROM lines_base;

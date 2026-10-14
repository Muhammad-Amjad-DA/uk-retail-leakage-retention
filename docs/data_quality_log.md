# Data quality log

Source: `online_retail_II.xlsx`, two sheets (2009-12 to 2010-12 and 2010-12 to 2011-12), 1,067,371 rows combined.

| # | Issue found | Rows affected | Decision | Effect on results |
|---|---|---|---|---|
| 1 | Exact duplicate rows (the two sheets overlap in Dec 2010, plus repeated scans) | 34,335 | Removed with `SELECT DISTINCT` | Revenue falls by £431,717 (2.2%). **Assumption:** some of these could be genuine repeated scans. Keeping them would add £0.43M to net revenue |
| 2 | Non-merchandise stock codes (POST, DOT, M, D, S, BANK CHARGES, ADJUST, AMAZONFEE, CRUK and similar) | 5,980 | Excluded from product revenue (kept in `lines` as `fee_or_adjustment`) | Net effect of fees is -£70,732 |
| 3 | Zero-price lines | 5,928 | Excluded from sales (`zero_price`) | £0 value |
| 4 | Missing Customer ID | 226,965 sale/return lines | Kept for revenue KPIs, excluded from customer analysis | **13.6% (£2.57M) of net product revenue cannot be attributed to a customer** |
| 5 | Missing descriptions | 4,382 | Not used. Descriptions are only used for display | None |
| 6 | Negative quantities without a credit-note invoice (stock write-offs) | 3,457 before dedup | All fell into `zero_price` or `fee_or_adjustment` after classification (none left as `stock_write_off`); no value impact | None |
| 7 | Order-and-cancel errors (see KPI definitions) | 4 lines (2 events) | Tagged `order_error`, removed from return rate | 2011 return rate 4.84% -> 2.31% |
| 8 | Dataset starts Dec 2009, so first-seen is not first-purchase | Dec 2009 cohort | Excluded from retention headline | Avoids overstating retention |

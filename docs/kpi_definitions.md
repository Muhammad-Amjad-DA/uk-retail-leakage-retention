# KPI definitions

One definition per KPI. If a number in this repo does not match one of these, it is a bug.

| KPI | Definition | Source table | Value |
|---|---|---|---|
| Gross product sales | Sum of `qty * unit_price` on `sale` lines **plus** the sale side of order-and-cancel errors | `lines` | £19.64M |
| Returns (credit notes) | Sum of `qty * unit_price` on credit-note lines (invoice starts with `C`), negative | `lines` | -£0.72M |
| **Net product revenue** | Gross product sales + returns. Excludes postage, bank charges, Amazon fees, manual adjustments | `lines` | **£18.93M** |
| Return rate (headline) | All credit-note value / gross product sales | `lines` | 2010: 2.54%, 2011: 4.84% |
| **Return rate (genuine)** | Credit-note value **excluding order-and-cancel errors** / gross product sales excluding the matching sales | `lines` | 2010: 2.54%, 2011: **2.31%** |
| Order-and-cancel error | A credit note over GBP 5,000 that exactly reverses a sale (same customer, same product, same quantity) in the previous 7 days | `order_error_pairs` | 2 events, £245,653 |
| Cohort | Month of a customer's first purchase **in this file** (file starts Dec 2009, so the Dec 2009 cohort mixes new and existing customers and is excluded) | `cohorts` | - |
| Monthly retention | Customers from a cohort who bought in month N / cohort size | `retention` | ~20% per month |
| 12-month repeat rate | Customers from Jan-Nov 2010 cohorts who ordered again within 12 months / cohort size | `cohorts` | 70.0% |
| Recency / Frequency / Monetary | Days since last order at 2011-12-10 / distinct invoices / net revenue (sales minus returns). Customers with net revenue <= 0 are excluded | `rfm_base` | - |
| At-risk (high value) | RFM frequency score >= 4 and recency score <= 2 | `rfm_segments` | 423 customers |

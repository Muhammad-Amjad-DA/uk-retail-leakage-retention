# How AI was used

This project was built with Claude (Anthropic) as a coding and writing assistant. This log records what it did, where it was wrong, and which decisions are analytical judgement calls that a reviewer should challenge.

## What AI did
- Drafted the SQL files, the Python runner and the chart code
- Proposed the "order-and-cancel error" check after the return-rate number looked wrong
- Drafted the README text from the computed result files

## Where AI was wrong (caught during validation)
1. **A tie-out test was logically wrong.** The first version asserted that RFM revenue (positive-net customers only) was less than or equal to total identified revenue. That fails by construction when net-negative customers are excluded, because dropping negatives raises the sum. The test was rewritten to reconcile: RFM revenue + excluded customers' net = total.
2. **A join bug tagged every credit note as an order error.** The first version of the order-error table unioned all return lines instead of only matched ones. The tie-out suite failed on the revenue bridge and the cohort test, and the 2010 return rate came back as 6.4% instead of 2.5%, which was implausible. Fixed by building the table from matched pairs only.

## Judgement calls made by the analyst (review these)
- The GBP 5,000 threshold and 7-day window for order-and-cancel errors. A lower threshold catches more normal exact-quantity returns (2,553 lines, £412k) that are genuine customer behaviour.
- Treating exact duplicate rows as errors rather than repeated scans.
- Treating customers with net revenue <= 0 as outside the RFM analysis.

## What was not delegated
Every KPI is reconciled by `sql/06_tieout_tests.sql`, which must return PASS on every row before any number is quoted.

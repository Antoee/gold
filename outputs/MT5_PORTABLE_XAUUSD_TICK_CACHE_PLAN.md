# MT5 Portable XAUUSD Tick Cache Plan

- Status: **COVERAGE_MISSING**
- Action: `RUN_DISJOINT_ERAS_BEFORE_SYNC`
- Portable roots: `4`
- Cached months visible: `39`
- Required complete months: `138`
- Excluded partial cutoff month: `202607`
- Missing required months: `100`
- Inventory files inspected: `156`
- Complete-month files hashed: `152`
- Copy operations required: `0`
- Bytes to copy: `0`
- Hash conflicts: `0`

Only allowlisted MetaQuotes-Demo XAUUSD TKC (.tkc) files are inventoried. The frozen partial cutoff month is reported but never copied because unused tail ticks may differ between roots. Account, trade, configuration, source, binary, and report files are outside this operation. A complete-month hash conflict fails closed and is never overwritten.

# Transferable Portfolio Forward Demo Package

Prepared for a frozen MetaQuotes-Demo hedging-account forward observation beginning after the 2026-07-16 research cutoff.

**Current observation status: invalid before first trade.** The read-only sentinel measured a `$100,000` demo balance while the frozen registration requires `$10,000`. The unchanged candidate must be moved to a correctly capitalized demo account and newly preregistered before the forward clock starts.

- Source SHA-256: 5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3
- Base profile SHA-256: ECBD1693D09AF6A04CB92F2756442DF8BF0B604118834D1C5E0F50CC57FFEC3E
- Forward profile SHA-256: CB1A4A78834C9780267F9EA06DB24E656FFAE87DC466D4442926F55562F3321D
- EA filename: Professional_XAUUSD_Transferable_Portfolio.ex5
- Attached chart: XAUUSD M15 (both strategy lanes calculate signals on H1)
- Forward event logs: TRANSFERABLE_FORWARD_RV_EVENTS.csv and TRANSFERABLE_FORWARD_MO_EVENTS.csv
- Required starting balance: $10,000 (+/- $1 before any trade)
- Shared maximum open risk: 0.75%
- Read-only sentinel: Professional_XAUUSD_Forward_Sentinel.ex5 on an auxiliary chart
- Sentinel heartbeat: TRANSFERABLE_FORWARD_SENTINEL.csv (account identifier excluded)
- Real-account trading remains disabled and the real-account safety lock remains enabled.
- Trading rules and risk inputs are identical to the released v0.1 profile; only logging, dashboard, and run-label fields differ.

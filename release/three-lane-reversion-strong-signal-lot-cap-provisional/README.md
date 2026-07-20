# Strong-Signal Selective Lot-Cap Provisional Candidate

This folder contains the exact source and profile that produced the current highest verified historical result. It is a provisional research package, not a live-trading release.

## Exact Identity

- Source SHA-256: `C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91`
- Profile SHA-256: `A0099C6701311BAE105F29909166358D4D30050593318F340AD8F3B932F65F04`
- Tested EX5 SHA-256: `A1640E4D0E6892F4E826CA8FC5524C7F3BDB9FABE2121F508F94FD2D7AB7BE7A`
- Symbol/timeframe: `XAUUSD M15`
- Starting balance: `$10,000`
- Test model/range: Model 4 real ticks, `2015-01-01` through `2026-07-18`

## Historical Result

- Net: `+$2,428.50`
- Total increase: `+24.28%`
- CAGR: `+1.90% per year`
- Profit factor: `1.89`
- Maximum equity drawdown: `1.18%`
- Recovery factor: `17.09`
- Trades: `404`

The profile enables a `0.15`-lot ceiling only for existing reversion signals whose completed H1 candle body ratio is at least `0.25`. Requested reversion risk remains `0.45%`, and portfolio open risk remains capped at `0.75%`.

## Boundary

Discovery, recent-data, Model 4, annual, hard-risk, added-cost, and clustered Monte Carlo gates passed. Second-broker variation and a valid frozen `$10,000` forward demo are still missing. Real-account trading is disabled in the included profile.

# Momentum Exit Ablation Diagnostic Decision

**Decision: REJECTED DIAGNOSTIC. No code follow-up, recent-data test, Model 4 test, promotion, forward substitution, or live approval is permitted.**

- Exact accepted reports: `24/24`; attempts: `27`; identity refusals retried unchanged: `3`
- Source SHA-256: `C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91`
- EX5 SHA-256: `21DDE8A2C1E04CB1D26C76E791A1EA1F0F26167667F19479F29A98BAE1D905A4`
- Manifest SHA-256: `5C8B949BAE2D8A4296AC9932DEEC9B02ECB8255FDF4E153D9D8A47C3A49D91DE`
- `$10,000`; MT5 Model 1; sealed 2015-2020 diagnostic; reversion risk `0.45%`; portfolio cap `0.75%`; real trading disabled

| Exit profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD | Changed | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---:|:---:|
| Control: channel + momentum + time | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 | False | False |
| No channel exit | +$879.08 | +$428.75 | +$1,302.73 | 13.03% | 2.06%/yr | 1.73 | 265 | 1.24% | 9.5368 | 10.5081 | True | False |
| No momentum-failure exit | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 | False | False |
| No 120-bar time exit | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 | False | False |
| Channel exit only | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 | False | False |
| Momentum-failure exit only | +$879.08 | +$428.75 | +$1,302.73 | 13.03% | 2.06%/yr | 1.73 | 265 | 1.24% | 9.5368 | 10.5081 | True | False |
| 120-bar time exit only | +$879.08 | +$428.75 | +$1,302.73 | 13.03% | 2.06%/yr | 1.73 | 265 | 1.24% | 9.5368 | 10.5081 | True | False |
| Fixed SL/TP only | +$879.08 | +$428.75 | +$1,302.73 | 13.03% | 2.06%/yr | 1.73 | 265 | 1.24% | 9.5368 | 10.5081 | True | False |

## Frozen Gate

A code follow-up required at least two related, behavior-changing ablations that were no worse in both disjoint eras, improved continuous net by at least 3%, did not reduce PF/recovery/return-DD, kept drawdown at or below 1.30%, and retained at least 200 trades.

- Passing related ablations: `0`; required: `2`
- Removing the channel exit changed 2015-18 by `-$122.64` and 2019-20 by `+$58.34`.
- Its continuous change was `-$51.01`: `+$1,302.73` versus `+$1,353.74` control.
- Removing momentum-failure and/or the 120-bar time exit while preserving the channel exit produced identical results to control. These mechanisms were inactive in the sealed sample.
- Every profile remained profitable, but the only behavior-changing architecture was unstable across eras and reduced continuous profit and efficiency.

The provisional strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.

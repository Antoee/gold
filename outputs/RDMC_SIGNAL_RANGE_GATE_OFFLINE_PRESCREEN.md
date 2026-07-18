# RDMC Signal-Range Gate Offline Pre-Screen

**Diagnostic status: POSTHOC_REJECT_ALL_FROZEN_THRESHOLDS. This is not the frozen MT5 decision.**

The read-only pre-screen removes already observed control trades whose completed-H1 signal range is below each frozen threshold. Removing a trade can expose later signals that were blocked in the control path, so only the preregistered eight Model1 reports may accept or reject the repair.

- H1 cache SHA-256: `9B19B41AEF4B183C463777C907E05F8BD8F974B5AF670660B885DEA278AB3E7C`
- H1 base coverage: `2009-06-19 06:00` through `2026-07-17 22:00` UTC-like broker timestamps
- H1 base bars: `100,000`; trailing cache records ignored: `4,581`
- Annual ledger SHA-256: `6BC726AB9D2C1BBC022419B1AEEB2F62C1D9E2EA7435B59F7BADD03539F22576`
- Telemetry SHA-256: `2BA7856B36D144B57334037A2B1B2BD389E94495413549B6388465A52179B087`
- ATR/bar validation: `135 / 135` matched; maximum six-decimal range-ATR error `0.000000491`

| Profile | Year | Post-hoc net | PF | Trades | Kept momentum | Excluded | Excluded P/L | Positive | 18+ trades |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| `srg_control` | 2019 | $-3.77 | 0.9778 | 32 | 32 | 0 | $+0.00 | False | True |
| `srg_control` | 2022 | $-92.78 | 0.5743 | 35 | 34 | 0 | $+0.00 | False | True |
| `srg_min100` | 2019 | $-47.01 | 0.6445 | 24 | 24 | 8 | $+43.24 | False | True |
| `srg_min100` | 2022 | $-86.36 | 0.3836 | 22 | 21 | 13 | $-6.42 | False | True |
| `srg_min125_center` | 2019 | $-16.36 | 0.8371 | 19 | 19 | 13 | $+12.59 | False | True |
| `srg_min125_center` | 2022 | $-76.42 | 0.2883 | 14 | 13 | 21 | $-16.36 | False | False |
| `srg_min150` | 2019 | $-14.88 | 0.6755 | 11 | 11 | 21 | $+11.11 | False | False |
| `srg_min150` | 2022 | $-53.31 | 0.3570 | 10 | 9 | 25 | $-39.47 | False | False |

## Interpretation

- `1.00 ATR` remains negative in both years and is worse than control in combined net.
- The `1.25 ATR` center remains negative in both years and falls to 14 total trades in 2022.
- `1.50 ATR` remains negative in both years and falls below 18 trades in each year.
- None of the frozen thresholds passes the post-hoc approximation. The exact MT5 gate therefore has a low prior probability of success, but it remains authoritative because entry availability is path-dependent.

No candidate was promoted or substituted. The registered forward candidate is unchanged, the invalid $100,000 demo contributes zero evidence, and real-money trading remains locked.

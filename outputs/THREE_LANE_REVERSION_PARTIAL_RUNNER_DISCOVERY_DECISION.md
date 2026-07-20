# Three-Lane Reversion Partial Runner Discovery Decision

**Decision: REJECTED IN DISCOVERY. Recent data, Model 4, promotion, forward substitution, and live approval remain closed. NO NEW BEST.**

- Exact accepted reports: `24/24`; attempts: `29`; infrastructure failures retried unchanged: `5`
- Source SHA-256: `614DCF5B0C55DF25DABDCF903C3193A0CE248AA2671788A400B5C39A4209F719`
- EX5 SHA-256: `37F90A3C23CEF638AEE689807E01F7EC220EF01EC999CA6D41D6F8BE6906A810`
- Manifest SHA-256: `66E6E01AE5A802E1E3423C51B4E5A015B480E369424EA8D84539312304512D40`
- `$10,000`; MT5 Model 1; frozen 2015-2020 discovery; unchanged initial risk and entries; portfolio cap `0.75%`; real trading disabled
- Active profiles produced 270 continuous report trades versus 265 for control, confirming the partial-exit path executed

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled control | +$1,001.72 | +$370.41 | +$1,353.74 | 13.54% | 2.14%/yr | 1.85 | 265 | 1.06% | 11.4559 | 12.7736 |
| **80% / 2.00x / +0.50R center** | +$995.00 | +$348.78 | +$1,325.39 | 13.25% | 2.1%/yr | 1.84 | 270 | 1.06% | 11.216 | 12.5 |
| Close 75% | +$977.54 | +$341.02 | +$1,300.22 | 13.0% | 2.06%/yr | 1.82 | 270 | 1.06% | 11.003 | 12.2642 |
| Close 85% | +$995.00 | +$348.78 | +$1,325.39 | 13.25% | 2.1%/yr | 1.84 | 270 | 1.06% | 11.216 | 12.5 |
| Target 1.75x | +$1,070.15 | +$348.78 | +$1,392.02 | 13.92% | 2.2%/yr | 1.87 | 270 | 1.05% | 11.7798 | 13.2571 |
| Target 2.25x | +$962.51 | +$348.78 | +$1,292.95 | 12.93% | 2.05%/yr | 1.81 | 270 | 1.06% | 10.9414 | 12.1981 |
| Lock +0.25R | +$1,028.88 | +$346.89 | +$1,357.38 | 13.57% | 2.14%/yr | 1.86 | 270 | 1.06% | 11.4867 | 12.8019 |
| Lock +0.75R | +$1,006.17 | +$350.70 | +$1,338.48 | 13.38% | 2.12%/yr | 1.84 | 270 | 1.06% | 11.3267 | 12.6226 |

## Frozen Gate

- Every report profitable: `True`
- Center partial path active: `True`
- Center retained at least 98% of control in both eras: `False`
- Center net at least 4% above control: `False` (+$1,325.39 vs required +$1,407.89)
- Center CAGR at least 0.06 point above control: `False`
- Center PF, drawdown, recovery, and return/DD gate: `False`
- At least 4 of 6 neighbors passed: `False` (`0/6`)

The center reduced continuous net by `-$28.35` and reduced 2019-2020 by `-$21.63`. It also lowered PF, CAGR, recovery, and return/drawdown, so it fails without opening post-2020 data.

The best observed row was `rvpr_target175` at `+$1,392.02`, but it was not the preregistered center and its 2019-2020 result was below the 98% era floor. Selecting it now would be result-driven threshold chasing.

The strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.

# Independent M15 Failed-Breakout Trap Decision

Decision date: 2026-07-16

**Verdict: rejected before holdout. No 2021-2026 retrospective run was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Test Contract

The standalone M15 EA fades the first closed-bar snapback after a false break of a bounded compression box. It uses a stop beyond the failed excursion, either the opposite box edge or a fixed-R target, broker-accurate `OrderCalcProfit` sizing at `0.10%` risk, no forced minimum lot, and account-wide exposure protection.

- Source: `work/Independent_XAUUSD_M15_Failed_Breakout_Trap.mq5`
- Source SHA-256: `EFB39ED06E5C7CA3D75C971F24ADB3073E597CC9CB2373257521EC41BDC57990`
- Compile: `0 errors, 0 warnings`
- Data used: 2015-01-01 through 2020-12-31 only
- Initial discovery: `48 / 48` reports parsed
- Bounded liveness follow-up: `36 / 36` reports parsed
- Total reports: `84 / 84`
- 2021-2026 configurations run: `0`
- Model 4 configurations run: `0`

## Result

The initial 16-variant screen had no promotion pass. Its 16-bar structural-target row was positive in both eras at `+$32.66` and PF `1.49`, but had only `16` trades in six years and no support from the losing 8/12-bar neighbors.

The liveness follow-up found a coherent 16-bar fixed-R neighborhood: 1.25R, 1.5R, and 2.0R were all profitable in both disjoint eras, with continuous PF from `1.26` to `1.45` and drawdown from `0.58%` to `0.65%`. Every row had only `54` trades, below the frozen minimum of `60`.

The only quantitative gate row was `fbt_b14_fixed_r200`. It made `+$112.52` continuously, but only `+$0.76` in 2019-2020 at PF `1.00`; adjacent 1.25R and 1.5R versions lost in that era. It therefore failed the required neighbor-support gate and is not robust evidence.

| Candidate | 2015-2018 | 2019-2020 | Continuous | Annualized | PF | Max DD | Trades | Neighbor support | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `fbt_b14_fixed_r200` | `+$110.75` | `+$0.76` | `+$112.52` | `0.19%` | `1.28` | `0.84%` | `95` | `False` | `REJECTED_UNSUPPORTED_NUMERIC_PASS` |
| `fbt_b16_fixed_r200` | `+$65.89` | `+$29.31` | `+$95.20` | `0.16%` | `1.45` | `0.60%` | `54` | `True` | `REJECTED_ACTIVITY_FLOOR` |
| `fbt_b16_fixed_r150` | `+$61.33` | `+$29.87` | `+$91.20` | `0.15%` | `1.43` | `0.65%` | `54` | `True` | `REJECTED_ACTIVITY_FLOOR` |
| `fbt_b14_fixed_r150` | `+$75.03` | `-$4.26` | `+$72.29` | `0.12%` | `1.18` | `0.81%` | `95` | `False` | `REJECTED_DISCOVERY_GATE` |
| `fbt_b16_fixed_r125` | `+$34.90` | `+$20.43` | `+$55.33` | `0.09%` | `1.26` | `0.58%` | `54` | `True` | `REJECTED_ACTIVITY_FLOOR` |
| `fbt_b14_fixed_r125` | `+$55.62` | `-$8.87` | `+$46.75` | `0.08%` | `1.11` | `0.73%` | `96` | `False` | `REJECTED_DISCOVERY_GATE` |
| `fbt_b16_struct_r075` | `+$18.59` | `+$17.14` | `+$35.73` | `0.06%` | `1.33` | `0.39%` | `28` | `False` | `REJECTED_DISCOVERY_GATE` |
| `fbt_b14_struct_r075` | `+$51.88` | `-$19.91` | `+$31.97` | `0.05%` | `1.15` | `0.60%` | `51` | `False` | `REJECTED_DISCOVERY_GATE` |
| `fbt_b18_fixed_r150` | `+$31.43` | `-$0.01` | `+$31.42` | `0.05%` | `1.35` | `0.31%` | `23` | `False` | `REJECTED_DISCOVERY_GATE` |
| `fbt_b18_struct_r075` | `+$32.45` | `-$7.43` | `+$25.02` | `0.04%` | `1.73` | `0.23%` | `11` | `False` | `REJECTED_DISCOVERY_GATE` |
| `fbt_b18_fixed_r125` | `+$15.45` | `-$3.43` | `+$12.02` | `0.02%` | `1.14` | `0.33%` | `23` | `False` | `REJECTED_DISCOVERY_GATE` |
| `fbt_b18_fixed_r200` | `+$29.09` | `-$19.14` | `+$9.95` | `0.02%` | `1.11` | `0.40%` | `23` | `False` | `REJECTED_DISCOVERY_GATE` |

## Decision

- Do not promote or merge the failed-breakout trap into the frozen EA.
- Do not lower the activity floor after observing a 54-trade neighborhood.
- Do not use the newer holdout to rescue an underpowered discovery result.
- Skip Model 4 because the predeclared discovery contract was not fully met.
- Preserve the 16-bar fixed-R neighborhood as a research clue only, not a deployable profile.

## Evidence

- `outputs/INDEPENDENT_M15_FAILED_BREAKOUT_TRAP_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M15_FAILED_BREAKOUT_LIVENESS_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M15_FAILED_BREAKOUT_DECISION.csv`

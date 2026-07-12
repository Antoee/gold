# Professional XAUUSD EA

Research project for a professional-grade MetaTrader 5 Expert Advisor focused on XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. Risk control stays first while profit is improved through local MT5 Strategy Tester validation.

## Latest Status

Last updated: 2026-07-12.

This README is the no-chat status board for the bot.

| Item | Current State |
| --- | --- |
| Current research-best | `Score7 Regime No-M1-Shock Dec-ISLP-Off` |
| Profile | `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_NO_M1SHOCK_DEC_ISLP_OFF_PROFILE.set` |
| Builder | `work/build_score7_regime_no_m1shock_dec_islp_off_profile.ps1` |
| SHA-256 | `D1B665E193A5126B879E0DCA08A85CB5C8E1D1C9D2007075D6C2EA6ABBF82672` |
| Best Model=1 continuous | `+$10,127.76` from `2024.01.01` to `2026.07.12` |
| Real-tick status | Model4 total improved from `+$4,075.62` to `+$7,469.00` |
| Model=2 caveat | Previous no-m1-shock wins `+$12,054.55`; Dec-ISLP-Off is lower but clean at `+$10,127.76` |
| Live-ready? | No. Research-best only, needs wider real-tick monthly/quarterly validation |
| GitHub Actions | Manual-only. Heavy MT5 testing should run locally, hidden/background only |

## Latest Human Update

The newest promoted profile is `Score7 Regime No-M1-Shock Dec-ISLP-Off`. It disables only December entries for the In-Session Liquidity Pullback lane after diagnostics showed the Q4 2024 red window came from a single December ISLP loss.

The guard improved Model0, Model1, and Model4 real-tick sampled totals, removed the Q4 2024 red window, and preserved Q4 2025. Model2 still prefers the previous no-m1-shock profile, so this is a research-best candidate, not a production claim.

## December ISLP Guard Validation

| Model | Previous No-M1-Shock | Dec-ISLP-Off | Decision |
| --- | ---: | ---: | --- |
| Model0 total | `+$4,495.93` | `+$8,768.34` | guard wins |
| Model1 total | `+$14,739.08` | `+$15,361.76` | guard wins |
| Model2 total | `+$17,890.63` | `+$15,361.76` | previous wins |
| Model4 total | `+$4,075.62` | `+$7,469.00` | guard wins |

Key continuous rows:

| Model | Previous No-M1-Shock | Dec-ISLP-Off |
| --- | ---: | ---: |
| Model0 continuous | `+$1,288.93` | `+$5,386.54` |
| Model1 continuous | `+$9,753.58` | `+$10,127.76` |
| Model2 continuous | `+$12,054.55` | `+$10,127.76` |
| Model4 continuous | `+$1,288.93` | `+$4,507.51` |

## Why It Was Promoted

Trade diagnostics showed Q4 2024 had two trades:

| Date | Lane | Result |
| --- | --- | ---: |
| 2024-10-08 | Flat Month Micro Reversion buy | `+$46.75` |
| 2024-12-06 | In-Session Liquidity Pullback sell | `-$51.30` |

The losing trade was December ISLP. Q4 2025 gains came from October/November ISLP trades, not December, so `InpISLPTradeDecember=false` was the narrowest guard to test.

## Evidence Files

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `outputs/DEC_ISLP_GUARD_DECISION_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL1_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL2_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL0_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `research/2026-07-12-december-islp-guard-promotion-note.md`

## Risk Rules

- No martingale.
- No grid.
- No averaging down.
- No unrealistic recovery systems.
- Do not promote a change just because one backtest makes more money.
- Prefer changes that improve profit without increasing drawdown, weak windows, or hidden fragility.

## Background Testing Safety

Local MT5 testing should use the hidden/background launch path only. The latest safety audit after local MT5 runs passed `39 / 39` checks.

## Next Research Gates

1. Run wider real-tick monthly/quarterly validation on Dec-ISLP-Off.
2. Investigate why Model2 prefers the previous no-m1-shock profile while Model0, Model1, and Model4 prefer Dec-ISLP-Off.
3. Continue looking for profit lanes that add trades without creating losing windows.
4. Keep rejected high-profit variants documented so they are not accidentally re-promoted.

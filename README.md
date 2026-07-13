# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

No martingale. No grid. No averaging down. No recovery sizing. Risk control stays above profit chasing.

## Latest Status

Last updated: 2026-07-13 after adding a conservative trade-readiness candidate and FMLR tick-speed reclaim probe.

Use this README as the GitHub status board. The local workspace is still the research source of truth because this Codex folder is not a valid Git checkout, but this page tracks the current local research state.

## Current Answer

- Current stability-best research profile: `Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`.
- Trade-readiness candidate: `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set`.
- Trade-readiness profile SHA-256: `B683100CA5BE912A9A848C3F715A67E4705473B00DEEF4B9070AE02BFDB708C5`.
- Trade-readiness status: demo/forward-test only, not real-money approved.
- Live trading status: not live-ready.
- Latest promoted idea: Low-ATR ISLP trades require order-flow confirmation.
- Latest local source hash: `B6AA1915D2CA7483B1066C227F2506D7A85756D918820FF1100BAF66B0FBDBBE`.
- Latest source manifest: `outputs/SOURCE_MANIFEST.md`.
- Latest package/profile refinement: added isolated `fmlr_tick_speed_reclaim` validation profile.
- Active full FMLR validation package: `456` Model4 configs, `38` profiles.
- Active fast FMLR screen: `150` Model4 configs, `25` profiles.
- MT5 compile/backtest for the new FMLR package and readiness candidate: pending. No new profit result yet.
- MT5 local launch lock: still active to prevent popups/focus stealing.
- GitHub Actions: manual-only; heavy tester runs should stay local, not in Actions.

## Trade-Readiness Candidate

The readiness candidate starts from the current stability-best profile but tightens risk and execution controls:

- `InpRiskPercent=0.50`
- `InpMaxEffectiveRiskPercent=0.50`
- `InpMaxOpenRiskPercent=0.75`
- `InpMaxPositionLots=0.05`
- `InpMaxDailyLossPercent=0.75`
- `InpMaxWeeklyLossPercent=2.00`
- `InpMaxMonthlyLossPercent=4.00`
- `InpMaxEquityDrawdownPercent=10.00`
- `InpMaxDailyLossCount=1`
- `InpMaxConsecutiveLosses=2`
- `InpCooldownMinutesAfterLoss=240`
- Adaptive Reverse disabled
- FMLR research lane disabled
- tick-speed research input disabled
- spread, margin, drawdown, loss-scaling, and profit-giveback guards enabled

This is safer than the research profile, but it still needs fresh Model4 real-tick backtests, full report exports, monthly/quarterly validation, broker-specific stress checks, Monte Carlo, and demo forward testing before real money.

## Screenshot Clarification

The first screenshot is a profit-context table, not a pure best-to-worst leaderboard.

The second screenshot is the older Dec-ISLP-Off promotion comparison. Some of those larger numbers are sampled validation totals. They are useful for comparing profiles, but they are not one continuous account curve and should not be read as yearly account growth.

Return math below assumes a `$1,000` starting balance and uses CAGR over `2024.01.01` to `2026.07.12`, about `2.53` years. Sampled totals are marked `N/A` because they are aggregate validation scores, not sequential account returns.

## Profit Context

| Result | Type | Return Math | Meaning |
| --- | --- | --- | --- |
| `+$10,127.76` | Continuous Model1 | `+1012.78%` total, `+159.47%/yr` CAGR | Best historical/current Model1 continuous research result for Dec-ISLP-Off style profile |
| `+$4,507.51` | Continuous Model4 | `+450.75%` total, `+96.43%/yr` CAGR | Historical real-tick Dec-ISLP-Off result, stale until reproduced on current compact path |
| `+$1,195.69` | Continuous Model4 | `+119.57%` total, `+36.51%/yr` CAGR | Fresh current-source real-tick LowATR OrderFlow check |
| `+$7,469.00` | Sampled Model4 total | N/A, sampled score | Aggregate validation-window score, not a sequential account return |

The bot is still a research project. The current evidence is good enough to keep testing, not good enough to fund seriously.

## Latest Local Work

The local source now has a default-off FMLR tick-speed reclaim path. It can tag `FMLR tick-speed reclaim` when an existing sweep/reclaim context is followed by a directional tick-speed impulse through `InpUseTickSpeedImpulse`.

The latest isolated package profile is `fmlr_tick_speed_reclaim`. It is not promoted and has not been MT5 backtested.

## Validation Passed Locally

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `TRADE_READINESS_PROFILE_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

Cleanup dry-run after the package refresh found `0` active generated cleanup candidates.

## Current Work Queue

1. Do not run heavy MT5 tests in GitHub Actions.
2. Keep the MT5 launch lock active until the focus-stealing issue is solved.
3. Run the trade-readiness candidate in local hidden Model4 real-tick tests when MT5 launch safety is acceptable.
4. Run the 150-config fast FMLR screen locally before the full 456-config FMLR package.
5. Extract full trade stats: drawdown, trades, profit factor, expected payoff, average winner/loss, largest loss, consecutive losses, exposure, spread, swap, commission, and slippage.
6. Validate with older data, walk-forward, Monte Carlo, and broker variation before any live use.

## Source Sync Status

Important: this GitHub status update was made through the GitHub connector because the local folder is not a valid Git checkout. The local `.git` directory exists but is empty. Local shell also has no GitHub CLI, no SSH key for GitHub, and HTTPS Git needs credentials.

That means this GitHub update refreshes lightweight dashboard/evidence files. The full local EA source and generated scripts may still be ahead of GitHub until a proper authenticated Git push path is available.

## Latest Evidence Notes

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `outputs/SOURCE_MANIFEST.md`
- `research/2026-07-13-trade-readiness-candidate-note.md`
- `research/2026-07-13-fmlr-tick-speed-reclaim-note.md`
- `research/2026-07-13-fmlr-sweep-unlimited-runner-note.md`
- `research/2026-07-13-flat-month-liquidity-reclaim-lane-note.md`

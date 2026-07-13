# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

No martingale. No grid. No averaging down. No recovery sizing. Risk control stays above profit chasing.

## Latest Status

Last updated: 2026-07-13 after the local cleanup/package refresh.

Use this README as the GitHub status board. The detailed local workspace is currently ahead of GitHub source, so treat this page as the current research dashboard, not a live-trading approval.

## Current Answer

- Current stability-best research profile: `Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`.
- Live trading status: not live-ready.
- Latest promoted idea: Low-ATR ISLP trades require order-flow confirmation.
- Latest local source hash: `10D1007CFD4CB124C8DE6EC247E1DE1611F1A7955E4E8EC2F9816B2A238DFA04`.
- Latest source change: default-off FMLR sweep-runner target path for clean non-structural liquidity-sweep reclaims.
- Latest package/profile refinement: added isolated `fmlr_sweep_runner` validation profile.
- Active full FMLR validation package: `432` Model4 configs, `36` profiles.
- Active fast FMLR screen: `138` Model4 configs, `23` profiles.
- MT5 compile/backtest for the new FMLR package: pending. No new profit result yet.
- MT5 local launch lock: still active to prevent popups/focus stealing.
- GitHub Actions: manual-only; heavy tester runs should stay local, not in Actions.

## Profit Context

The old `$866 in 2.5 years` number is outdated. The best promoted research profile remains better than that baseline, but the newest FMLR work has not produced a confirmed new best yet.

Known headline numbers still need caution:

| Result | Meaning |
| --- | --- |
| `+$10,127.76` | Best historical/current Model1 continuous research result for Dec-ISLP-Off style profile |
| `+$4,507.51` | Historical Model4 continuous Dec-ISLP-Off result, stale until reproduced on current compact path |
| `+$1,195.69` | Fresh current-source Model4 continuous LowATR OrderFlow check from earlier validation |
| `+$7,469.00` | Aggregate sampled Model4 validation-window score, not a sequential account return |

The bot is still a research project. The current evidence is good enough to keep testing, not good enough to fund seriously.

## Latest Local Work

The local workspace now has a much larger default-off FMLR research surface, including:

- liquidity sweeps and reclaims
- session/Asian range reclaims
- equal-level and swing-sweep reclaims
- previous day/week/month and open-level logic
- failed-breakout traps
- breakout retests
- displacement pullbacks
- FVG, order-block, and CHoCH retests
- imbalance continuation
- runner target stretch
- structural target/fallback runner paths
- structural stop cluster/pocket buffering
- catch-up threshold, cadence, and risk controls
- Adaptive Reverse quarantine guardrails

The latest isolated package profile is `fmlr_sweep_runner`. It tests the new non-structural sweep-runner payoff path without requiring sweep-displacement BOS.

## Validation Passed Locally

These checks passed locally after the `fmlr_sweep_runner` package refresh:

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

Cleanup dry-run after the package refresh found `0` active generated cleanup candidates.

## Current Work Queue

1. Do not run heavy MT5 tests in GitHub Actions.
2. Keep the MT5 launch lock active until the focus-stealing issue is solved.
3. Run the 138-config fast FMLR screen locally first.
4. Only run the full 432-config FMLR package if a candidate beats `lowatr_current` without adding red control windows.
5. Extract full trade stats: drawdown, trades, profit factor, expected payoff, average winner/loss, largest loss, consecutive losses, exposure, spread, swap, commission, and slippage.
6. Validate with older data, walk-forward, Monte Carlo, and broker variation before any live use.

## Source Sync Status

Important: this GitHub status update was made through the GitHub connector because the local folder is not a valid Git checkout. The local `.git` directory exists but is empty. Local shell also has no GitHub CLI, no SSH key for GitHub, and HTTPS Git needs credentials.

That means this GitHub update refreshes the dashboard/status files, but the full local EA source and all generated local scripts may still be ahead of GitHub until a proper authenticated Git push path is available.

Recommended fix for full source sync:

1. Install/authenticate GitHub CLI with `gh auth login`, or clone `Antoee/gold` fresh with valid Git credentials.
2. Copy the current local workspace files into that real checkout.
3. Commit and push from the real checkout.
4. Keep `.github/workflows/static-safety.yml` manual-only so the push does not spend Actions minutes.

## Latest Evidence Notes

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `research/2026-07-13-fmlr-sweep-runner-profile-note.md`
- `research/2026-07-13-repository-cleanup-refresh-note.md`
- `research/2026-07-13-flat-month-liquidity-reclaim-lane-note.md`

## Rules For Future Updates

When Codex changes the bot or runs meaningful tests, update this README with:

1. Current best profile, or say the old best still stands.
2. Exact tester model: `Model=0`, `Model=1`, `Model=2`, or `Model=4`.
3. Exact date window.
4. Net profit, worst window, losing-window count, and failures.
5. Evidence CSV or research note.
6. Promotion decision: promoted, rejected, or probe only.

If a run returns `NO_REPORT`, it does not count as proof.

# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

No martingale. No grid. No averaging down. No recovery sizing. Risk control stays above profit chasing.

## Latest Status

Last updated: 2026-07-13 after the local FMLR sweep-unlimited runner package and source-manifest refresh.

Use this README as the GitHub status board. The local workspace is still the research source of truth because this Codex folder is not a valid Git checkout, but this page tracks the current local research state.

## Current Answer

- Current stability-best research profile: `Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`.
- Live trading status: not live-ready.
- Latest promoted idea: Low-ATR ISLP trades require order-flow confirmation.
- Latest local source hash: `0289641ABE4F1B93FB69D81FF098FFBAA28FFA14478282ACD0BCA4B3A1CBAFC3`.
- Latest source manifest: `outputs/SOURCE_MANIFEST.md`.
- Latest source change: default-off FMLR no-fixed-TP runner permission now recognizes proven non-structural sweep-runner setups when forward clearance, runner-stretch evidence, and FMLR structure trailing are present.
- Latest package/profile refinement: added isolated `fmlr_sweep_unlimited_runner` validation profile.
- Active full FMLR validation package: `444` Model4 configs, `37` profiles.
- Active fast FMLR screen: `144` Model4 configs, `24` profiles.
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

The local workspace now has a larger default-off FMLR research surface. The newest profit-capture change lets clean non-structural sweep-runner setups use the existing no-fixed-TP runner only when the setup still proves forward clearance, runner-stretch evidence, planned RR, spread-adjusted RR, and FMLR structure trailing.

The latest isolated package profile is `fmlr_sweep_unlimited_runner`. It tests the new no-fixed-TP sweep-runner payoff path without requiring sweep-displacement BOS.

The source manifest records the current local `.mq5` hash, size, line count, active FMLR package counts, and smoke-test status so GitHub can still track the real local research state while full Git push access is unavailable.

## Validation Passed Locally

These checks passed locally after the `fmlr_sweep_unlimited_runner` package refresh:

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
3. Run the 144-config fast FMLR screen locally first.
4. Only run the full 444-config FMLR package if a candidate beats `lowatr_current` without adding red control windows.
5. Extract full trade stats: drawdown, trades, profit factor, expected payoff, average winner/loss, largest loss, consecutive losses, exposure, spread, swap, commission, and slippage.
6. Validate with older data, walk-forward, Monte Carlo, and broker variation before any live use.

## Source Sync Status

Important: this GitHub status update was made through the GitHub connector because the local folder is not a valid Git checkout. The local `.git` directory exists but is empty. Local shell also has no GitHub CLI, no SSH key for GitHub, and HTTPS Git needs credentials.

That means this GitHub update refreshes lightweight dashboard/evidence files. The full local EA source and generated scripts may still be ahead of GitHub until a proper authenticated Git push path is available.

## Latest Evidence Notes

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `outputs/SOURCE_MANIFEST.md`
- `research/2026-07-13-fmlr-sweep-unlimited-runner-note.md`
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

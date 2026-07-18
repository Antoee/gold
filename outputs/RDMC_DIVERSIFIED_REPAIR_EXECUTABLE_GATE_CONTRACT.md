# RDMC Diversified Repair Executable Gate Contract

Status: **FROZEN / LOCKED / ZERO MT5 REPORTS / NOT PROMOTED**

This contract replaces chronological all-at-once testing with early rejection. It preserves the exact source and profile while spending real-tick time only after cheaper evidence passes.

## Frozen Identity

- Source SHA-256: `EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F`
- Profile SHA-256: `746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883`
- Starting capital: `10,000 USD`
- Symbol/timeframe: `XAUUSD M15`
- Data cutoff: `2026.07.12`
- Configs: `24` with each config SHA-256 pinned in the combined manifest

## Efficient Waves

| Wave | Model | Runs | Maximum workers | Admission purpose |
|---:|---|---:|---:|---|
| 1 | Model1 | 2 | 2 | Reject immediately on the known 2019 or 2022 failure year |
| 2 | Model1 | 4 | 4 | Check three disjoint broad eras plus the continuous path |
| 3 | Model4 real ticks | 2 | 2 | Recheck 2019 and 2022 before broad real-tick cost |
| 4 | Model4 real ticks | 4 | 3 | Run three disjoint eras, union verified complete-month tick caches, then check continuous risk-adjusted return |
| 5 | Model4 real ticks | 12 | 6 | Prove annual restart stability only after all earlier gates pass |

A failed or incomplete wave never admits later waves. At most two tests are spent before the first rejection decision and only eight tests are spent before real-tick testing begins.

Wave 4 keeps all four frozen evidence rows but executes them in two stages. The three non-overlapping eras run first on at most three workers. With every portable terminal stopped, only missing complete-month `MetaQuotes-Demo/ticks/XAUUSD/*.tkc` files from January 2015 through June 2026 are copied through SHA-256-verified temporary files to form one cache union. The partial July 2026 cutoff month is never copied because unused tail ticks can differ between roots. Any missing complete month, same-name hash conflict, target overwrite, running portable process, or failed post-copy union stops the wave. The continuous 2015-2026 row starts only after that cache step succeeds.

## Frozen Gates

- Critical 2019/2022 rows: positive net, PF at least `1.05`, frozen activity floor, and drawdown no higher than `3%`.
- Broad eras: every disjoint era positive, PF at least `1.20`, frozen activity floor, and drawdown no higher than `5%`.
- Continuous Model1 triage: PF at least `1.25`, at least `250` trades, drawdown no higher than `5%`, recovery at least `2`, and CAGR at least `0.75%`.
- Continuous Model4: PF at least `1.30`, at least `250` trades, drawdown no higher than `5%`, recovery at least `3`, and CAGR at least `1.00%`.
- Annual Model4: all 12 annual/YTD rows profitable with frozen activity floors and drawdown no higher than `3%`; summed annual net must remain within `0.75x` to `1.25x` of continuous Model4 net.

## Identity-Bound Admission

- Plan mode selects only the currently admitted wave and never launches MT5.
- Parallel, worker, and direct-config launch layers each invoke the hard-lock guard before resolving a runtime or config.
- Run mode compiles the exact package source once on one allowlisted leader and distributes the same source, EX5, and two-line source/binary identity file to every portable root before workers start.
- The prepared binary SHA-256 is passed through the orchestrator, parallel runner, worker, and direct launcher. A worker with missing or changed bytes fails before testing and may not compile independently.
- Every worker rechecks the manifest-pinned config and source hashes and records the compiled binary hash.
- Before launch, the direct runner removes every same-named report under the admitted portable root. It waits for clean terminal exit and then requires exactly one fresh, non-empty report whose size and timestamp remain stable after exit.
- A completed worker row is reusable only with an adjacent schema-versioned sidecar binding the exact report hash, config hash, source hash, compiled-binary hash, report name, size, and creation time.
- The collector requires one runner row per admitted config, one shared binary identity, the exact report name, the frozen source identity inside every report, and an independently revalidated sidecar/report hash before parsing metrics.
- The admission evaluator rejects failed completed waves, leaves missing waves pending, and cannot promote a five-wave pass without executable-ledger stress.

## Hard Boundary

- Both MT5 launch locks are present. No terminal, MetaEditor, tester, or worker was launched to build this package.
- Model1 only rejects cheaply; it can never promote the candidate.
- Passing wave 5 still requires an executable trade ledger, deterministic cost stress, order-aware Monte Carlo, broker variation, and a valid forward demo.
- The post-hoc `+$2,067.64` collision score is not attributed to this source. The registered forward candidate and real-account lock remain unchanged.

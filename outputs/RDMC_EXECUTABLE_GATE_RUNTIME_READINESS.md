# RDMC Executable Gate Runtime Readiness

Status: **LOCKED / COMPILE ONCE REQUIRED / WAVE 1 BAR DATA READY**

Read-only inventory performed on 2026-07-18. No terminal, MetaEditor, or tester process was launched.

## Portable Runtimes

- Four allowlisted roots are present: leader plus workers `w2`, `w3`, and `w4`.
- Every root contains `terminal64.exe` and `MetaEditor64.exe` at MT5 build `5989`.
- Approximately `91.3 GB` was free on the workspace drive during the inventory.
- Both repository and outer-workspace launch locks were present; no unlock acknowledgement was present.

## Binary Blocker Closed In Code

All four roots currently contain one older source identity but four different compiled EX5 identities. Independent compilation is therefore not byte-reproducible enough for the collector's one-binary admission contract.

The staged run path now:

1. validates the exact candidate source hash;
2. compiles once on the first allowlisted portable root;
3. distributes the exact source, EX5, and source/binary identity file to all roots;
4. verifies every copied hash;
5. passes the prepared EX5 hash through the parallel runner to each worker;
6. prohibits any worker from compiling independently;
7. starts the admitted wave only after shared-binary preparation succeeds.

Current plan status is `LOCKED_COMPILE_ONCE_REQUIRED`. Compilation is intentionally unclaimed while the locks remain active.

## Historical Data

Every root has XAUUSD bar-history files for 2008 through 2026, so the admitted Model1 2019/2022 rejection wave is locally staged.

Each root currently has the same 39 cached real-tick months:

- all months in 2019 and 2020;
- May through December 2025;
- January through July 2026.

Real-tick months for 2015-2018 and 2021-2024 are not cached. MT5 must obtain them before the later Model4 waves can complete. This is an execution-time efficiency gap, not missing historical evidence and not permission to shorten the frozen test windows.

Wave 4 now avoids downloading that missing history twice for overlapping windows. Its three disjoint era rows run first, then a process-free cache step hashes complete-month XAUUSD `.tkc` files and copies only verified missing months across the four allowlisted roots. The continuous row runs afterward only if all `138` required months from January 2015 through June 2026 are covered. The partial July 2026 cutoff month remains local to each terminal because unused tail ticks can differ; it is reported but never copied. The current inventory sees `39` cached months, with `152` complete-month files hash-checked, zero historical conflicts, and zero cross-root copies currently required. It also reports the important gap: `100` required months are absent from every root and must be downloaded by the disjoint era stage before the continuous row is allowed.

## Boundaries

- Source/profile identities and all gate thresholds remain unchanged.
- The registered forward candidate remains unchanged.
- The invalid `$100,000` demo attachment still contributes zero forward days, trades, or profit.
- No profitability result, new best, compilation success, or real-money approval is inferred from runtime readiness.

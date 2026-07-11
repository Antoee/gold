# Adaptive Reverse Off Promotion Note

Date: 2026-07-11

## Decision

Promote `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_MICRO_JULOCT_PROFILE.set` as the current research-best profile.

This profile is the prior Aug40 research-best with one explicit risk-reduction override:

```text
InpUseAdaptiveReverse=false||false||0||0||N
```

SHA-256:

```text
43FD53C09EDA74BA449B5754B502EADA68EADD53AAE74AE89153BB2DA122E96D
```

## Promotion Evidence

Model 2 ablation summary:

- Source: `outputs/CURRENT_BEST_ADAPTIVE_REVERSE_ABLATION_MODEL2_LOG_SUMMARY.csv`
- `reverse_off` matched `base` exactly across 11/11 parsed windows.
- Continuous: `5805.71`
- 2026 YTD: `1107.90`
- Full 2025: `214.18`
- Full 2024: `2360.86`
- Worst window: `0`
- Losing windows: `0`

Model 0 confirmation summary:

- Source: `outputs/CURRENT_BEST_ADAPTIVE_REVERSE_ABLATION_MODEL0_LOG_SUMMARY.csv`
- `reverse_off` matched `base` exactly across 11/11 parsed windows.
- Continuous: `5814.52`
- 2026 YTD: `1107.93`
- Full 2025: `214.30`
- Full 2024: `2371.39`
- Worst window: `0`
- Losing windows: `0`

## Rationale

The active research-best did not need Adaptive Reverse to produce its measured edge on the tested full, recent, yearly, May, and flat-month windows. Disabling Adaptive Reverse reduces the hidden stop-and-reverse whipsaw risk without reducing measured profit in the current validation set.

This does not solve the flat-month opportunity problem by itself. It is a risk-quality improvement: same measured edge, less fragile execution behavior.

## Rejected Branches

May-window expansion:

- Source: `outputs/CURRENT_BEST_MAY_WINDOW_LADDER_MODEL2_LOG_SUMMARY.csv`
- `may_d10_r280` tied baseline continuous but did not improve YTD.
- `may_d15_r320` and `may_d20_r320` increased target May upside but introduced a losing May 2024 window (`-207.86`), so they were rejected.

Guarded expansion:

- Source: `outputs/CURRENT_BEST_GUARDED_EXPANSION_MODEL2_LOG_SUMMARY.csv`
- May 3.20 risk plus Adaptive Reverse guards still had a losing window.
- Liquidity-aware stop combinations reduced continuous profit sharply or introduced multiple losing windows.
- Flat breakout and missed-move guard lanes reduced continuous profit and introduced red windows.

Adaptive Reverse strict guards:

- Source: `outputs/CURRENT_BEST_ADAPTIVE_REVERSE_ABLATION_MODEL2_LOG_SUMMARY.csv`
- `range_trap_guard` and `followthrough_guard` avoided red windows but cut continuous profit from `5805.71` to `1028.98`.
- They are rejected for the current research-best, though the ideas remain useful for future strategies that rely more heavily on reversals.

## Next Work

The next useful research direction is not more broad flat-month relaxation. Prior flat-month lanes repeatedly hurt robustness. A better next step is to add a very small, independently gated flat-month lane that requires fresh structural displacement plus liquidity clearance and does not interact with Adaptive Reverse.

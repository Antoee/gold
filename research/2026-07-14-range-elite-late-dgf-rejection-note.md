# 2026-07-14 Range-Elite Late DGF Rejection Note

The latest Model4 follow-up did not produce a new best profile.

What changed:

- Added a default-off late-session guard for pure diagnostic-fallback entries.
- Recompiled the current source successfully with `0 errors, 0 warnings`.
- Verified the root and mirrored EA source hash as `129A489FECFE46470E5417FAD8C98B83E14A691D1370CA493F52A5E59B1E022B`.
- Ran focused Model4 real-tick yearly/YTD packages across 2019, 2021, 2023, 2024, 2025, and 2026 YTD.

What improved:

- `re_may140_late15_pure` reduced the worst losing window from `-$140.18` to `-$62.11`.
- It turned 2023 from red to green.
- It kept 2024 and 2025 profitable.

What failed:

- 2019 and 2021 were still red.
- 2026 YTD dropped from `+$871.35` on `re_may140` to `+$472.36`.
- The best late-session variant had only `26` trades across six broad windows.
- No variant cleared the no-red-broad-window stability gate.

Conclusion:

Keep the source switch for future diagnostics, but reject the profiles. The next useful work is entry-quality or market-phase filtering for the older-year failure pattern, not more risk shaping or session-only blocking.

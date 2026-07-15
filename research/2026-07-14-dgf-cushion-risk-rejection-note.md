# 2026-07-14 DGF Cushion-Risk Rejection Note

The DGF cushion-risk throttle improved safety but did not create a money-ready profile.

What improved:

- `cush50` reduced worst DD from `24.72%` to `20.84%`.
- `cush50` flipped 2021 and 2025 from red to green.
- `cush50` still made `+$2,770.74` across six Model4 yearly/YTD windows.
- The source compiled cleanly and all `54 / 54` focused reports parsed as exported MT5 reports.

What failed:

- 2019 remained red.
- Drawdown remained above `20%`.
- More defensive `cush35` and `cush25` reduced profit too much.
- August-off variants were rejected because they were too calendar-specific and created a new red 2025 window.

Conclusion:

Keep the default-off DGF cushion-risk code. Do not promote the profile. The next useful step is reducing drawdown in the 2023/2026 high-DD windows or finding a non-calendar explanation for the remaining 2019 August failures.

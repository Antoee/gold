# Primary August 0.40 Risk Promotion Note

## Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_AUG40_MICRO_JULOCT_PROFILE.set`
- SHA-256: `F351328C3DB0AC78BE97E6FFF5904C80D15B9E80107C4F9F34323BF4811B51EA`
- Base profile: `outputs/CANDIDATE_PRIMARY_AUG20_MICRO_JULOCT_PROFILE.set`
- Change: `InpAugustRiskMultiplier` increased from `0.20` to `0.40`

## Model 0 Validation

- Evidence: `outputs/CURRENT_BEST_AUGUST_RISK_LADDER_MODEL0_LOG_SUMMARY.csv`
- `aug_risk040` continuous: `5814.52`
- `aug_risk020` continuous: `5340.46`
- Delta versus previous research-best: `+474.06`
- Full 2024 improved from `2179.44` to `2371.39`
- Full 2025 unchanged at `214.30`
- 2026 YTD unchanged at `1107.93`
- Worst window: `0`
- Losing windows: `0`

## Model 2 Triage

- Evidence: `outputs/CURRENT_BEST_AUGUST_RISK_LADDER_MODEL2_LOG_SUMMARY.csv`
- `aug_risk040` continuous: `5805.71`
- `aug_risk020` continuous: `5369.25`
- Worst window: `0`
- Losing windows: `0`

## Rejected Higher-Risk Variants

- `aug_risk060`: rejected. Model 0 had `2` losing windows and worst window `-54.90`.
- `aug_risk100`: rejected. Model 2 had `2` losing windows and worst window `-98.64`.
- `aug_risk150`: rejected. Model 2 had `1` losing window and worst window `-147.96`.
- `aug_risk200`: rejected. Model 2 had `2` losing windows and worst window `-197.28`.

## Decision

Promote `aug_risk040` as the current research-best candidate. It increases profit versus the prior August 0.20 profile without adding losing validation windows in the tested broad/recent/OOS/target windows. This remains a research-best profile, not a final production deployment.

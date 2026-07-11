# Current Best Spread Stress Note

## Scope

Tested `outputs/CANDIDATE_PRIMARY_AUG20_MICRO_JULOCT_PROFILE.set` against stricter spread protections:

- `aug20_maxspread220`
- `aug20_regime155`
- `aug20_shock180`
- `aug20_spread_rr125`

## Results

- Model 2 evidence: `outputs/CURRENT_BEST_SPREAD_STRESS_MODEL2_LOG_SUMMARY.csv`
- Model 0 evidence: `outputs/CURRENT_BEST_SPREAD_STRESS_MODEL0_LOG_SUMMARY.csv`
- All variants matched the baseline in the tested windows.
- Model 0 continuous stayed `5340.46`.
- Model 2 continuous stayed `5369.25`.
- No spread variant added losing windows, but none improved profit either.

## Decision

Do not promote a spread-stress variant from this test. Keep the spread controls available as defensive knobs, but use profit-improving candidates for the research-best pointer.

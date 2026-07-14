# Peak R20 Diagnostic Fallback Performance Risk Yearly Package

Offline package builder only. This does not launch MT5.

- Source hash: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`
- Base profile hash: `CB182D026A62AE499052949F88F514EF7FC67D8C071E9179AB069D29575C59B2`
- Model: `1`
- Candidates: `6`
- Windows: `8`
- Configs: `48`

- `r10_a7_dgf_perf_base`: Control: no diagnostic fallback performance risk scaling.
- `r10_a7_dgf_perf_4_2_50`: Throttle DGF risk to floor 0.50 when last 4 DGF trades, minimum 2 samples, average R is weak.
- `r10_a7_dgf_perf_3_2_40`: More reactive DGF performance throttle using last 3 DGF trades, minimum 2 samples, floor 0.40.
- `r10_a7_dgf_perf_5_2_50`: Smoother DGF performance throttle using last 5 DGF trades, minimum 2 samples, floor 0.50.
- `r10_a7_dgf_spread_perf_4_2_50`: Combine spread risk 25-45 floor 0.50 with DGF performance throttle 4/2 floor 0.50.
- `r10_a7_dgf_spread_perf_3_2_40`: Combine spread risk 25-45 floor 0.50 with more reactive DGF performance throttle 3/2 floor 0.40.

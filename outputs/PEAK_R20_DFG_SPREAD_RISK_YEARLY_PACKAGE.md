# Peak R20 Diagnostic Fallback Spread Risk Yearly Package

Offline package builder only. This does not launch MT5.

- Source hash: `0C6C3A6237A1C4007924DDB4054DA41007ACDC2323828AD97C6BFFAE2B64C7F9`
- Base profile hash: `CB182D026A62AE499052949F88F514EF7FC67D8C071E9179AB069D29575C59B2`
- Model: `1`
- Candidates: `6`
- Windows: `8`
- Configs: `48`

- `r10_a7_dfg_risk_base`: Control: no diagnostic fallback spread risk scaling.
- `r10_a7_dfg_risk_25_45_50`: Scale diagnostic fallback risk from 25 to 45 spread points, floor 0.50.
- `r10_a7_dfg_risk_25_35_35`: Scale diagnostic fallback risk from 25 to 35 spread points, floor 0.35.
- `r10_a7_dfg_risk_25_31_25`: Aggressively scale diagnostic fallback risk from 25 to 31 spread points, floor 0.25.
- `r10_a7_dfg_risk_20_35_35`: Scale diagnostic fallback risk from 20 to 35 spread points, floor 0.35.
- `r10_a7_dfg_risk_20_31_25`: Aggressively scale diagnostic fallback risk from 20 to 31 spread points, floor 0.25.

# DGF High-Profit Risk-Shape Probe Package

Offline package builder only. This does not launch MT5.

- Purpose: reduce drawdown on the profitable DGF continuous branch without returning to the early global peak-trail freeze.
- Source hash: 8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A
- Base profile hash: 0FBFA1F540422DF1B88A9410752E706B917F3111BFEF317F7EE9A03D7A4C2499
- Window: 2019.01.01 to 2026.07.12
- Model: 4
- Configs: 11

## Candidates

| Rank | Candidate | Profile SHA-256 | Rationale |
| ---: | --- | --- | --- |
| 1 | dgf_hp_control | C8B25273CC6A42F433F38C1DB78A65A454E6890EBC91379F09885C5DBE5AB207 | Current high-profit DGF continuous lead control. |
| 2 | dgf_hp_risk050 | 819D56A5C404F2470348A51911C257DAF314D59AD7C95A92B202F6909DA83D6A | Scale base risk from 1.00% to 0.50%. |
| 3 | dgf_hp_risk060 | 554611B7A8F8FC35530942D3014F78BFA2F8497A0A7425CA216346F00534C21E | Scale base risk from 1.00% to 0.60%. |
| 4 | dgf_hp_risk070 | 039297AAAE7929B73AFB73E9C03A714B9D2AF76D558EA3EF6391703437D8012A | Scale base risk from 1.00% to 0.70%. |
| 5 | dgf_hp_risk080 | FC64C9F6D9946090E574A368EE97D0D48923829DF8CC11B453EE702B7BA9CF25 | Scale base risk from 1.00% to 0.80%. |
| 6 | dgf_hp_risk060_loss_scale | 9BA20D63588B4FF4DCEFB5FD93756C151AAF35A82CC001A1546A66E92B17FA6F | 0.60% base risk plus daily/weekly/monthly loss-risk scaling. |
| 7 | dgf_hp_risk080_loss_scale | 9DF4723EA6B1C4CFE3B3A8027345120B58845025ECB6F0EB3D8067FA22CE402B | 0.80% base risk plus daily/weekly/monthly loss-risk scaling. |
| 8 | dgf_hp_risk080_dd12 | 9D4CA569D5C6F2BC851E555EA0D33502958A51831CDD4F53A80C6A19AA58869B | 0.80% base risk plus 12% max-equity-drawdown safety cap. |
| 9 | dgf_hp_peaktrail_20p70gb | 2FDD1D7E0191987BE66DD7050B4BBC94DDEAF9835E232354957B58B5DFD553FB | Late profit lock after 20% gain with 70% peak-profit giveback. |
| 10 | dgf_hp_peaktrail_35p70gb | 28CE2706FBA9E2014E0CD5130BD3BFDAB3122DE98E23DD1131A4183D647FB30F | Later profit lock after 35% gain with 70% peak-profit giveback. |
| 11 | dgf_hp_risk080_peaktrail_20p70gb | C12525677F8817F02C3E55C1C61CD5494C75C6BFFF540D0E7996C04ED4A646FF | 0.80% base risk plus late 20%/70% profit lock. |

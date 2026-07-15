# Peak-Trail Unblock Probe Package

Offline package builder only. This does not launch MT5.

- Purpose: test whether the global equity profit peak trail caused the continuous-account stall after August 2019.
- Window: `2019.01.01` to `2026.07.12`
- Model: `4`
- Source hash: `8D62D907EBF8295DAA44F85DECD0C86690CF4D9A3FE6B858DFD9223E7CF8DF7A`

## Candidates

| Rank | Candidate | Profile SHA-256 | Description |
| ---: | --- | --- | --- |
| 1 | `lossblock_stability_peaktrail_off` | `C51E67430B5B21AFF25F0771F57F0242AF48BF1DF6A506F89A75551F56B61C6E` | Disable global equity profit peak trail to test whether it caused the continuous-account stall. |
| 2 | `lossblock_stability_peaktrail_8p_50gb` | `D6778DEA343CD0AE978D6F9AA168A495CBE2EB4C0FB7691D413524F3CB5EA212` | Keep peak-trail risk control, but only after an 8% account gain with 50% peak-profit giveback. |
| 3 | `lossblock_highprofit_peaktrail_off` | `0FBFA1F540422DF1B88A9410752E706B917F3111BFEF317F7EE9A03D7A4C2499` | Disable global equity profit peak trail to test whether it caused the continuous-account stall. |
| 4 | `lossblock_highprofit_peaktrail_8p_50gb` | `B94014C5CEF1AAC55E4C63CB7A6C09EAAAC899756F9BBFBE6A51B23DC872B70F` | Keep peak-trail risk control, but only after an 8% account gain with 50% peak-profit giveback. |

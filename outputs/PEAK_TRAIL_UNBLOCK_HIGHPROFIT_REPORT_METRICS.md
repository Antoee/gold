# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\PEAK_TRAIL_UNBLOCK_HIGHPROFIT_REMAINING_MANIFEST.csv`
- Hidden run CSV: `outputs\PEAK_TRAIL_UNBLOCK_HIGHPROFIT_RUN.csv`
- Log files scanned: `2`
- Expected rows: `2`
- Parsed exported reports: `2`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lossblock_highprofit_peaktrail_8p_50gb` |  | peak_trail_unblock_probe | 1 | 0 | 1 | 108.48 | 108.48 |  |  | 19.9 | 1.22 | 32 |
| `lossblock_highprofit_peaktrail_off` |  | peak_trail_unblock_probe | 1 | 0 | 1 | 1915.83 | 1915.83 |  |  | 24.58 | 1.72 | 127 |

## Missing Or Unparsed

All queued rows have report or log evidence.

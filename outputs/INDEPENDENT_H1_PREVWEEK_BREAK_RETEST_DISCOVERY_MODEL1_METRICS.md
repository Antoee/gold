# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `42`
- Parsed exported reports: `42`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `pwbr_adx18` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -48.3 | -57.2 | 0 | -0.14 | 0.73 | 0.5 | 48 |
| `pwbr_age12` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -119.44 | -92.77 | -0.05 | -0.23 | 1.07 | 0.45 | 64 |
| `pwbr_age4` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -120.94 | -83.57 | -0.06 | -0.21 | 1.07 | 0.41 | 50 |
| `pwbr_base` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -135.98 | -101.04 | -0.06 | -0.25 | 1.24 | 0.37 | 60 |
| `pwbr_break_loose` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -162.64 | -115.53 | -0.09 | -0.29 | 1.31 | 0.44 | 74 |
| `pwbr_break_strict` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -89.78 | -64.1 | -0.04 | -0.16 | 0.88 | 0.39 | 42 |
| `pwbr_buffer15` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -139.26 | -91.38 | -0.08 | -0.23 | 1.15 | 0.39 | 56 |
| `pwbr_no_trend` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -172.92 | -111.19 | -0.1 | -0.28 | 1.25 | 0.41 | 70 |
| `pwbr_retest_loose` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -72.7 | -54.15 | -0.04 | -0.14 | 1.56 | 0.75 | 118 |
| `pwbr_retest_tight` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -70.2 | -54.73 | -0.03 | -0.14 | 0.69 | 0 | 16 |
| `pwbr_rr15` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -137.94 | -101.38 | -0.07 | -0.25 | 1.17 | 0.37 | 60 |
| `pwbr_rr25` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -111.76 | -87.07 | -0.05 | -0.22 | 1.15 | 0.45 | 60 |
| `pwbr_session_off` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -177.2 | -103.79 | -0.11 | -0.26 | 1.24 | 0.53 | 84 |
| `pwbr_volume_both` | independent_h1_prevweek_break_retest | discovery_model1 | 3 | 0 | 3 | -67.5 | -33.75 | -0.05 | -0.08 | 0.43 | 0 | 8 |

## Missing Or Unparsed

All queued rows have report or log evidence.

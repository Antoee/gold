# Reversion D1 Momentum-Cap Annual Model4 Decision

**Decision: MONEY-READINESS FAIL. The stability candidate is retained for research, but cost and Monte Carlo stress remain closed and the forward candidate is unchanged.**

- Exact source: `8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B`
- Exact profile: `BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC`
- Exact annual contract: `77AF52DAD7DF99F2AC4BD4340A3B20AD78F4DCB89EAAE59F941F0384402F4087`
- Reports parsed: `12 / 12`; one exact identity-failed rank was retried
- Positive years: `10 / 12`
- Negative years: `2 / 12`
- Summed annual robustness score: `1541.63 USD` on `342` trades

| Year | Net | Return | PF | Trades | DD | Loss streak | Recovery | Non-red |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `year_2015` | $+85.73 | 0.86% | 1.57 | 20 | 0.87% | 3 | 0.9774 | True |
| `year_2016` | $+161.69 | 1.62% | 1.83 | 35 | 0.5% | 4 | 3.2338 | True |
| `year_2017` | $+168.93 | 1.69% | 1.55 | 45 | 0.96% | 5 | 1.7392 | True |
| `year_2018` | $+227.16 | 2.27% | 1.98 | 47 | 0.57% | 3 | 3.8606 | True |
| `year_2019` | $-3.77 | -0.04% | 0.98 | 32 | 0.84% | 6 | -0.0445 | False |
| `year_2020` | $+166.06 | 1.66% | 1.91 | 26 | 0.65% | 3 | 2.5039 | True |
| `year_2021` | $+338.63 | 3.39% | 2.65 | 29 | 1.16% | 8 | 2.925 | True |
| `year_2022` | $-92.78 | -0.93% | 0.57 | 35 | 1.04% | 4 | -0.8933 | False |
| `year_2023` | $+160.80 | 1.61% | 1.66 | 40 | 1.24% | 6 | 1.2781 | True |
| `year_2024` | $+239.93 | 2.4% | 2.53 | 29 | 1.04% | 4 | 2.2669 | True |
| `year_2025` | $+17.78 | 0.18% | 2.91 | 3 | 0.12% | 1 | 1.4235 | True |
| `year_2026_ytd` | $+71.47 | 0.71% | 0 | 1 | 0.55% | 0 | 1.288 | True |

## Gate

- No negative year: `False`
- At least 10 positive years: `True`
- At least 300 summed trades: `True`
- Every annual drawdown no more than 2.50%: `True`
- Every annual loss streak no more than eight: `True`

The center is unusually stable on the continuous path and passes Model 1 holdout plus Model 4 transfer, but annual restarts expose `-$3.77` in 2019 and `-$92.78` in 2022. Better aggregate profit cannot override the frozen no-red-year requirement.

This profile is not money-ready and is not substituted into the registered forward run.

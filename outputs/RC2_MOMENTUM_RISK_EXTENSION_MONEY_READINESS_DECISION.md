# RC2 Momentum-Risk Extension Money-Readiness Decision

**Decision: NOT MONEY-READY. The 0.20% profile remains the highest validated historical net, but the 0.15% control remains the safer forward-test candidate. Real-account trading remains disabled.**

## What Passed

- Continuous Model4: `+1812.42`, PF `1.50`, `362` trades, `3.19%` equity drawdown, `12 / 12` center/neighbor reports passed.
- Annual restarts: `9 / 11` completed years positive, `+$1,778.14` summed restart net, worst annual loss `-$64.93`.
- Added-cost stress: moderate `0.05R` and severe `0.10R` per trade remained profitable; deterministic cost gate passed.

## Blocking Evidence

- Annual restart gate: 2019-2020 totals `-$117.26` versus the frozen `-$100` floor; 2019 PF is `0.82` versus `0.85`.
- Standard bootstrap: center P95 drawdown `6.3829%` and loss run `15.0`; both exceed the frozen caps. The 0.15% control is safer at `5.1797%` P95 drawdown.
- Severe bootstrap: P05 net `-539.32`, P95 drawdown `9.629%`, and `23.33%` red trials.
- Forward demo: zero valid days and zero trades because the attached account violates the frozen starting-capital contract.
- No exact second-broker XAUUSD validation exists.

## Gate Summary

| Area | Status | Evidence |
|---|---|---|
| historical:model4 | PASS | net=1812.42;reports=12;profile=06AE8127CF2719D7D3A19FEE069ECA3D50B83B3B0329C04F7B08E5F9135AFA5A |
| historical:annual-restarts | FAIL | passed=7/9;failed=adjacent-two-year-floor,active-year-profit-factor |
| stress:deterministic-cost | PASS | moderate and severe frozen cost gates |
| stress:bootstrap-monte-carlo | FAIL | standard/severe 10000-trial bootstrap gates |
| forward:capital-contract | FAIL | attached balance does not match frozen 10000 contract |
| forward:minimum-sample | PENDING | validDays=0/90;trades=0/30 |
| broker:second-specification | PENDING | no exact second-broker XAUUSD report |
| safety:real-account-lock | PASS | real-account trading remains disabled |

## Next Strategy Work

Do not raise risk further. The next code experiment must improve the momentum lane's date-independent breakout quality or add a genuinely independent return stream, then repeat broad Model1, exact Model4, annual restart, cost, and bootstrap gates. Calendar exclusions and post-result threshold changes are not permitted.

The registered source/profile/binary identity, evidence logs, account contract, and real-account lock remain unchanged.

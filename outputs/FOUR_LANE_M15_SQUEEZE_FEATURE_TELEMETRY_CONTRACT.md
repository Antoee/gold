# Four-Lane M15 Squeeze Feature-Telemetry Contract

**Status: PREREGISTERED BEHAVIOR-NEUTRAL PRE-2021 RESEARCH. THE VERIFIED LEADER AND FROZEN FORWARD CANDIDATE ARE UNCHANGED.**

- Telemetry source SHA-256: `C6B4BC66F661BB70CC51B92E320A87A5643745454C26791B09766F84DA9C94C4`
- Leader profile SHA-256: `ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C`
- Partial-runner decision SHA-256: `22D031D7C398B7F76DF988523B849C295C812FE650BAAA1BE9773FC94419AD20`
- Frozen analyzer SHA-256: `EDD9DC6CE723F111C9C888B321DF76405A0E581AF539C0DD04F566912E7558C8`
- Manifest SHA-256: `80FA027F757922A9E5404DCD682BC769F2328E5D8FC6F86CEED592B374BB1C07`

- The fork adds zero inputs and zero buy, sell, partial-close, or stop-modification paths. Features are calculated from completed M15 bars and completed H1 indicator values only after every existing entry gate passes.
- Recorded fields: breakout depth, body ratio, close location, range/ATR, expansion ratio, channel width/ATR, squeeze range/ATR, tick-volume ratio, ATR percentage, ADX, direction-adjusted H1 EMA distance/slope, squeeze-width mean/max, and actual stop/ATR.
- Behavior-neutral telemetry only. Exact Model 1 reproduction requires +1695.16 net, 391 report trades, PF 1.84, and 1.10% rounded drawdown before screening. Feature nomination uses only 2015-2018, requires nonnegative removal impact in both 2015-2016 and 2017-2018, >=75% trade retention, improved kept-trade PF, and two adjacent threshold supports. The selected threshold is then frozen before one-shot 2019-2020 validation, which requires nonnegative removal impact in both years and at least one validating neighbor. Post-2020 data remains unopened.
- The offline screen is a hypothesis generator, not a performance claim. Any nominated filter must be implemented default-off and pass a separately frozen MT5 neighborhood before newer data can open.
- No martingale, grid, averaging down, recovery sizing, outcome-conditioned sizing, risk increase, capital change, forward substitution, or real-account trading.

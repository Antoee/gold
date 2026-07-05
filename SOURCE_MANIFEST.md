# Source Manifest

Generated from the local EA source without launching MT5.

## Local EA Source

- File: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `1706`
- Size: `55572` bytes
- SHA-256: `9243BFB13A89473424EDEA0291C69AFE4E6907B88217261C6545195E4EC4E360`
- Last verified locally: `2026-07-04`

## Verified Source Features

- No martingale, grid, averaging down, or recovery-system logic in the source header.
- Promoted default inputs:
  - `InpRiskPercent=1.60`
  - `InpStopATRMultiplier=1.80`
  - `InpTakeProfitATRMultiplier=3.50`
- Profit giveback guard is present:
  - `InpUseProfitGivebackGuard`
  - daily, weekly, and monthly giveback thresholds
  - blocks new entries after protected period profit gives back too much
- Custom Strategy Tester optimization scoring is present:
  - `double OnTester()`
  - `FITNESS_ROBUST_PROFIT`
  - `FITNESS_NET_PROFIT`
  - `FITNESS_RECOVERY_SHARPE`

## Static Checks

- Braces: `178` opening / `178` closing
- Parentheses: `720` opening / `720` closing
- MT5 was not launched during verification.

## Validation Pack State

- Generated configs: `196`
- Profiles:
  - `risk160_sl16_tp38`
  - `risk160_sl18_tp38`
  - `risk160_sl18_tp35_giveback`
  - `promoted_risk160_sl18_tp35`
- Date range covered by prepared configs: `2024.01.01` through `2026.07.02`

## GitHub Note

The full `.mq5` source is currently verified locally. If GitHub upload tooling supports a non-truncated file transfer, upload `outputs/Professional_XAUUSD_EA.mq5` as `Professional_XAUUSD_EA.mq5` and confirm the SHA-256 above after download.

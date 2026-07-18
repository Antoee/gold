# Operational-Hardening rc2 Portfolio Model1 Fidelity Package

Dedicated-account and funding-drift safety fork of v0.2-rc1.

- Source SHA-256: 9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302
- Profile SHA-256: 6E3B7D4B2377ADF7A2BF9B5EA5111D6F09CD74951788E3C8E3093DD5B5A1AFB3
- Window: 2015-01-01 through 2026-07-16
- Risk: 0.45% reversion + 0.15% momentum; 0.75% shared open-risk cap
- Added gates: 1.25% weekly, 1.50% monthly, nine-loss/48-hour cooldown, 300% margin floor
- Initial attachment: USD account and 10,000 balance within 1%

Require zero signal drift versus v0.1 and v0.2-rc1: identical trade count, lane, side, entry time, exit time, and profit within report precision. Any historical divergence rejects rc2.

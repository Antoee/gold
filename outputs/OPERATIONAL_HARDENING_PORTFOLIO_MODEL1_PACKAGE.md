# Operational-Hardening Portfolio Model1 Fidelity Package

Safety-only fork of the released transferable portfolio.

- Source SHA-256: 015DCCDBA020796895C1A71B150C31B4F0F276A9334243BD7474293F73385EB4
- Profile SHA-256: A07186CA0A8BEF485529E53748BEB805DC1BF9CE310685946EE58D25ACC71121
- Window: 2015-01-01 through 2026-07-16
- Risk: 0.45% reversion + 0.15% momentum; 0.75% shared open-risk cap
- Added gates: 1.25% weekly, 1.50% monthly, nine-loss/48-hour cooldown, 300% margin floor
- Initial attachment: USD account and 10,000 balance within 1%

Require zero signal drift versus v0.1: identical trade count, lane, side, entry time, exit time, and profit within report precision. Any safety-triggered historical divergence rejects v0.2 pending review.

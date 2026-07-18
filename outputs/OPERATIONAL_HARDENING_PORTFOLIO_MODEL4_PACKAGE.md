# Operational-Hardening Portfolio Model4 Fidelity Package

Safety-only fork of the released transferable portfolio.

- Source SHA-256: 015DCCDBA020796895C1A71B150C31B4F0F276A9334243BD7474293F73385EB4
- Profile SHA-256: 7E7081A9BF179BC1B93623316D8EFFFB3C0CED91ACF0FFDE91BD61ABD712F6B2
- Window: 2015-01-01 through 2026-07-16
- Risk: 0.45% reversion + 0.15% momentum; 0.75% shared open-risk cap
- Added gates: 1.25% weekly, 1.50% monthly, nine-loss/48-hour cooldown, 300% margin floor
- Initial attachment: USD account and 10,000 balance within 1%

Require zero signal drift versus v0.1: identical trade count, lane, side, entry time, exit time, and profit within report precision. Any safety-triggered historical divergence rejects v0.2 pending review.

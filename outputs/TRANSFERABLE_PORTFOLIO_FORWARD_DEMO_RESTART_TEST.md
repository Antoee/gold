# Transferable Portfolio Forward Demo Restart Test

Date: 2026-07-17

Result: **PASS for normal chart/EA restoration; FAIL as forward-capital evidence.**

- Before restart, the attached frozen EA reported demo allowed, zero drawdown, zero positions, and zero open risk.
- MetaTrader 5 was closed normally and relaunched from its installed executable.
- The saved chart profile reopened automatically with `Professional_XAUUSD_Transferable_Portfolio` still attached.
- The EA again reported `READY (allowed)`, zero drawdown, zero positions, and zero open risk without reloading the `.set` file.
- The original post-restart monitor passed 22 source, profile, binary, log-identity, and process checks, but it did not independently verify account capital.
- A subsequently attached read-only sentinel proved that the actual demo balance and equity were `$100,000.00`, not the preregistered `$10,000.00` starting capital. The upgraded 47-check monitor therefore marks this forward sample `FAIL` before its first trade.
- MT5 was re-muted, returned to BelowNormal priority with the 80% CPU-affinity ceiling, and minimized.
- Real-account trading remained disabled.

The account login is intentionally excluded. This test proves normal close/relaunch restoration only; it does not validate the current account-capital contract and does not yet prove recovery from a forced process crash, operating-system reboot, network loss, broker outage, or an open-position restart.

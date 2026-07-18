# Operational-Hardening rc2 Forward Preflight Test

**PASS.** The deterministic $10,000 contract fixture passed, while the $100,000 capital-mismatch fixture was refused before registration.

| Scenario | Balance | Equity | Ready to register | Expected | Failed gates |
|---|---:|---:|---:|---:|---|
| Valid capital | $10,000 | $10,000 | True | True | none |
| Wrong capital | $100,000 | $100,000 | False | False | starting-balance;starting-equity |

The wrong-capital fixture matches the balance and equity condition measured on the currently attached invalid demo. The test contains no account identifier, creates no registration, freezes no funding-history baseline, and changes no strategy or risk input. It does not count as forward evidence.

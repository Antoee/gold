# Operational-Hardening rc2 Account-Contract Canary

**PASS.** The exact rc2 source rejected a deliberately wrong 100,000 USD tester balance against its frozen 10,000 USD contract.

- MT5 logged the 100,000 USD initial deposit.
- The embedded run label matched the canary identity.
- The EA logged the starting-capital initialization block.
- MT5 stopped because OnInit returned nonzero.
- The generated report remained flat with zero trades and zero net profit.

This proves the first-attachment capital lock dynamically. Dedicated-account and post-registration funding-drift paths are additionally compile-checked and source-audited; they still require forward operational observation on a correctly registered demo.

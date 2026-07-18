# Operational-Hardening rc2 Decision

## Decision

**PROMOTE AS v0.2-rc2 OPERATIONAL CANDIDATE; DO NOT DECLARE LIVE-READY.**

rc2 fixes a live-account contract gap in rc1. A correctly capitalized account could previously receive later funding changes without invalidating its persisted starting-capital approval. rc2 continuously rejects new funding records and unrelated account trading while preserving every validated strategy event.

This is not a higher-profit strategy. It supersedes rc1 only as the safer executable candidate. The frozen v0.1 forward registration is unchanged.

## Exact fidelity

| Model | Net profit | PF | Trades | Max DD | Recovery | Event comparison |
|---|---:|---:|---:|---:|---:|---|
| Model1 fast gate | +$1,616.49 | 1.58 | 370 | 3.24% | 4.56 | 740/740 exact; 0 identity mismatches |
| Model4 real ticks | +$1,615.36 | 1.58 | 362 | 2.83% | 5.22 | 724/724 exact; 0 identity mismatches |

Lane, side, entry time, exit time, volume, price, stop, profit, and reason match v0.2-rc1 exactly.

## New rc2 contracts

- New portfolio identity prevents accidental reuse of rc1's persisted account approval.
- A baseline count is stored for balance, credit, charge, correction, bonus, standalone commission, and interest records.
- Any later change to that count locks new risk until manual review.
- Any buy/sell history using a non-portfolio magic locks the account.
- Reusing a portfolio magic on a symbol other than the allowed XAUUSD also locks the account.
- Account-history checks are cached and invalidated after every account transaction; they do not add per-tick tester overhead.
- Existing USD/$10,000 initial attachment, weekly/monthly loss, loss-streak, margin, stop-protection, drawdown, open-risk, hedging, symbol, and real-account locks remain.

## Dynamic safety evidence

The exact final rc2 source was run with a deliberately wrong `$100,000` tester deposit against its required `$10,000` capital contract. MT5 logged the wrong deposit and embedded run identity, the EA logged `initialization blocked by starting-capital contract`, MT5 stopped because `OnInit` returned nonzero, and the report remained flat with zero trades and zero net profit.

The dedicated-account and post-registration funding-drift paths are compile-checked and source-audited. MT5 tester mode cannot create realistic live deposits or unrelated account transactions, so those paths still require operational observation on a correctly registered demo.

## Identity

- Source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Binary SHA-256: `710C20730933E6EB2AE1AD14079C67E33C592881E1471BF0110E045335153EE5`
- Model1 profile SHA-256: `6E3B7D4B2377ADF7A2BF9B5EA5111D6F09CD74951788E3C8E3093DD5B5A1AFB3`
- Model4 profile SHA-256: `5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827`
- Wrong-capital canary profile SHA-256: `D6B4B54AE9EF23650BC331E11176785F4C7D33F4592B86F0968CD131FA8CD570`
- Compile: 0 errors, 0 warnings.

## Forward status

rc2 has no valid forward evidence. The currently attached v0.1 demo still has `$100,000` rather than the frozen `$10,000` starting capital, its terminal and heartbeat are stopped, and its zero days/trades remain excluded. No source, profile, binary, run label, evidence log, or registration was amended to make that account pass.

rc2 requires a separate immutable registration on a fresh `$10,000` USD demo hedging account. Real-money use is not approved.

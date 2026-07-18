# RDMC Money-Ready Gate Repair Contract

**STATIC ADMISSION CANDIDATE ONLY. NOT COMPILED, BACKTESTED, FORWARD-REGISTERED, OR REAL-MONEY APPROVED.**

## Objective

Resolve the combined candidate's two source-level readiness blockers without removing its profitable diversification lane or weakening any risk ceiling. This creates a new source and profile identity that must complete the full executable, stress, distinct-broker, and forward-demo sequence.

## Frozen derivation

- Base source SHA-256: `EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F`
- Candidate source SHA-256: `104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8`
- Base profile SHA-256: `746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883`
- Research profile SHA-256: `8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E`
- Forward profile SHA-256: `816F0FAC4141AB0930A058317C9B5501DC180825B7D8B568BBCE8248D030FA7B`

The source diff is restricted to the version marker and the Band/VWAP trade-readiness predicate. The research profile changes three evidence fields plus `InpMaxConsecutiveLosses=2`. Signals, entry filters, exits, position sizing, requested lane risk, exposure ceilings, loss percentages, drawdown limits, and trading sessions remain unchanged.

## Conditional Band/VWAP admission

The lane is admitted only with isolated execution, positive risk multiplier no higher than `0.90`, requested lane risk no higher than `0.45%`, one to 16 monthly entries, at least 240 minutes between entries, spread no higher than `18%` of ATR, stop no wider than `2.20 ATR`, minimum RR `1.20`, DI edge at least `-12`, and an enabled completed-D1 momentum cap no higher than `12%`.

## Loss-streak equivalence

The only non-evidence research-profile change lowers the streak threshold from four to two. With the frozen 240-minute generic post-loss cooldown, both thresholds block the same valid loss-timestamp states. At streaks two or three with missing timestamp persistence, the new profile blocks while the old profile could continue, so the change is fail-closed rather than permissive.

## Evidence boundary

Static readiness now passes, but no historical profit transfers to this new identity. It must compile cleanly and pass the complete staged primary executable gate, identity-bound cost and order-aware stress, distinct-broker Model4 validation, and a fresh `$10,000` demo forward registration. Real-account trading remains disabled.

# Three-Lane Trade-Ready RC2 Growth Screen

**Status: MODEL 1 RESEARCH ONLY. RC2 RELEASE UNCHANGED.**

- Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`
- Manifest SHA-256: `67188FE66A6A6F0DB7CFD31A2DFFC0B1063072CFF89BF51D8F19C0F086DC6A17`
- Signal, exit, calendar, and execution logic remain byte-identical to Trade-Ready RC2.
- Only lane risk and the matching portfolio open-risk allowance vary by adjacent scale.
- Daily, weekly, monthly, and 5% portfolio equity-loss limits remain fixed.
- Every broad era must be profitable; continuous PF >= 1.50, DD <= 3%, recovery >= 6, and useful profit scaling are required before Model 4.
- Any losing era, protection-driven trade collapse, or dominated return/drawdown profile rejects the scale.

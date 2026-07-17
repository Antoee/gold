# Independent M15 XAG Relative-Value Discovery Package

Standalone cross-metal mean-reversion family. XAUUSD is traded only after an ATR-normalized XAU/XAG divergence begins reversing while rolling return correlation remains positive.

- Source SHA-256: `F79BED792F6F2D961181C9A8B0BC9297F5EC41039A816B492CA4CAF442749657`
- Variants: `16`
- Disjoint windows: `older_2015_2017, discovery_2018_2020`
- Configurations: `32`
- Latest permitted discovery date: `2020-12-31`
- Risk: `0.10%` per accepted trade; no minimum lot is forced; real trading is disabled.
- Stop rule: Pre-registered Model1 gate: both 2015-2017 and 2018-2020 must be profitable with PF >= 1.10, DD <= 5%, and >= 30 trades each. Only supported neighborhoods may receive a continuous 2015-2020 test; recent years remain closed.

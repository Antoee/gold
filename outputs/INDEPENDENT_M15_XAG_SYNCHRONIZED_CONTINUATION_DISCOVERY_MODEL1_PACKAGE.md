# Independent M15 XAG Synchronized-Continuation Discovery Package

Standalone cross-metal continuation family. XAUUSD is traded only when XAU and XAG have same-direction ATR-normalized moves, rolling return correlation is positive, and XAU makes a fresh closed-bar channel breakout.

- Source SHA-256: `53D4864FDBA2365193AA9D7AC1185B1B9CD2BFA3CC34453D18AF3A8DD8552D88`
- Variants: `16`
- Disjoint windows: `older_2015_2017, discovery_2018_2020`
- Configurations: `32`
- Latest permitted discovery date: `2020-12-31`
- Risk: `0.10%` per accepted trade; no minimum lot is forced; real trading is disabled.
- Stop rule: Pre-registered Model1 gate: both 2015-2017 and 2018-2020 must be profitable with PF >= 1.10, DD <= 5%, and >= 30 trades each. Only supported neighborhoods may receive a continuous 2015-2020 test; recent years remain closed.

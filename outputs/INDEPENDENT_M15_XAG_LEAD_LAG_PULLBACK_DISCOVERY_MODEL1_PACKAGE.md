# Independent M15 XAG Lead-Lag Pullback Discovery Package

Standalone cross-metal lead-lag family. XAUUSD is traded only when XAG shows a stronger directional impulse, XAU remains trend-aligned but less extended, and XAU completes a closed-bar EMA pullback and reclaim.

- Source SHA-256: `AC1B533EBCBBB42505589DEAD08A11143C88B3FB13A11C57AB4BB96F06F8F21F`
- Variants: `16`
- Disjoint windows: `older_2015_2017, discovery_2018_2020`
- Configurations: `32`
- Latest permitted discovery date: `2020-12-31`
- Risk: `0.10%` per accepted trade; no minimum lot is forced; real trading is disabled.
- Stop rule: Pre-registered Model1 gate: both 2015-2017 and 2018-2020 must be profitable with PF >= 1.10, DD <= 5%, and >= 30 trades each. Only supported neighborhoods may receive a continuous 2015-2020 test; recent years remain closed.

# Independent M15 XAG Lead-Lag Pullback Neighborhood Package

Bounded lead-lookback support test around the isolated four-bar discovery result. All non-lookback inputs remain frozen.

- Source SHA-256: `AC1B533EBCBBB42505589DEAD08A11143C88B3FB13A11C57AB4BB96F06F8F21F`
- Variants: `6`
- Disjoint windows: `older_2015_2017, discovery_2018_2020`
- Configurations: `12`
- Latest permitted discovery date: `2020-12-31`
- Risk: `0.10%` per accepted trade; no minimum lot is forced; real trading is disabled.
- Stop rule: Frozen support gate: both eras must be profitable with PF >= 1.10, DD <= 5%, and >= 30 trades. Lead-4 must reproduce and at least one adjacent lead lookback (3 or 5) must pass before continuous testing; recent years remain closed.

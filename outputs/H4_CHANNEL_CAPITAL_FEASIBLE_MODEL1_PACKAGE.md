# H4 Channel Capital-Feasible Model1 Package

This is a bounded engineering follow-up to the previously rejected 0.10% sizing experiment.
The signal and exit shapes were frozen before the original holdout; only risk is changed to the project's existing 0.50% hard trade cap.

- Source SHA-256: `E8EB53728A83042598460A691784E800512DFC43DC2B503B49427870B032A4FA`
- Frozen base-profile SHA-256: `940CB5B7C2E6C9786473460ED4C65274430C4CDC3665DDDBAF5EADDA870760DE`
- Starting balance: `$10,000`
- Risk per requested trade: `0.50%`
- Forced minimum lot: `false`
- Candidates: `4`
- Windows: `discovery_2015_2020, validation_2021_2026, continuous_2015_2026`
- Configurations: `12`

Require discovery and validation net above zero, continuous PF >= 1.30, at least 100 continuous trades, max DD <= 5%, and at least two neighboring shapes passing before Model4. This follow-up is holdout-informed capital-feasibility research, not pristine OOS evidence.

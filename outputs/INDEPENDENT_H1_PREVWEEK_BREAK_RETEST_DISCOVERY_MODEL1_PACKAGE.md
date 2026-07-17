# Independent H1 Previous-Week Break-And-Retest Discovery Package

Standalone, date-independent market-structure family. No configuration includes data after 2020.

- Source SHA-256: `1A5799C5829D0E7108F60CBB331EB98BE39DACD0422C592020B6973C17147F26`
- Variants: `14`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `42`

Every profile requires an H1 close beyond the previous W1 high or low and a later bounded retest/reclaim. Stops use recent structure, reject distances above `$10`, preserve take profit during stop updates, size with broker-accurate `OrderCalcProfit` at `0.10%` risk, and keep real-account trading disabled.

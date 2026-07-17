# Transferable Portfolio Forward Demo Activation

The forward clock must not begin during an account switch. The activation workflow has two deliberate phases:

1. Disable MT5 algorithmic trading globally.
2. Create or switch to the exact `$10,000` MetaQuotes demo hedging account.
3. Wait for a fresh read-only sentinel heartbeat.
4. Run `work/activate_transferable_portfolio_forward_demo.ps1 -Phase Check`.
5. Run `work/activate_transferable_portfolio_forward_demo.ps1 -Phase Register` only when every gate passes.
6. Re-enable algorithmic trading.
7. Wait for a fresh heartbeat and run `work/activate_transferable_portfolio_forward_demo.ps1 -Phase Verify`.

`Register` refuses to start the clock unless candidate and sentinel identities match, algorithmic trading is disabled, the account is demo/hedging, balance and equity are both `$10,000` within `$1`, there are no positions or open risk, and both dedicated event logs are empty. It archives the invalid registration/status locally before writing the new timestamp.

`Verify` requires the new registration marker, a fresh operational heartbeat, the complete account contract, zero initial events, and `PENDING` forward status. It does not enable real-account trading or expose the account identifier.

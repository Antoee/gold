from __future__ import annotations

import csv
import hashlib
from datetime import datetime
from pathlib import Path

import rdmc_executable_ledger_stress_core as core


REPO = Path(__file__).resolve().parents[1]
MANIFEST = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_BROAD_MANIFEST.csv"
RESULTS = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_BROAD_RESULTS.csv"
REPORT_ROOT = REPO / "outputs" / "three_lane_adaptive_trend_model4_broad_package" / "reports_here"
REPORT_NAME = "tlat_di12_atb10_center_continuous_2015_2026_m4"
REPORT = REPORT_ROOT / f"{REPORT_NAME}.htm"
IDENTITY = REPORT_ROOT / f"{REPORT_NAME}.identity.json"
LEDGER = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_CONTINUOUS_TRADES.csv"
OUT_COST = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_COST_STRESS.csv"
OUT_MC = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_MONTE_CARLO.csv"
OUT_DECISION = REPO / "outputs" / "THREE_LANE_ADAPTIVE_TREND_MODEL4_STRESS_DECISION.md"

EXPECTED_MANIFEST_SHA256 = "148184FFFD8509EAAD5336B832D7DB36AEA103084B68F34D1AC2870BDEF74643"
EXPECTED_SOURCE_SHA256 = "51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB"
EXPECTED_PROFILE_SHA256 = "48636124EE5E38D516A48D7551F401F4B179A34296B6373C317F843CD3DEF1B1"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    require(bool(rows), f"No rows for {path.name}")
    with path.open("w", newline="", encoding="ascii") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def money(value: float) -> str:
    return f"{'+' if value >= 0 else '-'}${abs(value):,.2f}"


require(sha256(MANIFEST) == EXPECTED_MANIFEST_SHA256, "Broad Model 4 manifest identity changed")
manifest_rows = read_csv(MANIFEST)
manifest_matches = [row for row in manifest_rows if row["ExpectedReportName"] == REPORT_NAME]
require(len(manifest_matches) == 1, "Expected one continuous center manifest row")
manifest_row = manifest_matches[0]
require(manifest_row["SourceSha256"].upper() == EXPECTED_SOURCE_SHA256, "Source identity changed")
require(manifest_row["ProfileSha256"].upper() == EXPECTED_PROFILE_SHA256, "Profile identity changed")

identity = core.validate_report_identity(
    REPORT,
    IDENTITY,
    REPORT_NAME,
    manifest_row["ConfigSha256"],
    EXPECTED_SOURCE_SHA256,
)

result_matches = [row for row in read_csv(RESULTS) if row["ExpectedReportName"] == REPORT_NAME]
require(len(result_matches) == 1 and result_matches[0]["Status"] == "PARSED", "Continuous result is not parsed")
result = result_matches[0]
source_rows = read_csv(LEDGER)
require(len(source_rows) == int(float(result["TotalTrades"])), "Ledger trade count differs from report metrics")
require(abs(sum(float(row["Profit"]) for row in source_rows) - float(result["NetProfit"])) <= 0.02, "Ledger net differs from report metrics")

trades: list[core.Trade] = []
for index, row in enumerate(source_rows, start=1):
    profit = float(row["Profit"])
    trades.append(
        core.Trade(
            index=index,
            entry_time=datetime.fromisoformat(row["EntryTime"]),
            exit_time=datetime.fromisoformat(row["ExitTime"]),
            entry_deal=f"ledger-entry-{index}",
            exit_deal=f"ledger-exit-{index}",
            entry_order=f"ledger-entry-order-{index}",
            exit_order=f"ledger-exit-order-{index}",
            symbol=row["Symbol"],
            side=row["Side"],
            volume=float(row["Volume"]),
            entry_price=float(row["EntryPrice"]),
            exit_price=float(row["ExitPrice"]),
            initial_stop=float(row["InitialStop"]),
            initial_target=float(row["InitialTarget"]),
            initial_risk=float(row["InitialRiskMoney"]),
            gross_profit=profit,
            commission=0.0,
            fee=0.0,
            swap=0.0,
            profit=profit,
            entry_comment=row["EntryComment"],
            exit_comment=row["ExitComment"],
        )
    )

cost_rows = core.cost_stress(trades)
mc_rows = core.monte_carlo_stress(trades, trials=10_000)
write_csv(OUT_COST, cost_rows)
write_csv(OUT_MC, mc_rows)
cost_pass = all(bool(row["GatePass"]) for row in cost_rows)
mc_pass = all(bool(row["GatePass"]) for row in mc_rows)
status = "PASS" if cost_pass and mc_pass else "FAIL"

lines = [
    "# Three-Lane Adaptive Trend Stress Decision",
    "",
    f"**Status: {status}. This is historical trade-ledger stress, not real-money approval.**",
    "",
    f"- Source SHA-256: `{EXPECTED_SOURCE_SHA256}`",
    f"- Profile SHA-256: `{EXPECTED_PROFILE_SHA256}`",
    f"- Report SHA-256: `{sha256(REPORT)}`",
    f"- Portable binary SHA-256: `{identity['PortableBinarySha256']}`",
    f"- Ledger SHA-256: `{sha256(LEDGER)}`",
    f"- Trades: `{len(trades)}`; base net: `{money(sum(trade.profit for trade in trades))}`",
    "",
    "## Added Execution Cost",
    "",
    "| Scenario | Added R/trade | Extra cost | Net | PF | Closed DD | Older | Middle | Recent | Gate |",
    "|---|---:|---:|---:|---:|---:|---:|---:|---:|---|",
]
for row in cost_rows:
    lines.append(
        f"| {row['Scenario']} | {float(row['AddedCostRPerTrade']):.2f}R | ${float(row['ExtraCost']):,.2f} | "
        f"{money(float(row['NetProfit']))} | {float(row['ProfitFactor']):.3f} | "
        f"{float(row['MaxClosedDrawdownPercent']):.3f}% | {money(float(row['Older2015To2018']))} | "
        f"{money(float(row['Middle2019To2022']))} | {money(float(row['Recent2023To2026']))} | {row['GatePass']} |"
    )
lines.extend(
    [
        "",
        "## Order-Aware Monte Carlo",
        "",
        "| Sampler | Stress | Trials | P05 net | Median net | Median PF | P95 DD | P95 loss run | Red trials | Gate |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
)
for row in mc_rows:
    lines.append(
        f"| {row['Sampler']} | {row['StressScenario']} | {row['Trials']} | "
        f"{money(float(row['P05NetProfit']))} | {money(float(row['MedianNetProfit']))} | "
        f"{float(row['MedianProfitFactor']):.3f} | {float(row['P95MaxClosedDrawdownPercent']):.3f}% | "
        f"{float(row['P95MaxConsecutiveLosses']):.0f} | {float(row['RedTrialPercent']):.3f}% | {row['GatePass']} |"
    )
lines.extend(
    [
        "",
        "- Block and calendar-year resampling preserve local clustering better than independent trade shuffling.",
        "- Standard and severe paths add random slippage, delay, spread shocks, and missed winners.",
        "- Drawdown here is closed-trade path drawdown; MT5 reports remain authoritative for intratrade equity drawdown.",
        "- Broker-specification variation and a valid untouched forward demo are still required.",
    ]
)
OUT_DECISION.write_text("\n".join(lines) + "\n", encoding="ascii")

require(cost_pass, "One or more deterministic cost scenarios failed")
require(mc_pass, "One or more Monte Carlo scenarios failed")
print(f"THREE_LANE_ADAPTIVE_TREND_STRESS_PASS trades={len(trades)} cost_rows={len(cost_rows)} mc_rows={len(mc_rows)}")

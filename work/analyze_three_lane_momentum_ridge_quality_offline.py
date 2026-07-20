#!/usr/bin/env python3
import csv
import hashlib
import math
from pathlib import Path


REPO = Path(__file__).resolve().parent.parent
TELEMETRY_PATH = REPO / "outputs" / "RDMC_MOMENTUM_FEATURE_TRAINING_2015_2022.csv"
TRADES_PATH = REPO / "outputs" / "THREE_LANE_TRADE_READY_RC2_ATB150_MODEL4_CONTINUOUS_TRADES.csv"
EXPECTED_TELEMETRY_SHA256 = "EA2A0DB1C38E890291785BB0B474B80586D71352C32EA7C55E7A11D1B698365C"
EXPECTED_TRADES_SHA256 = "D784E3F4289E989DDA2E6C686C80A20086825A6586355AFA8556021486373E69"
RIDGE_ALPHA = 25.0
FEATURES = (
    "channel_width_atr",
    "breakout_atr",
    "h1_efficiency",
    "d1_efficiency",
    "d1_momentum_pct",
    "atr_pct",
    "body_ratio",
    "close_location",
    "range_atr",
    "volume_ratio",
    "stop_atr",
)
FOLDS = (
    ("fold_2017_2018", 2016, 2017, 2018),
    ("fold_2019_2020", 2018, 2019, 2020),
    ("fold_2021_2022", 2020, 2021, 2022),
)
PROFILES = (("ridge_q20", 0.20), ("ridge_q25_center", 0.25), ("ridge_q30", 0.30))


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path):
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path, rows, fields):
    with path.open("w", encoding="ascii", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def trade_key(row):
    return row["EntryTime"][:16], row["Side"].lower()


def quantile(values, fraction):
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = int(math.floor(position))
    upper = int(math.ceil(position))
    if lower == upper:
        return ordered[lower]
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def solve_linear(matrix, vector):
    size = len(vector)
    augmented = [list(matrix[row]) + [vector[row]] for row in range(size)]
    for column in range(size):
        pivot = max(range(column, size), key=lambda row: abs(augmented[row][column]))
        if abs(augmented[pivot][column]) < 1e-12:
            raise RuntimeError("Ridge system is singular")
        augmented[column], augmented[pivot] = augmented[pivot], augmented[column]
        divisor = augmented[column][column]
        augmented[column] = [value / divisor for value in augmented[column]]
        for row in range(size):
            if row == column:
                continue
            factor = augmented[row][column]
            if abs(factor) < 1e-18:
                continue
            augmented[row] = [
                augmented[row][item] - factor * augmented[column][item]
                for item in range(size + 1)
            ]
    return [augmented[row][-1] for row in range(size)]


def fit_ridge(rows):
    means = []
    scales = []
    for feature in FEATURES:
        values = [float(row[feature]) for row in rows]
        mean = sum(values) / len(values)
        variance = sum((value - mean) ** 2 for value in values) / len(values)
        means.append(mean)
        scales.append(max(math.sqrt(variance), 1e-9))

    width = len(FEATURES) + 1
    xtx = [[0.0 for _ in range(width)] for _ in range(width)]
    xty = [0.0 for _ in range(width)]
    for row in rows:
        vector = [1.0] + [
            (float(row[feature]) - means[index]) / scales[index]
            for index, feature in enumerate(FEATURES)
        ]
        target = float(row["MatchedRiskR"])
        for left in range(width):
            xty[left] += vector[left] * target
            for right in range(width):
                xtx[left][right] += vector[left] * vector[right]
    for index in range(1, width):
        xtx[index][index] += RIDGE_ALPHA
    return {"means": means, "scales": scales, "weights": solve_linear(xtx, xty)}


def score(model, row):
    value = model["weights"][0]
    for index, feature in enumerate(FEATURES):
        standardized = (float(row[feature]) - model["means"][index]) / model["scales"][index]
        value += model["weights"][index + 1] * standardized
    return value


def metrics(rows):
    net = sum(float(row["Profit"]) for row in rows)
    gross_profit = sum(float(row["Profit"]) for row in rows if float(row["Profit"]) > 0.0)
    gross_loss = -sum(float(row["Profit"]) for row in rows if float(row["Profit"]) < 0.0)
    return {
        "NetProfit": net,
        "ProfitFactor": gross_profit / gross_loss if gross_loss > 0.0 else 999.0,
        "Trades": len(rows),
    }


def bool_text(value):
    return "PASS" if value else "FAIL"


def money(value):
    return ("+" if value >= 0.0 else "-") + "$" + f"{abs(value):,.2f}"


def main():
    if sha256(TELEMETRY_PATH) != EXPECTED_TELEMETRY_SHA256:
        raise RuntimeError("Frozen momentum telemetry identity changed")
    if sha256(TRADES_PATH) != EXPECTED_TRADES_SHA256:
        raise RuntimeError("Frozen ATB150 trade-ledger identity changed")

    telemetry = read_csv(TELEMETRY_PATH)
    trades = read_csv(TRADES_PATH)
    if len(telemetry) != 246 or len(trades) != 404:
        raise RuntimeError("Frozen row topology changed")
    momentum = {
        trade_key(row): row
        for row in trades
        if row["EntryComment"].startswith("MTSM") and int(row["EntryYear"]) <= 2022
    }
    joined = []
    for row in telemetry:
        matched = momentum.get(trade_key(row))
        if matched is None:
            raise RuntimeError(f"Telemetry entry is not in the ATB150 ledger: {trade_key(row)}")
        enriched = dict(row)
        enriched["MatchedProfit"] = matched["Profit"]
        enriched["MatchedRiskR"] = matched["RiskR"]
        joined.append(enriched)
    if len(joined) != 246 or len(momentum) != 249:
        raise RuntimeError("Expected 246 matched and 249 total pre-2023 momentum trades")

    fold_rows = []
    coefficient_rows = []
    removed_by_profile = {name: set() for name, _ in PROFILES}
    control_by_fold = {}
    for fold_name, train_end, test_start, test_end in FOLDS:
        train = [row for row in joined if int(row["Year"]) <= train_end]
        test = [row for row in joined if test_start <= int(row["Year"]) <= test_end]
        model = fit_ridge(train)
        train_scores = [score(model, row) for row in train]
        for index, feature in enumerate(("intercept",) + FEATURES):
            coefficient_rows.append({
                "Fold": fold_name,
                "TrainThrough": train_end,
                "Feature": feature,
                "Weight": round(model["weights"][index], 10),
                "Mean": "" if index == 0 else round(model["means"][index - 1], 10),
                "Scale": "" if index == 0 else round(model["scales"][index - 1], 10),
            })

        control_rows = [row for row in trades if test_start <= int(row["EntryYear"]) <= test_end]
        control = metrics(control_rows)
        control_by_fold[fold_name] = control
        for profile, fraction in PROFILES:
            threshold = quantile(train_scores, fraction)
            scored = [(row, score(model, row)) for row in test]
            retained = [row for row, value in scored if value >= threshold]
            removed = [row for row, value in scored if value < threshold]
            removed_keys = {trade_key(row) for row in removed}
            removed_by_profile[profile].update(removed_keys)
            candidate_rows = [
                row for row in control_rows
                if not (row["EntryComment"].startswith("MTSM") and trade_key(row) in removed_keys)
            ]
            candidate = metrics(candidate_rows)
            retained_r = [float(momentum[trade_key(row)]["RiskR"]) for row in retained]
            removed_r = [float(momentum[trade_key(row)]["RiskR"]) for row in removed]
            annual = []
            for year in range(test_start, test_end + 1):
                annual_rows = [row for row in candidate_rows if int(row["EntryYear"]) == year]
                annual.append(metrics(annual_rows)["NetProfit"])
            fold_rows.append({
                "Profile": profile,
                "Quantile": fraction,
                "Fold": fold_name,
                "TrainThrough": train_end,
                "TestYears": f"{test_start}-{test_end}",
                "Threshold": round(threshold, 10),
                "MatchedTestTrades": len(test),
                "RetainedMomentumTrades": len(retained),
                "RemovedMomentumTrades": len(removed),
                "RetentionPercent": round(100.0 * len(retained) / len(test), 4),
                "RetainedAverageR": round(sum(retained_r) / len(retained_r), 6),
                "RemovedAverageR": round(sum(removed_r) / len(removed_r), 6),
                "ControlNetProfit": round(control["NetProfit"], 2),
                "CandidateNetProfit": round(candidate["NetProfit"], 2),
                "NetChange": round(candidate["NetProfit"] - control["NetProfit"], 2),
                "ControlProfitFactor": round(control["ProfitFactor"], 4),
                "CandidateProfitFactor": round(candidate["ProfitFactor"], 4),
                "CandidateTrades": candidate["Trades"],
                "AllYearsPositive": all(value > 0.0 for value in annual),
                "RankingPass": sum(retained_r) / len(retained_r) > sum(removed_r) / len(removed_r),
            })

    validation_rows = [row for row in trades if 2017 <= int(row["EntryYear"]) <= 2022]
    control = metrics(validation_rows)
    summary_rows = []
    profile_gates = {}
    for profile, fraction in PROFILES:
        removed_keys = removed_by_profile[profile]
        candidate_rows = [
            row for row in validation_rows
            if not (row["EntryComment"].startswith("MTSM") and trade_key(row) in removed_keys)
        ]
        candidate = metrics(candidate_rows)
        relevant_folds = [row for row in fold_rows if row["Profile"] == profile]
        annual_net = {
            year: metrics([row for row in candidate_rows if int(row["EntryYear"]) == year])["NetProfit"]
            for year in range(2017, 2023)
        }
        control_annual_net = {
            year: metrics([row for row in validation_rows if int(row["EntryYear"]) == year])["NetProfit"]
            for year in range(2017, 2023)
        }
        center = profile == "ridge_q25_center"
        retention_gate = all(float(row["RetentionPercent"]) >= (65.0 if center else 60.0) for row in relevant_folds)
        fold_net_gate = all(
            float(row["CandidateNetProfit"]) >= (1.0 if center else 0.98) * float(row["ControlNetProfit"])
            for row in relevant_folds
        )
        fold_positive_gate = all(float(row["CandidateNetProfit"]) > 0.0 for row in relevant_folds)
        annual_gate = all(value > 0.0 for value in annual_net.values())
        ranking_gate = all(str(row["RankingPass"]).lower() == "true" for row in relevant_folds)
        improvement_percent = 100.0 * (candidate["NetProfit"] / control["NetProfit"] - 1.0)
        growth_gate = improvement_percent >= (5.0 if center else 2.0)
        pf_gate = candidate["ProfitFactor"] >= control["ProfitFactor"]
        weak_year_gate = True if not center else (
            annual_net[2019] >= control_annual_net[2019] and annual_net[2022] >= control_annual_net[2022]
        )
        passed = all((retention_gate, fold_net_gate, fold_positive_gate, annual_gate,
                      ranking_gate, growth_gate, pf_gate, weak_year_gate))
        profile_gates[profile] = passed
        summary_rows.append({
            "Profile": profile,
            "Quantile": fraction,
            "ControlNetProfit": round(control["NetProfit"], 2),
            "CandidateNetProfit": round(candidate["NetProfit"], 2),
            "NetImprovementPercent": round(improvement_percent, 4),
            "ControlProfitFactor": round(control["ProfitFactor"], 4),
            "CandidateProfitFactor": round(candidate["ProfitFactor"], 4),
            "CandidateTrades": candidate["Trades"],
            "RemovedMomentumTrades": len(removed_keys),
            "MinimumFoldRetentionPercent": round(min(float(row["RetentionPercent"]) for row in relevant_folds), 4),
            "FoldNetGate": fold_net_gate,
            "FoldPositiveGate": fold_positive_gate,
            "AnnualPositiveGate": annual_gate,
            "RankingGate": ranking_gate,
            "GrowthGate": growth_gate,
            "ProfitFactorGate": pf_gate,
            "WeakYearGate": weak_year_gate,
            "ProfileGate": passed,
            **{f"Net{year}": round(annual_net[year], 2) for year in range(2017, 2023)},
        })

    passed = all(profile_gates.values())
    decision = {
        "Status": "OFFLINE_GATE_PASSED" if passed else "REJECTED_OFFLINE",
        "TelemetryRows": len(telemetry),
        "MatchedMomentumTrades": len(joined),
        "TotalPre2023MomentumTrades": len(momentum),
        "ValidationFolds": len(FOLDS),
        "CenterGate": profile_gates["ridge_q25_center"],
        "LowerNeighborGate": profile_gates["ridge_q20"],
        "UpperNeighborGate": profile_gates["ridge_q30"],
        "EAImplementationPermitted": passed,
        "RecentHoldoutOpened": False,
        "Model4ValidationPermitted": False,
        "ResearchPromotionPermitted": False,
        "ForwardCandidateChanged": False,
        "RealAccountTradingAllowed": False,
        "TelemetrySha256": EXPECTED_TELEMETRY_SHA256,
        "TradeLedgerSha256": EXPECTED_TRADES_SHA256,
    }

    outputs = REPO / "outputs"
    write_csv(outputs / "THREE_LANE_MOMENTUM_RIDGE_QUALITY_OFFLINE_FOLDS.csv", fold_rows, list(fold_rows[0]))
    write_csv(outputs / "THREE_LANE_MOMENTUM_RIDGE_QUALITY_OFFLINE_COEFFICIENTS.csv", coefficient_rows, list(coefficient_rows[0]))
    write_csv(outputs / "THREE_LANE_MOMENTUM_RIDGE_QUALITY_OFFLINE_SUMMARY.csv", summary_rows, list(summary_rows[0]))
    write_csv(outputs / "THREE_LANE_MOMENTUM_RIDGE_QUALITY_OFFLINE_DECISION.csv", [decision], list(decision))

    lines = [
        "# Three-Lane Momentum Ridge-Quality Offline Decision",
        "",
        ("**Decision: OFFLINE GATE PASSED. A default-off MQL implementation may be built; recent data, Model 4, promotion, forward substitution, and live approval remain closed.**"
         if passed else
         "**Decision: REJECTED OFFLINE. No MQL implementation, recent holdout, Model 4, promotion, forward change, or live approval is permitted.**"),
        "",
        f"- Telemetry rows: `{len(telemetry)}`; exact matched momentum trades: `{len(joined)} / {len(momentum)}`",
        f"- Model: standardized ridge, alpha `{RIDGE_ALPHA:.1f}`, features `{len(FEATURES)}`, expanding validation folds `{len(FOLDS)}`",
        f"- Input hashes: telemetry `{EXPECTED_TELEMETRY_SHA256}`; ATB150 ledger `{EXPECTED_TRADES_SHA256}`",
        "- The offline replay can remove historical trades but cannot recreate the resulting executable account path.",
        "- Real-account trading: disabled",
        "",
        "| Profile | Net | Change | PF | Trades | Removed MO | Min retention | 2017 | 2018 | 2019 | 2020 | 2021 | 2022 | Gate |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in summary_rows:
        lines.append(
            f"| {row['Profile']} | {money(float(row['CandidateNetProfit']))} | {float(row['NetImprovementPercent']):+.2f}% | "
            f"{float(row['CandidateProfitFactor']):.3f} | {row['CandidateTrades']} | {row['RemovedMomentumTrades']} | "
            f"{float(row['MinimumFoldRetentionPercent']):.1f}% | "
            + " | ".join(money(float(row[f'Net{year}'])) for year in range(2017, 2023))
            + f" | {bool_text(bool(row['ProfileGate']))} |"
        )
    lines.extend(["", "## Fold Evidence", "",
                  "| Profile | Fold | Retained | Control | Candidate | Change | Kept avg R | Removed avg R | Ranking | Positive years |",
                  "|---|---|---:|---:|---:|---:|---:|---:|---|---|"])
    for row in fold_rows:
        lines.append(
            f"| {row['Profile']} | {row['Fold']} | {float(row['RetentionPercent']):.1f}% | "
            f"{money(float(row['ControlNetProfit']))} | {money(float(row['CandidateNetProfit']))} | "
            f"{money(float(row['NetChange']))} | {float(row['RetainedAverageR']):+.3f} | "
            f"{float(row['RemovedAverageR']):+.3f} | {bool_text(bool(row['RankingPass']))} | "
            f"{bool_text(bool(row['AllYearsPositive']))} |"
        )
    lines.extend([
        "",
        "## Boundary",
        "",
        ("Every frozen offline gate passed. Only the exact center model may be implemented default-off. Its final coefficients must be trained once on 2015-2022, frozen before 2023-2026 is opened, and subjected to static, compile, Model 1 holdout, and then Model 4 gates."
         if passed else
         "At least one center or neighbor gate failed. The score family stops here without another feature, ridge penalty, percentile, model, or split search on these trades."),
        "",
        "ATB150 remains the historical champion. The registered forward candidate, invalid-account boundary, and real-account lock remain unchanged.",
    ])
    (outputs / "THREE_LANE_MOMENTUM_RIDGE_QUALITY_OFFLINE_DECISION.md").write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"STATUS={decision['Status']}")
    for row in summary_rows:
        print(f"{row['Profile']} net={row['CandidateNetProfit']:.2f} improvement={row['NetImprovementPercent']:.4f}% "
              f"pf={row['CandidateProfitFactor']:.4f} gate={row['ProfileGate']}")


if __name__ == "__main__":
    main()

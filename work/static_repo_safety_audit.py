#!/usr/bin/env python3
"""Static safety checks for the XAUUSD EA research repo.

This script intentionally does not launch MT5, MetaEditor, or any local tester.
It checks repository structure, risk-first input coverage, handoff config safety,
and candidate guardrail consistency before expensive tester time is spent.
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []
WARNINGS: list[str] = []

def fail(message: str) -> None: FAILURES.append(message)
def warn(message: str) -> None: WARNINGS.append(message)

def repo_path(value: str) -> Path:
    return ROOT / value.replace("\\", "/")

def rel_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT)).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")

def read_text(path: Path) -> str:
    if not path.exists():
        fail(f"Missing required file: {rel_path(path)}")
        return ""
    return path.read_text(encoding="utf-8", errors="replace")

def strip_mql_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//.*", "", text)
    return text

def parse_ini(path: Path) -> tuple[dict[str, str], dict[str, str]]:
    tester: dict[str, str] = {}; inputs: dict[str, str] = {}; section = ""
    for raw in read_text(path).splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or line.startswith("#"): continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]; continue
        if "=" not in line: continue
        key, value = line.split("=", 1)
        target = inputs if section == "TesterInputs" else tester if section == "Tester" else None
        if target is not None: target[key.strip()] = value.strip()
    return tester, inputs

def first_value(value: str) -> str: return value.split("||", 1)[0].strip()

def parse_set(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in read_text(path).splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or "=" not in line: continue
        key, value = line.split("=", 1)
        values[key.strip()] = first_value(value)
    return values

def check_source() -> None:
    source = read_text(ROOT / "Professional_XAUUSD_EA.mq5")
    code = strip_mql_comments(source)
    if '#property strict' not in source: fail("EA source must use #property strict.")
    for label, pattern in {"martingale": r"\bmartingale\b", "grid": r"\bgrid\b", "averaging down": r"averag(?:e|ing)\s+down"}.items():
        if re.search(pattern, code, flags=re.I): fail(f"Forbidden strategy concept appears in executable EA code: {label}")
    required_inputs = [
        "InpRiskPercent", "InpMinRiskReward", "InpStopATRMultiplier", "InpTakeProfitATRMultiplier",
        "InpUseBreakEven", "InpBreakEvenTriggerATR", "InpBreakEvenOffsetATR",
        "InpMaxDailyLossPercent", "InpMaxWeeklyLossPercent", "InpMaxMonthlyLossPercent", "InpMaxEquityDrawdownPercent",
        "InpMaxConsecutiveLosses", "InpCooldownMinutesAfterLoss", "InpMaxSpreadPoints", "InpUseATRSpreadGuard", "InpMaxSpreadATRPercent", "InpSlippagePoints",
        "InpMinADX", "InpUseTimeExit", "InpMaxTradeMinutes", "InpUseSessionFilter", "InpSessionStartHour", "InpSessionEndHour", "InpAllowMonday", "InpAllowTuesday",
        "InpAllowWednesday", "InpAllowThursday", "InpAllowFriday", "InpAllowSunday", "InpDisableFridayEvening", "InpFridayCutoffHour",
        "InpUseBOS", "InpUseLiquiditySweep", "InpMinimumConfirmations", "InpUseATRTrailing",
        "InpUseStructureTrailing", "InpStructureTrailingLookback", "InpStructureTrailingBufferATR", "InpStructureTrailingTriggerATR",
        "InpUseProfitGivebackGuard", "InpUseMTFTrendFilter", "InpMTFTrendTimeframe", "InpMTFTrendEMA",
        "InpShowDashboard", "InpDashboardInTester", "InpTesterFitnessMode",
    ]
    input_names = set(re.findall(r"^\s*input\s+(?:bool|int|long|double|string|datetime|ENUM_TIMEFRAMES)\s+(Inp[A-Za-z0-9_]+)\s*=", source, flags=re.M))
    for name in required_inputs:
        if name not in input_names: fail(f"EA source missing required risk/research input: {name}")
    for term in ["OrderCalcProfit", "OrderCalcMargin", "HistoryDealSelect", "TradingSessionAllowsNewTrade", "TimeToStruct", "OnTester", "consecutiveLosses", "ATRSpreadAllowsTrade", "TimeExitTriggered", "ApplyMTFTrendFilter", "HigherTimeframeTrendBias", "MTFTrendAllowsDirection", "StructureTrailingStop", "InpMinADX", "InpUseBreakEven", "InpBreakEvenTriggerATR"]:
        if term not in source: fail(f"EA source missing expected safety/analytics implementation marker: {term}")

def check_hard_lock() -> None:
    text = read_text(ROOT / "work" / "MT5_LOCAL_LAUNCH_DISABLED.lock")
    if "hard lock" not in text.lower(): fail("MT5 local launch lock exists but does not describe itself as a hard lock.")
    guard = read_text(ROOT / "work" / "assert_mt5_launch_allowed.ps1")
    for term in ["MT5_LOCAL_LAUNCH_DISABLED.lock", "ALLOW_MT5_FOCUS_RISK", "ALLOW_MT5_HIDDEN_DESKTOP_ACK", "Stop-Process", "Get-CimInstance", "mt5ExcludeNameRegex"]:
        if term not in guard: fail(f"Launch guard missing required term: {term}")

def check_profiles() -> None:
    base_session = {"InpUseSessionFilter": "false", "InpSessionStartHour": "0", "InpSessionEndHour": "24", "InpAllowMonday": "true", "InpAllowTuesday": "true", "InpAllowWednesday": "true", "InpAllowThursday": "true", "InpAllowFriday": "true", "InpAllowSunday": "false", "InpDisableFridayEvening": "false", "InpFridayCutoffHour": "20"}
    base_mtf = {"InpUseMTFTrendFilter": "false", "InpMTFTrendTimeframe": "PERIOD_H1", "InpMTFTrendEMA": "200"}
    base_adx = {"InpMinADX": "0.0"}
    base_structure = {"InpUseStructureTrailing": "false", "InpStructureTrailingLookback": "12", "InpStructureTrailingBufferATR": "0.20", "InpStructureTrailingTriggerATR": "1.20"}
    base_spread = {"InpMaxSpreadPoints": "350", "InpUseATRSpreadGuard": "false", "InpMaxSpreadATRPercent": "8.0"}
    base_time = {"InpUseTimeExit": "false", "InpMaxTradeMinutes": "240"}
    base_breakeven = {"InpUseBreakEven": "false", "InpBreakEvenTriggerATR": "1.00", "InpBreakEvenOffsetATR": "0.05"}
    expected = {
        "ROBUST_BOS_SWEEP_PROFILE.set": {"InpTakeProfitATRMultiplier": "3.50", "InpRiskPercent": "1.60", **base_session, **base_mtf, **base_adx, **base_structure, **base_spread, **base_time, **base_breakeven},
        "CANDIDATE_RISK16_SL18_TP38_PROFILE.set": {"InpTakeProfitATRMultiplier": "3.80", "InpMaxEquityDrawdownPercent": "4.00", **base_session, **base_mtf, **base_adx, **base_structure, **base_spread, **base_time, **base_breakeven},
        "CANDIDATE_RISK16_SL16_TP38_PROFILE.set": {"InpTakeProfitATRMultiplier": "3.80", "InpMaxEquityDrawdownPercent": "4.00", **base_session, **base_mtf, **base_adx, **base_structure, **base_spread, **base_time, **base_breakeven},
        "CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set": {"InpUseProfitGivebackGuard": "true", **base_session, **base_mtf, **base_adx, **base_structure, **base_spread, **base_time, **base_breakeven},
    }
    for rel, required in expected.items():
        values = parse_set(ROOT / rel)
        for key, expected_value in required.items():
            actual = values.get(key, "")
            if actual != expected_value: fail(f"{rel} expected {key}={expected_value}, found {actual or '<missing>'}.")

def check_manifest(path: Path, expected_rows: int, label: str) -> None:
    if not path.exists(): fail(f"Missing {label} manifest: {rel_path(path)}"); return
    with path.open("r", encoding="utf-8", newline="") as handle: rows = list(csv.DictReader(handle))
    if len(rows) != expected_rows: fail(f"{label} manifest expected {expected_rows} rows, found {len(rows)}.")
    for row in rows:
        config_value = row.get("HandoffConfig", "")
        config = repo_path(config_value)
        report = row.get("ExpectedReportName", "")
        if not config.exists(): fail(f"{label} manifest points at missing config: {config_value}")
        if not report: fail(f"{label} manifest row missing ExpectedReportName for {row.get('Profile')} {row.get('Window')}")

def check_configs(config_dir: Path, label: str) -> None:
    configs = sorted(config_dir.glob("*.ini"))
    if not configs: fail(f"No configs found for {label}: {rel_path(config_dir)}"); return
    for config in configs:
        tester, inputs = parse_ini(config); rel = rel_path(config)
        for key, expected in {"Expert": "Professional_XAUUSD_EA.ex5", "Symbol": "XAUUSD", "Period": "M15", "Model": "2", "Optimization": "0", "Visual": "0", "ReplaceReport": "1", "ShutdownTerminal": "1"}.items():
            actual = tester.get(key, "")
            if actual != expected: fail(f"{rel} expected [Tester] {key}={expected}, found {actual or '<missing>'}.")
        profile_name = config.name.lower(); parent_name = str(config.parent.parent).lower()
        if "tp38" in profile_name:
            if first_value(inputs.get("InpTakeProfitATRMultiplier", "")) != "3.80": fail(f"{rel} tp38 config must set InpTakeProfitATRMultiplier=3.80.")
            if first_value(inputs.get("InpMaxEquityDrawdownPercent", "")) != "4.00": fail(f"{rel} protected candidate must set InpMaxEquityDrawdownPercent=4.00.")
        if "confirmation_probe" in parent_name:
            actual_confirm = first_value(inputs.get("InpMinimumConfirmations", "")); expected_confirm = "3" if "confirm3" in profile_name else "2"
            if actual_confirm != expected_confirm: fail(f"{rel} expected InpMinimumConfirmations={expected_confirm}, found {actual_confirm or '<missing>'}.")
        if "breakeven_probe" in parent_name:
            actual_be = first_value(inputs.get("InpUseBreakEven", "")); expected_be = "true" if "_be_" in profile_name else "false"
            if actual_be.lower() != expected_be: fail(f"{rel} expected InpUseBreakEven={expected_be}, found {actual_be or '<missing>'}.")
            if first_value(inputs.get("InpBreakEvenTriggerATR", "")) != "1.00": fail(f"{rel} must pin InpBreakEvenTriggerATR=1.00.")
            if first_value(inputs.get("InpBreakEvenOffsetATR", "")) != "0.05": fail(f"{rel} must pin InpBreakEvenOffsetATR=0.05.")
        if "adx_filter_probe" in parent_name:
            actual_adx = first_value(inputs.get("InpMinADX", "")); expected_adx = "18.0" if "adx18" in profile_name else "0.0"
            if actual_adx != expected_adx: fail(f"{rel} expected InpMinADX={expected_adx}, found {actual_adx or '<missing>'}.")
        if "session_variant" in parent_name and "tp38" in profile_name and first_value(inputs.get("InpUseSessionFilter", "")) != "true": fail(f"{rel} session candidate must enable InpUseSessionFilter=true.")
        if "mtf_trend_probe" in parent_name:
            actual_mtf = first_value(inputs.get("InpUseMTFTrendFilter", "")); expected_mtf = "true" if "h1_mtf" in profile_name else "false"
            if actual_mtf.lower() != expected_mtf: fail(f"{rel} expected InpUseMTFTrendFilter={expected_mtf}, found {actual_mtf or '<missing>'}.")
            if first_value(inputs.get("InpMTFTrendTimeframe", "")) != "PERIOD_H1": fail(f"{rel} must pin InpMTFTrendTimeframe=PERIOD_H1.")
            if first_value(inputs.get("InpMTFTrendEMA", "")) != "200": fail(f"{rel} must pin InpMTFTrendEMA=200.")
        if "structure_trailing_probe" in parent_name:
            actual_structure = first_value(inputs.get("InpUseStructureTrailing", "")); expected_structure = "true" if "structure_trail" in profile_name else "false"
            if actual_structure.lower() != expected_structure: fail(f"{rel} expected InpUseStructureTrailing={expected_structure}, found {actual_structure or '<missing>'}.")
            if first_value(inputs.get("InpStructureTrailingLookback", "")) != "12": fail(f"{rel} must pin InpStructureTrailingLookback=12.")
            if first_value(inputs.get("InpStructureTrailingBufferATR", "")) != "0.20": fail(f"{rel} must pin InpStructureTrailingBufferATR=0.20.")
            if first_value(inputs.get("InpStructureTrailingTriggerATR", "")) != "1.20": fail(f"{rel} must pin InpStructureTrailingTriggerATR=1.20.")
        if "spread_guard_probe" in parent_name:
            actual_spread = first_value(inputs.get("InpUseATRSpreadGuard", "")); expected_spread = "true" if "atr_spread_guard" in profile_name else "false"
            if actual_spread.lower() != expected_spread: fail(f"{rel} expected InpUseATRSpreadGuard={expected_spread}, found {actual_spread or '<missing>'}.")
            if first_value(inputs.get("InpMaxSpreadATRPercent", "")) != "8.0": fail(f"{rel} must pin InpMaxSpreadATRPercent=8.0.")
        if "time_exit_probe" in parent_name:
            actual_time = first_value(inputs.get("InpUseTimeExit", "")); expected_time = "true" if "time_exit" in profile_name else "false"
            if actual_time.lower() != expected_time: fail(f"{rel} expected InpUseTimeExit={expected_time}, found {actual_time or '<missing>'}.")
            if first_value(inputs.get("InpMaxTradeMinutes", "")) != "240": fail(f"{rel} must pin InpMaxTradeMinutes=240.")
        if "baseline_promoted" in profile_name and first_value(inputs.get("InpTakeProfitATRMultiplier", "")) != "3.50": fail(f"{rel} baseline config must set InpTakeProfitATRMultiplier=3.50.")
        if first_value(inputs.get("InpShowDashboard", "false")).lower() != "false": fail(f"{rel} must disable dashboard for non-interrupting tester use.")
        if first_value(inputs.get("InpDashboardInTester", "false")).lower() != "false": fail(f"{rel} must disable tester dashboard for non-interrupting tester use.")

def main() -> int:
    check_source(); check_hard_lock(); check_profiles()
    check_manifest(ROOT / "outputs" / "stress_smoke_handoff" / "HANDOFF_MANIFEST.csv", 2, "stress smoke")
    check_manifest(ROOT / "outputs" / "micro_test_handoff" / "HANDOFF_MANIFEST.csv", 8, "stress micro")
    check_manifest(ROOT / "outputs" / "recent_oos_handoff" / "HANDOFF_MANIFEST.csv", 8, "recent OOS")
    check_manifest(ROOT / "outputs" / "confirmation_probe_handoff" / "HANDOFF_MANIFEST.csv", 4, "confirmation probe")
    check_manifest(ROOT / "outputs" / "breakeven_probe_handoff" / "HANDOFF_MANIFEST.csv", 4, "break-even probe")
    check_manifest(ROOT / "outputs" / "adx_filter_probe_handoff" / "HANDOFF_MANIFEST.csv", 4, "ADX filter probe")
    check_manifest(ROOT / "outputs" / "spread_guard_probe_handoff" / "HANDOFF_MANIFEST.csv", 4, "ATR spread guard probe")
    check_manifest(ROOT / "outputs" / "time_exit_probe_handoff" / "HANDOFF_MANIFEST.csv", 4, "time exit probe")
    check_manifest(ROOT / "outputs" / "mtf_trend_probe_handoff" / "HANDOFF_MANIFEST.csv", 4, "MTF trend probe")
    check_manifest(ROOT / "outputs" / "structure_trailing_probe_handoff" / "HANDOFF_MANIFEST.csv", 4, "structure trailing probe")
    check_manifest(ROOT / "outputs" / "session_variant_handoff" / "HANDOFF_MANIFEST.csv", 6, "session variant")
    check_configs(ROOT / "outputs" / "stress_smoke_handoff" / "configs", "stress smoke")
    check_configs(ROOT / "outputs" / "micro_test_handoff" / "configs", "stress micro")
    check_configs(ROOT / "outputs" / "recent_oos_handoff" / "configs", "recent OOS")
    check_configs(ROOT / "outputs" / "confirmation_probe_handoff" / "configs", "confirmation probe")
    check_configs(ROOT / "outputs" / "breakeven_probe_handoff" / "configs", "break-even probe")
    check_configs(ROOT / "outputs" / "adx_filter_probe_handoff" / "configs", "ADX filter probe")
    check_configs(ROOT / "outputs" / "spread_guard_probe_handoff" / "configs", "ATR spread guard probe")
    check_configs(ROOT / "outputs" / "time_exit_probe_handoff" / "configs", "time exit probe")
    check_configs(ROOT / "outputs" / "mtf_trend_probe_handoff" / "configs", "MTF trend probe")
    check_configs(ROOT / "outputs" / "structure_trailing_probe_handoff" / "configs", "structure trailing probe")
    check_configs(ROOT / "outputs" / "session_variant_handoff" / "configs", "session variant")
    print("Static repository safety audit"); print(f"Warnings: {len(WARNINGS)}")
    for item in WARNINGS: print(f"WARNING: {item}")
    if FAILURES:
        print(f"Failures: {len(FAILURES)}")
        for item in FAILURES: print(f"FAIL: {item}")
        return 1
    print("PASS: static safety checks completed without failures."); return 0

if __name__ == "__main__": sys.exit(main())
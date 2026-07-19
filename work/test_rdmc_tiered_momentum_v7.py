#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "outputs" / "rdmc_tiered_momentum_v7_package" / "source" / "Professional_XAUUSD_EA.mq5"
PROFILE = ROOT / "outputs" / "rdmc_tiered_momentum_v7_package" / "profiles" / "rdmc_tiered_momentum_v7.set"
PREDECESSOR = ROOT / "outputs" / "rdmc_momentum_retest_hold_v6_package" / "source" / "Professional_XAUUSD_EA.mq5"
EXPECTED_SOURCE = "27CAD37CD903032335DA570CDEC75AC39C2EA6BEF04CA264D1586EDC866F6AF6"
EXPECTED_PROFILE = "6E2EF7B031FF30216876E0232A8CE9D6BFC9F7913A863103DC9B12C1A04A100C"
EXPECTED_PREDECESSOR = "B99BEFF28BB0D28596F4D7786C65BDA11001B0BC4924F269F534817EADC6CDCC"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def set_inputs(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if not line or line.startswith((";", "#")) or "=" not in line:
            continue
        name, value = line.split("=", 1)
        result[name] = value.split("||", 1)[0]
    return result


require(sha256(SOURCE) == EXPECTED_SOURCE, "rewrite source identity changed")
require(sha256(PROFILE) == EXPECTED_PROFILE, "rewrite profile identity changed")
require(sha256(PREDECESSOR) == EXPECTED_PREDECESSOR, "rejected predecessor was mutated")

text = SOURCE.read_text(encoding="utf-8-sig")
profile = set_inputs(PROFILE)
input_names = set(re.findall(r"(?m)^\s*input\s+(?!group\b)[^;=]+?\s+(Inp[A-Za-z0-9_]+)\s*=", text))
require(len(profile) == 614, f"expected 614 profile inputs, found {len(profile)}")
require(input_names == set(profile), "source/profile input surface is not exact")
require(profile["InpEvidenceSourceHash"] == EXPECTED_SOURCE, "profile evidence source hash changed")
require(profile["InpEvidenceProfileId"] == "rdmc_tiered_momentum_v7", "profile id changed")

for token in (
    "EffectiveRiskPercent(const bool bypassPrimaryLossStreakScaling = false)",
    "CanOpen(reason, true, true)",
    "LotsForRisk(bias, entryPrice, stopDistance, riskMultiplier, true)",
    "IsIsolatedPrimaryMagicLaneComment",
    "IsPrimarySoftStateExitDeal",
):
    require(token in text, f"missing rewrite token: {token}")

require(profile["InpMORiskPercent"] == "0.10", "MTSM risk is not capped at 0.10 percent")
require(profile["InpMOUseFastMomentumAgreement"] == "false", "fast momentum overfilter remains enabled")
require(profile["InpMOUseBreakoutQualityFilter"] == "false", "breakout quality overfilter remains enabled")
require(profile["InpMOUseTickVolumeExpansion"] == "false", "tick-volume overfilter remains enabled")
require(profile["InpMOLossRiskReductionStepHours"] == "24", "MTSM loss-risk decay step changed")
require(profile["InpUseDailyEquityTrailGuard"] == "false", "single-trade equity giveback guard remains enabled")
require(profile["InpMaxDailyLossPercent"] == "0.75", "portfolio daily loss cap changed")
require(profile["InpMOMaximumDailyLossPercent"] == "0.75", "MTSM daily loss cap changed")
require(profile["InpPrimaryLaneRiskMultiplier"] == "0.50", "primary feasibility budget changed")
require(profile["InpMOUseBreakoutRetestEntry"] == "true", "breakout-retest mechanism is not enabled")
require(profile["InpMOBreakoutRetestMaxBars"] == "6", "breakout-retest age changed")
require(profile["InpMOBreakoutRetestToleranceATR"] == "0.18", "breakout-retest tolerance changed")
require(profile["InpMOBreakoutRetestMaxDistanceATR"] == "0.75", "breakout-retest failure depth changed")
require(profile["InpMOBreakoutRetestMinBreakBodyPercent"] == "30.0", "breakout candle body floor changed")
require(profile["InpMOBreakoutRetestMinBodyPercent"] == "20.0", "retest candle body floor changed")
require(profile["InpMOBreakoutRetestMinCloseLocationPercent"] == "56.0", "retest close-location floor changed")
require(profile["InpMOUseBreakoutHoldEntry"] == "false", "rejected breakout-hold path remains enabled")
require(profile["InpMOBreakoutHoldRiskPercent"] == "0.05", "breakout-hold risk tier changed")
require(profile["InpMOBreakoutHoldMaxExtensionATR"] == "1.25", "breakout-hold extension cap changed")
require(profile["InpMOBreakoutHoldMinCloseBufferATR"] == "0.05", "breakout-hold close buffer changed")
require(profile["InpMOUseReducedRiskImmediateBreakoutEntry"] == "true", "reduced-risk immediate trigger is not enabled")
require(profile["InpMOImmediateBreakoutRiskPercent"] == "0.05", "immediate breakout risk tier changed")

retest = text[text.index("bool BreakoutRetestSignal"):text.index("bool RegimeAllows", text.index("bool BreakoutRetestSignal"))]
for token in (
    "ChannelBounds(shift + 1, InpMOEntryLookbackBars, channelHigh, channelLow)",
    "breakClose > channelHigh + buffer",
    "breakClose < channelLow - buffer",
    "low1 <= channelHigh + tolerance",
    "high1 >= channelLow - tolerance",
    "intermediateBuyHold",
    "intermediateSellHold",
):
    require(token in retest, f"missing stateless breakout-retest mechanism: {token}")
require("TimeDay" not in retest and "day_of_week" not in retest and "month" not in retest,
        "breakout-retest mechanism contains a calendar exclusion")

hold = text[text.index("bool BreakoutHoldSignal"):text.index("bool RegimeAllows", text.index("bool BreakoutHoldSignal"))]
for token in (
    "ChannelBounds(3, InpMOEntryLookbackBars, channelHigh, channelLow)",
    "low1 > channelHigh + retestTolerance",
    "high1 < channelLow - retestTolerance",
    "close1 > channelHigh + holdBuffer",
    "close1 < channelLow - holdBuffer",
    "InpMOBreakoutHoldMaxExtensionATR",
):
    require(token in hold, f"missing stateless breakout-hold mechanism: {token}")
require("TimeDay" not in hold and "day_of_week" not in hold and "month" not in hold,
        "breakout-hold mechanism contains a calendar exclusion")

momentum_entry = text[text.index("void TryEntry(const double atr)"):text.index("public:", text.index("void TryEntry(const double atr)"))]
require("BreakoutRetestSignal(atr, buyRetest, sellRetest)" in momentum_entry,
        "momentum entry does not route through the retest mechanism")
require("RegimeAllows(true, retestClose, atr)" in momentum_entry and
        "RegimeAllows(false, retestClose, atr)" in momentum_entry,
        "retest entry bypasses the D1 momentum/volatility regime")
require("BreakoutHoldSignal(atr, buyHold, sellHold)" in momentum_entry,
        "momentum entry does not route through the hold mechanism")
require("MathMin(InpMORiskPercent, InpMOBreakoutHoldRiskPercent)" in momentum_entry,
        "breakout-hold path is not bounded by the momentum lane cap")
require("MathMin(InpMORiskPercent, InpMOImmediateBreakoutRiskPercent)" in momentum_entry,
        "immediate breakout path is not bounded by the momentum lane cap")
require("OpenPosition(true, atr, breakoutRiskPercent, breakoutEntryReason)" in momentum_entry and
        "OpenPosition(false, atr, breakoutRiskPercent, breakoutEntryReason)" in momentum_entry,
        "immediate breakout entries do not use the selected reduced-risk tier")

hard_cap = text[text.index("double CapLotsToRiskPercent"):text.index("double LotsForRisk", text.index("double CapLotsToRiskPercent"))]
for token in (
    "RiskMoneyForOrder(orderType, entryPrice, stopPrice, lots)",
    "maxRiskMoney = equity * hardRiskPercent / 100.0",
    "lots = NormalizeVolumeDown(lots * maxRiskMoney / actualRiskMoney, step)",
):
    require(token in hard_cap, f"missing broker-valued lane cap mechanism: {token}")
require("InpAllowMinLotRiskOverflow" not in hard_cap, "hard lane cap permits minimum-lot risk overflow")
require(text.count("riskManager.CapLotsToRiskPercent(") == 6, "hard risk caps do not match the four entry routes and two primary rechecks")

momentum_open = text[text.index("bool OpenPosition(const bool buy"):text.index("bool TryChannelExit", text.index("bool OpenPosition(const bool buy"))]
require("riskMultiplier = laneRiskPercent / InpRiskPercent" in momentum_open,
        "momentum lot sizing does not use the selected setup risk tier")
require("CapLotsToRiskPercent(bias, entryPrice, stopDistance, lots, laneRiskPercent)" in momentum_open,
        "momentum setup risk tier is not broker-value capped")
for token in (
    "InpMOLossRiskReductionStepHours",
    "expiredSteps = (int)(elapsedSeconds / stepSeconds)",
    "reductionSteps -= expiredSteps",
):
    require(token in momentum_open, f"missing time-decayed MTSM loss-risk mechanism: {token}")

refresh = text[text.index("void RefreshConsecutiveLosses()"):text.index("bool AbnormalLossStreakQuarantineActive()")]
require("IsResearchPortfolioMagic" not in refresh, "primary soft streak still consumes every lane")
require("DEAL_MAGIC) != InpMagicNumber" in refresh, "primary soft streak is not primary scoped")
require("IsPrimarySoftStateExitDeal(ticket)" in refresh, "isolated lanes still feed primary soft streak")

band_open = text[text.index("bool OpenIsolatedBandVWAPReversionSignal"):text.index("bool OpenIsolatedDailyDonchianSignal")]
daily_open = text[text.index("bool OpenIsolatedDailyDonchianSignal"):text.index("bool OpenSignal(", text.index("bool OpenIsolatedDailyDonchianSignal"))]
for name, block in (("RRO", band_open), ("DDB", daily_open)):
    require("CanOpen(blockReason, true, true)" in block, f"{name} still consumes primary soft gate state")
    require("LotsForRisk(signal.bias, entry, stopDistance, riskMultiplier, true)" in block, f"{name} still consumes primary loss-size scaling")
    require("CapLotsToRiskPercent" in block, f"{name} is missing its broker-valued hard risk cap")

manager = text[text.index("class CPositionManager"):text.index("datetime g_lastBarTime")]
require(manager.count("IsIsolatedPrimaryMagicLaneComment(PositionGetString(POSITION_COMMENT))") >= 2,
        "shared basket management still includes isolated RRO/DDB positions")

safety = text[text.index("bool SafetyAllows(string &reason)"):text.index("bool ChannelBounds", text.index("bool SafetyAllows(string &reason)"))]
require("CanOpen(reason, true, true)" in safety, "MTSM still consumes primary soft-loss state")
for hard_limit in ("momentum daily loss limit", "momentum daily trade limit", "momentum spread limit", "momentum loss cooldown"):
    require(hard_limit in safety, f"MTSM hard/own safety limit disappeared: {hard_limit}")

on_tick = text[text.rindex("void OnTick()") : text.index("void OnTradeTransaction", text.rindex("void OnTick()"))]
primary_open = on_tick.index("openedPosition = OpenSignal(signal)")
final_momentum = on_tick.rindex("g_momentum.OnTick();")
require(primary_open < final_momentum, "primary entry is not scheduled before new-bar MTSM entry")
require("if(InpTradeOnlyNewBar && !newBar)\n   {\n      g_momentum.OnTick();" in on_tick, "non-M15-bar momentum management was lost")

for forbidden in ("martingale", "averaging down", "recovery sizing"):
    require(forbidden not in text.lower() or forbidden in text[:400].lower(), f"forbidden strategy behavior mentioned: {forbidden}")

print("RDMC_TIERED_MOMENTUM_V7_TEST_PASS inputs=614 identity=exact predecessor=unchanged")

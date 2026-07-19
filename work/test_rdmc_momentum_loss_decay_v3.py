#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "outputs" / "rdmc_momentum_loss_decay_v3_package" / "source" / "Professional_XAUUSD_EA.mq5"
PROFILE = ROOT / "outputs" / "rdmc_momentum_loss_decay_v3_package" / "profiles" / "rdmc_momentum_loss_decay_v3.set"
PREDECESSOR = ROOT / "outputs" / "rdmc_lane_isolation_rewrite_v2_package" / "source" / "Professional_XAUUSD_EA.mq5"
EXPECTED_SOURCE = "59A872EB7D4DA5159CDCAED791A51DF1C118F3E34EE460F0242BA486D7977370"
EXPECTED_PROFILE = "ED26F488D5E3025093714BF1C376AEEF95868E60334ACFFF20CD375632D9028D"
EXPECTED_PREDECESSOR = "1376E383DBB4A040DBC14337EA736DBFA4417C3B5D36DD629205665B9B81E569"


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
require(len(profile) == 601, f"expected 601 profile inputs, found {len(profile)}")
require(input_names == set(profile), "source/profile input surface is not exact")
require(profile["InpEvidenceSourceHash"] == EXPECTED_SOURCE, "profile evidence source hash changed")
require(profile["InpEvidenceProfileId"] == "rdmc_momentum_loss_decay_v3", "profile id changed")

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

momentum_open = text[text.index("bool OpenPosition(const bool buy"):text.index("bool TryChannelExit", text.index("bool OpenPosition(const bool buy"))]
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

print("RDMC_MOMENTUM_LOSS_DECAY_V3_TEST_PASS inputs=601 identity=exact predecessor=unchanged")

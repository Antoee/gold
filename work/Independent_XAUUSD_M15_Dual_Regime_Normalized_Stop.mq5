#property strict
#property version   "1.01"
#property description "XAUUSD M15 dual-regime research EA with optional price-normalized stop ceiling"

#include <Trade/Trade.mqh>

CTrade trade;

input group "Identity and Safety"
input string InpAllowedSymbol = "XAUUSD";
input ulong  InpMagicNumber = 26071774;
input bool   InpUseSymbolSafetyLock = true;
input bool   InpUseRealAccountSafetyLock = true;
input bool   InpAllowRealAccountTrading = false;
input string InpRealAccountApprovalCode = "DISABLED";

input group "Portfolio Engines"
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_M15;
input bool   InpEnableVolumeClimax = true;
input bool   InpEnableVolatilitySqueeze = true;
input bool   InpAllowBuy = true;
input bool   InpAllowSell = true;

input group "Volume-Climax Reversal Engine"
input int    InpVcrVolumeLookbackBars = 24;
input double InpVcrMinimumVolumeRatio = 1.30;
input int    InpVcrExtremeLookbackBars = 8;
input double InpVcrMinimumRangeATR = 1.10;
input double InpVcrMaximumRangeATR = 3.00;
input double InpVcrMinimumWickPercent = 45.0;
input double InpVcrMaximumBodyPercent = 55.0;
input double InpVcrMinimumCloseLocation = 0.55;
input double InpVcrMinimumVWAPDeviationATR = 0.45;
input double InpVcrMaximumVWAPDeviationATR = 2.50;
input double InpVcrMinimumRiskReward = 1.10;
input double InpVcrMaximumTargetR = 1.75;
input bool   InpVcrRequireFreshExtreme = true;

input group "Volatility-Squeeze Continuation Engine"
input int    InpSqSqueezeBars = 3;
input int    InpSqBollingerPeriod = 20;
input double InpSqBollingerDeviation = 2.00;
input int    InpSqKeltnerEMAPeriod = 20;
input double InpSqKeltnerATRMultiplier = 1.50;
input int    InpSqBreakoutLookbackBars = 8;
input double InpSqMaximumBreakoutChannelATR = 3.50;
input double InpSqBreakBufferATR = 0.03;
input double InpSqMinimumBreakRangeATR = 0.40;
input double InpSqMaximumBreakRangeATR = 1.60;
input double InpSqMinimumExpansionRatio = 1.10;
input double InpSqMinimumBreakBodyPercent = 35.0;
input double InpSqMinimumBreakCloseLocation = 0.65;
input bool   InpSqRequireDirectionCandle = true;
input bool   InpSqUseBreakoutTickVolumeFilter = false;
input int    InpSqVolumeLookbackBars = 20;
input double InpSqMinimumVolumeRatio = 1.05;

input group "Regime Filters"
input ENUM_TIMEFRAMES InpTrendTimeframe = PERIOD_H1;
input int  InpTrendEMAPeriod = 100;
input int  InpADXPeriod = 14;
input bool InpVcrUseRangePhaseFilter = true;
input double InpVcrMaximumADX = 28.0;
input double InpVcrMaximumTrendDistanceATR = 2.50;
input bool InpSqUseTrendEMAFilter = true;
input int  InpSqTrendEMASlopeBars = 3;
input bool InpSqRequireTrendAlignment = true;
input bool InpSqUseADXFilter = false;
input double InpSqMinimumADX = 14.0;
input double InpSqMaximumADX = 45.0;
input bool InpUseVolatilityFilter = true;
input double InpMinimumATRPercent = 0.03;
input double InpMaximumATRPercent = 2.50;

input group "Stops and Position Management"
input int    InpATRPeriod = 20;
input double InpMaximumStopPriceDistance = 6.00;
input bool   InpUsePriceNormalizedStopCap = false;
input double InpMaximumStopPricePercent = 0.30;
input double InpVcrStopBufferATR = 0.08;
input double InpVcrMinimumStopATR = 0.20;
input double InpVcrMaximumStopATR = 1.50;
input bool   InpVcrUseBreakEven = true;
input double InpVcrBreakEvenTriggerR = 0.90;
input double InpVcrBreakEvenLockR = 0.10;
input bool   InpVcrUseVWAPCrossExit = true;
input int    InpVcrMaximumHoldBars = 24;
input double InpSqStopBufferATR = 0.10;
input double InpSqMinimumStopATR = 0.25;
input double InpSqMaximumStopATR = 1.25;
input bool   InpSqUseFixedTakeProfit = true;
input double InpSqTakeProfitR = 1.50;
input bool   InpSqUseBreakEven = true;
input double InpSqBreakEvenTriggerR = 0.80;
input double InpSqBreakEvenLockR = 0.10;
input bool   InpSqUseTrendFailureExit = false;
input int    InpSqMaximumHoldBars = 32;
input bool   InpUseChandelierTrail = false;
input int    InpChandelierLookbackBars = 8;
input double InpChandelierATR = 2.50;

input group "Trading Session"
input bool InpUseSessionFilter = true;
input int  InpSessionStartHour = 6;
input int  InpSessionEndHour = 20;
input bool InpDisableFridayAfterHour = true;
input int  InpFridayCutoffHour = 18;

input group "Risk Manager"
input double InpRiskPercent = 0.10;
input double InpMaximumPositionLots = 1.00;
input int    InpMaximumSimultaneousPositions = 1;
input int    InpMaximumTradesPerDay = 2;
input double InpMaximumDailyLossPercent = 0.75;
input double InpMaximumEquityDrawdownPercent = 5.00;
input int    InpMaximumConsecutiveLosses = 4;
input int    InpLossCooldownHours = 24;
input double InpMaximumSpreadPoints = 50.0;
input int    InpDeviationPoints = 20;
input bool   InpUseAccountWideExposureGuard = true;
input double InpAccountWideMaxOpenRiskPercent = 3.00;
input int    InpAccountWideMaxPositions = 3;
input bool   InpAccountWideBlockUnprotectedExposure = true;

input group "Evidence Logging"
input bool   InpLogTrades = false;
input string InpLogFileName = "Independent_XAUUSD_M15_Dual_Regime_Portfolio_Trades.csv";
input string InpEvidenceProfileId = "";
input string InpEvidenceSourceHash = "";
input string InpEvidenceRunLabel = "";

int g_atrHandle = INVALID_HANDLE;
int g_bollingerHandle = INVALID_HANDLE;
int g_keltnerEmaHandle = INVALID_HANDLE;
int g_trendEmaHandle = INVALID_HANDLE;
int g_adxHandle = INVALID_HANDLE;
int g_logHandle = INVALID_HANDLE;
datetime g_dayStart = 0;
datetime g_lastSignalBar = 0;
double g_peakEquity = 0.0;
int g_climaxCandidates = 0;
int g_reversalSignals = 0;
int g_volumeRejects = 0;
int g_candleShapeRejects = 0;
int g_vwapRejects = 0;
int g_regimeRejects = 0;
int g_safetyRejects = 0;
int g_stopShapeRejects = 0;
int g_minimumLotRejects = 0;
int g_exposureRejects = 0;
int g_ordersOpened = 0;
int g_orderFailures = 0;
int g_squeezeCandidates = 0;
int g_breakoutSignals = 0;
int g_squeezeRejects = 0;
int g_breakShapeRejects = 0;

bool DailyAnchoredVWAP(const int signalShift, double &vwap);

string RiskKey(const ulong ticket)
{
   return "IM15DRP_RISK_" + IntegerToString((long)ticket);
}

double SpreadPoints()
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return DBL_MAX;
   return (tick.ask - tick.bid) / _Point;
}

bool SessionAllows()
{
   MqlDateTime now;
   if(!TimeToStruct(TimeCurrent(), now))
      return false;
   if(InpDisableFridayAfterHour && now.day_of_week == 5 && now.hour >= InpFridayCutoffHour)
      return false;
   if(!InpUseSessionFilter)
      return true;
   if(InpSessionStartHour == InpSessionEndHour)
      return true;
   if(InpSessionStartHour < InpSessionEndHour)
      return now.hour >= InpSessionStartHour && now.hour < InpSessionEndHour;
   return now.hour >= InpSessionStartHour || now.hour < InpSessionEndHour;
}

bool BufferValue(const int handle, const int buffer, const int shift, double &value)
{
   double values[];
   ArraySetAsSeries(values, true);
   if(handle == INVALID_HANDLE || CopyBuffer(handle, buffer, shift, 1, values) != 1)
      return false;
   value = values[0];
   return MathIsValidNumber(value) && value != EMPTY_VALUE;
}

void LogEvent(const string eventName,
              const ulong ticket,
              const string side,
              const double volume,
              const double price,
              const double sl,
              const double profit,
              const string reason)
{
   if(!InpLogTrades || g_logHandle == INVALID_HANDLE)
      return;
   FileWrite(g_logHandle,
             TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
             eventName,
             _Symbol,
             (string)ticket,
             side,
             DoubleToString(volume, 2),
             DoubleToString(price, _Digits),
             DoubleToString(sl, _Digits),
             DoubleToString(profit, 2),
             reason,
             InpEvidenceProfileId,
             InpEvidenceSourceHash,
             InpEvidenceRunLabel);
   FileFlush(g_logHandle);
}

datetime CurrentDayStart()
{
   return iTime(_Symbol, PERIOD_D1, 0);
}

void RefreshDayState()
{
   datetime dayStart = CurrentDayStart();
   if(dayStart > 0)
      g_dayStart = dayStart;
}

double ClosedProfitSince(const datetime fromTime)
{
   if(fromTime <= 0 || !HistorySelect(fromTime, TimeCurrent()))
      return 0.0;
   double profit = 0.0;
   for(int i = 0; i < HistoryDealsTotal(); ++i)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol)
         continue;
      if((ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber)
         continue;
      long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
         continue;
      profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
      profit += HistoryDealGetDouble(ticket, DEAL_SWAP);
      profit += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
   }
   return profit;
}

int EntriesSince(const datetime fromTime)
{
   if(fromTime <= 0 || !HistorySelect(fromTime, TimeCurrent()))
      return 0;
   int count = 0;
   for(int i = 0; i < HistoryDealsTotal(); ++i)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol)
         continue;
      if((ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber)
         continue;
      long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entryType == DEAL_ENTRY_IN || entryType == DEAL_ENTRY_INOUT)
         count++;
   }
   return count;
}

void LossStreak(int &streak, datetime &lastLossTime)
{
   streak = 0;
   lastLossTime = 0;
   if(!HistorySelect(0, TimeCurrent()))
      return;
   for(int i = HistoryDealsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol)
         continue;
      if((ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber)
         continue;
      long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
         continue;
      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                      HistoryDealGetDouble(ticket, DEAL_SWAP) +
                      HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      if(profit >= 0.0)
         return;
      if(lastLossTime == 0)
         lastLossTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      streak++;
   }
}

int ManagedPositionCount()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         count++;
   }
   return count;
}

bool RiskMoneyForOrder(const string symbol,
                       const ENUM_ORDER_TYPE orderType,
                       const double entryPrice,
                       const double stopPrice,
                       const double lots,
                       double &riskMoney)
{
   riskMoney = 0.0;
   if(StringLen(symbol) <= 0 || entryPrice <= 0.0 || stopPrice <= 0.0 || lots <= 0.0)
      return false;
   double stopProfit = 0.0;
   if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))
      return false;
   riskMoney = MathAbs(stopProfit);
   return riskMoney > 0.0 && MathIsValidNumber(riskMoney);
}

double AccountPositionRiskMoney(const ulong ticket, bool &unprotected)
{
   unprotected = false;
   if(ticket == 0 || !PositionSelectByTicket(ticket))
      return 0.0;
   string symbol = PositionGetString(POSITION_SYMBOL);
   double sl = PositionGetDouble(POSITION_SL);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double volume = PositionGetDouble(POSITION_VOLUME);
   long positionType = PositionGetInteger(POSITION_TYPE);
   if(StringLen(symbol) <= 0 || sl <= 0.0 || openPrice <= 0.0 || volume <= 0.0)
   {
      unprotected = true;
      return 0.0;
   }
   ENUM_ORDER_TYPE orderType;
   if(positionType == POSITION_TYPE_BUY)
   {
      if(sl >= openPrice)
         return 0.0;
      orderType = ORDER_TYPE_BUY;
   }
   else if(positionType == POSITION_TYPE_SELL)
   {
      if(sl <= openPrice)
         return 0.0;
      orderType = ORDER_TYPE_SELL;
   }
   else
   {
      unprotected = true;
      return 0.0;
   }
   double riskMoney = 0.0;
   if(!RiskMoneyForOrder(symbol, orderType, openPrice, sl, volume, riskMoney))
      unprotected = true;
   return riskMoney;
}

double AccountWideOpenRiskPercent(bool &hasUnprotectedPosition, int &positionCount)
{
   hasUnprotectedPosition = false;
   positionCount = 0;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
      return -1.0;
   double riskMoney = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      positionCount++;
      bool unprotected = false;
      riskMoney += AccountPositionRiskMoney(ticket, unprotected);
      if(unprotected)
         hasUnprotectedPosition = true;
   }
   return 100.0 * riskMoney / equity;
}

bool SafetyAllows(string &reason)
{
   if(InpUseSymbolSafetyLock && _Symbol != InpAllowedSymbol)
   {
      reason = "symbol safety lock";
      return false;
   }
   if(!MQLInfoInteger(MQL_TESTER) &&
      AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL &&
      (InpUseRealAccountSafetyLock || !InpAllowRealAccountTrading ||
       InpRealAccountApprovalCode != "M15DRP-LIVE-ACK"))
   {
      reason = "real-account safety lock";
      return false;
   }
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
   {
      reason = "invalid equity";
      return false;
   }
   if(g_peakEquity <= 0.0 || equity > g_peakEquity)
      g_peakEquity = equity;
   double drawdownPercent = 100.0 * (g_peakEquity - equity) / g_peakEquity;
   if(InpMaximumEquityDrawdownPercent > 0.0 && drawdownPercent >= InpMaximumEquityDrawdownPercent)
   {
      reason = "equity drawdown limit";
      return false;
   }
   double dailyProfit = ClosedProfitSince(g_dayStart);
   double dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE) - dailyProfit;
   if(InpMaximumDailyLossPercent > 0.0 && dayStartBalance > 0.0 &&
      dailyProfit <= -dayStartBalance * InpMaximumDailyLossPercent / 100.0)
   {
      reason = "daily loss limit";
      return false;
   }
   if(InpMaximumTradesPerDay > 0 && EntriesSince(g_dayStart) >= InpMaximumTradesPerDay)
   {
      reason = "daily trade limit";
      return false;
   }
   if(ManagedPositionCount() >= MathMax(1, InpMaximumSimultaneousPositions))
   {
      reason = "position limit";
      return false;
   }
   if(SpreadPoints() > InpMaximumSpreadPoints)
   {
      reason = "spread limit";
      return false;
   }
   if(!SessionAllows())
   {
      reason = "session filter";
      return false;
   }
   int streak = 0;
   datetime lastLoss = 0;
   LossStreak(streak, lastLoss);
   if(InpMaximumConsecutiveLosses > 0 && streak >= InpMaximumConsecutiveLosses &&
      lastLoss > 0 && TimeCurrent() - lastLoss < InpLossCooldownHours * 3600)
   {
      reason = "loss cooldown";
      return false;
   }
   reason = "allowed";
   return true;
}

bool ChannelBounds(const int startShift,
                   const int count,
                   double &channelHigh,
                   double &channelLow)
{
   if(startShift < 1 || count < 2)
      return false;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, InpSignalTimeframe, startShift, count, rates) != count)
      return false;
   channelHigh = -DBL_MAX;
   channelLow = DBL_MAX;
   for(int i = 0; i < count; ++i)
   {
      channelHigh = MathMax(channelHigh, rates[i].high);
      channelLow = MathMin(channelLow, rates[i].low);
   }
   return channelHigh > channelLow && channelLow > 0.0;
}

bool VcrRegimeAllows(const bool buy, const double closePrice, const double atr)
{
   if(closePrice <= 0.0 || atr <= 0.0)
      return false;
   if(InpUseVolatilityFilter)
   {
      double atrPercent = 100.0 * atr / closePrice;
      if(atrPercent < InpMinimumATRPercent || atrPercent > InpMaximumATRPercent)
         return false;
   }
   if(InpVcrUseRangePhaseFilter)
   {
      double ema = 0.0;
      double adx = 0.0;
      if(!BufferValue(g_trendEmaHandle, 0, 1, ema) || ema <= 0.0 ||
         !BufferValue(g_adxHandle, 0, 1, adx))
         return false;
      if((InpVcrMaximumADX > 0.0 && adx > InpVcrMaximumADX) ||
         (InpVcrMaximumTrendDistanceATR > 0.0 &&
          MathAbs(closePrice - ema) > InpVcrMaximumTrendDistanceATR * atr))
         return false;
   }
   return true;
}

bool SqRegimeAllows(const bool buy, const double closePrice, const double atr)
{
   if(closePrice <= 0.0 || atr <= 0.0)
      return false;
   if(InpUseVolatilityFilter)
   {
      double atrPercent = 100.0 * atr / closePrice;
      if(atrPercent < InpMinimumATRPercent || atrPercent > InpMaximumATRPercent)
         return false;
   }
   if(InpSqUseTrendEMAFilter)
   {
      double emaNow = 0.0;
      double emaPast = 0.0;
      if(!BufferValue(g_trendEmaHandle, 0, 1, emaNow) ||
         !BufferValue(g_trendEmaHandle, 0, 1 + MathMax(1, InpSqTrendEMASlopeBars), emaPast))
         return false;
      if(InpSqRequireTrendAlignment)
      {
         if(buy && (closePrice <= emaNow || emaNow <= emaPast))
            return false;
         if(!buy && (closePrice >= emaNow || emaNow >= emaPast))
            return false;
      }
   }
   if(InpSqUseADXFilter)
   {
      double adx = 0.0;
      if(!BufferValue(g_adxHandle, 0, 1, adx) || adx < InpSqMinimumADX ||
         (InpSqMaximumADX > 0.0 && adx > InpSqMaximumADX))
         return false;
   }
   return true;
}

double NormalizeVolume(const double rawVolume)
{
   double minimum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maximum = MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), InpMaximumPositionLots);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(minimum <= 0.0 || maximum < minimum || step <= 0.0)
      return 0.0;
   double volume = MathFloor(rawVolume / step + 1e-8) * step;
   if(volume < minimum)
      return 0.0;
   return MathMin(volume, maximum);
}

double LotsForRisk(const bool buy, const double entryPrice, const double stopPrice)
{
   if(entryPrice <= 0.0 || stopPrice <= 0.0 || InpRiskPercent <= 0.0)
      return 0.0;
   double lossPerLot = 0.0;
   ENUM_ORDER_TYPE orderType = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!RiskMoneyForOrder(_Symbol, orderType, entryPrice, stopPrice, 1.0, lossPerLot))
      return 0.0;
   double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * InpRiskPercent / 100.0;
   return NormalizeVolume(riskMoney / lossPerLot);
}

bool AccountWideExposureAllows(const bool buy,
                               const double entryPrice,
                               const double stopPrice,
                               const double lots,
                               string &reason)
{
   if(!InpUseAccountWideExposureGuard)
      return true;
   bool hasUnprotected = false;
   int positionCount = 0;
   double openRiskPercent = AccountWideOpenRiskPercent(hasUnprotected, positionCount);
   if(openRiskPercent < 0.0)
   {
      reason = "account-wide equity unavailable";
      return false;
   }
   if(hasUnprotected && InpAccountWideBlockUnprotectedExposure)
   {
      reason = "account-wide unprotected exposure";
      return false;
   }
   if(InpAccountWideMaxPositions <= 0 || positionCount >= InpAccountWideMaxPositions)
   {
      reason = "account-wide position limit";
      return false;
   }
   if(InpAccountWideMaxOpenRiskPercent <= 0.0)
   {
      reason = "account-wide risk cap disabled";
      return false;
   }
   double addedRiskMoney = 0.0;
   ENUM_ORDER_TYPE orderType = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!RiskMoneyForOrder(_Symbol, orderType, entryPrice, stopPrice, lots, addedRiskMoney))
   {
      reason = "account-wide added risk calculation";
      return false;
   }
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
   {
      reason = "account-wide equity unavailable";
      return false;
   }
   double addedRiskPercent = 100.0 * addedRiskMoney / equity;
   if(openRiskPercent + addedRiskPercent > InpAccountWideMaxOpenRiskPercent)
   {
      reason = "account-wide open risk limit";
      return false;
   }
   return true;
}

void RegisterRiskForNewestPosition(const double riskDistance)
{
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
      {
         GlobalVariableSet(RiskKey(ticket), riskDistance);
         return;
      }
   }
}

bool FinalizeStructureStop(const bool buy,
                           const double entryPrice,
                           const double rawStop,
                           const double atr,
                           const double minimumStopATR,
                           const double maximumStopATR,
                           double &stopPrice,
                           double &stopDistance)
{
   if(entryPrice <= 0.0 || rawStop <= 0.0 || atr <= 0.0)
      return false;
   stopDistance = buy ? entryPrice - rawStop : rawStop - entryPrice;
   if(stopDistance <= 0.0)
      return false;
   double minimumDistance = MathMax(minimumStopATR * atr,
                                    (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point + _Point);
   if(stopDistance < minimumDistance)
      stopDistance = minimumDistance;
   double atrUnits = stopDistance / atr;
   if(atrUnits > maximumStopATR)
      return false;
   double maximumPriceDistance = InpMaximumStopPriceDistance;
   if(InpUsePriceNormalizedStopCap)
      maximumPriceDistance = entryPrice * InpMaximumStopPricePercent / 100.0;
   if(maximumPriceDistance > 0.0 && stopDistance > maximumPriceDistance)
      return false;
   stopPrice = NormalizeDouble(buy ? entryPrice - stopDistance : entryPrice + stopDistance, _Digits);
   return stopPrice > 0.0;
}

bool OpenClimaxPosition(const bool buy,
                        const double atr,
                        const double rawStop,
                        const double vwapTarget)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || atr <= 0.0)
      return false;
   double entryPrice = buy ? tick.ask : tick.bid;
   double stopPrice = 0.0;
   double stopDistance = 0.0;
   if(!FinalizeStructureStop(buy, entryPrice, rawStop, atr,
                             InpVcrMinimumStopATR, InpVcrMaximumStopATR,
                             stopPrice, stopDistance))
   {
      g_stopShapeRejects++;
      return false;
   }
   double lots = LotsForRisk(buy, entryPrice, stopPrice);
   if(lots <= 0.0)
   {
      g_minimumLotRejects++;
      return false;
   }
   string exposureReason = "";
   if(!AccountWideExposureAllows(buy, entryPrice, stopPrice, lots, exposureReason))
   {
      g_exposureRejects++;
      return false;
   }
   double takeProfit = vwapTarget;
   if(InpVcrMaximumTargetR > 0.0)
   {
      double cappedTarget = buy ? entryPrice + InpVcrMaximumTargetR * stopDistance
                                : entryPrice - InpVcrMaximumTargetR * stopDistance;
      takeProfit = buy ? MathMin(takeProfit, cappedTarget) : MathMax(takeProfit, cappedTarget);
   }
   double rewardDistance = buy ? takeProfit - entryPrice : entryPrice - takeProfit;
   if(rewardDistance <= 0.0 || rewardDistance / stopDistance < InpVcrMinimumRiskReward)
   {
      g_vwapRejects++;
      return false;
   }
   takeProfit = NormalizeDouble(takeProfit, _Digits);
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   string comment = buy ? "M15DRP_VCR_BUY" : "M15DRP_VCR_SELL";
   bool opened = buy ? trade.Buy(lots, _Symbol, 0.0, stopPrice, takeProfit, comment)
                     : trade.Sell(lots, _Symbol, 0.0, stopPrice, takeProfit, comment);
   if(!opened)
   {
      g_orderFailures++;
      return false;
   }
   g_ordersOpened++;
   RegisterRiskForNewestPosition(stopDistance);
   LogEvent("entry", trade.ResultOrder(), buy ? "buy" : "sell", lots, entryPrice, stopPrice, 0.0,
            "M15 volume climax VWAP reversal");
   return true;
}

bool OpenSqueezePosition(const bool buy,
                         const double atr,
                         const double rawStop)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || atr <= 0.0)
      return false;
   double entryPrice = buy ? tick.ask : tick.bid;
   double stopPrice = 0.0;
   double stopDistance = 0.0;
   if(!FinalizeStructureStop(buy, entryPrice, rawStop, atr,
                             InpSqMinimumStopATR, InpSqMaximumStopATR,
                             stopPrice, stopDistance))
   {
      g_stopShapeRejects++;
      return false;
   }
   double lots = LotsForRisk(buy, entryPrice, stopPrice);
   if(lots <= 0.0)
   {
      g_minimumLotRejects++;
      return false;
   }
   string exposureReason = "";
   if(!AccountWideExposureAllows(buy, entryPrice, stopPrice, lots, exposureReason))
   {
      g_exposureRejects++;
      return false;
   }
   double takeProfit = 0.0;
   if(InpSqUseFixedTakeProfit && InpSqTakeProfitR > 0.0)
      takeProfit = NormalizeDouble(buy ? entryPrice + InpSqTakeProfitR * stopDistance
                                       : entryPrice - InpSqTakeProfitR * stopDistance, _Digits);
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   string comment = buy ? "M15DRP_SQ_BUY" : "M15DRP_SQ_SELL";
   bool opened = buy ? trade.Buy(lots, _Symbol, 0.0, stopPrice, takeProfit, comment)
                     : trade.Sell(lots, _Symbol, 0.0, stopPrice, takeProfit, comment);
   if(!opened)
   {
      g_orderFailures++;
      return false;
   }
   g_ordersOpened++;
   RegisterRiskForNewestPosition(stopDistance);
   LogEvent("entry", trade.ResultOrder(), buy ? "buy" : "sell", lots, entryPrice, stopPrice, 0.0,
            "M15 volatility squeeze continuation");
   return true;
}

bool TryManagedExit(const ulong ticket, const bool buy)
{
   string positionComment = PositionGetString(POSITION_COMMENT);
   bool squeezeLane = StringFind(positionComment, "M15DRP_SQ_") == 0;
   int maximumHoldBars = squeezeLane ? InpSqMaximumHoldBars : InpVcrMaximumHoldBars;
   if(maximumHoldBars > 0)
   {
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int openShift = iBarShift(_Symbol, InpSignalTimeframe, openTime, false);
      if(openShift >= maximumHoldBars)
         return trade.PositionClose(ticket);
   }
   if(squeezeLane && InpSqUseTrendFailureExit)
   {
      double ema = 0.0;
      double closePrice = iClose(_Symbol, InpSignalTimeframe, 1);
      if(BufferValue(g_trendEmaHandle, 0, 1, ema) && closePrice > 0.0)
      {
         bool failed = buy ? closePrice < ema : closePrice > ema;
         if(failed)
            return trade.PositionClose(ticket);
      }
   }
   if(!squeezeLane && InpVcrUseVWAPCrossExit)
   {
      double vwap = 0.0;
      double closePrice = iClose(_Symbol, InpSignalTimeframe, 1);
      if(DailyAnchoredVWAP(1, vwap) && closePrice > 0.0)
      {
         bool reachedMean = buy ? closePrice >= vwap : closePrice <= vwap;
         if(reachedMean)
            return trade.PositionClose(ticket);
      }
   }
   return false;
}

void ImproveProtectiveStop(const ulong ticket, const bool buy, const double atr)
{
   string positionComment = PositionGetString(POSITION_COMMENT);
   bool squeezeLane = StringFind(positionComment, "M15DRP_SQ_") == 0;
   bool useBreakEven = squeezeLane ? InpSqUseBreakEven : InpVcrUseBreakEven;
   double breakEvenTriggerR = squeezeLane ? InpSqBreakEvenTriggerR : InpVcrBreakEvenTriggerR;
   double breakEvenLockR = squeezeLane ? InpSqBreakEvenLockR : InpVcrBreakEvenLockR;
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double oldSl = PositionGetDouble(POSITION_SL);
   double current = buy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double initialRisk = GlobalVariableCheck(RiskKey(ticket)) ? GlobalVariableGet(RiskKey(ticket))
                                                            : MathAbs(openPrice - oldSl);
   if(initialRisk <= 0.0 || current <= 0.0)
      return;
   double favorable = buy ? current - openPrice : openPrice - current;
   double r = favorable / initialRisk;
   double newSl = oldSl;
   if(useBreakEven && r >= breakEvenTriggerR)
   {
      double breakEven = buy ? openPrice + breakEvenLockR * initialRisk
                             : openPrice - breakEvenLockR * initialRisk;
      if((buy && breakEven > newSl) || (!buy && breakEven < newSl))
         newSl = breakEven;
   }
   if(InpUseChandelierTrail)
   {
      double channelHigh = 0.0;
      double channelLow = 0.0;
      if(ChannelBounds(1, InpChandelierLookbackBars, channelHigh, channelLow))
      {
         double chandelier = buy ? channelHigh - InpChandelierATR * atr
                                  : channelLow + InpChandelierATR * atr;
         if((buy && chandelier > newSl) || (!buy && chandelier < newSl))
            newSl = chandelier;
      }
   }
   newSl = NormalizeDouble(newSl, _Digits);
   double minimumDistance = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   bool valid = buy ? newSl > 0.0 && newSl < current - minimumDistance
                    : newSl > current + minimumDistance;
   bool improved = buy ? newSl > oldSl + _Point : newSl < oldSl - _Point;
   if(valid && improved)
   {
      double oldTp = PositionGetDouble(POSITION_TP);
      trade.PositionModify(ticket, newSl, oldTp);
   }
}

bool ManagePositionOnBar(const double atr)
{
   bool closed = false;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      bool buy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      if(TryManagedExit(ticket, buy))
      {
         closed = true;
         continue;
      }
      if(PositionSelectByTicket(ticket))
         ImproveProtectiveStop(ticket, buy, atr);
   }
   return closed;
}

double CandleBodyPercent(const int shift)
{
   double open = iOpen(_Symbol, InpSignalTimeframe, shift);
   double close = iClose(_Symbol, InpSignalTimeframe, shift);
   double high = iHigh(_Symbol, InpSignalTimeframe, shift);
   double low = iLow(_Symbol, InpSignalTimeframe, shift);
   double range = high - low;
   if(range <= 0.0)
      return 0.0;
   return 100.0 * MathAbs(close - open) / range;
}

double CandleCloseLocation(const bool buy, const int shift)
{
   double close = iClose(_Symbol, InpSignalTimeframe, shift);
   double high = iHigh(_Symbol, InpSignalTimeframe, shift);
   double low = iLow(_Symbol, InpSignalTimeframe, shift);
   double range = high - low;
   if(range <= 0.0)
      return 0.0;
   return buy ? (close - low) / range : (high - close) / range;
}

double CandleWickPercent(const bool lowerWick, const int shift)
{
   double open = iOpen(_Symbol, InpSignalTimeframe, shift);
   double close = iClose(_Symbol, InpSignalTimeframe, shift);
   double high = iHigh(_Symbol, InpSignalTimeframe, shift);
   double low = iLow(_Symbol, InpSignalTimeframe, shift);
   double range = high - low;
   if(range <= 0.0)
      return 0.0;
   double wick = lowerWick ? MathMin(open, close) - low
                           : high - MathMax(open, close);
   return 100.0 * MathMax(0.0, wick) / range;
}

double TickVolumeRatio(const int signalShift)
{
   long signalVolume = iVolume(_Symbol, InpSignalTimeframe, signalShift);
   if(signalVolume <= 0 || InpVcrVolumeLookbackBars < 2)
      return 0.0;
   double total = 0.0;
   int count = 0;
   for(int shift = signalShift + 1; shift <= signalShift + InpVcrVolumeLookbackBars; ++shift)
   {
      long volume = iVolume(_Symbol, InpSignalTimeframe, shift);
      if(volume <= 0)
         continue;
      total += (double)volume;
      count++;
   }
   if(count <= 0 || total <= 0.0)
      return 0.0;
   return (double)signalVolume / (total / count);
}

bool DailyAnchoredVWAP(const int signalShift, double &vwap)
{
   vwap = 0.0;
   datetime signalTime = iTime(_Symbol, InpSignalTimeframe, signalShift);
   if(signalTime <= 0)
      return false;
   int dayShift = iBarShift(_Symbol, PERIOD_D1, signalTime, false);
   if(dayShift < 0)
      return false;
   datetime dayStart = iTime(_Symbol, PERIOD_D1, dayShift);
   int oldestShift = iBarShift(_Symbol, InpSignalTimeframe, dayStart, false);
   int firstShift = signalShift + 1;
   if(dayStart <= 0 || oldestShift < firstShift)
      return false;
   double weightedPrice = 0.0;
   double totalVolume = 0.0;
   for(int shift = firstShift; shift <= oldestShift; ++shift)
   {
      double high = iHigh(_Symbol, InpSignalTimeframe, shift);
      double low = iLow(_Symbol, InpSignalTimeframe, shift);
      double close = iClose(_Symbol, InpSignalTimeframe, shift);
      long volume = iVolume(_Symbol, InpSignalTimeframe, shift);
      if(high <= 0.0 || low <= 0.0 || close <= 0.0 || volume <= 0)
         continue;
      double typical = (high + low + close) / 3.0;
      weightedPrice += typical * (double)volume;
      totalVolume += (double)volume;
   }
   if(totalVolume <= 0.0)
      return false;
   vwap = weightedPrice / totalVolume;
   return vwap > 0.0 && MathIsValidNumber(vwap);
}

bool FreshExtremeAllows(const bool buy)
{
   if(!InpVcrRequireFreshExtreme)
      return true;
   double channelHigh = 0.0;
   double channelLow = 0.0;
   if(!ChannelBounds(2, InpVcrExtremeLookbackBars, channelHigh, channelLow))
      return false;
   return buy ? iLow(_Symbol, InpSignalTimeframe, 1) < channelLow
              : iHigh(_Symbol, InpSignalTimeframe, 1) > channelHigh;
}

bool TryVolumeClimaxEntry(const double atr)
{
   if(!InpEnableVolumeClimax || atr <= 0.0)
      return false;
   double open1 = iOpen(_Symbol, InpSignalTimeframe, 1);
   double close1 = iClose(_Symbol, InpSignalTimeframe, 1);
   double high1 = iHigh(_Symbol, InpSignalTimeframe, 1);
   double low1 = iLow(_Symbol, InpSignalTimeframe, 1);
   double range1 = high1 - low1;
   if(open1 <= 0.0 || close1 <= 0.0 || range1 <= 0.0)
      return false;

   double volumeRatio = TickVolumeRatio(1);
   if(volumeRatio < InpVcrMinimumVolumeRatio)
   {
      g_volumeRejects++;
      return false;
   }
   if(range1 < InpVcrMinimumRangeATR * atr ||
      range1 > InpVcrMaximumRangeATR * atr ||
      CandleBodyPercent(1) > InpVcrMaximumBodyPercent)
   {
      g_candleShapeRejects++;
      return false;
   }
   g_climaxCandidates++;

   double vwap = 0.0;
   if(!DailyAnchoredVWAP(1, vwap))
   {
      g_vwapRejects++;
      return false;
   }
   double deviationATR = MathAbs(close1 - vwap) / atr;
   if(deviationATR < InpVcrMinimumVWAPDeviationATR ||
      deviationATR > InpVcrMaximumVWAPDeviationATR)
   {
      g_vwapRejects++;
      return false;
   }

   bool buy = InpAllowBuy && close1 < vwap &&
              CandleWickPercent(true, 1) >= InpVcrMinimumWickPercent &&
              CandleCloseLocation(true, 1) >= InpVcrMinimumCloseLocation &&
              FreshExtremeAllows(true);
   bool sell = InpAllowSell && close1 > vwap &&
               CandleWickPercent(false, 1) >= InpVcrMinimumWickPercent &&
               CandleCloseLocation(false, 1) >= InpVcrMinimumCloseLocation &&
               FreshExtremeAllows(false);
   if(buy == sell)
   {
      g_candleShapeRejects++;
      return false;
   }
   if(!VcrRegimeAllows(buy, close1, atr))
   {
      g_regimeRejects++;
      return false;
   }
   string safetyReason = "";
   if(!SafetyAllows(safetyReason))
   {
      g_safetyRejects++;
      return false;
   }

   g_reversalSignals++;
   double rawStop = buy ? low1 - InpVcrStopBufferATR * atr
                        : high1 + InpVcrStopBufferATR * atr;
   return OpenClimaxPosition(buy, atr, rawStop, vwap);
}

bool SqTickVolumeAllows(const int signalShift)
{
   if(!InpSqUseBreakoutTickVolumeFilter)
      return true;
   long signalVolume = iVolume(_Symbol, InpSignalTimeframe, signalShift);
   if(signalVolume <= 0 || InpSqVolumeLookbackBars < 2)
      return false;
   double total = 0.0;
   int count = 0;
   for(int shift = signalShift + 1; shift <= signalShift + InpSqVolumeLookbackBars; ++shift)
   {
      long volume = iVolume(_Symbol, InpSignalTimeframe, shift);
      if(volume <= 0)
         continue;
      total += (double)volume;
      count++;
   }
   if(count <= 0 || total <= 0.0)
      return false;
   return (double)signalVolume >= (total / count) * InpSqMinimumVolumeRatio;
}

double AverageBarRange(const int startShift, const int count)
{
   if(startShift < 1 || count < 1)
      return 0.0;
   double total = 0.0;
   for(int shift = startShift; shift < startShift + count; ++shift)
   {
      double high = iHigh(_Symbol, InpSignalTimeframe, shift);
      double low = iLow(_Symbol, InpSignalTimeframe, shift);
      if(high <= low || low <= 0.0)
         return 0.0;
      total += high - low;
   }
   return total / count;
}

bool SqSqueezeBarAllows(const int shift)
{
   double atr = 0.0;
   double basis = 0.0;
   double upperBand = 0.0;
   double lowerBand = 0.0;
   if(!BufferValue(g_atrHandle, 0, shift, atr) || atr <= 0.0 ||
      !BufferValue(g_keltnerEmaHandle, 0, shift, basis) || basis <= 0.0 ||
      !BufferValue(g_bollingerHandle, 1, shift, upperBand) ||
      !BufferValue(g_bollingerHandle, 2, shift, lowerBand) ||
      upperBand <= lowerBand)
      return false;
   double keltnerOffset = InpSqKeltnerATRMultiplier * atr;
   return upperBand <= basis + keltnerOffset &&
          lowerBand >= basis - keltnerOffset;
}

bool SqSqueezeWindowAllows(const int startShift, const int count)
{
   for(int shift = startShift; shift < startShift + count; ++shift)
   {
      if(!SqSqueezeBarAllows(shift))
         return false;
   }
   return true;
}

bool TryVolatilitySqueezeEntry(const double atr)
{
   if(!InpEnableVolatilitySqueeze || atr <= 0.0)
      return false;
   double open1 = iOpen(_Symbol, InpSignalTimeframe, 1);
   double close1 = iClose(_Symbol, InpSignalTimeframe, 1);
   double high1 = iHigh(_Symbol, InpSignalTimeframe, 1);
   double low1 = iLow(_Symbol, InpSignalTimeframe, 1);
   double range1 = high1 - low1;
   if(open1 <= 0.0 || close1 <= 0.0 || range1 <= 0.0)
      return false;

   if(!SqSqueezeWindowAllows(2, InpSqSqueezeBars))
   {
      g_squeezeRejects++;
      return false;
   }
   double channelHigh = 0.0;
   double channelLow = 0.0;
   if(!ChannelBounds(2, InpSqBreakoutLookbackBars, channelHigh, channelLow))
      return false;
   double channelRange = channelHigh - channelLow;
   double averageSqueezeBarRange = AverageBarRange(2, InpSqSqueezeBars);
   if(channelRange <= 0.0 ||
      channelRange > InpSqMaximumBreakoutChannelATR * atr ||
      averageSqueezeBarRange <= 0.0)
   {
      g_squeezeRejects++;
      return false;
   }
   g_squeezeCandidates++;

   double buffer = InpSqBreakBufferATR * atr;
   bool buy = InpAllowBuy && close1 > channelHigh + buffer;
   bool sell = InpAllowSell && close1 < channelLow - buffer;
   if(buy == sell)
      return false;

   bool directionCandle = !InpSqRequireDirectionCandle || (buy ? close1 > open1 : close1 < open1);
   bool breakShapeAllows = directionCandle &&
                           range1 >= InpSqMinimumBreakRangeATR * atr &&
                           range1 <= InpSqMaximumBreakRangeATR * atr &&
                           range1 >= InpSqMinimumExpansionRatio * averageSqueezeBarRange &&
                           CandleBodyPercent(1) >= InpSqMinimumBreakBodyPercent &&
                           CandleCloseLocation(buy, 1) >= InpSqMinimumBreakCloseLocation &&
                           SqTickVolumeAllows(1);
   if(!breakShapeAllows)
   {
      g_breakShapeRejects++;
      return false;
   }
   if(!SqRegimeAllows(buy, close1, atr))
   {
      g_regimeRejects++;
      return false;
   }
   string safetyReason = "";
   if(!SafetyAllows(safetyReason))
   {
      g_safetyRejects++;
      return false;
   }

   g_breakoutSignals++;
   double rawStop = buy ? low1 - InpSqStopBufferATR * atr
                        : high1 + InpSqStopBufferATR * atr;
   return OpenSqueezePosition(buy, atr, rawStop);
}

int OnInit()
{
   if((!InpEnableVolumeClimax && !InpEnableVolatilitySqueeze) ||
      InpVcrVolumeLookbackBars < 2 || InpVcrMinimumVolumeRatio <= 0.0 ||
      InpVcrExtremeLookbackBars < 2 ||
      InpVcrMinimumRangeATR <= 0.0 || InpVcrMaximumRangeATR < InpVcrMinimumRangeATR ||
      InpVcrMinimumWickPercent < 0.0 || InpVcrMinimumWickPercent > 100.0 ||
      InpVcrMaximumBodyPercent < 0.0 || InpVcrMaximumBodyPercent > 100.0 ||
      InpVcrMinimumCloseLocation < 0.50 || InpVcrMinimumCloseLocation > 1.0 ||
      InpVcrMinimumVWAPDeviationATR < 0.0 ||
      InpVcrMaximumVWAPDeviationATR < InpVcrMinimumVWAPDeviationATR ||
      InpVcrMinimumRiskReward <= 0.0 || InpVcrMaximumTargetR < InpVcrMinimumRiskReward ||
      InpSqSqueezeBars < 1 || InpSqBollingerPeriod < 2 || InpSqKeltnerEMAPeriod < 2 ||
      InpSqBreakoutLookbackBars < 2 ||
      InpSqMinimumBreakRangeATR <= 0.0 || InpSqMaximumBreakRangeATR < InpSqMinimumBreakRangeATR ||
      InpSqMinimumBreakBodyPercent < 0.0 || InpSqMinimumBreakBodyPercent > 100.0 ||
      InpSqMinimumBreakCloseLocation < 0.50 || InpSqMinimumBreakCloseLocation > 1.0 ||
      InpSqVolumeLookbackBars < 2 || InpSqMinimumVolumeRatio <= 0.0 ||
      InpTrendEMAPeriod < 2 || InpADXPeriod < 2 || InpVcrMaximumADX < 0.0 ||
      InpVcrMaximumTrendDistanceATR < 0.0 || InpSqTrendEMASlopeBars < 1 ||
      InpSqMinimumADX < 0.0 || InpSqMaximumADX < InpSqMinimumADX ||
      InpATRPeriod < 2 || InpVcrStopBufferATR < 0.0 || InpSqStopBufferATR < 0.0 ||
      InpMaximumStopPriceDistance < 0.0 ||
      (InpUsePriceNormalizedStopCap &&
       (InpMaximumStopPricePercent <= 0.0 || InpMaximumStopPricePercent > 5.0)) ||
      InpVcrMinimumStopATR <= 0.0 || InpVcrMaximumStopATR < InpVcrMinimumStopATR ||
      InpSqMinimumStopATR <= 0.0 || InpSqMaximumStopATR < InpSqMinimumStopATR ||
      InpRiskPercent <= 0.0 || InpRiskPercent > 2.0 ||
      InpSessionStartHour < 0 || InpSessionStartHour > 23 ||
      InpSessionEndHour < 0 || InpSessionEndHour > 23 ||
      InpFridayCutoffHour < 0 || InpFridayCutoffHour > 23 ||
      InpMaximumSimultaneousPositions < 1 ||
      InpAccountWideMaxPositions < 1)
      return INIT_PARAMETERS_INCORRECT;
   g_atrHandle = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);
   g_bollingerHandle = iBands(_Symbol, InpSignalTimeframe, InpSqBollingerPeriod,
                              0, InpSqBollingerDeviation, PRICE_CLOSE);
   g_keltnerEmaHandle = iMA(_Symbol, InpSignalTimeframe, InpSqKeltnerEMAPeriod,
                            0, MODE_EMA, PRICE_CLOSE);
   g_trendEmaHandle = iMA(_Symbol, InpTrendTimeframe, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_adxHandle = iADX(_Symbol, InpTrendTimeframe, InpADXPeriod);
   if(g_atrHandle == INVALID_HANDLE || g_bollingerHandle == INVALID_HANDLE ||
      g_keltnerEmaHandle == INVALID_HANDLE || g_trendEmaHandle == INVALID_HANDLE ||
      g_adxHandle == INVALID_HANDLE)
      return INIT_FAILED;
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   RefreshDayState();
   if(InpLogTrades)
   {
      g_logHandle = FileOpen(InpLogFileName,
                             FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_SHARE_READ | FILE_SHARE_WRITE);
      if(g_logHandle != INVALID_HANDLE)
      {
         if(FileSize(g_logHandle) == 0)
            FileWrite(g_logHandle, "time", "event", "symbol", "ticket", "side", "volume", "price", "sl", "profit", "reason", "profile_id", "source_hash", "run_label");
         FileSeek(g_logHandle, 0, SEEK_END);
      }
   }
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   PrintFormat("M15DRP_DIAGNOSTIC climaxes=%d reversals=%d squeezes=%d breakouts=%d volume_rejects=%d shape_rejects=%d squeeze_rejects=%d break_shape_rejects=%d vwap_rejects=%d regime_rejects=%d safety_rejects=%d opened=%d stop_shape_rejects=%d minimum_lot_rejects=%d exposure_rejects=%d order_failures=%d",
               g_climaxCandidates, g_reversalSignals,
               g_squeezeCandidates, g_breakoutSignals, g_volumeRejects,
               g_candleShapeRejects, g_squeezeRejects, g_breakShapeRejects,
               g_vwapRejects, g_regimeRejects,
               g_safetyRejects, g_ordersOpened, g_stopShapeRejects, g_minimumLotRejects,
               g_exposureRejects, g_orderFailures);
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   if(g_bollingerHandle != INVALID_HANDLE)
      IndicatorRelease(g_bollingerHandle);
   if(g_keltnerEmaHandle != INVALID_HANDLE)
      IndicatorRelease(g_keltnerEmaHandle);
   if(g_trendEmaHandle != INVALID_HANDLE)
      IndicatorRelease(g_trendEmaHandle);
   if(g_adxHandle != INVALID_HANDLE)
      IndicatorRelease(g_adxHandle);
   if(g_logHandle != INVALID_HANDLE)
      FileClose(g_logHandle);
}

void OnTick()
{
   RefreshDayState();
   datetime currentBar = iTime(_Symbol, InpSignalTimeframe, 0);
   if(currentBar <= 0 || currentBar == g_lastSignalBar)
      return;
   g_lastSignalBar = currentBar;
   double atr = 0.0;
   if(!BufferValue(g_atrHandle, 0, 1, atr) || atr <= 0.0)
      return;
   bool closed = ManagePositionOnBar(atr);
   if(closed)
      return;
   if(ManagedPositionCount() > 0)
      return;
   if(TryVolumeClimaxEntry(atr) || ManagedPositionCount() > 0)
      return;
   TryVolatilitySqueezeEntry(atr);
}

void OnTradeTransaction(const MqlTradeTransaction &transaction,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(transaction.type != TRADE_TRANSACTION_DEAL_ADD || !HistoryDealSelect(transaction.deal))
      return;
   if(HistoryDealGetString(transaction.deal, DEAL_SYMBOL) != _Symbol ||
      (ulong)HistoryDealGetInteger(transaction.deal, DEAL_MAGIC) != InpMagicNumber)
      return;
   long entryType = HistoryDealGetInteger(transaction.deal, DEAL_ENTRY);
   if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
      return;
   double profit = HistoryDealGetDouble(transaction.deal, DEAL_PROFIT) +
                   HistoryDealGetDouble(transaction.deal, DEAL_SWAP) +
                   HistoryDealGetDouble(transaction.deal, DEAL_COMMISSION);
   LogEvent("exit", transaction.deal, "close",
            HistoryDealGetDouble(transaction.deal, DEAL_VOLUME),
            HistoryDealGetDouble(transaction.deal, DEAL_PRICE), 0.0, profit,
            HistoryDealGetString(transaction.deal, DEAL_COMMENT));
}

double OnTester()
{
   double profit = TesterStatistics(STAT_PROFIT);
   double drawdown = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);
   double trades = TesterStatistics(STAT_TRADES);
   if(trades < 120.0)
      return profit - (120.0 - trades) * 1000.0;
   return profit * MathMax(0.0, MathMin(5.0, profitFactor)) / (1.0 + MathMax(0.0, drawdown));
}

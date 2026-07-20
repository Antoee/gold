#property strict
#property version   "1.00"
#property description "Date-independent XAUUSD D1 NR7 compression and H1 breakout research EA"

#include <Trade/Trade.mqh>

CTrade trade;

input group "Identity and Safety"
input string InpAllowedSymbol = "XAUUSD";
input ulong  InpMagicNumber = 26072031;
input bool   InpUseSymbolSafetyLock = true;
input bool   InpUseRealAccountSafetyLock = true;
input bool   InpAllowRealAccountTrading = false;
input string InpRealAccountApprovalCode = "DISABLED";

input group "Daily Narrow-Range Breakout Engine"
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_H1;
input int    InpNarrowRangeLookbackDays = 7;
input int    InpDailyATRPeriod = 20;
input double InpMaximumSetupRangeATR = 0.85;
input double InpBreakoutBufferATR = 0.05;
input double InpMinimumBodyPercent = 35.0;
input int    InpVolumeLookbackBars = 20;
input double InpMinimumVolumeRatio = 1.00;
input bool   InpAllowBuy = true;
input bool   InpAllowSell = true;
input bool   InpRequireFreshBreakout = true;

input group "Regime Filters"
input bool InpUseTrendEMAFilter = true;
input ENUM_TIMEFRAMES InpTrendTimeframe = PERIOD_D1;
input int  InpTrendEMAPeriod = 50;
input int  InpTrendEMASlopeBars = 3;
input bool InpUseADXFilter = false;
input ENUM_TIMEFRAMES InpADXTimeframe = PERIOD_H1;
input int  InpADXPeriod = 14;
input double InpMinimumADX = 16.0;
input bool InpUseVolatilityFilter = true;
input double InpMinimumATRPercent = 0.03;
input double InpMaximumATRPercent = 2.50;

input group "Stops and Position Management"
input int    InpATRPeriod = 20;
input int    InpStopLookbackBars = 12;
input double InpStopBufferATR = 0.10;
input double InpMinimumStopATR = 0.50;
input double InpMaximumStopATR = 2.50;
input double InpMaximumStopPriceDistance = 40.00;
input bool   InpUseFixedTakeProfit = true;
input double InpTakeProfitR = 3.00;
input bool   InpUseBreakEven = true;
input double InpBreakEvenTriggerR = 1.00;
input double InpBreakEvenLockR = 0.10;
input bool   InpUseChandelierTrail = true;
input int    InpChandelierLookbackBars = 24;
input double InpChandelierATR = 2.75;
input int    InpMaximumHoldBars = 120;

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
input int    InpMaximumTradesPerDay = 1;
input double InpMaximumDailyLossPercent = 0.75;
input double InpMaximumEquityDrawdownPercent = 5.00;
input int    InpMaximumConsecutiveLosses = 4;
input int    InpLossCooldownHours = 24;
input double InpMaximumSpreadPoints = 50.0;
input int    InpDeviationPoints = 20;
input bool   InpUseAccountWideExposureGuard = true;
input double InpAccountWideMaxOpenRiskPercent = 1.00;
input int    InpAccountWideMaxPositions = 3;
input bool   InpAccountWideBlockUnprotectedExposure = true;

input group "Evidence Logging"
input bool   InpLogTrades = false;
input string InpLogFileName = "Independent_XAUUSD_D1_NR7_H1_Breakout_Trades.csv";
input string InpEvidenceProfileId = "";
input string InpEvidenceSourceHash = "";
input string InpEvidenceRunLabel = "";

int g_atrHandle = INVALID_HANDLE;
int g_trendEmaHandle = INVALID_HANDLE;
int g_adxHandle = INVALID_HANDLE;
int g_logHandle = INVALID_HANDLE;
datetime g_dayStart = 0;
datetime g_lastSignalBar = 0;
datetime g_lastNarrowRangeSetupDay = 0;
double g_peakEquity = 0.0;
int g_entrySignals = 0;
int g_narrowRangeSetups = 0;
int g_candleRejects = 0;
int g_volumeRejects = 0;
int g_regimeRejects = 0;
int g_stopShapeRejects = 0;
int g_minimumLotRejects = 0;
int g_exposureRejects = 0;
int g_ordersOpened = 0;
int g_orderFailures = 0;

string RiskKey(const ulong ticket)
{
   return "IDNRB_RISK_" + IntegerToString((long)ticket);
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
       InpRealAccountApprovalCode != "DNRB-LIVE-ACK"))
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

double TickVolumeRatio(const int signalShift)
{
   long signalVolume = iVolume(_Symbol, InpSignalTimeframe, signalShift);
   if(signalVolume <= 0 || InpVolumeLookbackBars < 2)
      return 0.0;
   double total = 0.0;
   int count = 0;
   for(int shift = signalShift + 1; shift <= signalShift + InpVolumeLookbackBars; ++shift)
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

double DailyTrueRange(const int shift)
{
   double high = iHigh(_Symbol, PERIOD_D1, shift);
   double low = iLow(_Symbol, PERIOD_D1, shift);
   double previousClose = iClose(_Symbol, PERIOD_D1, shift + 1);
   if(high <= 0.0 || low <= 0.0 || previousClose <= 0.0 || high <= low)
      return 0.0;
   return MathMax(high - low,
                  MathMax(MathAbs(high - previousClose),
                          MathAbs(low - previousClose)));
}

bool NarrowRangeContext(double &setupHigh,
                        double &setupLow,
                        double &setupRangeATR)
{
   setupHigh = iHigh(_Symbol, PERIOD_D1, 1);
   setupLow = iLow(_Symbol, PERIOD_D1, 1);
   double setupRange = setupHigh - setupLow;
   if(setupLow <= 0.0 || setupRange <= 0.0)
      return false;

   int atrPeriod = MathMax(2, InpDailyATRPeriod);
   double trueRangeTotal = 0.0;
   int trueRangeCount = 0;
   for(int shift = 2; shift < 2 + atrPeriod; ++shift)
   {
      double trueRange = DailyTrueRange(shift);
      if(trueRange <= 0.0)
         return false;
      trueRangeTotal += trueRange;
      trueRangeCount++;
   }
   if(trueRangeCount != atrPeriod || trueRangeTotal <= 0.0)
      return false;

   double dailyATR = trueRangeTotal / trueRangeCount;
   setupRangeATR = setupRange / dailyATR;
   if(setupRangeATR > InpMaximumSetupRangeATR)
      return false;

   int lookback = MathMax(3, InpNarrowRangeLookbackDays);
   for(int shift = 2; shift <= lookback; ++shift)
   {
      double priorRange = iHigh(_Symbol, PERIOD_D1, shift) -
                          iLow(_Symbol, PERIOD_D1, shift);
      if(priorRange <= 0.0 || setupRange > priorRange)
         return false;
   }
   return true;
}

bool RegimeAllows(const bool buy, const double closePrice, const double atr)
{
   if(closePrice <= 0.0 || atr <= 0.0)
      return false;
   if(InpUseVolatilityFilter)
   {
      double atrPercent = 100.0 * atr / closePrice;
      if(atrPercent < InpMinimumATRPercent || atrPercent > InpMaximumATRPercent)
         return false;
   }
   if(InpUseTrendEMAFilter)
   {
      double emaNow = 0.0;
      double emaPast = 0.0;
      if(!BufferValue(g_trendEmaHandle, 0, 1, emaNow) ||
         !BufferValue(g_trendEmaHandle, 0, 1 + MathMax(1, InpTrendEMASlopeBars), emaPast))
         return false;
      if(buy && (closePrice <= emaNow || emaNow <= emaPast))
         return false;
      if(!buy && (closePrice >= emaNow || emaNow >= emaPast))
         return false;
   }
   if(InpUseADXFilter)
   {
      double adx = 0.0;
      if(!BufferValue(g_adxHandle, 0, 1, adx) || adx < InpMinimumADX)
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

bool StructureStop(const bool buy,
                   const double entryPrice,
                   const double atr,
                   double &stopPrice,
                   double &stopDistance)
{
   double structureHigh = 0.0;
   double structureLow = 0.0;
   if(entryPrice <= 0.0 || atr <= 0.0 ||
      !ChannelBounds(1, InpStopLookbackBars, structureHigh, structureLow))
      return false;
   double rawStop = buy ? structureLow - InpStopBufferATR * atr
                        : structureHigh + InpStopBufferATR * atr;
   stopDistance = buy ? entryPrice - rawStop : rawStop - entryPrice;
   double minimumDistance = MathMax(InpMinimumStopATR * atr,
                                    (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point + _Point);
   if(stopDistance < minimumDistance)
      stopDistance = minimumDistance;
   double atrUnits = stopDistance / atr;
   if(atrUnits > InpMaximumStopATR ||
      (InpMaximumStopPriceDistance > 0.0 && stopDistance > InpMaximumStopPriceDistance))
      return false;
   stopPrice = NormalizeDouble(buy ? entryPrice - stopDistance : entryPrice + stopDistance, _Digits);
   return stopPrice > 0.0;
}

bool OpenNarrowRangePosition(const bool buy, const double atr)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || atr <= 0.0)
      return false;
   double entryPrice = buy ? tick.ask : tick.bid;
   double stopPrice = 0.0;
   double stopDistance = 0.0;
   if(!StructureStop(buy, entryPrice, atr, stopPrice, stopDistance))
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
   if(InpUseFixedTakeProfit && InpTakeProfitR > 0.0)
      takeProfit = NormalizeDouble(buy ? entryPrice + InpTakeProfitR * stopDistance
                                       : entryPrice - InpTakeProfitR * stopDistance, _Digits);
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   string comment = buy ? "DNRB_BUY" : "DNRB_SELL";
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
            "fresh H1 break of completed D1 narrow-range setup");
   return true;
}

bool TryTimedExit(const ulong ticket)
{
   if(InpMaximumHoldBars > 0)
   {
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int openShift = iBarShift(_Symbol, InpSignalTimeframe, openTime, false);
      if(openShift >= InpMaximumHoldBars)
         return trade.PositionClose(ticket);
   }
   return false;
}

void ImproveProtectiveStop(const ulong ticket, const bool buy, const double atr)
{
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
   if(InpUseBreakEven && r >= InpBreakEvenTriggerR)
   {
      double breakEven = buy ? openPrice + InpBreakEvenLockR * initialRisk
                             : openPrice - InpBreakEvenLockR * initialRisk;
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
      if(TryTimedExit(ticket))
      {
         closed = true;
         continue;
      }
      if(PositionSelectByTicket(ticket))
         ImproveProtectiveStop(ticket, buy, atr);
   }
   return closed;
}

void TryEntry(const double atr)
{
   string safetyReason = "";
   if(!SafetyAllows(safetyReason))
      return;
   double setupHigh = 0.0;
   double setupLow = 0.0;
   double setupRangeATR = 0.0;
   if(!NarrowRangeContext(setupHigh, setupLow, setupRangeATR))
      return;
   if(g_lastNarrowRangeSetupDay != g_dayStart)
   {
      g_lastNarrowRangeSetupDay = g_dayStart;
      g_narrowRangeSetups++;
   }
   double close1 = iClose(_Symbol, InpSignalTimeframe, 1);
   double close2 = iClose(_Symbol, InpSignalTimeframe, 2);
   if(close1 <= 0.0 || close2 <= 0.0)
      return;
   double buffer = InpBreakoutBufferATR * atr;
   bool buyBreak = InpAllowBuy && close1 > setupHigh + buffer;
   bool sellBreak = InpAllowSell && close1 < setupLow - buffer;
   if(InpRequireFreshBreakout)
   {
      buyBreak = buyBreak && close2 <= setupHigh + buffer;
      sellBreak = sellBreak && close2 >= setupLow - buffer;
   }
   if(!buyBreak && !sellBreak)
      return;
   if(CandleBodyPercent(1) < InpMinimumBodyPercent)
   {
      g_candleRejects++;
      return;
   }
   double volumeRatio = TickVolumeRatio(1);
   if(InpMinimumVolumeRatio > 0.0 && volumeRatio < InpMinimumVolumeRatio)
   {
      g_volumeRejects++;
      return;
   }
   if(buyBreak)
   {
      if(!RegimeAllows(true, close1, atr))
      {
         g_regimeRejects++;
         return;
      }
      g_entrySignals++;
      OpenNarrowRangePosition(true, atr);
   }
   else if(sellBreak)
   {
      if(!RegimeAllows(false, close1, atr))
      {
         g_regimeRejects++;
         return;
      }
      g_entrySignals++;
      OpenNarrowRangePosition(false, atr);
   }
}

int OnInit()
{
   if(InpNarrowRangeLookbackDays < 3 ||
      InpNarrowRangeLookbackDays > 20 ||
      InpDailyATRPeriod < 2 ||
      InpMaximumSetupRangeATR <= 0.0 ||
      InpMaximumSetupRangeATR > 2.0 ||
      InpBreakoutBufferATR < 0.0 ||
      InpMinimumBodyPercent < 0.0 || InpMinimumBodyPercent > 100.0 ||
      InpVolumeLookbackBars < 2 || InpMinimumVolumeRatio < 0.0 ||
      InpATRPeriod < 2 || InpStopLookbackBars < 1 || InpStopBufferATR < 0.0 ||
      InpMinimumStopATR <= 0.0 || InpMaximumStopATR < InpMinimumStopATR ||
      (InpUseFixedTakeProfit && InpTakeProfitR <= 0.0) ||
      InpRiskPercent <= 0.0 || InpRiskPercent > 2.0 ||
      InpSessionStartHour < 0 || InpSessionStartHour > 23 ||
      InpSessionEndHour < 0 || InpSessionEndHour > 23 ||
      InpFridayCutoffHour < 0 || InpFridayCutoffHour > 23 ||
      InpMaximumSimultaneousPositions < 1 ||
      InpAccountWideMaxPositions < 1)
      return INIT_PARAMETERS_INCORRECT;
   g_atrHandle = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);
   g_trendEmaHandle = iMA(_Symbol, InpTrendTimeframe, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_adxHandle = iADX(_Symbol, InpADXTimeframe, InpADXPeriod);
   if(g_atrHandle == INVALID_HANDLE || g_trendEmaHandle == INVALID_HANDLE || g_adxHandle == INVALID_HANDLE)
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
   PrintFormat("DNRB_DIAGNOSTIC narrow_range_setups=%d signals=%d candle_rejects=%d volume_rejects=%d regime_rejects=%d opened=%d stop_shape_rejects=%d minimum_lot_rejects=%d exposure_rejects=%d order_failures=%d",
               g_narrowRangeSetups, g_entrySignals, g_candleRejects, g_volumeRejects,
               g_regimeRejects, g_ordersOpened, g_stopShapeRejects, g_minimumLotRejects,
               g_exposureRejects, g_orderFailures);
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
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
   if(!closed && ManagedPositionCount() == 0)
      TryEntry(atr);
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
   if(trades < 60.0)
      return profit - (60.0 - trades) * 1000.0;
   return profit * MathMax(0.0, MathMin(5.0, profitFactor)) / (1.0 + MathMax(0.0, drawdown));
}




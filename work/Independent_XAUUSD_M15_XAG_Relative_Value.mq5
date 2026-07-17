#property strict
#property version   "1.00"
#property description "Date-independent XAUUSD M15 XAGUSD relative-value reversion research EA"

#include <Trade/Trade.mqh>

CTrade trade;

input group "Identity and Safety"
input string InpAllowedSymbol = "XAUUSD";
input string InpReferenceSymbol = "XAGUSD";
input ulong  InpMagicNumber = 26071751;
input bool   InpUseSymbolSafetyLock = true;
input bool   InpUseRealAccountSafetyLock = true;
input bool   InpAllowRealAccountTrading = false;
input string InpRealAccountApprovalCode = "DISABLED";

input group "Cross-Metal Signal"
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_M15;
input int    InpMoveLookbackBars = 16;
input int    InpCorrelationLookbackBars = 32;
input double InpMinimumCorrelation = 0.35;
input double InpDivergenceThresholdATR = 1.00;
input bool   InpRequireDivergenceTurn = true;
input double InpMinimumDivergenceTurnATR = 0.05;
input bool   InpRequireXAUStretchDirection = true;
input double InpMinimumXAUMoveATR = 0.25;
input bool   InpRequireDirectionCandle = true;
input double InpMinimumSignalBodyPercent = 25.0;
input double InpMinimumSignalCloseLocation = 0.60;
input int    InpMaximumAlignmentSeconds = 900;
input bool   InpAllowBuy = true;
input bool   InpAllowSell = true;

input group "Volatility, Stops, and Exits"
input int    InpATRPeriod = 20;
input bool   InpUseVolatilityFilter = true;
input double InpMinimumATRPercent = 0.03;
input double InpMaximumATRPercent = 2.50;
input int    InpStopLookbackBars = 8;
input double InpStopBufferATR = 0.15;
input double InpMinimumStopATR = 0.50;
input double InpMaximumStopATR = 2.50;
input double InpMaximumStopPriceDistance = 10.00;
input double InpTakeProfitR = 1.50;
input bool   InpUseBreakEven = true;
input double InpBreakEvenTriggerR = 0.80;
input double InpBreakEvenLockR = 0.05;
input int    InpMaximumHoldBars = 24;
input bool   InpCloseBeforeWeekend = true;
input int    InpFridayPositionCloseHour = 20;

input group "Trading Session"
input bool InpUseSessionFilter = true;
input int  InpSessionStartHour = 6;
input int  InpSessionEndHour = 20;
input bool InpDisableFridayAfterHour = true;
input int  InpFridayEntryCutoffHour = 18;

input group "Risk Manager"
input double InpRiskPercent = 0.10;
input double InpMaximumPositionLots = 1.00;
input int    InpMaximumSimultaneousPositions = 1;
input int    InpMaximumTradesPerDay = 3;
input double InpMaximumDailyLossPercent = 0.75;
input double InpMaximumEquityDrawdownPercent = 5.00;
input int    InpMaximumConsecutiveLosses = 4;
input int    InpLossCooldownHours = 12;
input double InpMaximumSpreadPoints = 50.0;
input int    InpDeviationPoints = 20;
input bool   InpUseAccountWideExposureGuard = true;
input double InpAccountWideMaxOpenRiskPercent = 3.00;
input int    InpAccountWideMaxPositions = 3;
input bool   InpAccountWideBlockUnprotectedExposure = true;

input group "Evidence Logging"
input bool   InpLogTrades = false;
input string InpLogFileName = "Independent_XAUUSD_M15_XAG_Relative_Value_Trades.csv";
input string InpEvidenceProfileId = "";
input string InpEvidenceSourceHash = "";
input string InpEvidenceRunLabel = "";

struct CrossMetalFeatures
{
   datetime signalTime;
   double xauAtr;
   double xagAtr;
   double xauMoveAtr;
   double xagMoveAtr;
   double divergenceAtr;
   double priorDivergenceAtr;
   double correlation;
   double bodyPercent;
   double buyCloseLocation;
   double sellCloseLocation;
   bool bullishCandle;
   bool bearishCandle;
   double recentLow;
   double recentHigh;
};

int      g_logHandle = INVALID_HANDLE;
datetime g_dayStart = 0;
datetime g_lastSignalBar = 0;
double   g_peakEquity = 0.0;
int      g_featureBars = 0;
int      g_featureFailures = 0;
int      g_alignmentFailures = 0;
int      g_divergenceCandidates = 0;
int      g_correlationRejects = 0;
int      g_turnRejects = 0;
int      g_candleRejects = 0;
int      g_safetyRejects = 0;
int      g_stopShapeRejects = 0;
int      g_minimumLotRejects = 0;
int      g_exposureRejects = 0;
int      g_ordersOpened = 0;
int      g_orderFailures = 0;

string RiskKey(const ulong ticket)
{
   return "IM15XMRV_RISK_" + IntegerToString((long)ticket);
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
   if(InpDisableFridayAfterHour && now.day_of_week == 5 && now.hour >= InpFridayEntryCutoffHour)
      return false;
   if(!InpUseSessionFilter || InpSessionStartHour == InpSessionEndHour)
      return true;
   if(InpSessionStartHour < InpSessionEndHour)
      return now.hour >= InpSessionStartHour && now.hour < InpSessionEndHour;
   return now.hour >= InpSessionStartHour || now.hour < InpSessionEndHour;
}

void LogEvent(const string eventName,
              const ulong ticket,
              const string side,
              const double volume,
              const double price,
              const double sl,
              const double profit,
              const string reason,
              const double divergence,
              const double correlation)
{
   if(!InpLogTrades || g_logHandle == INVALID_HANDLE)
      return;
   FileWrite(g_logHandle,
             TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
             eventName,
             _Symbol,
             InpReferenceSymbol,
             (string)ticket,
             side,
             DoubleToString(volume, 2),
             DoubleToString(price, _Digits),
             DoubleToString(sl, _Digits),
             DoubleToString(profit, 2),
             reason,
             DoubleToString(divergence, 4),
             DoubleToString(correlation, 4),
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
       InpRealAccountApprovalCode != "XMRV-LIVE-ACK"))
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

bool CopyReferenceRate(const datetime xauTime, MqlRates &referenceRate)
{
   int shift = iBarShift(InpReferenceSymbol, InpSignalTimeframe, xauTime, false);
   if(shift < 0)
      return false;
   MqlRates one[];
   ArraySetAsSeries(one, true);
   if(CopyRates(InpReferenceSymbol, InpSignalTimeframe, shift, 1, one) != 1)
      return false;
   long alignment = (long)MathAbs((double)(xauTime - one[0].time));
   if(one[0].time <= 0 || one[0].close <= 0.0 || alignment > InpMaximumAlignmentSeconds)
      return false;
   referenceRate = one[0];
   return true;
}

bool LoadAlignedRates(const int count, MqlRates &xauRates[], MqlRates &xagRates[])
{
   ArrayResize(xauRates, count);
   ArraySetAsSeries(xauRates, true);
   if(CopyRates(_Symbol, InpSignalTimeframe, 1, count, xauRates) != count)
      return false;
   ArrayResize(xagRates, count);
   ArraySetAsSeries(xagRates, true);
   for(int i = 0; i < count; ++i)
   {
      if(!CopyReferenceRate(xauRates[i].time, xagRates[i]))
      {
         g_alignmentFailures++;
         return false;
      }
   }
   return true;
}

double AverageTrueRange(const MqlRates &rates[], const int period, const int offset)
{
   if(period < 1 || offset < 0 || ArraySize(rates) < offset + period + 1)
      return 0.0;
   double total = 0.0;
   for(int i = offset; i < offset + period; ++i)
   {
      double priorClose = rates[i + 1].close;
      double trueRange = MathMax(rates[i].high - rates[i].low,
                                 MathMax(MathAbs(rates[i].high - priorClose),
                                         MathAbs(rates[i].low - priorClose)));
      total += trueRange;
   }
   return total / period;
}

double PearsonCorrelation(const MqlRates &xauRates[],
                          const MqlRates &xagRates[],
                          const int lookback,
                          const int offset)
{
   if(lookback < 3 || ArraySize(xauRates) < offset + lookback + 1 ||
      ArraySize(xagRates) < offset + lookback + 1)
      return -2.0;
   double sumX = 0.0;
   double sumY = 0.0;
   double sumXX = 0.0;
   double sumYY = 0.0;
   double sumXY = 0.0;
   for(int i = offset; i < offset + lookback; ++i)
   {
      if(xauRates[i + 1].close <= 0.0 || xagRates[i + 1].close <= 0.0)
         return -2.0;
      double x = (xauRates[i].close - xauRates[i + 1].close) / xauRates[i + 1].close;
      double y = (xagRates[i].close - xagRates[i + 1].close) / xagRates[i + 1].close;
      sumX += x;
      sumY += y;
      sumXX += x * x;
      sumYY += y * y;
      sumXY += x * y;
   }
   double n = (double)lookback;
   double covariance = n * sumXY - sumX * sumY;
   double varianceX = n * sumXX - sumX * sumX;
   double varianceY = n * sumYY - sumY * sumY;
   if(varianceX <= 0.0 || varianceY <= 0.0)
      return -2.0;
   return covariance / MathSqrt(varianceX * varianceY);
}

bool BuildFeatures(CrossMetalFeatures &features)
{
   int required = InpMoveLookbackBars + 2;
   if(InpCorrelationLookbackBars + 2 > required)
      required = InpCorrelationLookbackBars + 2;
   if(InpATRPeriod + 2 > required)
      required = InpATRPeriod + 2;
   if(InpStopLookbackBars + 1 > required)
      required = InpStopLookbackBars + 1;

   MqlRates xauRates[];
   MqlRates xagRates[];
   if(!LoadAlignedRates(required, xauRates, xagRates))
      return false;

   features.xauAtr = AverageTrueRange(xauRates, InpATRPeriod, 0);
   features.xagAtr = AverageTrueRange(xagRates, InpATRPeriod, 0);
   double priorXauAtr = AverageTrueRange(xauRates, InpATRPeriod, 1);
   double priorXagAtr = AverageTrueRange(xagRates, InpATRPeriod, 1);
   if(features.xauAtr <= 0.0 || features.xagAtr <= 0.0 || priorXauAtr <= 0.0 || priorXagAtr <= 0.0)
      return false;

   features.signalTime = xauRates[0].time;
   features.xauMoveAtr = (xauRates[0].close - xauRates[InpMoveLookbackBars].close) / features.xauAtr;
   features.xagMoveAtr = (xagRates[0].close - xagRates[InpMoveLookbackBars].close) / features.xagAtr;
   features.divergenceAtr = features.xauMoveAtr - features.xagMoveAtr;
   double priorXauMove = (xauRates[1].close - xauRates[InpMoveLookbackBars + 1].close) / priorXauAtr;
   double priorXagMove = (xagRates[1].close - xagRates[InpMoveLookbackBars + 1].close) / priorXagAtr;
   features.priorDivergenceAtr = priorXauMove - priorXagMove;
   features.correlation = PearsonCorrelation(xauRates, xagRates, InpCorrelationLookbackBars, 0);

   double range = xauRates[0].high - xauRates[0].low;
   if(range <= 0.0)
      return false;
   features.bodyPercent = 100.0 * MathAbs(xauRates[0].close - xauRates[0].open) / range;
   features.buyCloseLocation = (xauRates[0].close - xauRates[0].low) / range;
   features.sellCloseLocation = (xauRates[0].high - xauRates[0].close) / range;
   features.bullishCandle = xauRates[0].close > xauRates[0].open;
   features.bearishCandle = xauRates[0].close < xauRates[0].open;
   features.recentLow = DBL_MAX;
   features.recentHigh = -DBL_MAX;
   for(int i = 0; i < InpStopLookbackBars; ++i)
   {
      features.recentLow = MathMin(features.recentLow, xauRates[i].low);
      features.recentHigh = MathMax(features.recentHigh, xauRates[i].high);
   }
   return features.recentLow > 0.0 && features.recentHigh > features.recentLow;
}

bool FinalizeStructureStop(const bool buy,
                           const double entryPrice,
                           const double rawStop,
                           const double atr,
                           double &stopPrice,
                           double &stopDistance)
{
   if(entryPrice <= 0.0 || rawStop <= 0.0 || atr <= 0.0)
      return false;
   stopDistance = buy ? entryPrice - rawStop : rawStop - entryPrice;
   if(stopDistance <= 0.0)
      return false;
   double brokerMinimum = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point + _Point;
   double minimumDistance = MathMax(InpMinimumStopATR * atr, brokerMinimum);
   if(stopDistance < minimumDistance)
      stopDistance = minimumDistance;
   if(stopDistance / atr > InpMaximumStopATR ||
      (InpMaximumStopPriceDistance > 0.0 && stopDistance > InpMaximumStopPriceDistance))
      return false;
   stopPrice = NormalizeDouble(buy ? entryPrice - stopDistance : entryPrice + stopDistance, _Digits);
   return stopPrice > 0.0;
}

bool OpenRelativeValuePosition(const bool buy, const CrossMetalFeatures &features)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || features.xauAtr <= 0.0)
      return false;
   double entryPrice = buy ? tick.ask : tick.bid;
   double rawStop = buy ? features.recentLow - InpStopBufferATR * features.xauAtr
                        : features.recentHigh + InpStopBufferATR * features.xauAtr;
   double stopPrice = 0.0;
   double stopDistance = 0.0;
   if(!FinalizeStructureStop(buy, entryPrice, rawStop, features.xauAtr, stopPrice, stopDistance))
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
   double takeProfit = NormalizeDouble(buy ? entryPrice + InpTakeProfitR * stopDistance
                                            : entryPrice - InpTakeProfitR * stopDistance,
                                       _Digits);
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   string comment = buy ? "M15XMRV_BUY" : "M15XMRV_SELL";
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
            "cross-metal relative-value reversal", features.divergenceAtr, features.correlation);
   return true;
}

bool WeekendCloseRequired()
{
   if(!InpCloseBeforeWeekend)
      return false;
   MqlDateTime now;
   if(!TimeToStruct(TimeCurrent(), now))
      return false;
   return now.day_of_week == 5 && now.hour >= InpFridayPositionCloseHour;
}

bool TryManagedExit(const ulong ticket)
{
   if(WeekendCloseRequired())
      return trade.PositionClose(ticket);
   if(InpMaximumHoldBars > 0)
   {
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int openShift = iBarShift(_Symbol, InpSignalTimeframe, openTime, false);
      if(openShift >= InpMaximumHoldBars)
         return trade.PositionClose(ticket);
   }
   return false;
}

void ImproveProtectiveStop(const ulong ticket, const bool buy)
{
   if(!InpUseBreakEven)
      return;
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double oldSl = PositionGetDouble(POSITION_SL);
   double current = buy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double initialRisk = GlobalVariableCheck(RiskKey(ticket)) ? GlobalVariableGet(RiskKey(ticket))
                                                            : MathAbs(openPrice - oldSl);
   if(initialRisk <= 0.0 || current <= 0.0)
      return;
   double favorable = buy ? current - openPrice : openPrice - current;
   if(favorable / initialRisk < InpBreakEvenTriggerR)
      return;
   double newSl = NormalizeDouble(buy ? openPrice + InpBreakEvenLockR * initialRisk
                                      : openPrice - InpBreakEvenLockR * initialRisk,
                                  _Digits);
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

bool ManagePositionOnBar()
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
      if(TryManagedExit(ticket))
      {
         closed = true;
         continue;
      }
      if(PositionSelectByTicket(ticket))
         ImproveProtectiveStop(ticket, buy);
   }
   return closed;
}

bool TryRelativeValueEntry()
{
   string safetyReason = "";
   if(!SafetyAllows(safetyReason))
   {
      g_safetyRejects++;
      return false;
   }

   CrossMetalFeatures features;
   if(!BuildFeatures(features))
   {
      g_featureFailures++;
      return false;
   }
   g_featureBars++;
   double atrPercent = 100.0 * features.xauAtr / iClose(_Symbol, InpSignalTimeframe, 1);
   if(InpUseVolatilityFilter &&
      (atrPercent < InpMinimumATRPercent || atrPercent > InpMaximumATRPercent))
      return false;
   if(features.correlation < InpMinimumCorrelation)
   {
      g_correlationRejects++;
      return false;
   }

   bool buy = InpAllowBuy && features.divergenceAtr <= -InpDivergenceThresholdATR;
   bool sell = InpAllowSell && features.divergenceAtr >= InpDivergenceThresholdATR;
   if(InpRequireXAUStretchDirection)
   {
      buy = buy && features.xauMoveAtr <= -InpMinimumXAUMoveATR;
      sell = sell && features.xauMoveAtr >= InpMinimumXAUMoveATR;
   }
   if(!buy && !sell)
      return false;
   g_divergenceCandidates++;

   if(InpRequireDivergenceTurn)
   {
      bool buyTurn = features.divergenceAtr - features.priorDivergenceAtr >= InpMinimumDivergenceTurnATR;
      bool sellTurn = features.priorDivergenceAtr - features.divergenceAtr >= InpMinimumDivergenceTurnATR;
      buy = buy && buyTurn;
      sell = sell && sellTurn;
      if(!buy && !sell)
      {
         g_turnRejects++;
         return false;
      }
   }

   if(InpRequireDirectionCandle)
   {
      buy = buy && features.bullishCandle;
      sell = sell && features.bearishCandle;
   }
   buy = buy && features.bodyPercent >= InpMinimumSignalBodyPercent &&
         features.buyCloseLocation >= InpMinimumSignalCloseLocation;
   sell = sell && features.bodyPercent >= InpMinimumSignalBodyPercent &&
          features.sellCloseLocation >= InpMinimumSignalCloseLocation;
   if(buy == sell)
   {
      g_candleRejects++;
      return false;
   }
   return OpenRelativeValuePosition(buy, features);
}

int OnInit()
{
   if(StringLen(InpReferenceSymbol) <= 0 || InpMoveLookbackBars < 2 ||
      InpCorrelationLookbackBars < 3 || InpMinimumCorrelation < -1.0 || InpMinimumCorrelation > 1.0 ||
      InpDivergenceThresholdATR <= 0.0 || InpMinimumDivergenceTurnATR < 0.0 ||
      InpMinimumXAUMoveATR < 0.0 || InpMinimumSignalBodyPercent < 0.0 ||
      InpMinimumSignalBodyPercent > 100.0 || InpMinimumSignalCloseLocation < 0.5 ||
      InpMinimumSignalCloseLocation > 1.0 || InpMaximumAlignmentSeconds < 0 ||
      InpATRPeriod < 2 || InpMinimumATRPercent < 0.0 ||
      InpMaximumATRPercent <= InpMinimumATRPercent || InpStopLookbackBars < 2 ||
      InpStopBufferATR < 0.0 || InpMinimumStopATR <= 0.0 ||
      InpMaximumStopATR < InpMinimumStopATR || InpTakeProfitR <= 0.0 ||
      InpBreakEvenTriggerR <= 0.0 || InpBreakEvenLockR < 0.0 ||
      InpSessionStartHour < 0 || InpSessionStartHour > 23 ||
      InpSessionEndHour < 0 || InpSessionEndHour > 23 ||
      InpFridayEntryCutoffHour < 0 || InpFridayEntryCutoffHour > 23 ||
      InpFridayPositionCloseHour < 0 || InpFridayPositionCloseHour > 23 ||
      InpRiskPercent <= 0.0 || InpRiskPercent > 2.0 ||
      InpMaximumSimultaneousPositions < 1 || InpAccountWideMaxPositions < 1)
      return INIT_PARAMETERS_INCORRECT;
   if(InpUseSymbolSafetyLock && _Symbol != InpAllowedSymbol)
      return INIT_FAILED;
   ENUM_ACCOUNT_TRADE_MODE mode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(!MQLInfoInteger(MQL_TESTER) && mode == ACCOUNT_TRADE_MODE_REAL &&
      (InpUseRealAccountSafetyLock || !InpAllowRealAccountTrading ||
       InpRealAccountApprovalCode != "XMRV-LIVE-ACK"))
      return INIT_FAILED;
   if(!SymbolSelect(InpReferenceSymbol, true))
      return INIT_FAILED;
   iClose(InpReferenceSymbol, InpSignalTimeframe, 1);
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   RefreshDayState();
   if(InpLogTrades)
   {
      g_logHandle = FileOpen(InpLogFileName,
                             FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_SHARE_READ | FILE_SHARE_WRITE);
      if(g_logHandle != INVALID_HANDLE)
      {
         if(FileSize(g_logHandle) == 0)
            FileWrite(g_logHandle, "time", "event", "symbol", "reference_symbol", "ticket", "side",
                      "volume", "price", "sl", "profit", "reason", "divergence_atr", "correlation",
                      "profile_id", "source_hash", "run_label");
         FileSeek(g_logHandle, 0, SEEK_END);
      }
   }
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   PrintFormat("M15XMRV_DIAGNOSTIC feature_bars=%d feature_failures=%d alignment_failures=%d divergence_candidates=%d correlation_rejects=%d turn_rejects=%d candle_rejects=%d safety_rejects=%d opened=%d stop_shape_rejects=%d minimum_lot_rejects=%d exposure_rejects=%d order_failures=%d",
               g_featureBars, g_featureFailures, g_alignmentFailures, g_divergenceCandidates,
               g_correlationRejects, g_turnRejects, g_candleRejects, g_safetyRejects,
               g_ordersOpened, g_stopShapeRejects, g_minimumLotRejects, g_exposureRejects,
               g_orderFailures);
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
   bool closed = ManagePositionOnBar();
   if(closed || ManagedPositionCount() > 0)
      return;
   TryRelativeValueEntry();
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
   LogEvent("exit", transaction.deal, "close", HistoryDealGetDouble(transaction.deal, DEAL_VOLUME),
            HistoryDealGetDouble(transaction.deal, DEAL_PRICE), 0.0, profit,
            HistoryDealGetString(transaction.deal, DEAL_COMMENT), 0.0, 0.0);
}

double OnTester()
{
   double profit = TesterStatistics(STAT_PROFIT);
   double drawdown = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);
   double trades = TesterStatistics(STAT_TRADES);
   if(trades < 100.0)
      return profit - (100.0 - trades) * 1000.0;
   return profit * MathMax(0.0, MathMin(5.0, profitFactor)) / (1.0 + MathMax(0.0, drawdown));
}

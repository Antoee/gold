#property strict
#property version   "1.00"
#property description "Date-independent XAUUSD M15 EURUSD/USDJPY consensus lead-lag research EA"

#include <Trade/Trade.mqh>

CTrade trade;

input group "Identity and Safety"
input string InpAllowedSymbol = "XAUUSD";
input string InpEURUSDSymbol = "EURUSD";
input string InpUSDJPYSymbol = "USDJPY";
input ulong  InpMagicNumber = 26072011;
input bool   InpUseSymbolSafetyLock = true;
input bool   InpUseRealAccountSafetyLock = true;
input bool   InpAllowRealAccountTrading = false;
input string InpRealAccountApprovalCode = "DISABLED";
input bool   InpEnforceInitialBalanceContract = true;
input double InpExpectedInitialBalance = 10000.0;
input double InpInitialBalanceTolerance = 1.0;
input bool   InpEnforceAccountCurrency = true;
input string InpExpectedAccountCurrency = "USD";

input group "USD Consensus Lead-Lag Signal"
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_M15;
input ENUM_TIMEFRAMES InpProxyTimeframe = PERIOD_H1;
input int    InpProxyLookbackBars = 4;
input int    InpProxyATRPeriod = 14;
input int    InpMaximumAlignmentSeconds = 3600;
input double InpMinimumProxyComponentATR = 0.10;
input double InpMinimumConsensusATR = 0.25;
input double InpMinimumAlignedGoldMoveATR = -0.25;
input double InpMaximumGoldExtensionATR = 0.35;
input int    InpBreakoutLookbackBars = 4;
input double InpBreakoutBufferATR = 0.05;
input double InpMinimumSignalBodyPercent = 30.0;
input bool   InpRequireFreshBreakout = true;
input bool   InpAllowBuy = true;
input bool   InpAllowSell = true;

input group "Stops and Position Management"
input int    InpATRPeriod = 20;
input int    InpStopLookbackBars = 6;
input double InpStopBufferATR = 0.15;
input double InpMinimumStopATR = 0.50;
input double InpMaximumStopATR = 2.50;
input double InpMaximumStopPriceDistance = 8.00;
input double InpTakeProfitR = 1.75;
input int    InpMaximumHoldBars = 32;
input int    InpExitHour = 20;
input bool   InpUseBreakEven = true;
input double InpBreakEvenTriggerR = 1.00;
input double InpBreakEvenLockR = 0.05;

input group "Trading Session"
input int  InpSessionStartHour = 6;
input int  InpSessionEndHour = 18;
input bool InpDisableFridayAfterHour = true;
input int  InpFridayEntryCutoffHour = 16;

input group "Risk Manager"
input double InpRiskPercent = 0.10;
input double InpMaximumPositionLots = 1.00;
input double InpMaximumDailyLossPercent = 0.75;
input double InpMaximumEquityDrawdownPercent = 5.00;
input int    InpMaximumConsecutiveLosses = 3;
input int    InpLossCooldownHours = 24;
input double InpMaximumSpreadPoints = 50.0;
input int    InpDeviationPoints = 20;
input bool   InpRequireEmptyAccountAtEntry = true;
input double InpAccountWideMaxOpenRiskPercent = 1.00;
input bool   InpAccountWideBlockUnprotectedExposure = true;

input group "Evidence Logging"
input bool   InpLogTrades = false;
input string InpLogFileName = "Independent_XAUUSD_M15_USD_Consensus_Lead_Lag_Trades.csv";
input string InpEvidenceProfileId = "";
input string InpEvidenceSourceHash = "";
input string InpEvidenceRunLabel = "";

int g_atrHandle = INVALID_HANDLE;
int g_logHandle = INVALID_HANDLE;
datetime g_dayStart = 0;
datetime g_lastSignalBar = 0;
double g_peakEquity = 0.0;
int g_proxyContexts = 0;
int g_alignmentRejects = 0;
int g_consensusCandidates = 0;
int g_goldLagRejects = 0;
int g_breakoutRejects = 0;
int g_geometryRejects = 0;
int g_safetyRejects = 0;
int g_minimumLotRejects = 0;
int g_ordersOpened = 0;
int g_orderFailures = 0;

string RiskKey(const ulong ticket)
{
   return "IM15USDCLL_RISK_" + IntegerToString((long)ticket);
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

double SpreadPoints()
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return DBL_MAX;
   return (tick.ask - tick.bid) / _Point;
}

void LogEvent(const string eventName,
              const ulong ticket,
              const string side,
              const double volume,
              const double price,
              const double sl,
              const double tp,
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
             DoubleToString(tp, _Digits),
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
   if(!HistorySelect(fromTime, TimeCurrent()))
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
   if(!HistorySelect(fromTime, TimeCurrent()))
      return 0;
   int entries = 0;
   for(int i = 0; i < HistoryDealsTotal(); ++i)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol)
         continue;
      if((ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber)
         continue;
      long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entryType == DEAL_ENTRY_IN || entryType == DEAL_ENTRY_INOUT)
         entries++;
   }
   return entries;
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

bool AccountContractAllows(string &reason)
{
   if(InpEnforceAccountCurrency && !MQLInfoInteger(MQL_TESTER) &&
      AccountInfoString(ACCOUNT_CURRENCY) != InpExpectedAccountCurrency)
   {
      reason = "account currency contract";
      return false;
   }
   if(InpEnforceInitialBalanceContract)
   {
      double initialBalance = AccountInfoDouble(ACCOUNT_BALANCE) - ClosedProfitSince(0);
      if(MathAbs(initialBalance - InpExpectedInitialBalance) > InpInitialBalanceTolerance)
      {
         reason = "initial balance contract";
         return false;
      }
   }
   reason = "account contract allowed";
   return true;
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

double PositionRiskMoney(const ulong ticket, bool &unprotected)
{
   unprotected = false;
   if(ticket == 0 || !PositionSelectByTicket(ticket))
      return 0.0;
   string symbol = PositionGetString(POSITION_SYMBOL);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double stopPrice = PositionGetDouble(POSITION_SL);
   double volume = PositionGetDouble(POSITION_VOLUME);
   long positionType = PositionGetInteger(POSITION_TYPE);
   if(StringLen(symbol) <= 0 || openPrice <= 0.0 || stopPrice <= 0.0 || volume <= 0.0)
   {
      unprotected = true;
      return 0.0;
   }
   ENUM_ORDER_TYPE orderType = positionType == POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if((positionType == POSITION_TYPE_BUY && stopPrice >= openPrice) ||
      (positionType == POSITION_TYPE_SELL && stopPrice <= openPrice))
      return 0.0;
   double riskMoney = 0.0;
   if(!RiskMoneyForOrder(symbol, orderType, openPrice, stopPrice, volume, riskMoney))
      unprotected = true;
   return riskMoney;
}

double AccountWideOpenRiskPercent(bool &hasUnprotected)
{
   hasUnprotected = false;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
      return -1.0;
   double riskMoney = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      bool unprotected = false;
      riskMoney += PositionRiskMoney(ticket, unprotected);
      if(unprotected)
         hasUnprotected = true;
   }
   return 100.0 * riskMoney / equity;
}

bool EntrySafetyAllows(string &reason)
{
   if(InpUseSymbolSafetyLock && _Symbol != InpAllowedSymbol)
   {
      reason = "symbol safety lock";
      return false;
   }
   if(!MQLInfoInteger(MQL_TESTER) &&
      AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL &&
      (InpUseRealAccountSafetyLock || !InpAllowRealAccountTrading ||
        InpRealAccountApprovalCode != "M15USDCLL-LIVE-ACK"))
   {
      reason = "real-account safety lock";
      return false;
   }
   if(!AccountContractAllows(reason))
      return false;
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
   int streak = 0;
   datetime lastLoss = 0;
   LossStreak(streak, lastLoss);
   if(InpMaximumConsecutiveLosses > 0 && streak >= InpMaximumConsecutiveLosses &&
      lastLoss > 0 && TimeCurrent() - lastLoss < InpLossCooldownHours * 3600)
   {
      reason = "loss cooldown";
      return false;
   }
   if(InpRequireEmptyAccountAtEntry && PositionsTotal() > 0)
   {
      reason = "account position already open";
      return false;
   }
   if(ManagedPositionCount() > 0)
   {
      reason = "managed position already open";
      return false;
   }
   double spread = SpreadPoints();
   if(spread > InpMaximumSpreadPoints)
   {
      reason = "spread limit";
      return false;
   }
   bool hasUnprotected = false;
   double openRiskPercent = AccountWideOpenRiskPercent(hasUnprotected);
   if(openRiskPercent < 0.0 ||
      (hasUnprotected && InpAccountWideBlockUnprotectedExposure) ||
      openRiskPercent > InpAccountWideMaxOpenRiskPercent)
   {
      reason = "account-wide exposure limit";
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

bool FinalizeGeometry(const bool buy,
                      const double atr,
                      const double rawStop,
                      double &entryPrice,
                      double &stopPrice,
                      double &targetPrice,
                      double &stopDistance)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || atr <= 0.0 || rawStop <= 0.0)
      return false;
   entryPrice = buy ? tick.ask : tick.bid;
   stopDistance = buy ? entryPrice - rawStop : rawStop - entryPrice;
   if(entryPrice <= 0.0 || stopDistance <= 0.0)
      return false;
   double brokerMinimum = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point + _Point;
   stopDistance = MathMax(stopDistance, MathMax(brokerMinimum, InpMinimumStopATR * atr));
   if(stopDistance / atr > InpMaximumStopATR ||
      stopDistance > InpMaximumStopPriceDistance)
      return false;
   stopPrice = NormalizeDouble(buy ? entryPrice - stopDistance : entryPrice + stopDistance, _Digits);
   targetPrice = NormalizeDouble(buy ? entryPrice + InpTakeProfitR * stopDistance
                                     : entryPrice - InpTakeProfitR * stopDistance, _Digits);
   return stopPrice > 0.0 && targetPrice > 0.0;
}

bool AddedRiskAllows(const bool buy,
                     const double entryPrice,
                     const double stopPrice,
                     const double lots)
{
   bool hasUnprotected = false;
   double currentRiskPercent = AccountWideOpenRiskPercent(hasUnprotected);
   if(currentRiskPercent < 0.0 || (hasUnprotected && InpAccountWideBlockUnprotectedExposure))
      return false;
   double addedRiskMoney = 0.0;
   ENUM_ORDER_TYPE orderType = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!RiskMoneyForOrder(_Symbol, orderType, entryPrice, stopPrice, lots, addedRiskMoney))
      return false;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   return equity > 0.0 && currentRiskPercent + 100.0 * addedRiskMoney / equity <= InpAccountWideMaxOpenRiskPercent;
}

int DateKey(const datetime value)
{
   MqlDateTime parts;
   if(!TimeToStruct(value, parts))
      return 0;
   return parts.year * 10000 + parts.mon * 100 + parts.day;
}

double CandleBodyPercent(const MqlRates &bar)
{
   double range = bar.high - bar.low;
   if(range <= 0.0)
      return 0.0;
   return 100.0 * MathAbs(bar.close - bar.open) / range;
}

bool SessionAllows(const datetime barTime)
{
   MqlDateTime parts;
   if(!TimeToStruct(barTime, parts) || parts.day_of_week == 0 || parts.day_of_week == 6)
      return false;
   if(parts.hour < InpSessionStartHour || parts.hour >= InpSessionEndHour)
      return false;
   if(parts.day_of_week == 5 && InpDisableFridayAfterHour &&
      parts.hour >= InpFridayEntryCutoffHour)
      return false;
   return true;
}

bool NormalizedAlignedMove(const string symbol,
                           const datetime completedAt,
                           double &normalizedMove)
{
   normalizedMove = 0.0;
   int timeframeSeconds = PeriodSeconds(InpProxyTimeframe);
   if(StringLen(symbol) <= 0 || completedAt <= 0 || timeframeSeconds <= 0)
      return false;
   int shift = iBarShift(symbol, InpProxyTimeframe, completedAt, false);
   if(shift < 0)
      return false;
   datetime alignedOpen = iTime(symbol, InpProxyTimeframe, shift);
   if(alignedOpen <= 0)
      return false;
   if(alignedOpen + timeframeSeconds > completedAt)
   {
      shift++;
      alignedOpen = iTime(symbol, InpProxyTimeframe, shift);
   }
   long alignmentSeconds = (long)MathAbs((double)(completedAt - (alignedOpen + timeframeSeconds)));
   if(alignedOpen <= 0 || alignmentSeconds > InpMaximumAlignmentSeconds)
      return false;

   int required = (int)MathMax(InpProxyLookbackBars + 1, InpProxyATRPeriod + 1) + 1;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, InpProxyTimeframe, shift, required, rates) != required)
      return false;
   double atrSum = 0.0;
   for(int i = 0; i < InpProxyATRPeriod; ++i)
   {
      double trueRange = MathMax(rates[i].high - rates[i].low,
                                 MathMax(MathAbs(rates[i].high - rates[i + 1].close),
                                         MathAbs(rates[i].low - rates[i + 1].close)));
      if(trueRange <= 0.0)
         return false;
      atrSum += trueRange;
   }
   double atr = atrSum / InpProxyATRPeriod;
   if(atr <= 0.0 || rates[0].close <= 0.0 || rates[InpProxyLookbackBars].close <= 0.0)
      return false;
   normalizedMove = (rates[0].close - rates[InpProxyLookbackBars].close) / atr;
   return MathIsValidNumber(normalizedMove);
}

bool BuildConsensus(const datetime completedAt,
                    bool &buy,
                    double &consensus,
                    double &alignedGoldMove)
{
   buy = false;
   consensus = 0.0;
   alignedGoldMove = 0.0;
   double eurMove = 0.0;
   double jpyMove = 0.0;
   double goldMove = 0.0;
   if(!NormalizedAlignedMove(InpEURUSDSymbol, completedAt, eurMove) ||
      !NormalizedAlignedMove(InpUSDJPYSymbol, completedAt, jpyMove) ||
      !NormalizedAlignedMove(_Symbol, completedAt, goldMove))
   {
      g_alignmentRejects++;
      return false;
   }
   g_proxyContexts++;
   bool buyConsensus = eurMove >= InpMinimumProxyComponentATR &&
                       jpyMove <= -InpMinimumProxyComponentATR;
   bool sellConsensus = eurMove <= -InpMinimumProxyComponentATR &&
                        jpyMove >= InpMinimumProxyComponentATR;
   if(!buyConsensus && !sellConsensus)
      return false;
   buy = buyConsensus;
   consensus = buy ? 0.5 * (eurMove - jpyMove)
                   : 0.5 * (jpyMove - eurMove);
   if(consensus < InpMinimumConsensusATR)
      return false;
   g_consensusCandidates++;
   alignedGoldMove = buy ? goldMove : -goldMove;
   if(alignedGoldMove < InpMinimumAlignedGoldMoveATR ||
      alignedGoldMove > InpMaximumGoldExtensionATR)
   {
      g_goldLagRejects++;
      return false;
   }
   return (buy && InpAllowBuy) || (!buy && InpAllowSell);
}

bool BreakoutAllows(const bool buy, const double atr)
{
   int required = InpBreakoutLookbackBars + 1;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(atr <= 0.0 || InpBreakoutLookbackBars < 1 ||
      CopyRates(_Symbol, InpSignalTimeframe, 1, required, rates) != required)
      return false;
   MqlRates signal = rates[0];
   double priorHigh = 0.0;
   double priorLow = DBL_MAX;
   for(int i = 1; i < required; ++i)
   {
      priorHigh = MathMax(priorHigh, rates[i].high);
      priorLow = MathMin(priorLow, rates[i].low);
   }
   if(priorHigh <= priorLow || priorLow >= DBL_MAX ||
      CandleBodyPercent(signal) < InpMinimumSignalBodyPercent)
      return false;
   double buffer = InpBreakoutBufferATR * atr;
   bool directional = buy ? signal.close > signal.open : signal.close < signal.open;
   bool broken = buy ? signal.close > priorHigh + buffer
                     : signal.close < priorLow - buffer;
   bool fresh = !InpRequireFreshBreakout ||
                (buy ? signal.open <= priorHigh + buffer : signal.open >= priorLow - buffer);
   return directional && broken && fresh;
}

bool LocalStructureStop(const bool buy, const double atr, double &rawStop)
{
   rawStop = 0.0;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(InpStopLookbackBars < 1 ||
      CopyRates(_Symbol, InpSignalTimeframe, 1, InpStopLookbackBars, rates) != InpStopLookbackBars)
      return false;
   double structureHigh = 0.0;
   double structureLow = DBL_MAX;
   for(int i = 0; i < InpStopLookbackBars; ++i)
   {
      if(rates[i].high <= rates[i].low)
         return false;
      structureHigh = MathMax(structureHigh, rates[i].high);
      structureLow = MathMin(structureLow, rates[i].low);
   }
   if(structureHigh <= structureLow || structureLow >= DBL_MAX)
      return false;
   rawStop = buy ? structureLow - InpStopBufferATR * atr
                 : structureHigh + InpStopBufferATR * atr;
   return rawStop > 0.0;
}

bool OpenConsensusPosition(const bool buy,
                           const double atr,
                           const double rawStop)
{
   string safetyReason = "";
   if(!EntrySafetyAllows(safetyReason))
   {
      g_safetyRejects++;
      return false;
   }
   double entryPrice = 0.0;
   double stopPrice = 0.0;
   double targetPrice = 0.0;
   double stopDistance = 0.0;
   if(!FinalizeGeometry(buy, atr, rawStop,
                        entryPrice, stopPrice, targetPrice, stopDistance))
   {
      g_geometryRejects++;
      return false;
   }
   double lots = LotsForRisk(buy, entryPrice, stopPrice);
   if(lots <= 0.0)
   {
      g_minimumLotRejects++;
      return false;
   }
   if(!AddedRiskAllows(buy, entryPrice, stopPrice, lots))
   {
      g_safetyRejects++;
      return false;
   }
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   string comment = buy ? "M15USDCLL_BUY" : "M15USDCLL_SELL";
   bool opened = buy ? trade.Buy(lots, _Symbol, 0.0, stopPrice, targetPrice, comment)
                      : trade.Sell(lots, _Symbol, 0.0, stopPrice, targetPrice, comment);
   if(!opened)
   {
      g_orderFailures++;
      return false;
   }
   g_ordersOpened++;
   RegisterRiskForNewestPosition(stopDistance);
   LogEvent("entry", trade.ResultOrder(), buy ? "buy" : "sell", lots,
             entryPrice, stopPrice, targetPrice, 0.0, "EURUSD/USDJPY consensus lead-lag breakout");
   return true;
}

bool TryConsensusEntry(const double atr)
{
   datetime currentBarTime = iTime(_Symbol, InpSignalTimeframe, 0);
   if(currentBarTime <= 0 || g_dayStart <= 0 || EntriesSince(g_dayStart) >= 1)
      return false;
   if(!SessionAllows(currentBarTime))
      return false;
   bool buy = false;
   double consensus = 0.0;
   double alignedGoldMove = 0.0;
   if(!BuildConsensus(currentBarTime, buy, consensus, alignedGoldMove))
      return false;
   if(!BreakoutAllows(buy, atr))
   {
      g_breakoutRejects++;
      return false;
   }
   double rawStop = 0.0;
   if(!LocalStructureStop(buy, atr, rawStop))
   {
      g_geometryRejects++;
      return false;
   }
   return OpenConsensusPosition(buy, atr, rawStop);
}

void EmergencyDrawdownStop()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
      return;
   if(g_peakEquity <= 0.0 || equity > g_peakEquity)
      g_peakEquity = equity;
   if(InpMaximumEquityDrawdownPercent <= 0.0 ||
      100.0 * (g_peakEquity - equity) / g_peakEquity < InpMaximumEquityDrawdownPercent)
      return;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         trade.PositionClose(ticket);
   }
}

void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      bool buy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      MqlDateTime nowParts;
      bool timeExit = DateKey(TimeCurrent()) > DateKey(openTime);
      if(TimeToStruct(TimeCurrent(), nowParts) && nowParts.hour >= InpExitHour)
         timeExit = true;
      if(timeExit)
      {
         trade.PositionClose(ticket);
         continue;
      }
      int openShift = iBarShift(_Symbol, InpSignalTimeframe, openTime, false);
      if(InpMaximumHoldBars > 0 && openShift >= InpMaximumHoldBars)
      {
         trade.PositionClose(ticket);
         continue;
      }
      if(!InpUseBreakEven)
         continue;
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double oldStop = PositionGetDouble(POSITION_SL);
      double takeProfit = PositionGetDouble(POSITION_TP);
      double current = buy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double initialRisk = GlobalVariableCheck(RiskKey(ticket)) ? GlobalVariableGet(RiskKey(ticket))
                                                               : MathAbs(openPrice - oldStop);
      if(initialRisk <= 0.0 || current <= 0.0)
         continue;
      double favorable = buy ? current - openPrice : openPrice - current;
      if(favorable / initialRisk < InpBreakEvenTriggerR)
         continue;
      double newStop = NormalizeDouble(buy ? openPrice + InpBreakEvenLockR * initialRisk
                                           : openPrice - InpBreakEvenLockR * initialRisk, _Digits);
      double brokerMinimum = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      bool valid = buy ? newStop > oldStop + _Point && newStop < current - brokerMinimum
                       : newStop < oldStop - _Point && newStop > current + brokerMinimum;
      if(valid)
         trade.PositionModify(ticket, newStop, takeProfit);
   }
}

int OnInit()
{
   if(StringLen(InpEURUSDSymbol) <= 0 || StringLen(InpUSDJPYSymbol) <= 0 ||
      InpEURUSDSymbol == InpUSDJPYSymbol || InpProxyLookbackBars < 1 ||
      InpProxyATRPeriod < 2 || InpMaximumAlignmentSeconds < 0 ||
      InpMinimumProxyComponentATR < 0.0 || InpMinimumConsensusATR <= 0.0 ||
      InpMaximumGoldExtensionATR <= InpMinimumAlignedGoldMoveATR ||
      InpBreakoutLookbackBars < 1 || InpBreakoutBufferATR < 0.0 ||
      InpMinimumSignalBodyPercent < 0.0 || InpMinimumSignalBodyPercent > 100.0 ||
      InpATRPeriod < 2 ||
      InpStopLookbackBars < 1 || InpStopBufferATR < 0.0 || InpMinimumStopATR <= 0.0 ||
      InpMaximumStopATR <= InpMinimumStopATR || InpMaximumStopPriceDistance <= 0.0 ||
      InpTakeProfitR <= 0.0 || InpExitHour < 0 || InpExitHour > 23 ||
      InpSessionStartHour < 0 || InpSessionStartHour > 23 ||
      InpSessionEndHour <= InpSessionStartHour || InpSessionEndHour > 23 ||
      InpFridayEntryCutoffHour < InpSessionStartHour || InpFridayEntryCutoffHour > InpSessionEndHour ||
      InpMaximumHoldBars < 1 || InpBreakEvenTriggerR <= 0.0 ||
      InpBreakEvenLockR < 0.0 || InpRiskPercent <= 0.0 || InpRiskPercent > 1.0 ||
      InpMaximumPositionLots <= 0.0 || InpMaximumEquityDrawdownPercent <= 0.0 ||
      InpMaximumConsecutiveLosses < 1 || InpLossCooldownHours < 1 ||
      InpMaximumSpreadPoints <= 0.0 || InpAccountWideMaxOpenRiskPercent < InpRiskPercent ||
      InpExpectedInitialBalance <= 0.0 || InpInitialBalanceTolerance < 0.0)
      return INIT_PARAMETERS_INCORRECT;
   string accountReason = "";
   if(!AccountContractAllows(accountReason))
   {
      Print("M15USDCLL account contract failure: ", accountReason);
      return INIT_FAILED;
   }
   if(!SymbolSelect(InpEURUSDSymbol, true) || !SymbolSelect(InpUSDJPYSymbol, true))
   {
      Print("M15USDCLL proxy symbol selection failed code=", GetLastError());
      return INIT_FAILED;
   }
   iClose(InpEURUSDSymbol, InpProxyTimeframe, 1);
   iClose(InpUSDJPYSymbol, InpProxyTimeframe, 1);
   g_atrHandle = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);
   if(g_atrHandle == INVALID_HANDLE)
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
            FileWrite(g_logHandle, "time", "event", "symbol", "ticket", "side", "volume", "price", "sl", "tp", "profit", "reason", "profile_id", "source_hash", "run_label");
         FileSeek(g_logHandle, 0, SEEK_END);
      }
   }
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   PrintFormat("M15USDCLL_DIAGNOSTIC proxy_contexts=%d alignment_rejects=%d consensus_candidates=%d gold_lag_rejects=%d breakout_rejects=%d geometry_rejects=%d safety_rejects=%d minimum_lot_rejects=%d opened=%d order_failures=%d",
                g_proxyContexts, g_alignmentRejects, g_consensusCandidates, g_goldLagRejects,
                g_breakoutRejects, g_geometryRejects,
                g_safetyRejects, g_minimumLotRejects, g_ordersOpened, g_orderFailures);
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   if(g_logHandle != INVALID_HANDLE)
      FileClose(g_logHandle);
}

void OnTick()
{
   RefreshDayState();
   EmergencyDrawdownStop();
   ManagePositions();
   datetime currentBar = iTime(_Symbol, InpSignalTimeframe, 0);
   if(currentBar <= 0 || currentBar == g_lastSignalBar)
      return;
   g_lastSignalBar = currentBar;
   if(ManagedPositionCount() > 0)
      return;
   double atr = 0.0;
   if(!BufferValue(g_atrHandle, 0, 1, atr) || atr <= 0.0)
      return;
   TryConsensusEntry(atr);
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
            HistoryDealGetDouble(transaction.deal, DEAL_PRICE), 0.0, 0.0, profit,
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

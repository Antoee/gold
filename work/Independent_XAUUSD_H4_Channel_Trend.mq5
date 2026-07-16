#property strict
#property version   "1.00"
#property description "Date-independent XAUUSD H4 channel-trend research EA"

#include <Trade/Trade.mqh>

CTrade trade;

input group "Identity and Safety"
input string InpAllowedSymbol = "XAUUSD";
input ulong  InpMagicNumber = 26071651;
input bool   InpUseSymbolSafetyLock = true;
input bool   InpUseRealAccountSafetyLock = true;
input bool   InpAllowRealAccountTrading = false;
input string InpRealAccountApprovalCode = "DISABLED";

input group "Channel Trend Engine"
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_H4;
input int    InpEntryLookbackBars = 55;
input int    InpExitLookbackBars = 20;
input double InpBreakoutBufferATR = 0.00;
input bool   InpAllowBuy = true;
input bool   InpAllowSell = true;
input bool   InpRequireFreshBreakout = true;

input group "Regime Filters"
input bool InpUseTrendEMAFilter = false;
input ENUM_TIMEFRAMES InpTrendTimeframe = PERIOD_D1;
input int  InpTrendEMAPeriod = 100;
input int  InpTrendEMASlopeBars = 5;
input bool InpUseADXFilter = false;
input int  InpADXPeriod = 14;
input double InpMinimumADX = 16.0;
input bool InpUseVolatilityFilter = true;
input double InpMinimumATRPercent = 0.20;
input double InpMaximumATRPercent = 5.00;

input group "Stops and Position Management"
input int    InpATRPeriod = 20;
input double InpInitialStopATR = 2.00;
input bool   InpUseBreakEven = false;
input double InpBreakEvenTriggerR = 1.50;
input double InpBreakEvenLockR = 0.00;
input bool   InpUseChandelierTrail = false;
input int    InpChandelierLookbackBars = 20;
input double InpChandelierATR = 3.00;
input int    InpMaximumHoldBars = 0;

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
input string InpLogFileName = "Independent_XAUUSD_H4_Channel_Trend_Trades.csv";
input string InpEvidenceProfileId = "";
input string InpEvidenceSourceHash = "";
input string InpEvidenceRunLabel = "";

int g_atrHandle = INVALID_HANDLE;
int g_trendEmaHandle = INVALID_HANDLE;
int g_adxHandle = INVALID_HANDLE;
int g_logHandle = INVALID_HANDLE;
datetime g_dayStart = 0;
datetime g_lastSignalBar = 0;
double g_peakEquity = 0.0;

string RiskKey(const ulong ticket)
{
   return "IH4CT_RISK_" + IntegerToString((long)ticket);
}

double SpreadPoints()
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return DBL_MAX;
   return (tick.ask - tick.bid) / _Point;
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
       InpRealAccountApprovalCode != "H4CT-LIVE-ACK"))
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

bool OpenTrendPosition(const bool buy, const double atr)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || atr <= 0.0)
      return false;
   double entryPrice = buy ? tick.ask : tick.bid;
   double stopLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double stopDistance = MathMax(InpInitialStopATR * atr, stopLevel + _Point);
   double stopPrice = NormalizeDouble(buy ? entryPrice - stopDistance : entryPrice + stopDistance, _Digits);
   double lots = LotsForRisk(buy, entryPrice, stopPrice);
   if(lots <= 0.0)
      return false;
   string exposureReason = "";
   if(!AccountWideExposureAllows(buy, entryPrice, stopPrice, lots, exposureReason))
      return false;
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   string comment = buy ? "H4CT_BUY" : "H4CT_SELL";
   bool opened = buy ? trade.Buy(lots, _Symbol, 0.0, stopPrice, 0.0, comment)
                     : trade.Sell(lots, _Symbol, 0.0, stopPrice, 0.0, comment);
   if(!opened)
      return false;
   RegisterRiskForNewestPosition(stopDistance);
   LogEvent("entry", trade.ResultOrder(), buy ? "buy" : "sell", lots, entryPrice, stopPrice, 0.0,
            "fresh channel breakout");
   return true;
}

bool TryChannelExit(const ulong ticket, const bool buy)
{
   double exitHigh = 0.0;
   double exitLow = 0.0;
   if(!ChannelBounds(2, InpExitLookbackBars, exitHigh, exitLow))
      return false;
   double closePrice = iClose(_Symbol, InpSignalTimeframe, 1);
   bool channelExit = buy ? closePrice < exitLow : closePrice > exitHigh;
   if(channelExit)
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
      trade.PositionModify(ticket, newSl, 0.0);
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
      if(TryChannelExit(ticket, buy))
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
   double channelHigh = 0.0;
   double channelLow = 0.0;
   if(!ChannelBounds(2, InpEntryLookbackBars, channelHigh, channelLow))
      return;
   double close1 = iClose(_Symbol, InpSignalTimeframe, 1);
   double close2 = iClose(_Symbol, InpSignalTimeframe, 2);
   if(close1 <= 0.0 || close2 <= 0.0)
      return;
   double buffer = InpBreakoutBufferATR * atr;
   bool buyBreak = InpAllowBuy && close1 > channelHigh + buffer;
   bool sellBreak = InpAllowSell && close1 < channelLow - buffer;
   if(InpRequireFreshBreakout)
   {
      double priorHigh = 0.0;
      double priorLow = 0.0;
      if(!ChannelBounds(3, InpEntryLookbackBars, priorHigh, priorLow))
         return;
      buyBreak = buyBreak && close2 <= priorHigh + buffer;
      sellBreak = sellBreak && close2 >= priorLow - buffer;
   }
   if(buyBreak && RegimeAllows(true, close1, atr))
      OpenTrendPosition(true, atr);
   else if(sellBreak && RegimeAllows(false, close1, atr))
      OpenTrendPosition(false, atr);
}

int OnInit()
{
   if(InpEntryLookbackBars < 10 || InpExitLookbackBars < 3 ||
      InpATRPeriod < 2 || InpInitialStopATR <= 0.0 ||
      InpRiskPercent <= 0.0 || InpRiskPercent > 2.0 ||
      InpMaximumSimultaneousPositions < 1 ||
      InpAccountWideMaxPositions < 1)
      return INIT_PARAMETERS_INCORRECT;
   g_atrHandle = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);
   g_trendEmaHandle = iMA(_Symbol, InpTrendTimeframe, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_adxHandle = iADX(_Symbol, InpSignalTimeframe, InpADXPeriod);
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
   if(trades < 30.0)
      return profit - (30.0 - trades) * 1000.0;
   return profit * MathMax(0.0, MathMin(5.0, profitFactor)) / (1.0 + MathMax(0.0, drawdown));
}

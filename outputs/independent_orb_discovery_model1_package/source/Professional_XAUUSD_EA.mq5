#property strict
#property version   "1.00"
#property description "Date-independent XAUUSD opening-range breakout research EA"

#include <Trade/Trade.mqh>

CTrade trade;

input group "Identity and Safety"
input string InpAllowedSymbol = "XAUUSD";
input ulong  InpMagicNumber = 26071641;
input bool   InpUseSymbolSafetyLock = true;
input bool   InpUseRealAccountSafetyLock = true;
input bool   InpAllowRealAccountTrading = false;
input string InpRealAccountApprovalCode = "DISABLED";

input group "Session Engine (server time)"
input bool InpUseLondonSession = true;
input int  InpLondonRangeStartHour = 7;
input int  InpLondonRangeEndHour = 8;
input int  InpLondonTradeEndHour = 12;
input bool InpUseNewYorkSession = false;
input int  InpNewYorkRangeStartHour = 13;
input int  InpNewYorkRangeEndHour = 14;
input int  InpNewYorkTradeEndHour = 17;
input bool InpCloseAtSessionEnd = true;

input group "Opening Range Entry"
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_M15;
input int    InpATRPeriod = 14;
input double InpBreakoutBufferATR = 0.05;
input double InpMinimumRangeATR = 0.50;
input double InpMaximumRangeATR = 3.00;
input double InpMaximumExtensionATR = 0.60;
input double InpMinimumBreakoutBodyPercent = 45.0;
input bool   InpAllowBuy = true;
input bool   InpAllowSell = true;

input group "Trend and Activity Filters"
input bool InpUseH1TrendFilter = true;
input int  InpH1FastEMAPeriod = 50;
input int  InpH1SlowEMAPeriod = 200;
input bool InpUseADXFilter = true;
input int  InpADXPeriod = 14;
input double InpMinimumADX = 18.0;
input bool InpUseTickVolumeFilter = false;
input int  InpVolumeLookbackBars = 20;
input double InpMinimumVolumeRatio = 1.00;

input group "Stops and Position Management"
input double InpMinimumStopATR = 0.60;
input double InpMaximumStopATR = 1.80;
input double InpTakeProfitRR = 2.00;
input bool   InpUseBreakEven = true;
input double InpBreakEvenTriggerR = 1.00;
input double InpBreakEvenLockR = 0.05;
input bool   InpUseATRTrailing = true;
input double InpTrailingStartR = 1.50;
input double InpTrailingATRMultiplier = 1.20;

input group "Risk Manager"
input double InpRiskPercent = 0.10;
input double InpMaximumPositionLots = 1.00;
input int    InpMaximumSimultaneousPositions = 1;
input int    InpMaximumTradesPerDay = 2;
input double InpMaximumDailyLossPercent = 0.75;
input double InpMaximumEquityDrawdownPercent = 5.00;
input int    InpMaximumConsecutiveLosses = 3;
input int    InpLossCooldownHours = 24;
input double InpMaximumSpreadPoints = 50.0;
input int    InpDeviationPoints = 20;

input group "Evidence Logging"
input bool   InpLogTrades = false;
input string InpLogFileName = "Independent_XAUUSD_ORB_Trades.csv";
input string InpEvidenceProfileId = "";
input string InpEvidenceSourceHash = "";
input string InpEvidenceRunLabel = "";

int g_atrHandle = INVALID_HANDLE;
int g_fastEmaHandle = INVALID_HANDLE;
int g_slowEmaHandle = INVALID_HANDLE;
int g_adxHandle = INVALID_HANDLE;
int g_logHandle = INVALID_HANDLE;
datetime g_dayStart = 0;
datetime g_lastSignalBar = 0;
bool g_londonTraded = false;
bool g_newYorkTraded = false;
double g_peakEquity = 0.0;

string RiskKey(const ulong ticket)
{
   return "IORB_RISK_" + IntegerToString((long)ticket);
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
              const string session,
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
             session,
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
   if(dayStart <= 0 || dayStart == g_dayStart)
      return;
   g_dayStart = dayStart;
   g_londonTraded = false;
   g_newYorkTraded = false;
}

double ClosedProfitSince(const datetime fromTime)
{
   if(fromTime <= 0 || !HistorySelect(fromTime, TimeCurrent()))
      return 0.0;
   double profit = 0.0;
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; ++i)
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
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; ++i)
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

bool SafetyAllows(string &reason)
{
   if(InpUseSymbolSafetyLock && _Symbol != InpAllowedSymbol)
   {
      reason = "symbol safety lock";
      return false;
   }
   if(!MQLInfoInteger(MQL_TESTER) &&
      AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL &&
      (InpUseRealAccountSafetyLock || !InpAllowRealAccountTrading || InpRealAccountApprovalCode != "ORB-LIVE-ACK"))
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

bool GetSessionRange(const datetime dayStart,
                     const int startHour,
                     const int endHour,
                     double &rangeHigh,
                     double &rangeLow)
{
   if(dayStart <= 0 || startHour < 0 || startHour > 23 || endHour <= startHour || endHour > 24)
      return false;
   datetime fromTime = dayStart + startHour * 3600;
   datetime toTime = dayStart + endHour * 3600 - 1;
   MqlRates rates[];
   int copied = CopyRates(_Symbol, InpSignalTimeframe, fromTime, toTime, rates);
   if(copied <= 0)
      return false;
   rangeHigh = -DBL_MAX;
   rangeLow = DBL_MAX;
   for(int i = 0; i < copied; ++i)
   {
      rangeHigh = MathMax(rangeHigh, rates[i].high);
      rangeLow = MathMin(rangeLow, rates[i].low);
   }
   return rangeHigh > rangeLow && rangeHigh > 0.0 && rangeLow > 0.0;
}

bool TrendAllows(const bool buy)
{
   if(InpUseH1TrendFilter)
   {
      double fast = 0.0;
      double slow = 0.0;
      if(!BufferValue(g_fastEmaHandle, 0, 1, fast) || !BufferValue(g_slowEmaHandle, 0, 1, slow))
         return false;
      if(buy && fast <= slow)
         return false;
      if(!buy && fast >= slow)
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

bool VolumeAllows()
{
   if(!InpUseTickVolumeFilter)
      return true;
   long currentVolume = iVolume(_Symbol, InpSignalTimeframe, 1);
   if(currentVolume <= 0)
      return false;
   double average = 0.0;
   int samples = 0;
   for(int shift = 2; shift < 2 + MathMax(2, InpVolumeLookbackBars); ++shift)
   {
      long volume = iVolume(_Symbol, InpSignalTimeframe, shift);
      if(volume <= 0)
         continue;
      average += (double)volume;
      samples++;
   }
   if(samples <= 0)
      return false;
   average /= samples;
   return (double)currentVolume >= average * InpMinimumVolumeRatio;
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

double LotsForRisk(const double stopDistance)
{
   if(stopDistance <= 0.0 || InpRiskPercent <= 0.0)
      return 0.0;
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickValue <= 0.0)
      tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0.0 || tickValue <= 0.0)
      return 0.0;
   double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * InpRiskPercent / 100.0;
   double lossPerLot = stopDistance / tickSize * tickValue;
   if(lossPerLot <= 0.0)
      return 0.0;
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

bool OpenBreakout(const string session,
                  const bool buy,
                  const double rangeHigh,
                  const double rangeLow,
                  const double atr)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return false;
   double entry = buy ? tick.ask : tick.bid;
   double structureDistance = buy ? entry - rangeLow : rangeHigh - entry;
   double minimumDistance = MathMax(InpMinimumStopATR * atr,
                                    (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point);
   double maximumDistance = MathMax(minimumDistance, InpMaximumStopATR * atr);
   double stopDistance = MathMin(structureDistance, maximumDistance);
   stopDistance = MathMax(stopDistance, minimumDistance);
   if(stopDistance <= 0.0)
      return false;
   double lots = LotsForRisk(stopDistance);
   if(lots <= 0.0)
      return false;

   double sl = NormalizeDouble(buy ? entry - stopDistance : entry + stopDistance, _Digits);
   double tpDistance = stopDistance * MathMax(0.10, InpTakeProfitRR);
   double tp = NormalizeDouble(buy ? entry + tpDistance : entry - tpDistance, _Digits);
   string comment = "ORB_" + session;
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   bool opened = buy ? trade.Buy(lots, _Symbol, 0.0, sl, tp, comment)
                     : trade.Sell(lots, _Symbol, 0.0, sl, tp, comment);
   if(!opened)
      return false;
   RegisterRiskForNewestPosition(stopDistance);
   LogEvent("entry", trade.ResultOrder(), session, buy ? "buy" : "sell", lots, entry, sl, tp, 0.0,
            "opening range breakout");
   return true;
}

void TrySession(const string session,
                const int rangeStartHour,
                const int rangeEndHour,
                const int tradeEndHour,
                bool &sessionTraded)
{
   if(sessionTraded || g_dayStart <= 0)
      return;
   datetime now = TimeCurrent();
   datetime tradeStart = g_dayStart + rangeEndHour * 3600;
   datetime tradeEnd = g_dayStart + tradeEndHour * 3600;
   if(now < tradeStart || now >= tradeEnd)
      return;

   string safetyReason = "";
   if(!SafetyAllows(safetyReason))
      return;
   double rangeHigh = 0.0;
   double rangeLow = 0.0;
   if(!GetSessionRange(g_dayStart, rangeStartHour, rangeEndHour, rangeHigh, rangeLow))
      return;
   double atr = 0.0;
   if(!BufferValue(g_atrHandle, 0, 1, atr) || atr <= 0.0)
      return;
   double rangeAtr = (rangeHigh - rangeLow) / atr;
   if(rangeAtr < InpMinimumRangeATR || rangeAtr > InpMaximumRangeATR)
      return;
   if(!VolumeAllows())
      return;

   double open1 = iOpen(_Symbol, InpSignalTimeframe, 1);
   double high1 = iHigh(_Symbol, InpSignalTimeframe, 1);
   double low1 = iLow(_Symbol, InpSignalTimeframe, 1);
   double close1 = iClose(_Symbol, InpSignalTimeframe, 1);
   double close2 = iClose(_Symbol, InpSignalTimeframe, 2);
   double candleRange = high1 - low1;
   if(candleRange <= 0.0)
      return;
   double bodyPercent = 100.0 * MathAbs(close1 - open1) / candleRange;
   if(bodyPercent < InpMinimumBreakoutBodyPercent)
      return;
   double buffer = InpBreakoutBufferATR * atr;
   bool buyBreak = InpAllowBuy && close1 > rangeHigh + buffer && close2 <= rangeHigh + buffer &&
                   close1 - rangeHigh <= InpMaximumExtensionATR * atr;
   bool sellBreak = InpAllowSell && close1 < rangeLow - buffer && close2 >= rangeLow - buffer &&
                    rangeLow - close1 <= InpMaximumExtensionATR * atr;
   if(buyBreak && TrendAllows(true) && OpenBreakout(session, true, rangeHigh, rangeLow, atr))
      sessionTraded = true;
   else if(sellBreak && TrendAllows(false) && OpenBreakout(session, false, rangeHigh, rangeLow, atr))
      sessionTraded = true;
}

void ManagePositions()
{
   double atr = 0.0;
   if(!BufferValue(g_atrHandle, 0, 1, atr) || atr <= 0.0)
      return;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      string comment = PositionGetString(POSITION_COMMENT);
      int sessionEndHour = (StringFind(comment, "LONDON") >= 0) ? InpLondonTradeEndHour : InpNewYorkTradeEndHour;
      if(InpCloseAtSessionEnd && g_dayStart > 0 && TimeCurrent() >= g_dayStart + sessionEndHour * 3600)
      {
         trade.PositionClose(ticket);
         continue;
      }

      long type = PositionGetInteger(POSITION_TYPE);
      bool buy = type == POSITION_TYPE_BUY;
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double current = buy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double risk = GlobalVariableCheck(RiskKey(ticket)) ? GlobalVariableGet(RiskKey(ticket)) : MathAbs(openPrice - sl);
      if(risk <= 0.0)
         continue;
      double favorable = buy ? current - openPrice : openPrice - current;
      double r = favorable / risk;
      double newSl = sl;
      if(InpUseBreakEven && r >= InpBreakEvenTriggerR)
      {
         double breakEven = buy ? openPrice + InpBreakEvenLockR * risk : openPrice - InpBreakEvenLockR * risk;
         if((buy && (newSl <= 0.0 || breakEven > newSl)) || (!buy && (newSl <= 0.0 || breakEven < newSl)))
            newSl = breakEven;
      }
      if(InpUseATRTrailing && r >= InpTrailingStartR)
      {
         double trailing = buy ? current - InpTrailingATRMultiplier * atr : current + InpTrailingATRMultiplier * atr;
         if((buy && (newSl <= 0.0 || trailing > newSl)) || (!buy && (newSl <= 0.0 || trailing < newSl)))
            newSl = trailing;
      }
      newSl = NormalizeDouble(newSl, _Digits);
      double stopLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      bool valid = buy ? newSl > 0.0 && newSl < current - stopLevel : newSl > current + stopLevel;
      bool improved = buy ? newSl > sl + _Point : (sl <= 0.0 || newSl < sl - _Point);
      if(valid && improved)
         trade.PositionModify(ticket, newSl, tp);
   }
}

int OnInit()
{
   if(InpRiskPercent <= 0.0 || InpRiskPercent > 2.0 ||
      InpLondonRangeEndHour <= InpLondonRangeStartHour ||
      InpLondonTradeEndHour <= InpLondonRangeEndHour ||
      InpNewYorkRangeEndHour <= InpNewYorkRangeStartHour ||
      InpNewYorkTradeEndHour <= InpNewYorkRangeEndHour)
      return INIT_PARAMETERS_INCORRECT;
   g_atrHandle = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);
   g_fastEmaHandle = iMA(_Symbol, PERIOD_H1, InpH1FastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_slowEmaHandle = iMA(_Symbol, PERIOD_H1, InpH1SlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_adxHandle = iADX(_Symbol, PERIOD_H1, InpADXPeriod);
   if(g_atrHandle == INVALID_HANDLE || g_fastEmaHandle == INVALID_HANDLE ||
      g_slowEmaHandle == INVALID_HANDLE || g_adxHandle == INVALID_HANDLE)
      return INIT_FAILED;
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   RefreshDayState();
   if(InpLogTrades)
   {
      g_logHandle = FileOpen(InpLogFileName, FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_SHARE_READ | FILE_SHARE_WRITE);
      if(g_logHandle != INVALID_HANDLE)
      {
         if(FileSize(g_logHandle) == 0)
            FileWrite(g_logHandle, "time", "event", "symbol", "ticket", "session", "side", "volume", "price", "sl", "tp", "profit", "reason", "profile_id", "source_hash", "run_label");
         FileSeek(g_logHandle, 0, SEEK_END);
      }
   }
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   if(g_fastEmaHandle != INVALID_HANDLE)
      IndicatorRelease(g_fastEmaHandle);
   if(g_slowEmaHandle != INVALID_HANDLE)
      IndicatorRelease(g_slowEmaHandle);
   if(g_adxHandle != INVALID_HANDLE)
      IndicatorRelease(g_adxHandle);
   if(g_logHandle != INVALID_HANDLE)
      FileClose(g_logHandle);
}

void OnTick()
{
   RefreshDayState();
   ManagePositions();
   datetime currentBar = iTime(_Symbol, InpSignalTimeframe, 0);
   if(currentBar <= 0 || currentBar == g_lastSignalBar)
      return;
   g_lastSignalBar = currentBar;
   if(InpUseLondonSession)
      TrySession("LONDON", InpLondonRangeStartHour, InpLondonRangeEndHour, InpLondonTradeEndHour, g_londonTraded);
   if(InpUseNewYorkSession)
      TrySession("NEWYORK", InpNewYorkRangeStartHour, InpNewYorkRangeEndHour, InpNewYorkTradeEndHour, g_newYorkTraded);
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
   LogEvent("exit", transaction.deal, "", "close",
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
   if(trades < 10.0)
      return profit - (10.0 - trades) * 1000.0;
   return profit * MathMax(0.0, MathMin(5.0, profitFactor)) / (1.0 + MathMax(0.0, drawdown));
}

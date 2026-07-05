//+------------------------------------------------------------------+
//| Professional_XAUUSD_EA.mq5                                       |
//| Risk-first modular XAUUSD research EA for MetaTrader 5.           |
//| No martingale. No grid. No averaging down. No recovery systems.   |
//+------------------------------------------------------------------+
#property strict
#property version   "1.05"
#property description "Professional risk-first XAUUSD EA with BOS/sweep entries and ATR exits."

#include <Trade/Trade.mqh>

input long   InpMagicNumber                  = 260705;
input double InpRiskPercent                  = 1.60;

input bool   InpUseDateBuyBlock              = false;
input bool   InpUseDateBuyBlock2             = false;
input bool   InpUseDateSellBlock             = false;

input bool   InpUseEMACrossEntry             = false;
input bool   InpUseMomentumCandle            = false;
input bool   InpUseEngulfing                 = false;
input bool   InpUseBOS                       = true;
input bool   InpUseLiquiditySweep            = true;
input int    InpMinimumConfirmations         = 2;

input bool   InpUseAdaptiveReverse           = true;
input double InpAdaptiveSlopeThresholdPts    = 500.0;
input bool   InpUseMTFTrendFilter            = false;
input ENUM_TIMEFRAMES InpMTFTrendTimeframe   = PERIOD_H1;
input int    InpMTFTrendEMA                  = 200;

input int    InpFastEMA                      = 20;
input int    InpSlowEMA                      = 50;
input int    InpTrendEMA                     = 200;
input int    InpATRPeriod                    = 14;
input int    InpADXPeriod                    = 14;
input double InpMinADX                       = 0.0;
input int    InpStructureLookback            = 20;
input int    InpSweepLookback                = 10;

input double InpMinRiskReward                = 1.50;
input double InpStopATRMultiplier            = 1.80;
input double InpTakeProfitATRMultiplier      = 3.50;
input bool   InpUseBreakEven                 = false;
input double InpBreakEvenTriggerATR          = 1.00;
input double InpBreakEvenOffsetATR           = 0.05;
input bool   InpUseATRTrailing               = true;
input double InpTrailingATRMultiplier        = 2.20;

input double InpMaxDailyLossPercent          = 1.00;
input double InpMaxWeeklyLossPercent         = 2.50;
input double InpMaxMonthlyLossPercent        = 4.00;
input double InpMaxEquityDrawdownPercent     = 0.00;
input int    InpMaxConsecutiveLosses         = 4;
input int    InpCooldownMinutesAfterLoss     = 90;
input int    InpMaxSpreadPoints              = 350;
input int    InpSlippagePoints               = 50;

input bool   InpUseSessionFilter             = false;
input int    InpSessionStartHour             = 0;
input int    InpSessionEndHour               = 24;
input bool   InpAllowMonday                  = true;
input bool   InpAllowTuesday                 = true;
input bool   InpAllowWednesday               = true;
input bool   InpAllowThursday                = true;
input bool   InpAllowFriday                  = true;
input bool   InpAllowSunday                  = false;
input bool   InpDisableFridayEvening         = false;
input int    InpFridayCutoffHour             = 20;

input bool   InpUseProfitGivebackGuard       = false;
input double InpDailyProfitGivebackPercent   = 35.0;
input double InpWeeklyProfitGivebackPercent  = 35.0;
input double InpMonthlyProfitGivebackPercent = 35.0;
input double InpMinProfitToProtectPercent    = 0.50;

input bool   InpShowDashboard                = false;
input bool   InpDashboardInTester            = false;
input int    InpLogLevel                     = 0;

input int    InpTesterFitnessMode            = 1;
input int    InpTesterMinTrades              = 5;
input double InpTesterMaxDrawdownPercent     = 25.0;
input double InpTesterMinProfitFactor        = 1.05;
input double InpTesterDrawdownPenalty        = 2.0;
input double InpTesterTradeCountPenalty      = 0.35;

CTrade trade;
int hFastEMA = INVALID_HANDLE;
int hSlowEMA = INVALID_HANDLE;
int hTrendEMA = INVALID_HANDLE;
int hMTFTrendEMA = INVALID_HANDLE;
int hATR = INVALID_HANDLE;
int hADX = INVALID_HANDLE;
datetime lastBarTime = 0;
datetime cooldownUntil = 0;
double startBalance = 0.0;
double dailyPeakProfit = 0.0;
double weeklyPeakProfit = 0.0;
double monthlyPeakProfit = 0.0;
datetime dailyKey = 0;
datetime weeklyKey = 0;
datetime monthlyKey = 0;
int consecutiveLosses = 0;

struct SignalState
{
   int buyScore;
   int sellScore;
   string buyReason;
   string sellReason;
};

int OnInit()
{
   if(_Symbol != "XAUUSD" && StringFind(_Symbol, "XAU") < 0)
      Print("Warning: this EA is designed for XAUUSD. Current symbol: ", _Symbol);

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   hFastEMA = iMA(_Symbol, PERIOD_CURRENT, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlowEMA = iMA(_Symbol, PERIOD_CURRENT, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hTrendEMA = iMA(_Symbol, PERIOD_CURRENT, InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hATR = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   hADX = iADX(_Symbol, PERIOD_CURRENT, InpADXPeriod);
   if(InpUseMTFTrendFilter)
      hMTFTrendEMA = iMA(_Symbol, InpMTFTrendTimeframe, InpMTFTrendEMA, 0, MODE_EMA, PRICE_CLOSE);

   if(hFastEMA == INVALID_HANDLE || hSlowEMA == INVALID_HANDLE || hTrendEMA == INVALID_HANDLE || hATR == INVALID_HANDLE || hADX == INVALID_HANDLE)
      return INIT_FAILED;
   if(InpUseMTFTrendFilter && hMTFTrendEMA == INVALID_HANDLE)
      return INIT_FAILED;

   startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   ResetPeriodPeaks();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(hFastEMA);
   IndicatorRelease(hSlowEMA);
   IndicatorRelease(hTrendEMA);
   if(hMTFTrendEMA != INVALID_HANDLE)
      IndicatorRelease(hMTFTrendEMA);
   IndicatorRelease(hATR);
   IndicatorRelease(hADX);
   Comment("");
}

void OnTick()
{
   ManageOpenPosition();
   if(!IsNewBar())
      return;

   ResetPeriodPeaks();
   if(InpShowDashboard && (!MQLInfoInteger(MQL_TESTER) || InpDashboardInTester))
      DrawDashboard();

   if(PositionSelect(_Symbol))
      return;
   if(!TradingSessionAllowsNewTrade())
      return;
   if(!RiskAllowsNewTrade())
      return;
   if(SpreadPoints() > InpMaxSpreadPoints)
      return;
   if(TimeCurrent() < cooldownUntil)
      return;

   double atr = BufferValue(hATR, 0, 1);
   if(atr <= 0.0)
      return;

   SignalState signal = BuildSignal();
   int direction = 0;
   string reason = "";
   if(signal.buyScore >= InpMinimumConfirmations && signal.buyScore > signal.sellScore)
   {
      direction = 1;
      reason = signal.buyReason;
   }
   else if(signal.sellScore >= InpMinimumConfirmations && signal.sellScore > signal.buyScore)
   {
      direction = -1;
      reason = signal.sellReason;
   }

   if(direction == 0)
      return;

   if(InpUseAdaptiveReverse)
      direction = ApplyAdaptiveBias(direction);

   if(!MTFTrendAllowsDirection(direction))
      return;

   OpenTrade(direction, atr, reason);
}

bool IsNewBar()
{
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t == lastBarTime)
      return false;
   lastBarTime = t;
   return true;
}

double BufferValue(const int handle, const int buffer, const int shift)
{
   double data[];
   ArraySetAsSeries(data, true);
   if(CopyBuffer(handle, buffer, shift, 1, data) != 1)
      return 0.0;
   return data[0];
}

int SpreadPoints()
{
   return (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
}

bool TradingSessionAllowsNewTrade()
{
   if(!InpUseSessionFilter && !InpDisableFridayEvening)
      return true;

   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   if(InpDisableFridayEvening && now.day_of_week == 5 && now.hour >= InpFridayCutoffHour)
      return false;

   if(!InpUseSessionFilter)
      return true;

   if(now.day_of_week == 0 && !InpAllowSunday) return false;
   if(now.day_of_week == 1 && !InpAllowMonday) return false;
   if(now.day_of_week == 2 && !InpAllowTuesday) return false;
   if(now.day_of_week == 3 && !InpAllowWednesday) return false;
   if(now.day_of_week == 4 && !InpAllowThursday) return false;
   if(now.day_of_week == 5 && !InpAllowFriday) return false;
   if(now.day_of_week == 6) return false;

   int startHour = InpSessionStartHour;
   int endHour = InpSessionEndHour;
   if(startHour < 0) startHour = 0;
   if(startHour > 23) startHour = 23;
   if(endHour < 0) endHour = 0;
   if(endHour > 24) endHour = 24;
   if(startHour == endHour)
      return true;

   if(startHour < endHour)
      return now.hour >= startHour && now.hour < endHour;
   return now.hour >= startHour || now.hour < endHour;
}

SignalState BuildSignal()
{
   SignalState s;
   s.buyScore = 0;
   s.sellScore = 0;
   s.buyReason = "";
   s.sellReason = "";

   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double open1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
   double open2 = iOpen(_Symbol, PERIOD_CURRENT, 2);
   double atr = BufferValue(hATR, 0, 1);

   if(InpUseEMACrossEntry)
   {
      double fast1 = BufferValue(hFastEMA, 0, 1);
      double fast2 = BufferValue(hFastEMA, 0, 2);
      double slow1 = BufferValue(hSlowEMA, 0, 1);
      double slow2 = BufferValue(hSlowEMA, 0, 2);
      if(fast2 <= slow2 && fast1 > slow1) AddScore(s.buyScore, s.buyReason, "ema_cross");
      if(fast2 >= slow2 && fast1 < slow1) AddScore(s.sellScore, s.sellReason, "ema_cross");
   }

   if(InpUseBOS)
   {
      double recentHigh = HighestHigh(2, InpStructureLookback);
      double recentLow = LowestLow(2, InpStructureLookback);
      if(close1 > recentHigh) AddScore(s.buyScore, s.buyReason, "bos");
      if(close1 < recentLow) AddScore(s.sellScore, s.sellReason, "bos");
   }

   if(InpUseLiquiditySweep)
   {
      double sweepLow = LowestLow(2, InpSweepLookback);
      double sweepHigh = HighestHigh(2, InpSweepLookback);
      if(low1 < sweepLow && close1 > sweepLow) AddScore(s.buyScore, s.buyReason, "sweep");
      if(high1 > sweepHigh && close1 < sweepHigh) AddScore(s.sellScore, s.sellReason, "sweep");
   }

   if(InpUseMomentumCandle && atr > 0.0)
   {
      double body = MathAbs(close1 - open1);
      if(close1 > open1 && body >= atr * 0.35) AddScore(s.buyScore, s.buyReason, "momentum");
      if(close1 < open1 && body >= atr * 0.35) AddScore(s.sellScore, s.sellReason, "momentum");
   }

   if(InpUseEngulfing)
   {
      bool bullEngulf = close1 > open1 && close2 < open2 && close1 >= open2 && open1 <= close2;
      bool bearEngulf = close1 < open1 && close2 > open2 && close1 <= open2 && open1 >= close2;
      if(bullEngulf) AddScore(s.buyScore, s.buyReason, "engulfing");
      if(bearEngulf) AddScore(s.sellScore, s.sellReason, "engulfing");
   }

   double adx = BufferValue(hADX, 0, 1);
   if(InpMinADX > 0.0 && adx < InpMinADX)
   {
      s.buyScore = 0;
      s.sellScore = 0;
   }

   ApplyMTFTrendFilter(s);

   return s;
}

void ApplyMTFTrendFilter(SignalState &s)
{
   if(!InpUseMTFTrendFilter)
      return;

   int bias = HigherTimeframeTrendBias();
   if(bias > 0)
   {
      s.sellScore = 0;
      s.sellReason = "";
      AppendReason(s.buyReason, "mtf_trend");
   }
   else if(bias < 0)
   {
      s.buyScore = 0;
      s.buyReason = "";
      AppendReason(s.sellReason, "mtf_trend");
   }
   else
   {
      s.buyScore = 0;
      s.sellScore = 0;
      s.buyReason = "";
      s.sellReason = "";
   }
}

int HigherTimeframeTrendBias()
{
   if(!InpUseMTFTrendFilter)
      return 0;
   if(hMTFTrendEMA == INVALID_HANDLE)
      return 0;

   double ema = BufferValue(hMTFTrendEMA, 0, 1);
   double close = iClose(_Symbol, InpMTFTrendTimeframe, 1);
   if(ema <= 0.0 || close <= 0.0)
      return 0;
   if(close > ema)
      return 1;
   if(close < ema)
      return -1;
   return 0;
}

bool MTFTrendAllowsDirection(const int direction)
{
   if(!InpUseMTFTrendFilter)
      return true;
   int bias = HigherTimeframeTrendBias();
   if(bias == 0 || direction == 0)
      return false;
   return direction == bias;
}

void AddScore(int &score, string &reason, const string tag)
{
   score++;
   AppendReason(reason, tag);
}

void AppendReason(string &reason, const string tag)
{
   if(tag == "") return;
   if(reason == "") reason = tag;
   else if(StringFind(reason, tag) < 0) reason += "+" + tag;
}

double HighestHigh(const int startShift, const int count)
{
   double value = -DBL_MAX;
   for(int i = startShift; i < startShift + count; i++)
      value = MathMax(value, iHigh(_Symbol, PERIOD_CURRENT, i));
   return value;
}

double LowestLow(const int startShift, const int count)
{
   double value = DBL_MAX;
   for(int i = startShift; i < startShift + count; i++)
      value = MathMin(value, iLow(_Symbol, PERIOD_CURRENT, i));
   return value;
}

int ApplyAdaptiveBias(const int direction)
{
   double trend1 = BufferValue(hTrendEMA, 0, 1);
   double trend6 = BufferValue(hTrendEMA, 0, 6);
   if(trend1 <= 0.0 || trend6 <= 0.0)
      return direction;

   double slopePts = (trend1 - trend6) / _Point;
   if(MathAbs(slopePts) < InpAdaptiveSlopeThresholdPts)
      return direction;

   if(slopePts > 0 && direction < 0)
      return 1;
   if(slopePts < 0 && direction > 0)
      return -1;
   return direction;
}

bool RiskAllowsNewTrade()
{
   if(InpMaxConsecutiveLosses > 0 && consecutiveLosses >= InpMaxConsecutiveLosses)
      return false;

   if(InpMaxEquityDrawdownPercent > 0.0 && startBalance > 0.0)
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double ddPct = 100.0 * (startBalance - equity) / startBalance;
      if(ddPct >= InpMaxEquityDrawdownPercent)
         return false;
   }

   if(PeriodProfit(PERIOD_D1) <= -AccountInfoDouble(ACCOUNT_BALANCE) * InpMaxDailyLossPercent / 100.0)
      return false;
   if(PeriodProfit(PERIOD_W1) <= -AccountInfoDouble(ACCOUNT_BALANCE) * InpMaxWeeklyLossPercent / 100.0)
      return false;
   if(PeriodProfit(PERIOD_MN1) <= -AccountInfoDouble(ACCOUNT_BALANCE) * InpMaxMonthlyLossPercent / 100.0)
      return false;

   if(InpUseProfitGivebackGuard && ProfitGivebackBlocked())
      return false;

   return true;
}

double PeriodProfit(const ENUM_TIMEFRAMES period)
{
   datetime from = iTime(_Symbol, period, 0);
   datetime to = TimeCurrent();
   if(!HistorySelect(from, to))
      return 0.0;

   double profit = 0.0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if((long)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      profit += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
   }
   return profit;
}

void ResetPeriodPeaks()
{
   datetime d = iTime(_Symbol, PERIOD_D1, 0);
   datetime w = iTime(_Symbol, PERIOD_W1, 0);
   datetime m = iTime(_Symbol, PERIOD_MN1, 0);
   if(d != dailyKey) { dailyKey = d; dailyPeakProfit = MathMax(0.0, PeriodProfit(PERIOD_D1)); }
   if(w != weeklyKey) { weeklyKey = w; weeklyPeakProfit = MathMax(0.0, PeriodProfit(PERIOD_W1)); }
   if(m != monthlyKey) { monthlyKey = m; monthlyPeakProfit = MathMax(0.0, PeriodProfit(PERIOD_MN1)); }
   dailyPeakProfit = MathMax(dailyPeakProfit, PeriodProfit(PERIOD_D1));
   weeklyPeakProfit = MathMax(weeklyPeakProfit, PeriodProfit(PERIOD_W1));
   monthlyPeakProfit = MathMax(monthlyPeakProfit, PeriodProfit(PERIOD_MN1));
}

bool ProfitGivebackBlocked()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double minProfit = balance * InpMinProfitToProtectPercent / 100.0;
   if(GivebackHit(PeriodProfit(PERIOD_D1), dailyPeakProfit, minProfit, InpDailyProfitGivebackPercent)) return true;
   if(GivebackHit(PeriodProfit(PERIOD_W1), weeklyPeakProfit, minProfit, InpWeeklyProfitGivebackPercent)) return true;
   if(GivebackHit(PeriodProfit(PERIOD_MN1), monthlyPeakProfit, minProfit, InpMonthlyProfitGivebackPercent)) return true;
   return false;
}

bool GivebackHit(const double currentProfit, const double peakProfit, const double minProfit, const double givebackPct)
{
   if(peakProfit < minProfit)
      return false;
   double allowedGiveback = peakProfit * givebackPct / 100.0;
   return (peakProfit - currentProfit) >= allowedGiveback;
}

void OpenTrade(const int direction, const double atr, const string reason)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entry = direction > 0 ? ask : bid;
   double slDistance = atr * InpStopATRMultiplier;
   double tpDistance = MathMax(atr * InpTakeProfitATRMultiplier, slDistance * InpMinRiskReward);
   double sl = direction > 0 ? entry - slDistance : entry + slDistance;
   double tp = direction > 0 ? entry + tpDistance : entry - tpDistance;
   double lots = CalculateLots(entry, sl);
   if(lots <= 0.0)
      return;

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   bool ok = false;
   if(direction > 0)
      ok = trade.Buy(lots, _Symbol, ask, sl, tp, reason);
   else
      ok = trade.Sell(lots, _Symbol, bid, sl, tp, reason);

   if(InpLogLevel > 0 && ok)
      Print("Opened ", direction > 0 ? "BUY" : "SELL", " lots=", lots, " reason=", reason);
}

double CalculateLots(const double entry, const double sl)
{
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double distance = MathAbs(entry - sl);
   if(riskMoney <= 0.0 || distance <= 0.0 || minLot <= 0.0 || maxLot <= 0.0 || step <= 0.0)
      return 0.0;

   ENUM_ORDER_TYPE orderType = sl < entry ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double profitForOneLot = 0.0;
   double moneyPerLot = 0.0;
   if(OrderCalcProfit(orderType, _Symbol, 1.0, entry, sl, profitForOneLot))
      moneyPerLot = MathAbs(profitForOneLot);

   if(moneyPerLot <= 0.0)
   {
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize <= 0.0 || tickValue <= 0.0)
         return 0.0;
      moneyPerLot = distance / tickSize * tickValue;
   }

   if(moneyPerLot <= 0.0)
      return 0.0;

   double rawLots = riskMoney / moneyPerLot;
   double lots = MathFloor(rawLots / step) * step;
   if(lots < minLot)
      return 0.0;

   lots = MathMin(maxLot, lots);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double requiredMargin = 0.0;
   while(lots >= minLot)
   {
      requiredMargin = 0.0;
      if(!OrderCalcMargin(orderType, _Symbol, lots, entry, requiredMargin))
         return 0.0;
      if(requiredMargin <= freeMargin)
         break;
      lots = MathFloor((lots - step) / step) * step;
   }

   if(lots < minLot)
      return 0.0;

   return NormalizeDouble(lots, 2);
}

void ManageOpenPosition()
{
   if(!PositionSelect(_Symbol))
      return;
   if((long)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
      return;

   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl = PositionGetDouble(POSITION_SL);
   double tp = PositionGetDouble(POSITION_TP);
   double atr = BufferValue(hATR, 0, 1);
   if(atr <= 0.0)
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double price = type == POSITION_TYPE_BUY ? bid : ask;
   double profitDistance = type == POSITION_TYPE_BUY ? price - openPrice : openPrice - price;
   double newSl = sl;

   if(InpUseBreakEven && profitDistance >= atr * InpBreakEvenTriggerATR)
   {
      double be = type == POSITION_TYPE_BUY ? openPrice + atr * InpBreakEvenOffsetATR : openPrice - atr * InpBreakEvenOffsetATR;
      if(type == POSITION_TYPE_BUY && (sl == 0.0 || be > sl)) newSl = be;
      if(type == POSITION_TYPE_SELL && (sl == 0.0 || be < sl)) newSl = be;
   }

   if(InpUseATRTrailing && profitDistance > atr)
   {
      double trail = type == POSITION_TYPE_BUY ? price - atr * InpTrailingATRMultiplier : price + atr * InpTrailingATRMultiplier;
      if(type == POSITION_TYPE_BUY && (newSl == 0.0 || trail > newSl)) newSl = trail;
      if(type == POSITION_TYPE_SELL && (newSl == 0.0 || trail < newSl)) newSl = trail;
   }

   if(newSl != sl && newSl > 0.0)
      trade.PositionModify(_Symbol, NormalizeDouble(newSl, _Digits), tp);
}

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;
   ulong deal = trans.deal;
   if(deal == 0) return;
   if(!HistoryDealSelect(deal)) return;
   if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol) return;
   if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagicNumber) return;
   if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT) return;

   double profit = HistoryDealGetDouble(deal, DEAL_PROFIT) + HistoryDealGetDouble(deal, DEAL_SWAP) + HistoryDealGetDouble(deal, DEAL_COMMISSION);
   if(profit < 0.0)
   {
      consecutiveLosses++;
      if(InpCooldownMinutesAfterLoss > 0)
         cooldownUntil = TimeCurrent() + InpCooldownMinutesAfterLoss * 60;
   }
   else
   {
      consecutiveLosses = 0;
   }
}

void DrawDashboard()
{
   string text = "Professional XAUUSD EA\n";
   text += "Spread: " + IntegerToString(SpreadPoints()) + " pts\n";
   text += "ATR: " + DoubleToString(BufferValue(hATR, 0, 1), _Digits) + "\n";
   text += "Loss streak: " + IntegerToString(consecutiveLosses) + "\n";
   text += "Daily P/L: " + DoubleToString(PeriodProfit(PERIOD_D1), 2) + "\n";
   text += "Weekly P/L: " + DoubleToString(PeriodProfit(PERIOD_W1), 2) + "\n";
   text += "Monthly P/L: " + DoubleToString(PeriodProfit(PERIOD_MN1), 2);
   Comment(text);
}

double OnTester()
{
   double profit = TesterStatistics(STAT_PROFIT);
   double drawdown = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   double pf = TesterStatistics(STAT_PROFIT_FACTOR);
   double trades = TesterStatistics(STAT_TRADES);
   double sharpe = TesterStatistics(STAT_SHARPE_RATIO);
   double recovery = TesterStatistics(STAT_RECOVERY_FACTOR);

   if(InpTesterFitnessMode == 0)
      return profit;

   double score = profit;
   if(drawdown > InpTesterMaxDrawdownPercent) score -= (drawdown - InpTesterMaxDrawdownPercent) * InpTesterDrawdownPenalty * 100.0;
   if(pf < InpTesterMinProfitFactor) score -= (InpTesterMinProfitFactor - pf) * 1000.0;
   if(trades < InpTesterMinTrades) score -= (InpTesterMinTrades - trades) * InpTesterTradeCountPenalty * 100.0;

   if(InpTesterFitnessMode == 2)
      score += recovery * 100.0 + sharpe * 25.0;

   return score;
}

#property strict
#property version   "1.53"
#property description "Research-only three-lane XAUUSD portfolio with base-eligible residual-risk allocation"

#include <Trade/Trade.mqh>

input group "Portfolio Identity and Safety"
input string InpAllowedSymbol = "XAUUSD";
input ulong  InpPortfolioMagic = 26071781;
input bool   InpUseSymbolSafetyLock = true;
input bool   InpRequireHedgingAccount = true;
input bool   InpUseRealAccountSafetyLock = true;
input bool   InpAllowRealAccountTrading = false;
input string InpRealAccountApprovalCode = "DISABLED";
input bool   InpUseInitialBalanceContract = true;
input double InpExpectedInitialBalance = 10000.0;
input double InpInitialBalanceTolerancePercent = 1.0;
input bool   InpUseAccountCurrencyLock = true;
input string InpRequiredAccountCurrency = "USD";
input bool   InpUseDedicatedAccountContract = true;
input bool   InpRejectFundingChangesAfterRegistration = true;

input group "Shared Risk Manager"
input double InpMaximumPortfolioEquityDrawdownPercent = 5.00;
input double InpMaximumPortfolioDailyLossPercent = 0.75;
input double InpMaximumPortfolioWeeklyLossPercent = 1.25;
input double InpMaximumPortfolioMonthlyLossPercent = 1.50;
input int    InpMaximumPortfolioConsecutiveLosses = 9;
input int    InpPortfolioLossCooldownHours = 48;
input double InpMaximumPortfolioOpenRiskPercent = 0.75;
input int    InpMaximumAccountPositions = 3;
input double InpMinimumMarginLevelPercent = 300.0;
input bool   InpBlockUnprotectedAccountExposure = true;
input bool   InpCloseUnprotectedManagedPositions = true;
input bool   InpUseTradeEnvironmentGuard = true;
input int    InpMaximumQuoteAgeSeconds = 30;
input double InpMaximumStopsLevelPoints = 250.0;
input double InpMaximumFreezeLevelPoints = 250.0;
input bool   InpRequireConfirmedTradeResults = true;
input bool   InpUsePostFillRiskReconciliation = true;
input double InpPostFillRiskTolerancePercent = 0.005;

input group "Residual Risk Allocation Research"
input bool   InpUseResidualRiskAllocation = false;
input double InpResidualRiskReservePercent = 0.05;
input double InpRVMaximumEntryRiskPercent = 0.45;
input double InpMOMaximumEntryRiskPercent = 0.15;
input double InpATBMaximumEntryRiskPercent = 0.10;

input group "H1 Band VWAP Reversion Lane"
input bool   InpRVEnabled = true;
input ulong  InpRVMagicNumber = 26071721;
input double InpRVRiskPercent = 0.45;
input ENUM_TIMEFRAMES InpRVSignalTimeframe = PERIOD_H1;
input int    InpRVATRPeriod = 14;
input int    InpRVADXPeriod = 14;
input int    InpRVRSIPeriod = 14;
input int    InpRVBollingerPeriod = 20;
input double InpRVBollingerDeviation = 2.00;
input int    InpRVVWAPLookbackBars = 48;
input int    InpRVMaximumMonthlyEntries = 16;
input int    InpRVEntrySpacingMinutes = 240;
input double InpRVMaximumADX = 22.0;
input double InpRVBuyMaximumRSI = 40.0;
input double InpRVSellMinimumRSI = 60.0;
input double InpRVMinimumBandPenetrationATR = 0.0;
input double InpRVMinimumBandWidthATR = 1.0;
input double InpRVMaximumBandWidthATR = 4.5;
input double InpRVMinimumWickPercent = 15.0;
input double InpRVMinimumCloseLocation = 0.55;
input int    InpRVStopLookbackBars = 5;
input double InpRVStopBufferATR = 0.10;
input double InpRVStopBufferPoints = 20.0;
input double InpRVMaximumStopATR = 2.20;
input double InpRVMinimumTargetATR = 0.40;
input double InpRVMinimumRiskReward = 1.20;
input double InpRVMaximumSpreadATRPercent = 18.0;
input bool   InpRVUseDIEdgeGate = true;
input double InpRVMinimumDIEdge = -12.0;
input bool   InpRVUseD1MomentumCap = false;
input int    InpRVD1MomentumLookbackBars = 126;
input double InpRVMaximumAbsoluteD1MomentumPercent = 12.0;
input double InpRVMaximumPositionLots = 0.10;
input int    InpRVMaximumDailyLossCount = 1;
input double InpRVMaximumDailyLossPercent = 0.75;
input double InpRVMaximumSpreadPoints = 220.0;
input int    InpRVDeviationPoints = 25;

input group "Multiscale Momentum Lane"
input bool   InpMOEnabled = true;
input ulong  InpMOMagicNumber = 26071761;
input double InpMORiskPercent = 0.15;
input ENUM_TIMEFRAMES InpMOSignalTimeframe = PERIOD_H1;
input ENUM_TIMEFRAMES InpMOMomentumTimeframe = PERIOD_D1;
input int    InpMOMomentumLookbackBars = 126;
input int    InpMOEntryLookbackBars = 20;
input double InpMOBreakoutBufferATR = 0.05;
input bool   InpMOAllowBuy = true;
input bool   InpMOAllowSell = true;
input bool   InpMORequireFreshBreakout = true;
input bool   InpMOUseVolatilityFilter = true;
input double InpMOMinimumATRPercent = 0.03;
input double InpMOMaximumATRPercent = 2.50;
input int    InpMOATRPeriod = 20;
input int    InpMOStopLookbackBars = 5;
input double InpMOStopBufferATR = 0.10;
input double InpMOMinimumStopATR = 0.40;
input double InpMOMaximumStopATR = 2.50;
input double InpMOMaximumStopPriceDistance = 10.00;
input double InpMOTakeProfitR = 2.00;
input bool   InpMOUseBreakEven = true;
input double InpMOBreakEvenTriggerR = 1.00;
input double InpMOBreakEvenLockR = 0.10;
input bool   InpMOUseChannelExit = true;
input int    InpMOExitLookbackBars = 5;
input bool   InpMOUseMomentumFailureExit = true;
input int    InpMOMaximumHoldBars = 120;
input bool   InpMOUseSessionFilter = true;
input int    InpMOSessionStartHour = 6;
input int    InpMOSessionEndHour = 20;
input bool   InpMODisableFridayAfterHour = true;
input int    InpMOFridayCutoffHour = 18;
input double InpMOMaximumPositionLots = 1.00;
input int    InpMOMaximumTradesPerDay = 2;
input double InpMOMaximumDailyLossPercent = 0.75;
input int    InpMOMaximumConsecutiveLosses = 4;
input int    InpMOLossCooldownHours = 24;
input double InpMOMaximumSpreadPoints = 50.0;
input int    InpMODeviationPoints = 20;

input group "Independent Adaptive H4/D1 Trend Breakout Lane"
input bool   InpATBEnabled = true;
input ulong  InpATBMagicNumber = 26071971;
input double InpATBRiskPercent = 0.10;
input ENUM_TIMEFRAMES InpATBSignalTimeframe = PERIOD_H4;
input ENUM_TIMEFRAMES InpATBMomentumTimeframe = PERIOD_D1;
input int    InpATBMomentumLookbackBars = 126;
input bool   InpATBUseLongMomentumAgreement = false;
input int    InpATBEntryLookbackBars = 20;
input double InpATBBreakoutBufferATR = 0.05;
input bool   InpATBAllowBuy = true;
input bool   InpATBAllowSell = true;
input bool   InpATBRequireFreshBreakout = true;
input bool   InpATBUseTrendEMAFilter = true;
input int    InpATBTrendFastEMAPeriod = 20;
input int    InpATBTrendSlowEMAPeriod = 100;
input int    InpATBTrendSlopeLookbackBars = 5;
input double InpATBMinimumTrendSlopeATR = 0.00;
input bool   InpATBUseSignalEMAFilter = true;
input int    InpATBSignalEMAPeriod = 50;
input int    InpATBSignalEMASlopeLookbackBars = 3;
input double InpATBMinimumSignalSlopeATR = 0.00;
input bool   InpATBUseADXFilter = true;
input int    InpATBADXPeriod = 14;
input double InpATBMinimumADX = 14.0;
input double InpATBMaximumADX = 50.0;
input bool   InpATBUseBreakoutQualityFilter = true;
input double InpATBMinimumBreakoutBodyPercent = 35.0;
input double InpATBMinimumBreakoutCloseLocationPercent = 60.0;
input double InpATBMinimumBreakoutRangeATR = 0.40;
input double InpATBMaximumBreakoutRangeATR = 2.50;
input bool   InpATBUseTickVolumeExpansion = false;
input int    InpATBTickVolumeLookbackBars = 20;
input double InpATBMinimumTickVolumeRatio = 1.00;
input bool   InpATBUseVolatilityFilter = true;
input double InpATBMinimumATRPercent = 0.03;
input double InpATBMaximumATRPercent = 2.50;
input int    InpATBATRPeriod = 20;
input int    InpATBStopLookbackBars = 8;
input double InpATBStopBufferATR = 0.10;
input double InpATBMinimumStopATR = 0.80;
input double InpATBMaximumStopATR = 3.00;
input double InpATBMaximumStopPriceDistance = 40.00;
input double InpATBTakeProfitR = 2.00;
input bool   InpATBUseBreakEven = true;
input double InpATBBreakEvenTriggerR = 1.00;
input double InpATBBreakEvenLockR = 0.10;
input bool   InpATBUseChannelExit = true;
input int    InpATBExitLookbackBars = 10;
input bool   InpATBUseMomentumFailureExit = true;
input int    InpATBMaximumHoldBars = 180;
input bool   InpATBUseSessionFilter = false;
input int    InpATBSessionStartHour = 6;
input int    InpATBSessionEndHour = 20;
input bool   InpATBDisableFridayAfterHour = true;
input int    InpATBFridayCutoffHour = 18;
input double InpATBMaximumPositionLots = 1.00;
input int    InpATBMaximumTradesPerDay = 2;
input double InpATBMaximumDailyLossPercent = 0.75;
input int    InpATBMaximumConsecutiveLosses = 4;
input int    InpATBLossCooldownHours = 24;
input double InpATBMaximumSpreadPoints = 50.0;
input int    InpATBDeviationPoints = 20;

input string InpATBLogFileName = "THREE_LANE_ATB_EVENTS.csv";

input group "Evidence and Dashboard"
input bool   InpLogTrades = false;
input string InpRVLogFileName = "TRANSFERABLE_PORTFOLIO_RV_EVENTS.csv";
input string InpMOLogFileName = "TRANSFERABLE_PORTFOLIO_MO_EVENTS.csv";
input string InpEvidenceSourceHash = "";
input string InpEvidenceRunLabel = "";
input bool   InpShowDashboard = false;

double g_peakEquity = 0.0;
datetime g_dayStart = 0;
string g_sharedSafetyReason = "initializing";
CTrade g_guardTrade;
bool g_portfolioRiskStateDirty = true;
datetime g_cachedDayStart = 0;
datetime g_cachedWeekStart = 0;
datetime g_cachedMonthStart = 0;
double g_cachedDailyProfit = 0.0;
double g_cachedWeeklyProfit = 0.0;
double g_cachedMonthlyProfit = 0.0;
int g_cachedPortfolioLossStreak = 0;
datetime g_cachedPortfolioLastLoss = 0;
bool g_accountHistoryStateDirty = true;
bool g_cachedAccountHistoryValid = false;
string g_cachedAccountHistoryReason = "not evaluated";
bool g_persistenceHealthy = true;

bool IsPortfolioMagic(const ulong magic)
{
   return magic == InpPortfolioMagic || magic == InpRVMagicNumber || magic == InpMOMagicNumber || magic == InpATBMagicNumber;
}

bool VerifiedGlobalSet(const string key, const double value)
{
   if(StringLen(key) <= 0 || !MathIsValidNumber(value) || !GlobalVariableSet(key, value) ||
      !GlobalVariableCheck(key) || MathAbs(GlobalVariableGet(key) - value) > 1e-8)
   {
      g_persistenceHealthy = false;
      return false;
   }
   return true;
}

bool VerifiedGlobalDelete(const string key)
{
   if(!GlobalVariableCheck(key))
      return true;
   if(!GlobalVariableDel(key) || GlobalVariableCheck(key))
   {
      g_persistenceHealthy = false;
      return false;
   }
   return true;
}

bool TradeResultAllows(CTrade &trade, const bool allowNoChanges = false)
{
   if(!InpRequireConfirmedTradeResults)
      return true;
   uint retcode = trade.ResultRetcode();
   return retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_DONE_PARTIAL ||
          (allowNoChanges && retcode == TRADE_RETCODE_NO_CHANGES);
}

bool SelectOwnedPosition(const ulong ticket, const ulong magic)
{
   return ticket > 0 && PositionSelectByTicket(ticket) &&
          PositionGetString(POSITION_SYMBOL) == _Symbol &&
          (ulong)PositionGetInteger(POSITION_MAGIC) == magic && IsPortfolioMagic(magic);
}

bool FindOnlyOwnedPosition(const ulong magic, ulong &ticket, string &reason)
{
   ticket = 0;
   int matches = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong candidate = PositionGetTicket(i);
      if(candidate == 0 || !PositionSelectByTicket(candidate) ||
         PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != magic)
         continue;
      ticket = candidate;
      matches++;
   }
   if(matches != 1)
   {
      reason = "owned position count after fill";
      ticket = 0;
      return false;
   }
   reason = "allowed";
   return true;
}

int CountOwnedMagicOrders(const ulong magic)
{
   int matches = 0;
   for(int i = OrdersTotal() - 1; i >= 0; --i)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 && OrderGetString(ORDER_SYMBOL) == _Symbol &&
         (ulong)OrderGetInteger(ORDER_MAGIC) == magic)
         matches++;
   }
   return matches;
}

int CountOwnedPortfolioOrders()
{
   int matches = 0;
   for(int i = OrdersTotal() - 1; i >= 0; --i)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 && OrderGetString(ORDER_SYMBOL) == _Symbol &&
         IsPortfolioMagic((ulong)OrderGetInteger(ORDER_MAGIC)))
         matches++;
   }
   return matches;
}

int CountOwnedMagicPositions(const ulong magic)
{
   int matches = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == magic)
         matches++;
   }
   return matches;
}

bool DeleteOwnedOrder(CTrade &trade,
                      const ulong ticket,
                      const ulong magic,
                      string &reason)
{
   if(ticket == 0 || !OrderSelect(ticket) || OrderGetString(ORDER_SYMBOL) != _Symbol ||
      (ulong)OrderGetInteger(ORDER_MAGIC) != magic || !IsPortfolioMagic(magic))
   {
      reason = "delete ownership";
      return false;
   }
   if(!trade.OrderDelete(ticket) || !TradeResultAllows(trade, false))
   {
      if(!OrderSelect(ticket))
      {
         reason = "order no longer active";
         return true;
      }
      reason = "delete result";
      return false;
   }
   if(OrderSelect(ticket))
   {
      reason = "delete not confirmed";
      return false;
   }
   reason = "deleted";
   return true;
}

bool DeleteOwnedMagicOrders(CTrade &trade, const ulong magic, string &reason)
{
   bool allDeleted = true;
   reason = "deleted";
   for(int i = OrdersTotal() - 1; i >= 0; --i)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || OrderGetString(ORDER_SYMBOL) != _Symbol ||
         (ulong)OrderGetInteger(ORDER_MAGIC) != magic)
         continue;
      string deleteReason = "";
      if(!DeleteOwnedOrder(trade, ticket, magic, deleteReason))
      {
         allDeleted = false;
         reason = deleteReason;
      }
   }
   return allDeleted && CountOwnedMagicOrders(magic) == 0;
}

bool DeleteOwnedPortfolioOrders(CTrade &trade, string &reason)
{
   bool allDeleted = true;
   reason = "deleted";
   for(int i = OrdersTotal() - 1; i >= 0; --i)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      ulong magic = (ulong)OrderGetInteger(ORDER_MAGIC);
      if(!IsPortfolioMagic(magic))
         continue;
      string deleteReason = "";
      if(!DeleteOwnedOrder(trade, ticket, magic, deleteReason))
      {
         allDeleted = false;
         reason = deleteReason;
      }
   }
   return allDeleted && CountOwnedPortfolioOrders() == 0;
}

bool CloseOwnedPosition(CTrade &trade,
                        const ulong ticket,
                        const ulong magic,
                        string &reason)
{
   if(!SelectOwnedPosition(ticket, magic))
   {
      reason = "close ownership";
      return false;
   }
   if(!trade.PositionClose(ticket) || !TradeResultAllows(trade, false))
   {
      reason = "close result";
      return false;
   }
   if(PositionSelectByTicket(ticket))
   {
      reason = "close not confirmed";
      return false;
   }
   reason = "closed";
   return true;
}

bool CloseOwnedMagicPositions(CTrade &trade, const ulong magic, string &reason)
{
   bool allClosed = true;
   reason = "closed";
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket) ||
         PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != magic)
         continue;
      string closeReason = "";
      if(!CloseOwnedPosition(trade, ticket, magic, closeReason))
      {
         allClosed = false;
         reason = closeReason;
      }
   }
   return allClosed;
}

bool ModifyOwnedPosition(CTrade &trade,
                         const ulong ticket,
                         const ulong magic,
                         const double requestedSl,
                         const double requestedTp,
                         string &reason)
{
   if(!SelectOwnedPosition(ticket, magic))
   {
      reason = "modify ownership";
      return false;
   }
   long positionType = PositionGetInteger(POSITION_TYPE);
   double oldSl = PositionGetDouble(POSITION_SL);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tolerance = MathMax(_Point, tickSize) * 0.5;
   if(oldSl <= 0.0 || requestedSl <= 0.0 || !MathIsValidNumber(requestedSl) ||
      !MathIsValidNumber(requestedTp))
   {
      reason = "modify geometry";
      return false;
   }
   bool buy = positionType == POSITION_TYPE_BUY;
   if((buy && requestedSl + tolerance < oldSl) ||
      (!buy && requestedSl - tolerance > oldSl))
   {
      reason = "stop must tighten";
      return false;
   }
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.bid <= 0.0 || tick.ask <= 0.0)
   {
      reason = "modify quote";
      return false;
   }
   double minimumDistance = MathMax((double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL),
                                    (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL)) * _Point;
   if((buy && requestedSl >= tick.bid - minimumDistance) ||
      (!buy && requestedSl <= tick.ask + minimumDistance))
   {
      reason = "modify stops/freeze level";
      return false;
   }
   if(!trade.PositionModify(ticket, requestedSl, requestedTp) ||
      !TradeResultAllows(trade, true) || !SelectOwnedPosition(ticket, magic) ||
      MathAbs(PositionGetDouble(POSITION_SL) - requestedSl) > tolerance)
   {
      reason = "modify not confirmed";
      return false;
   }
   reason = "modified";
   return true;
}

string PeakEquityKey()
{
   return "XAU_TLP_PEAK_" + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
          "_" + IntegerToString((long)InpPortfolioMagic);
}

string InitialBalanceContractKey()
{
   return "XAU_TLP3_CAP_" + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
          "_" + IntegerToString((long)InpPortfolioMagic);
}

string FundingCountContractKey()
{
   return "XAU_TLP3_FUND_" + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
          "_" + IntegerToString((long)InpPortfolioMagic);
}

bool IsFundingDealType(const ENUM_DEAL_TYPE dealType)
{
   return dealType == DEAL_TYPE_BALANCE || dealType == DEAL_TYPE_CREDIT ||
          dealType == DEAL_TYPE_CHARGE || dealType == DEAL_TYPE_CORRECTION ||
          dealType == DEAL_TYPE_BONUS || dealType == DEAL_TYPE_COMMISSION ||
          dealType == DEAL_TYPE_COMMISSION_DAILY || dealType == DEAL_TYPE_COMMISSION_MONTHLY ||
          dealType == DEAL_TYPE_COMMISSION_AGENT_DAILY ||
          dealType == DEAL_TYPE_COMMISSION_AGENT_MONTHLY ||
          dealType == DEAL_TYPE_INTEREST;
}

bool AccountHistoryContractSnapshot(int &fundingCount, int &foreignTradeCount)
{
   fundingCount = 0;
   foreignTradeCount = 0;
   if(!HistorySelect(0, TimeCurrent()))
      return false;
   for(int i = 0; i < HistoryDealsTotal(); ++i)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0)
         continue;
      ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
      if(IsFundingDealType(dealType))
      {
         fundingCount++;
         continue;
      }
      if(dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL)
      {
         string dealSymbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         ulong dealMagic = (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC);
         if(dealSymbol != InpAllowedSymbol || !IsPortfolioMagic(dealMagic))
            foreignTradeCount++;
      }
   }
   return true;
}

bool RuntimeAccountHistoryContractAllows(string &reason)
{
   if(MQLInfoInteger(MQL_TESTER) ||
      (!InpUseDedicatedAccountContract && !InpRejectFundingChangesAfterRegistration))
   {
      reason = "allowed";
      return true;
   }
   if(!g_accountHistoryStateDirty)
   {
      reason = g_cachedAccountHistoryReason;
      return g_cachedAccountHistoryValid;
   }
   int fundingCount = 0;
   int foreignTradeCount = 0;
   if(!AccountHistoryContractSnapshot(fundingCount, foreignTradeCount))
   {
      g_cachedAccountHistoryValid = false;
      g_cachedAccountHistoryReason = "account history unavailable";
   }
   else if(InpUseDedicatedAccountContract && foreignTradeCount > 0)
   {
      g_cachedAccountHistoryValid = false;
      g_cachedAccountHistoryReason = "dedicated-account history contract";
   }
   else if(InpRejectFundingChangesAfterRegistration &&
           (!GlobalVariableCheck(FundingCountContractKey()) ||
            (int)MathRound(GlobalVariableGet(FundingCountContractKey())) != fundingCount))
   {
      g_cachedAccountHistoryValid = false;
      g_cachedAccountHistoryReason = "account funding changed after registration";
   }
   else
   {
      g_cachedAccountHistoryValid = true;
      g_cachedAccountHistoryReason = "allowed";
   }
   g_accountHistoryStateDirty = false;
   reason = g_cachedAccountHistoryReason;
   return g_cachedAccountHistoryValid;
}

datetime StartOfWeek(const datetime value)
{
   MqlDateTime parts;
   if(!TimeToStruct(value, parts))
      return 0;
   parts.hour = 0;
   parts.min = 0;
   parts.sec = 0;
   datetime dayStart = StructToTime(parts);
   int daysSinceMonday = (parts.day_of_week + 6) % 7;
   return dayStart - daysSinceMonday * 86400;
}

datetime StartOfMonth(const datetime value)
{
   MqlDateTime parts;
   if(!TimeToStruct(value, parts))
      return 0;
   parts.day = 1;
   parts.hour = 0;
   parts.min = 0;
   parts.sec = 0;
   return StructToTime(parts);
}

bool InitialAccountContractAllows(string &reason)
{
   if(InpUseAccountCurrencyLock &&
      AccountInfoString(ACCOUNT_CURRENCY) != InpRequiredAccountCurrency)
   {
      reason = "account currency contract";
      return false;
   }
   if(MQLInfoInteger(MQL_TESTER))
   {
      if(InpUseInitialBalanceContract)
      {
         double testerBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         double testerTolerance = InpExpectedInitialBalance * InpInitialBalanceTolerancePercent / 100.0;
         if(testerBalance <= 0.0 || MathAbs(testerBalance - InpExpectedInitialBalance) > testerTolerance)
         {
            reason = "starting-capital contract";
            return false;
         }
      }
      reason = "allowed";
      return true;
   }

   int fundingCount = 0;
   int foreignTradeCount = 0;
   if((InpUseDedicatedAccountContract || InpRejectFundingChangesAfterRegistration) &&
      !AccountHistoryContractSnapshot(fundingCount, foreignTradeCount))
   {
      reason = "account history unavailable";
      return false;
   }
   if(InpUseDedicatedAccountContract && foreignTradeCount > 0)
   {
      reason = "dedicated-account history contract";
      return false;
   }

   bool balanceContractExists = false;
   if(InpUseInitialBalanceContract)
   {
      string key = InitialBalanceContractKey();
      if(GlobalVariableCheck(key))
      {
         if(MathAbs(GlobalVariableGet(key) - InpExpectedInitialBalance) > 0.01)
         {
            reason = "stored starting-capital contract";
            return false;
         }
         balanceContractExists = true;
      }
      else
      {
         double balance = AccountInfoDouble(ACCOUNT_BALANCE);
         double tolerance = InpExpectedInitialBalance * InpInitialBalanceTolerancePercent / 100.0;
         if(balance <= 0.0 || MathAbs(balance - InpExpectedInitialBalance) > tolerance)
         {
            reason = "starting-capital contract";
            return false;
         }
      }
   }

   if(InpRejectFundingChangesAfterRegistration)
   {
      string fundingKey = FundingCountContractKey();
      if(GlobalVariableCheck(fundingKey))
      {
         if((int)MathRound(GlobalVariableGet(fundingKey)) != fundingCount)
         {
            reason = "account funding changed after registration";
            return false;
         }
      }
      else
      {
         if(balanceContractExists)
         {
            reason = "funding contract persistence missing";
            return false;
         }
         if(!VerifiedGlobalSet(fundingKey, (double)fundingCount))
         {
            reason = "funding contract persistence";
            return false;
         }
      }
   }

   if(InpUseInitialBalanceContract && !balanceContractExists &&
      !VerifiedGlobalSet(InitialBalanceContractKey(), InpExpectedInitialBalance))
   {
      reason = "starting-capital contract persistence";
      return false;
   }
   g_accountHistoryStateDirty = true;
   reason = "allowed";
   return true;
}

void RefreshDayState()
{
   datetime current = iTime(_Symbol, PERIOD_D1, 0);
   if(current > 0)
      g_dayStart = current;
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

double RequestedLaneRiskPercent(const double baseRiskPercent,
                                const double maximumEntryRiskPercent)
{
   if(!InpUseResidualRiskAllocation)
      return baseRiskPercent;

   bool hasUnprotected = false;
   int positionCount = 0;
   double openRiskPercent = AccountWideOpenRiskPercent(hasUnprotected, positionCount);
   if(openRiskPercent < 0.0 || (hasUnprotected && InpBlockUnprotectedAccountExposure))
      return 0.0;

   double expansionCap = InpMaximumPortfolioOpenRiskPercent -
                         InpResidualRiskReservePercent;
   double availableRiskPercent = expansionCap - openRiskPercent;
   if(availableRiskPercent <= baseRiskPercent)
      return baseRiskPercent;
   return MathMin(maximumEntryRiskPercent, availableRiskPercent);
}

double ClosedPortfolioProfitSince(const datetime fromTime)
{
   if(fromTime <= 0 || !HistorySelect(fromTime, TimeCurrent()))
      return 0.0;
   double profit = 0.0;
   for(int i = 0; i < HistoryDealsTotal(); ++i)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
         !IsPortfolioMagic((ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC)))
         continue;
      long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
         continue;
      profit += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                HistoryDealGetDouble(ticket, DEAL_SWAP) +
                HistoryDealGetDouble(ticket, DEAL_COMMISSION);
   }
   return profit;
}

void PortfolioLossStreak(int &streak, datetime &lastLossTime)
{
   streak = 0;
   lastLossTime = 0;
   if(!HistorySelect(0, TimeCurrent()))
      return;
   for(int i = HistoryDealsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
         !IsPortfolioMagic((ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC)))
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

void RefreshPortfolioRiskState()
{
   datetime weekStart = StartOfWeek(TimeCurrent());
   datetime monthStart = StartOfMonth(TimeCurrent());
   if(!g_portfolioRiskStateDirty && g_cachedDayStart == g_dayStart &&
      g_cachedWeekStart == weekStart && g_cachedMonthStart == monthStart)
      return;
   g_cachedDayStart = g_dayStart;
   g_cachedWeekStart = weekStart;
   g_cachedMonthStart = monthStart;
   g_cachedDailyProfit = ClosedPortfolioProfitSince(g_dayStart);
   g_cachedWeeklyProfit = ClosedPortfolioProfitSince(weekStart);
   g_cachedMonthlyProfit = ClosedPortfolioProfitSince(monthStart);
   PortfolioLossStreak(g_cachedPortfolioLossStreak, g_cachedPortfolioLastLoss);
   g_portfolioRiskStateDirty = false;
}

void AuditManagedPositionProtection()
{
   if(!InpCloseUnprotectedManagedPositions)
      return;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket) ||
         PositionGetString(POSITION_SYMBOL) != _Symbol ||
         !IsPortfolioMagic((ulong)PositionGetInteger(POSITION_MAGIC)) ||
         PositionGetDouble(POSITION_SL) > 0.0)
         continue;
      ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      string closeReason = "";
      if(!CloseOwnedPosition(g_guardTrade, ticket, magic, closeReason))
         Print("SAFETY: failed to close unprotected managed position; reason=", closeReason,
               "; retcode=", g_guardTrade.ResultRetcode());
      else
         Print("SAFETY: closed unprotected managed position");
   }
}

bool AuditManagedOrders()
{
   string reason = "";
   if(DeleteOwnedPortfolioOrders(g_guardTrade, reason))
      return true;
   g_persistenceHealthy = false;
   Print("SAFETY: failed to delete unexpected managed order; reason=", reason,
         "; retcode=", g_guardTrade.ResultRetcode());
   return false;
}

bool StaticSafetyAllows(string &reason)
{
   if(InpUseSymbolSafetyLock && _Symbol != InpAllowedSymbol)
   {
      reason = "symbol safety lock";
      return false;
   }
   if(InpRequireHedgingAccount &&
      AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
   {
      reason = "hedging account required";
      return false;
   }
   if(!MQLInfoInteger(MQL_TESTER) &&
      AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL &&
      (InpUseRealAccountSafetyLock || !InpAllowRealAccountTrading ||
       InpRealAccountApprovalCode != "TLP-LIVE-ACK-v1"))
   {
      reason = "real-account safety lock";
      return false;
   }
   reason = "allowed";
   return true;
}

bool TradeEnvironmentAllows(string &reason)
{
   if(!InpUseTradeEnvironmentGuard)
   {
      reason = "allowed";
      return true;
   }
   if(CountOwnedPortfolioOrders() > 0)
   {
      reason = "unexpected active portfolio order";
      return false;
   }
   if(!MQLInfoInteger(MQL_TESTER) &&
      (!TerminalInfoInteger(TERMINAL_CONNECTED) ||
       !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
       !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
       !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ||
       !AccountInfoInteger(ACCOUNT_TRADE_EXPERT)))
   {
      reason = "terminal/account trade permission";
      return false;
   }
   if(!SymbolInfoInteger(_Symbol, SYMBOL_SELECT))
   {
      reason = "symbol unavailable";
      return false;
   }
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.bid <= 0.0 || tick.ask <= 0.0 ||
      tick.ask < tick.bid || tick.time <= 0)
   {
      reason = "invalid quote";
      return false;
   }
   long quoteAge = (long)(TimeCurrent() - tick.time);
   if(InpMaximumQuoteAgeSeconds > 0 &&
      (quoteAge < 0 || quoteAge > InpMaximumQuoteAgeSeconds))
   {
      reason = "stale quote";
      return false;
   }
   long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freezeLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   if(stopsLevel < 0 || freezeLevel < 0 ||
      (InpMaximumStopsLevelPoints > 0.0 && stopsLevel > InpMaximumStopsLevelPoints) ||
      (InpMaximumFreezeLevelPoints > 0.0 && freezeLevel > InpMaximumFreezeLevelPoints))
   {
      reason = "symbol stops/freeze contract";
      return false;
   }
   reason = "allowed";
   return true;
}

bool SharedSafetyAllows(string &reason)
{
   if(!StaticSafetyAllows(reason) || !TradeEnvironmentAllows(reason))
      return false;
   if(!g_persistenceHealthy)
   {
      reason = "persistence health";
      return false;
   }
   if(!RuntimeAccountHistoryContractAllows(reason))
      return false;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
   {
      reason = "invalid equity";
      return false;
   }
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(InpMinimumMarginLevelPercent > 0.0 && margin > 0.0 &&
      (marginLevel <= 0.0 || marginLevel < InpMinimumMarginLevelPercent))
   {
      reason = "minimum margin level";
      return false;
   }
   if(g_peakEquity <= 0.0 || equity > g_peakEquity)
   {
      g_peakEquity = equity;
      if(!MQLInfoInteger(MQL_TESTER) && !VerifiedGlobalSet(PeakEquityKey(), g_peakEquity))
      {
         reason = "peak-equity persistence";
         return false;
      }
   }
   double drawdownPercent = 100.0 * (g_peakEquity - equity) / g_peakEquity;
   if(InpMaximumPortfolioEquityDrawdownPercent > 0.0 &&
      drawdownPercent >= InpMaximumPortfolioEquityDrawdownPercent)
   {
      reason = "portfolio equity drawdown limit";
      return false;
   }
   RefreshPortfolioRiskState();
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double dailyProfit = g_cachedDailyProfit;
   double dayStartBalance = balance - dailyProfit;
   if(InpMaximumPortfolioDailyLossPercent > 0.0 && dayStartBalance > 0.0 &&
      dailyProfit <= -dayStartBalance * InpMaximumPortfolioDailyLossPercent / 100.0)
   {
      reason = "portfolio daily loss limit";
      return false;
   }
   double weekStartBalance = balance - g_cachedWeeklyProfit;
   if(InpMaximumPortfolioWeeklyLossPercent > 0.0 && weekStartBalance > 0.0 &&
      g_cachedWeeklyProfit <= -weekStartBalance * InpMaximumPortfolioWeeklyLossPercent / 100.0)
   {
      reason = "portfolio weekly loss limit";
      return false;
   }
   double monthStartBalance = balance - g_cachedMonthlyProfit;
   if(InpMaximumPortfolioMonthlyLossPercent > 0.0 && monthStartBalance > 0.0 &&
      g_cachedMonthlyProfit <= -monthStartBalance * InpMaximumPortfolioMonthlyLossPercent / 100.0)
   {
      reason = "portfolio monthly loss limit";
      return false;
   }
   if(InpMaximumPortfolioConsecutiveLosses > 0 &&
      g_cachedPortfolioLossStreak >= InpMaximumPortfolioConsecutiveLosses &&
      g_cachedPortfolioLastLoss > 0 &&
      TimeCurrent() - g_cachedPortfolioLastLoss < InpPortfolioLossCooldownHours * 3600)
   {
      reason = "portfolio loss-streak cooldown";
      return false;
   }
   reason = "allowed";
   return true;
}

double NormalizeVolume(const double rawVolume, const double maximumLots)
{
   double minimum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maximum = MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), maximumLots);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(minimum <= 0.0 || maximum < minimum || step <= 0.0)
      return 0.0;
   double volume = MathFloor(rawVolume / step + 1e-8) * step;
   if(volume < minimum)
      return 0.0;
   return MathMin(volume, maximum);
}

double LotsForRisk(const bool buy,
                   const double entryPrice,
                   const double stopPrice,
                   const double riskPercent,
                   const double maximumLots)
{
   if(entryPrice <= 0.0 || stopPrice <= 0.0 || riskPercent <= 0.0)
      return 0.0;
   double lossPerLot = 0.0;
   ENUM_ORDER_TYPE orderType = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!RiskMoneyForOrder(_Symbol, orderType, entryPrice, stopPrice, 1.0, lossPerLot))
      return 0.0;
   double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * riskPercent / 100.0;
   return NormalizeVolume(riskMoney / lossPerLot, maximumLots);
}

bool AccountWideExposureAllows(const bool buy,
                               const double entryPrice,
                               const double stopPrice,
                               const double lots,
                               string &reason)
{
   bool hasUnprotected = false;
   int positionCount = 0;
   double openRiskPercent = AccountWideOpenRiskPercent(hasUnprotected, positionCount);
   if(openRiskPercent < 0.0)
   {
      reason = "account equity unavailable";
      return false;
   }
   if(hasUnprotected && InpBlockUnprotectedAccountExposure)
   {
      reason = "unprotected account exposure";
      return false;
   }
   if(InpMaximumAccountPositions <= 0 || positionCount >= InpMaximumAccountPositions)
   {
      reason = "account position limit";
      return false;
   }
   double addedRiskMoney = 0.0;
   ENUM_ORDER_TYPE orderType = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!RiskMoneyForOrder(_Symbol, orderType, entryPrice, stopPrice, lots, addedRiskMoney))
   {
      reason = "added risk calculation";
      return false;
   }
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0 || InpMaximumPortfolioOpenRiskPercent <= 0.0)
   {
      reason = "portfolio risk cap unavailable";
      return false;
   }
   if(openRiskPercent + 100.0 * addedRiskMoney / equity > InpMaximumPortfolioOpenRiskPercent)
   {
      reason = "portfolio open risk limit";
      return false;
   }
   reason = "allowed";
   return true;
}

bool RejectPostFill(CTrade &trade,
                    const ulong magic,
                    const string failure,
                    string &reason)
{
   string deleteReason = "";
   string closeReason = "";
   reason = failure;
   bool ordersDeleted = DeleteOwnedMagicOrders(trade, magic, deleteReason);
   bool positionsClosed = CloseOwnedMagicPositions(trade, magic, closeReason);
   if(CountOwnedMagicOrders(magic) > 0 || CountOwnedMagicPositions(magic) > 0)
   {
      ordersDeleted = DeleteOwnedMagicOrders(trade, magic, deleteReason) && ordersDeleted;
      positionsClosed = CloseOwnedMagicPositions(trade, magic, closeReason) && positionsClosed;
   }
   if(!ordersDeleted || !positionsClosed || CountOwnedMagicOrders(magic) > 0 ||
      CountOwnedMagicPositions(magic) > 0)
   {
      g_persistenceHealthy = false;
      reason += "; emergency cleanup failed: " + deleteReason + "/" + closeReason;
   }
   return false;
}

bool PostFillReconcile(CTrade &trade,
                       const ulong magic,
                       const bool expectedBuy,
                       const double laneRiskCapPercent,
                       const double maximumLots,
                       ulong &ticket,
                       string &reason)
{
   if(!FindOnlyOwnedPosition(magic, ticket, reason))
      return RejectPostFill(trade, magic, "owned position count after fill", reason);
   if(CountOwnedMagicOrders(magic) > 0)
      return RejectPostFill(trade, magic, "active order remains after fill", reason);
   if(!InpUsePostFillRiskReconciliation)
      return true;
   if(!SelectOwnedPosition(ticket, magic))
      return RejectPostFill(trade, magic, "post-fill ownership", reason);

   long positionType = PositionGetInteger(POSITION_TYPE);
   bool actualBuy = positionType == POSITION_TYPE_BUY;
   double volume = PositionGetDouble(POSITION_VOLUME);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double stopPrice = PositionGetDouble(POSITION_SL);
   double targetPrice = PositionGetDouble(POSITION_TP);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minimum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double brokerMaximum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(positionType != POSITION_TYPE_BUY && positionType != POSITION_TYPE_SELL)
      return RejectPostFill(trade, magic, "post-fill position type", reason);
   if(actualBuy != expectedBuy || volume <= 0.0 || volume < minimum - 1e-8 ||
      volume > MathMin(maximumLots, brokerMaximum) + 1e-8 || step <= 0.0 ||
      MathAbs(volume / step - MathRound(volume / step)) > 1e-6)
      return RejectPostFill(trade, magic, "post-fill volume/direction", reason);
   if(openPrice <= 0.0 || stopPrice <= 0.0 || targetPrice <= 0.0 ||
      (actualBuy && (stopPrice >= openPrice || targetPrice <= openPrice)) ||
      (!actualBuy && (stopPrice <= openPrice || targetPrice >= openPrice)))
      return RejectPostFill(trade, magic, "post-fill protection geometry", reason);

   bool unprotected = false;
   double positionRiskMoney = AccountPositionRiskMoney(ticket, unprotected);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(unprotected || positionRiskMoney <= 0.0 || equity <= 0.0)
      return RejectPostFill(trade, magic, "post-fill risk valuation", reason);
   double laneRiskPercent = 100.0 * positionRiskMoney / equity;
   if(laneRiskPercent > laneRiskCapPercent + InpPostFillRiskTolerancePercent)
      return RejectPostFill(trade, magic, "post-fill lane risk cap", reason);

   bool anyUnprotected = false;
   int positionCount = 0;
   double portfolioRiskPercent = AccountWideOpenRiskPercent(anyUnprotected, positionCount);
   if(portfolioRiskPercent < 0.0 || anyUnprotected ||
      positionCount > InpMaximumAccountPositions ||
      portfolioRiskPercent > InpMaximumPortfolioOpenRiskPercent + InpPostFillRiskTolerancePercent)
      return RejectPostFill(trade, magic, "post-fill portfolio reconciliation", reason);

   reason = "reconciled";
   return true;
}

void WriteEvidenceEvent(const int handle,
                        const string profileId,
                        const string eventName,
                        const ulong ticket,
                        const string side,
                        const double volume,
                        const double price,
                        const double sl,
                        const double profit,
                        const string reason)
{
   if(!InpLogTrades || handle == INVALID_HANDLE)
      return;
   FileWrite(handle,
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
             profileId,
             InpEvidenceSourceHash,
             InpEvidenceRunLabel);
   FileFlush(handle);
}

int OpenEvidenceFile(const string filename)
{
   if(!InpLogTrades)
      return INVALID_HANDLE;
   int handle = FileOpen(filename,
                         FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON |
                         FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(handle != INVALID_HANDLE)
      FileSeek(handle, 0, SEEK_END);
   return handle;
}

class CReversionLane
{
private:
   CTrade m_trade;
   int m_atrHandle;
   int m_adxHandle;
   int m_rsiHandle;
   int m_bandsHandle;
   int m_logHandle;
   datetime m_lastSignalBar;

   bool D1MomentumCapAllows()
   {
      if(!InpRVUseD1MomentumCap)
         return true;
      int lookback = MathMax(20, InpRVD1MomentumLookbackBars);
      double recentClose = iClose(_Symbol, PERIOD_D1, 1);
      double pastClose = iClose(_Symbol, PERIOD_D1, 1 + lookback);
      if(recentClose <= 0.0 || pastClose <= 0.0)
         return false;
      double absoluteMomentumPercent = 100.0 * MathAbs(recentClose - pastClose) / pastClose;
      return absoluteMomentumPercent <= InpRVMaximumAbsoluteD1MomentumPercent;
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
            (ulong)PositionGetInteger(POSITION_MAGIC) == InpRVMagicNumber)
            count++;
      }
      return count;
   }

   double ClosedProfitSince(const datetime fromTime)
   {
      if(fromTime <= 0 || !HistorySelect(fromTime, TimeCurrent()))
         return 0.0;
      double profit = 0.0;
      for(int i = 0; i < HistoryDealsTotal(); ++i)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpRVMagicNumber)
            continue;
         long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
            continue;
         profit += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                   HistoryDealGetDouble(ticket, DEAL_SWAP) +
                   HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      }
      return profit;
   }

   int ClosedLossesSince(const datetime fromTime)
   {
      if(fromTime <= 0 || !HistorySelect(fromTime, TimeCurrent()))
         return 0;
      int losses = 0;
      for(int i = 0; i < HistoryDealsTotal(); ++i)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpRVMagicNumber)
            continue;
         long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
            continue;
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                         HistoryDealGetDouble(ticket, DEAL_SWAP) +
                         HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         if(profit < 0.0)
            losses++;
      }
      return losses;
   }

   int CurrentMonthEntryCount()
   {
      datetime start = iTime(_Symbol, PERIOD_MN1, 0);
      if(start <= 0 || !HistorySelect(start, TimeCurrent()))
         return 0;
      int count = 0;
      for(int i = 0; i < HistoryDealsTotal(); ++i)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpRVMagicNumber)
            continue;
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN)
            count++;
      }
      return count;
   }

   datetime LastEntryTime()
   {
      if(!HistorySelect(0, TimeCurrent()))
         return 0;
      for(int i = HistoryDealsTotal() - 1; i >= 0; --i)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpRVMagicNumber)
            continue;
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN)
            return (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      }
      return 0;
   }

   bool SafetyAllows(string &reason)
   {
      if(!SharedSafetyAllows(reason))
         return false;
      double dailyProfit = ClosedProfitSince(g_dayStart);
      double dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE) - dailyProfit;
      if(InpRVMaximumDailyLossPercent > 0.0 && dayStartBalance > 0.0 &&
         dailyProfit <= -dayStartBalance * InpRVMaximumDailyLossPercent / 100.0)
      {
         reason = "reversion daily loss limit";
         return false;
      }
      if(InpRVMaximumDailyLossCount > 0 &&
         ClosedLossesSince(g_dayStart) >= InpRVMaximumDailyLossCount)
      {
         reason = "reversion daily loss count";
         return false;
      }
      if(ManagedPositionCount() >= 1)
      {
         reason = "reversion position limit";
         return false;
      }
      if(SpreadPoints() > InpRVMaximumSpreadPoints)
      {
         reason = "reversion spread limit";
         return false;
      }
      return true;
   }

   bool VWAPValue(double &vwap)
   {
      double weighted = 0.0;
      double volume = 0.0;
      int bars = MathMax(5, InpRVVWAPLookbackBars);
      for(int shift = 1; shift <= bars; ++shift)
      {
         double high = iHigh(_Symbol, InpRVSignalTimeframe, shift);
         double low = iLow(_Symbol, InpRVSignalTimeframe, shift);
         double close = iClose(_Symbol, InpRVSignalTimeframe, shift);
         long tickVolume = iVolume(_Symbol, InpRVSignalTimeframe, shift);
         if(high <= 0.0 || low <= 0.0 || close <= 0.0 || tickVolume <= 0)
            continue;
         double typical = (high + low + close) / 3.0;
         weighted += typical * (double)tickVolume;
         volume += (double)tickVolume;
      }
      if(volume <= 0.0)
         return false;
      vwap = weighted / volume;
      return vwap > 0.0 && MathIsValidNumber(vwap);
   }

   bool LowestLow(const int startShift, const int bars, double &price)
   {
      price = DBL_MAX;
      for(int shift = startShift; shift < startShift + bars; ++shift)
      {
         double value = iLow(_Symbol, InpRVSignalTimeframe, shift);
         if(value <= 0.0)
            return false;
         price = MathMin(price, value);
      }
      return price < DBL_MAX;
   }

   bool HighestHigh(const int startShift, const int bars, double &price)
   {
      price = -DBL_MAX;
      for(int shift = startShift; shift < startShift + bars; ++shift)
      {
         double value = iHigh(_Symbol, InpRVSignalTimeframe, shift);
         if(value <= 0.0)
            return false;
         price = MathMax(price, value);
      }
      return price > 0.0;
   }

   bool OpenPosition(const bool buy,
                     const double entryPrice,
                     const double stopPrice,
                     const double targetPrice,
                     const double diEdge)
   {
      double baseLots = LotsForRisk(buy, entryPrice, stopPrice,
                                    InpRVRiskPercent, InpRVMaximumPositionLots);
      if(baseLots <= 0.0)
         return false;
      double laneRiskPercent = RequestedLaneRiskPercent(InpRVRiskPercent,
                                                        InpRVMaximumEntryRiskPercent);
      double lots = LotsForRisk(buy, entryPrice, stopPrice,
                                laneRiskPercent, InpRVMaximumPositionLots);
      string exposureReason = "";
      if(lots <= 0.0 ||
         !AccountWideExposureAllows(buy, entryPrice, stopPrice, lots, exposureReason))
         return false;
      m_trade.SetExpertMagicNumber(InpRVMagicNumber);
      m_trade.SetDeviationInPoints(InpRVDeviationPoints);
      m_trade.SetAsyncMode(false);
      m_trade.SetTypeFillingBySymbol(_Symbol);
      string comment = buy ? "RRO;Band VWAP reversion;Lower" : "RRO;Band VWAP reversion;Upper";
      bool opened = buy
                    ? m_trade.Buy(lots, _Symbol, 0.0, NormalizeDouble(stopPrice, _Digits),
                                  NormalizeDouble(targetPrice, _Digits), comment)
                    : m_trade.Sell(lots, _Symbol, 0.0, NormalizeDouble(stopPrice, _Digits),
                                   NormalizeDouble(targetPrice, _Digits), comment);
      if(!opened || !TradeResultAllows(m_trade, false))
      {
         string rejectReason = "";
         return RejectPostFill(m_trade, InpRVMagicNumber, "reversion entry result", rejectReason);
      }
      ulong ticket = 0;
      string postFillReason = "";
      if(!PostFillReconcile(m_trade, InpRVMagicNumber, buy, laneRiskPercent,
                            InpRVMaximumPositionLots, ticket, postFillReason))
         return false;
      string eventReason = buy ? "lower-band reclaim" : "upper-band reclaim";
      eventReason += "; DI edge " + DoubleToString(diEdge, 2) +
                     "; requested risk " + DoubleToString(laneRiskPercent, 4) + "%";
      WriteEvidenceEvent(m_logHandle, "tlp_rv_m12", "entry", ticket,
                         buy ? "buy" : "sell", lots, entryPrice, stopPrice, 0.0,
                         eventReason);
      return true;
   }

   void TryEntry()
   {
      string reason = "";
      if(!SafetyAllows(reason))
         return;
      if(InpRVMaximumMonthlyEntries > 0 &&
         CurrentMonthEntryCount() >= InpRVMaximumMonthlyEntries)
         return;
      datetime lastEntry = LastEntryTime();
      if(lastEntry > 0 && InpRVEntrySpacingMinutes > 0 &&
         TimeCurrent() - lastEntry < InpRVEntrySpacingMinutes * 60)
         return;

      double atr = 0.0, adx = 0.0, rsi = 0.0;
      double middle = 0.0, upper = 0.0, lower = 0.0;
      double plusDI = 0.0, minusDI = 0.0;
      if(!BufferValue(m_atrHandle, 0, 1, atr) || atr <= 0.0 ||
         !BufferValue(m_adxHandle, 0, 1, adx) ||
         !BufferValue(m_adxHandle, 1, 1, plusDI) ||
         !BufferValue(m_adxHandle, 2, 1, minusDI) ||
         !BufferValue(m_rsiHandle, 0, 1, rsi) ||
         !BufferValue(m_bandsHandle, 0, 1, middle) ||
         !BufferValue(m_bandsHandle, 1, 1, upper) ||
         !BufferValue(m_bandsHandle, 2, 1, lower))
         return;
      if(adx > InpRVMaximumADX)
         return;
      double bandWidthATR = (upper - lower) / atr;
      if(bandWidthATR < InpRVMinimumBandWidthATR ||
         (InpRVMaximumBandWidthATR > 0.0 && bandWidthATR > InpRVMaximumBandWidthATR))
         return;

      double high1 = iHigh(_Symbol, InpRVSignalTimeframe, 1);
      double low1 = iLow(_Symbol, InpRVSignalTimeframe, 1);
      double open1 = iOpen(_Symbol, InpRVSignalTimeframe, 1);
      double close1 = iClose(_Symbol, InpRVSignalTimeframe, 1);
      double range1 = high1 - low1;
      if(high1 <= 0.0 || low1 <= 0.0 || open1 <= 0.0 || close1 <= 0.0 ||
         range1 <= _Point)
         return;
      double penetration = atr * MathMax(0.0, InpRVMinimumBandPenetrationATR);
      double closeLocation = (close1 - low1) / range1;
      double upperWickPercent = 100.0 * (high1 - MathMax(open1, close1)) / range1;
      double lowerWickPercent = 100.0 * (MathMin(open1, close1) - low1) / range1;
      double minimumCloseLocation = MathMin(0.95, MathMax(0.50, InpRVMinimumCloseLocation));
      bool buy = low1 <= lower - penetration && close1 > lower && close1 > open1 &&
                 lowerWickPercent >= InpRVMinimumWickPercent &&
                 closeLocation >= minimumCloseLocation && rsi <= InpRVBuyMaximumRSI;
      bool sell = high1 >= upper + penetration && close1 < upper && close1 < open1 &&
                  upperWickPercent >= InpRVMinimumWickPercent &&
                  closeLocation <= 1.0 - minimumCloseLocation && rsi >= InpRVSellMinimumRSI;
      if(buy == sell)
         return;
      if(!D1MomentumCapAllows())
         return;
      double spreadATRPercent = 100.0 * SpreadPoints() / (atr / _Point);
      if(InpRVMaximumSpreadATRPercent > 0.0 &&
         spreadATRPercent > InpRVMaximumSpreadATRPercent)
         return;
      double vwap = 0.0;
      if(!VWAPValue(vwap))
         return;
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol, tick))
         return;
      double entryPrice = buy ? tick.ask : tick.bid;
      double targetPrice = vwap;
      if((buy && targetPrice <= entryPrice) || (sell && targetPrice >= entryPrice))
         return;

      int lookback = MathMax(2, InpRVStopLookbackBars);
      double structuralExtreme = 0.0;
      if(buy)
      {
         if(!LowestLow(1, lookback, structuralExtreme))
            return;
      }
      else if(!HighestHigh(1, lookback, structuralExtreme))
         return;
      double stopBuffer = atr * MathMax(0.0, InpRVStopBufferATR) +
                          _Point * MathMax(0.0, InpRVStopBufferPoints);
      double stopPrice = buy ? structuralExtreme - stopBuffer : structuralExtreme + stopBuffer;
      double stopDistance = buy ? entryPrice - stopPrice : stopPrice - entryPrice;
      double targetDistance = buy ? targetPrice - entryPrice : entryPrice - targetPrice;
      if(stopDistance <= 0.0 || targetDistance <= 0.0 ||
         (InpRVMaximumStopATR > 0.0 && stopDistance > atr * InpRVMaximumStopATR) ||
         targetDistance < atr * MathMax(0.0, InpRVMinimumTargetATR))
         return;
      double spreadDistance = SpreadPoints() * _Point;
      double adjustedReward = targetDistance - spreadDistance;
      double adjustedRisk = stopDistance + spreadDistance;
      if(adjustedReward <= 0.0 || adjustedRisk <= 0.0 ||
         adjustedReward / adjustedRisk < MathMax(0.0, InpRVMinimumRiskReward))
         return;
      double direction = buy ? 1.0 : -1.0;
      double diEdge = direction * (plusDI - minusDI);
      if(InpRVUseDIEdgeGate && diEdge < InpRVMinimumDIEdge)
         return;
      OpenPosition(buy, entryPrice, stopPrice, targetPrice, diEdge);
   }

public:
   CReversionLane()
   {
      m_atrHandle = INVALID_HANDLE;
      m_adxHandle = INVALID_HANDLE;
      m_rsiHandle = INVALID_HANDLE;
      m_bandsHandle = INVALID_HANDLE;
      m_logHandle = INVALID_HANDLE;
      m_lastSignalBar = 0;
   }

   bool Init()
   {
      if(!InpRVEnabled)
         return true;
      m_atrHandle = iATR(_Symbol, InpRVSignalTimeframe, InpRVATRPeriod);
      m_adxHandle = iADX(_Symbol, InpRVSignalTimeframe, InpRVADXPeriod);
      m_rsiHandle = iRSI(_Symbol, InpRVSignalTimeframe, InpRVRSIPeriod, PRICE_CLOSE);
      m_bandsHandle = iBands(_Symbol, InpRVSignalTimeframe, InpRVBollingerPeriod, 0,
                             InpRVBollingerDeviation, PRICE_CLOSE);
      if(m_atrHandle == INVALID_HANDLE || m_adxHandle == INVALID_HANDLE ||
         m_rsiHandle == INVALID_HANDLE || m_bandsHandle == INVALID_HANDLE)
         return false;
      m_trade.SetExpertMagicNumber(InpRVMagicNumber);
      m_trade.SetDeviationInPoints(InpRVDeviationPoints);
      m_trade.SetAsyncMode(false);
      m_trade.SetTypeFillingBySymbol(_Symbol);
      m_logHandle = OpenEvidenceFile(InpRVLogFileName);
      return !InpLogTrades || m_logHandle != INVALID_HANDLE;
   }

   void Deinit()
   {
      if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
      if(m_adxHandle != INVALID_HANDLE) IndicatorRelease(m_adxHandle);
      if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
      if(m_bandsHandle != INVALID_HANDLE) IndicatorRelease(m_bandsHandle);
      if(m_logHandle != INVALID_HANDLE) FileClose(m_logHandle);
   }

   void OnTick()
   {
      if(!InpRVEnabled)
         return;
      datetime currentBar = iTime(_Symbol, InpRVSignalTimeframe, 0);
      if(currentBar <= 0 || currentBar == m_lastSignalBar)
         return;
      m_lastSignalBar = currentBar;
      if(ManagedPositionCount() == 0)
         TryEntry();
   }

   void OnTradeTransaction(const MqlTradeTransaction &transaction)
   {
      if(transaction.type != TRADE_TRANSACTION_DEAL_ADD || !HistoryDealSelect(transaction.deal))
         return;
      if(HistoryDealGetString(transaction.deal, DEAL_SYMBOL) != _Symbol ||
         (ulong)HistoryDealGetInteger(transaction.deal, DEAL_MAGIC) != InpRVMagicNumber)
         return;
      long entryType = HistoryDealGetInteger(transaction.deal, DEAL_ENTRY);
      if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
         return;
      double profit = HistoryDealGetDouble(transaction.deal, DEAL_PROFIT) +
                      HistoryDealGetDouble(transaction.deal, DEAL_SWAP) +
                      HistoryDealGetDouble(transaction.deal, DEAL_COMMISSION);
      WriteEvidenceEvent(m_logHandle, "tlp_rv_m12", "exit", transaction.deal, "close",
                         HistoryDealGetDouble(transaction.deal, DEAL_VOLUME),
                         HistoryDealGetDouble(transaction.deal, DEAL_PRICE), 0.0, profit,
                         HistoryDealGetString(transaction.deal, DEAL_COMMENT));
   }
};

class CMomentumLane
{
private:
   CTrade m_trade;
   int m_atrHandle;
   int m_logHandle;
   datetime m_lastSignalBar;

   string RiskKey(const ulong ticket)
   {
      return "TLP_MO_RISK_" + IntegerToString((long)ticket);
   }

   bool SessionAllows()
   {
      MqlDateTime now;
      if(!TimeToStruct(TimeCurrent(), now))
         return false;
      if(InpMODisableFridayAfterHour && now.day_of_week == 5 &&
         now.hour >= InpMOFridayCutoffHour)
         return false;
      if(!InpMOUseSessionFilter || InpMOSessionStartHour == InpMOSessionEndHour)
         return true;
      if(InpMOSessionStartHour < InpMOSessionEndHour)
         return now.hour >= InpMOSessionStartHour && now.hour < InpMOSessionEndHour;
      return now.hour >= InpMOSessionStartHour || now.hour < InpMOSessionEndHour;
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
            (ulong)PositionGetInteger(POSITION_MAGIC) == InpMOMagicNumber)
            count++;
      }
      return count;
   }

   double ClosedProfitSince(const datetime fromTime)
   {
      if(fromTime <= 0 || !HistorySelect(fromTime, TimeCurrent()))
         return 0.0;
      double profit = 0.0;
      for(int i = 0; i < HistoryDealsTotal(); ++i)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMOMagicNumber)
            continue;
         long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
            continue;
         profit += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                   HistoryDealGetDouble(ticket, DEAL_SWAP) +
                   HistoryDealGetDouble(ticket, DEAL_COMMISSION);
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
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMOMagicNumber)
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
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMOMagicNumber)
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

   bool SafetyAllows(string &reason)
   {
      if(!SharedSafetyAllows(reason))
         return false;
      double dailyProfit = ClosedProfitSince(g_dayStart);
      double dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE) - dailyProfit;
      if(InpMOMaximumDailyLossPercent > 0.0 && dayStartBalance > 0.0 &&
         dailyProfit <= -dayStartBalance * InpMOMaximumDailyLossPercent / 100.0)
      {
         reason = "momentum daily loss limit";
         return false;
      }
      if(InpMOMaximumTradesPerDay > 0 && EntriesSince(g_dayStart) >= InpMOMaximumTradesPerDay)
      {
         reason = "momentum daily trade limit";
         return false;
      }
      if(ManagedPositionCount() >= 1)
      {
         reason = "momentum position limit";
         return false;
      }
      if(SpreadPoints() > InpMOMaximumSpreadPoints)
      {
         reason = "momentum spread limit";
         return false;
      }
      if(!SessionAllows())
      {
         reason = "momentum session filter";
         return false;
      }
      int streak = 0;
      datetime lastLoss = 0;
      LossStreak(streak, lastLoss);
      if(InpMOMaximumConsecutiveLosses > 0 && streak >= InpMOMaximumConsecutiveLosses &&
         lastLoss > 0 && TimeCurrent() - lastLoss < InpMOLossCooldownHours * 3600)
      {
         reason = "momentum loss cooldown";
         return false;
      }
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
      if(CopyRates(_Symbol, InpMOSignalTimeframe, startShift, count, rates) != count)
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

   int MomentumDirection()
   {
      if(InpMOMomentumLookbackBars < 2)
         return 0;
      double recentClose = iClose(_Symbol, InpMOMomentumTimeframe, 1);
      double pastClose = iClose(_Symbol, InpMOMomentumTimeframe,
                                1 + InpMOMomentumLookbackBars);
      if(recentClose <= 0.0 || pastClose <= 0.0)
         return 0;
      if(recentClose > pastClose) return 1;
      if(recentClose < pastClose) return -1;
      return 0;
   }

   bool RegimeAllows(const bool buy, const double closePrice, const double atr)
   {
      if(closePrice <= 0.0 || atr <= 0.0)
         return false;
      if(InpMOUseVolatilityFilter)
      {
         double atrPercent = 100.0 * atr / closePrice;
         if(atrPercent < InpMOMinimumATRPercent || atrPercent > InpMOMaximumATRPercent)
            return false;
      }
      int direction = MomentumDirection();
      return buy ? direction > 0 : direction < 0;
   }

   bool RegisterRiskForPosition(const ulong ticket)
   {
      if(!SelectOwnedPosition(ticket, InpMOMagicNumber))
         return false;
      double riskDistance = MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) -
                                    PositionGetDouble(POSITION_SL));
      return riskDistance > 0.0 && VerifiedGlobalSet(RiskKey(ticket), riskDistance);
   }

   bool OpenPosition(const bool buy, const double atr)
   {
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol, tick) || atr <= 0.0)
         return false;
      double entryPrice = buy ? tick.ask : tick.bid;
      double structureHigh = 0.0, structureLow = 0.0;
      if(!ChannelBounds(1, InpMOStopLookbackBars, structureHigh, structureLow))
         return false;
      double stopLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      double rawStop = buy ? structureLow - InpMOStopBufferATR * atr
                           : structureHigh + InpMOStopBufferATR * atr;
      double stopDistance = buy ? entryPrice - rawStop : rawStop - entryPrice;
      double minimumDistance = MathMax(InpMOMinimumStopATR * atr, stopLevel + _Point);
      if(stopDistance < minimumDistance)
         stopDistance = minimumDistance;
      if(stopDistance <= 0.0 || stopDistance > InpMOMaximumStopATR * atr ||
         (InpMOMaximumStopPriceDistance > 0.0 &&
          stopDistance > InpMOMaximumStopPriceDistance))
         return false;
      double stopPrice = NormalizeDouble(buy ? entryPrice - stopDistance
                                              : entryPrice + stopDistance, _Digits);
      double takeProfit = NormalizeDouble(buy ? entryPrice + InpMOTakeProfitR * stopDistance
                                               : entryPrice - InpMOTakeProfitR * stopDistance, _Digits);
      double baseLots = LotsForRisk(buy, entryPrice, stopPrice,
                                    InpMORiskPercent, InpMOMaximumPositionLots);
      if(baseLots <= 0.0)
         return false;
      double laneRiskPercent = RequestedLaneRiskPercent(InpMORiskPercent,
                                                        InpMOMaximumEntryRiskPercent);
      double lots = LotsForRisk(buy, entryPrice, stopPrice,
                                laneRiskPercent, InpMOMaximumPositionLots);
      string exposureReason = "";
      if(lots <= 0.0 ||
         !AccountWideExposureAllows(buy, entryPrice, stopPrice, lots, exposureReason))
         return false;
      m_trade.SetExpertMagicNumber(InpMOMagicNumber);
      m_trade.SetDeviationInPoints(InpMODeviationPoints);
      string comment = buy ? "MTSM_BUY" : "MTSM_SELL";
      bool opened = buy ? m_trade.Buy(lots, _Symbol, 0.0, stopPrice, takeProfit, comment)
                        : m_trade.Sell(lots, _Symbol, 0.0, stopPrice, takeProfit, comment);
      if(!opened || !TradeResultAllows(m_trade, false))
      {
         string rejectReason = "";
         return RejectPostFill(m_trade, InpMOMagicNumber, "momentum entry result", rejectReason);
      }
      ulong ticket = 0;
      string postFillReason = "";
      if(!PostFillReconcile(m_trade, InpMOMagicNumber, buy, laneRiskPercent,
                            InpMOMaximumPositionLots, ticket, postFillReason))
         return false;
      if(!RegisterRiskForPosition(ticket))
      {
         string rejectReason = "";
         return RejectPostFill(m_trade, InpMOMagicNumber, "momentum risk registration", rejectReason);
      }
      WriteEvidenceEvent(m_logHandle, "tlp_mom_e20", "entry", ticket,
                         buy ? "buy" : "sell", lots, entryPrice, stopPrice, 0.0,
                         "daily momentum plus fresh H1 breakout; requested risk " +
                         DoubleToString(laneRiskPercent, 4) + "%");
      return true;
   }

   bool TryChannelExit(const ulong ticket, const bool buy)
   {
      if(InpMOUseChannelExit)
      {
         double exitHigh = 0.0, exitLow = 0.0;
         if(ChannelBounds(2, InpMOExitLookbackBars, exitHigh, exitLow))
         {
            double closePrice = iClose(_Symbol, InpMOSignalTimeframe, 1);
            bool channelExit = buy ? closePrice < exitLow : closePrice > exitHigh;
            if(channelExit)
            {
               string closeReason = "";
               return CloseOwnedPosition(m_trade, ticket, InpMOMagicNumber, closeReason);
            }
         }
      }
      if(InpMOUseMomentumFailureExit)
      {
         int direction = MomentumDirection();
         if((buy && direction < 0) || (!buy && direction > 0))
         {
            string closeReason = "";
            return CloseOwnedPosition(m_trade, ticket, InpMOMagicNumber, closeReason);
         }
      }
      if(InpMOMaximumHoldBars > 0)
      {
         datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
         int openShift = iBarShift(_Symbol, InpMOSignalTimeframe, openTime, false);
         if(openShift >= InpMOMaximumHoldBars)
         {
            string closeReason = "";
            return CloseOwnedPosition(m_trade, ticket, InpMOMagicNumber, closeReason);
         }
      }
      return false;
   }

   void ImproveProtectiveStop(const ulong ticket, const bool buy)
   {
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double oldSl = PositionGetDouble(POSITION_SL);
      double takeProfit = PositionGetDouble(POSITION_TP);
      double current = buy ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                           : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double initialRisk = GlobalVariableCheck(RiskKey(ticket))
                           ? GlobalVariableGet(RiskKey(ticket))
                           : MathAbs(openPrice - oldSl);
      if(initialRisk <= 0.0 || current <= 0.0)
         return;
      double favorable = buy ? current - openPrice : openPrice - current;
      double r = favorable / initialRisk;
      double newSl = oldSl;
      if(InpMOUseBreakEven && r >= InpMOBreakEvenTriggerR)
      {
         double breakEven = buy ? openPrice + InpMOBreakEvenLockR * initialRisk
                                : openPrice - InpMOBreakEvenLockR * initialRisk;
         if((buy && breakEven > newSl) || (!buy && breakEven < newSl))
            newSl = breakEven;
      }
      newSl = NormalizeDouble(newSl, _Digits);
      double minimumDistance = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      bool valid = buy ? newSl > 0.0 && newSl < current - minimumDistance
                       : newSl > current + minimumDistance;
      bool improved = buy ? newSl > oldSl + _Point : newSl < oldSl - _Point;
      if(valid && improved)
      {
         string modifyReason = "";
         ModifyOwnedPosition(m_trade, ticket, InpMOMagicNumber,
                             newSl, takeProfit, modifyReason);
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
            (ulong)PositionGetInteger(POSITION_MAGIC) != InpMOMagicNumber)
            continue;
         bool buy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
         if(TryChannelExit(ticket, buy))
         {
            closed = true;
            continue;
         }
         if(PositionSelectByTicket(ticket))
            ImproveProtectiveStop(ticket, buy);
      }
      return closed;
   }

   void TryEntry(const double atr)
   {
      string safetyReason = "";
      if(!SafetyAllows(safetyReason))
         return;
      double channelHigh = 0.0, channelLow = 0.0;
      if(!ChannelBounds(2, InpMOEntryLookbackBars, channelHigh, channelLow))
         return;
      double close1 = iClose(_Symbol, InpMOSignalTimeframe, 1);
      double close2 = iClose(_Symbol, InpMOSignalTimeframe, 2);
      if(close1 <= 0.0 || close2 <= 0.0)
         return;
      double buffer = InpMOBreakoutBufferATR * atr;
      bool buyBreak = InpMOAllowBuy && close1 > channelHigh + buffer;
      bool sellBreak = InpMOAllowSell && close1 < channelLow - buffer;
      if(InpMORequireFreshBreakout)
      {
         double priorHigh = 0.0, priorLow = 0.0;
         if(!ChannelBounds(3, InpMOEntryLookbackBars, priorHigh, priorLow))
            return;
         buyBreak = buyBreak && close2 <= priorHigh + buffer;
         sellBreak = sellBreak && close2 >= priorLow - buffer;
      }
      if(buyBreak && RegimeAllows(true, close1, atr))
         OpenPosition(true, atr);
      else if(sellBreak && RegimeAllows(false, close1, atr))
         OpenPosition(false, atr);
   }

public:
   CMomentumLane()
   {
      m_atrHandle = INVALID_HANDLE;
      m_logHandle = INVALID_HANDLE;
      m_lastSignalBar = 0;
   }

   bool Init()
   {
      if(!InpMOEnabled)
         return true;
      m_atrHandle = iATR(_Symbol, InpMOSignalTimeframe, InpMOATRPeriod);
      if(m_atrHandle == INVALID_HANDLE)
         return false;
      m_trade.SetExpertMagicNumber(InpMOMagicNumber);
      m_trade.SetDeviationInPoints(InpMODeviationPoints);
      m_trade.SetAsyncMode(false);
      m_trade.SetTypeFillingBySymbol(_Symbol);
      m_logHandle = OpenEvidenceFile(InpMOLogFileName);
      return !InpLogTrades || m_logHandle != INVALID_HANDLE;
   }

   void Deinit()
   {
      if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
      if(m_logHandle != INVALID_HANDLE) FileClose(m_logHandle);
   }

   void OnTick()
   {
      if(!InpMOEnabled)
         return;
      datetime currentBar = iTime(_Symbol, InpMOSignalTimeframe, 0);
      if(currentBar <= 0 || currentBar == m_lastSignalBar)
         return;
      m_lastSignalBar = currentBar;
      double atr = 0.0;
      if(!BufferValue(m_atrHandle, 0, 1, atr) || atr <= 0.0)
         return;
      bool closed = ManagePositionOnBar();
      if(!closed && ManagedPositionCount() == 0)
         TryEntry(atr);
   }

   void OnTradeTransaction(const MqlTradeTransaction &transaction)
   {
      if(transaction.type != TRADE_TRANSACTION_DEAL_ADD || !HistoryDealSelect(transaction.deal))
         return;
      if(HistoryDealGetString(transaction.deal, DEAL_SYMBOL) != _Symbol ||
         (ulong)HistoryDealGetInteger(transaction.deal, DEAL_MAGIC) != InpMOMagicNumber)
         return;
      long entryType = HistoryDealGetInteger(transaction.deal, DEAL_ENTRY);
      if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
         return;
      if(transaction.position > 0)
         VerifiedGlobalDelete(RiskKey(transaction.position));
      double profit = HistoryDealGetDouble(transaction.deal, DEAL_PROFIT) +
                      HistoryDealGetDouble(transaction.deal, DEAL_SWAP) +
                      HistoryDealGetDouble(transaction.deal, DEAL_COMMISSION);
      WriteEvidenceEvent(m_logHandle, "tlp_mom_e20", "exit", transaction.deal, "close",
                         HistoryDealGetDouble(transaction.deal, DEAL_VOLUME),
                         HistoryDealGetDouble(transaction.deal, DEAL_PRICE), 0.0, profit,
                         HistoryDealGetString(transaction.deal, DEAL_COMMENT));
   }
};

class CAdaptiveTrendBreakoutLane
{
private:
   CTrade m_trade;
   int m_atrHandle;
   int m_trendAtrHandle;
   int m_trendFastEmaHandle;
   int m_trendSlowEmaHandle;
   int m_signalEmaHandle;
   int m_adxHandle;
   int m_logHandle;
   datetime m_lastSignalBar;

   string RiskKey(const ulong ticket)
   {
      return "TLP_ATB_RISK_" + IntegerToString((long)ticket);
   }

   bool SessionAllows()
   {
      MqlDateTime now;
      if(!TimeToStruct(TimeCurrent(), now))
         return false;
      if(InpATBDisableFridayAfterHour && now.day_of_week == 5 &&
         now.hour >= InpATBFridayCutoffHour)
         return false;
      if(!InpATBUseSessionFilter || InpATBSessionStartHour == InpATBSessionEndHour)
         return true;
      if(InpATBSessionStartHour < InpATBSessionEndHour)
         return now.hour >= InpATBSessionStartHour && now.hour < InpATBSessionEndHour;
      return now.hour >= InpATBSessionStartHour || now.hour < InpATBSessionEndHour;
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
            (ulong)PositionGetInteger(POSITION_MAGIC) == InpATBMagicNumber)
            count++;
      }
      return count;
   }

   double ClosedProfitSince(const datetime fromTime)
   {
      if(fromTime <= 0 || !HistorySelect(fromTime, TimeCurrent()))
         return 0.0;
      double profit = 0.0;
      for(int i = 0; i < HistoryDealsTotal(); ++i)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpATBMagicNumber)
            continue;
         long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
            continue;
         profit += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                   HistoryDealGetDouble(ticket, DEAL_SWAP) +
                   HistoryDealGetDouble(ticket, DEAL_COMMISSION);
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
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpATBMagicNumber)
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
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpATBMagicNumber)
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

   bool SafetyAllows(string &reason)
   {
      if(!SharedSafetyAllows(reason))
         return false;
      double dailyProfit = ClosedProfitSince(g_dayStart);
      double dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE) - dailyProfit;
      if(InpATBMaximumDailyLossPercent > 0.0 && dayStartBalance > 0.0 &&
         dailyProfit <= -dayStartBalance * InpATBMaximumDailyLossPercent / 100.0)
      {
         reason = "momentum daily loss limit";
         return false;
      }
      if(InpATBMaximumTradesPerDay > 0 && EntriesSince(g_dayStart) >= InpATBMaximumTradesPerDay)
      {
         reason = "momentum daily trade limit";
         return false;
      }
      if(ManagedPositionCount() >= 1)
      {
         reason = "momentum position limit";
         return false;
      }
      if(SpreadPoints() > InpATBMaximumSpreadPoints)
      {
         reason = "momentum spread limit";
         return false;
      }
      if(!SessionAllows())
      {
         reason = "momentum session filter";
         return false;
      }
      int streak = 0;
      datetime lastLoss = 0;
      LossStreak(streak, lastLoss);
      if(InpATBMaximumConsecutiveLosses > 0 && streak >= InpATBMaximumConsecutiveLosses &&
         lastLoss > 0 && TimeCurrent() - lastLoss < InpATBLossCooldownHours * 3600)
      {
         reason = "momentum loss cooldown";
         return false;
      }
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
      if(CopyRates(_Symbol, InpATBSignalTimeframe, startShift, count, rates) != count)
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

   int MomentumDirection()
   {
      if(InpATBMomentumLookbackBars < 2)
         return 0;
      double recentClose = iClose(_Symbol, InpATBMomentumTimeframe, 1);
      double pastClose = iClose(_Symbol, InpATBMomentumTimeframe,
                                1 + InpATBMomentumLookbackBars);
      if(recentClose <= 0.0 || pastClose <= 0.0)
         return 0;
      if(recentClose > pastClose) return 1;
      if(recentClose < pastClose) return -1;
      return 0;
   }

   bool RegimeAllows(const bool buy, const double closePrice, const double atr)
   {
      if(closePrice <= 0.0 || atr <= 0.0)
         return false;
      if(InpATBUseVolatilityFilter)
      {
         double atrPercent = 100.0 * atr / closePrice;
         if(atrPercent < InpATBMinimumATRPercent || atrPercent > InpATBMaximumATRPercent)
            return false;
      }
      if(InpATBUseLongMomentumAgreement)
      {
         int direction = MomentumDirection();
         if((buy && direction <= 0) || (!buy && direction >= 0))
            return false;
      }
      if(InpATBUseTrendEMAFilter)
      {
         double fast = 0.0, slow = 0.0, fastPast = 0.0, trendAtr = 0.0;
         int slopeShift = 1 + MathMax(1, InpATBTrendSlopeLookbackBars);
         if(!BufferValue(m_trendFastEmaHandle, 0, 1, fast) ||
            !BufferValue(m_trendSlowEmaHandle, 0, 1, slow) ||
            !BufferValue(m_trendFastEmaHandle, 0, slopeShift, fastPast) ||
            !BufferValue(m_trendAtrHandle, 0, 1, trendAtr) || trendAtr <= 0.0)
            return false;
         double trendClose = iClose(_Symbol, InpATBMomentumTimeframe, 1);
         double normalizedSlope = (fast - fastPast) / trendAtr;
         double minimumSlope = MathMax(0.0, InpATBMinimumTrendSlopeATR);
         if(buy && !(trendClose > fast && fast > slow && normalizedSlope >= minimumSlope))
            return false;
         if(!buy && !(trendClose < fast && fast < slow && normalizedSlope <= -minimumSlope))
            return false;
      }
      if(InpATBUseSignalEMAFilter)
      {
         double signalEma = 0.0, signalEmaPast = 0.0;
         int slopeShift = 1 + MathMax(1, InpATBSignalEMASlopeLookbackBars);
         if(!BufferValue(m_signalEmaHandle, 0, 1, signalEma) ||
            !BufferValue(m_signalEmaHandle, 0, slopeShift, signalEmaPast))
            return false;
         double normalizedSlope = (signalEma - signalEmaPast) / atr;
         double minimumSlope = MathMax(0.0, InpATBMinimumSignalSlopeATR);
         if(buy && !(closePrice > signalEma && normalizedSlope >= minimumSlope))
            return false;
         if(!buy && !(closePrice < signalEma && normalizedSlope <= -minimumSlope))
            return false;
      }
      if(InpATBUseADXFilter)
      {
         double adx = 0.0;
         if(!BufferValue(m_adxHandle, 0, 1, adx))
            return false;
         if(adx < MathMax(0.0, InpATBMinimumADX) ||
            (InpATBMaximumADX > 0.0 && adx > InpATBMaximumADX))
            return false;
      }
      return true;
   }

   bool BreakoutQualityAllows(const bool buy, const double atr)
   {
      if(!InpATBUseBreakoutQualityFilter && !InpATBUseTickVolumeExpansion)
         return true;
      double open1 = iOpen(_Symbol, InpATBSignalTimeframe, 1);
      double high1 = iHigh(_Symbol, InpATBSignalTimeframe, 1);
      double low1 = iLow(_Symbol, InpATBSignalTimeframe, 1);
      double close1 = iClose(_Symbol, InpATBSignalTimeframe, 1);
      double range = high1 - low1;
      if(open1 <= 0.0 || low1 <= 0.0 || range <= 0.0 || atr <= 0.0)
         return false;
      if(InpATBUseBreakoutQualityFilter)
      {
         double bodyPercent = 100.0 * MathAbs(close1 - open1) / range;
         double closeLocation = buy ? 100.0 * (close1 - low1) / range
                                    : 100.0 * (high1 - close1) / range;
         double rangeAtr = range / atr;
         if((buy && close1 <= open1) || (!buy && close1 >= open1) ||
            bodyPercent < MathMax(0.0, InpATBMinimumBreakoutBodyPercent) ||
            closeLocation < MathMax(0.0, InpATBMinimumBreakoutCloseLocationPercent) ||
            rangeAtr < MathMax(0.0, InpATBMinimumBreakoutRangeATR) ||
            (InpATBMaximumBreakoutRangeATR > 0.0 && rangeAtr > InpATBMaximumBreakoutRangeATR))
            return false;
      }
      if(InpATBUseTickVolumeExpansion)
      {
         int lookback = MathMax(2, InpATBTickVolumeLookbackBars);
         long currentVolume = iVolume(_Symbol, InpATBSignalTimeframe, 1);
         double averageVolume = 0.0;
         for(int shift = 2; shift < 2 + lookback; ++shift)
            averageVolume += (double)iVolume(_Symbol, InpATBSignalTimeframe, shift);
         averageVolume /= lookback;
         if(currentVolume <= 0 || averageVolume <= 0.0 ||
            (double)currentVolume / averageVolume < MathMax(0.0, InpATBMinimumTickVolumeRatio))
            return false;
      }
      return true;
   }

   bool RegisterRiskForPosition(const ulong ticket)
   {
      if(!SelectOwnedPosition(ticket, InpATBMagicNumber))
         return false;
      double riskDistance = MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) -
                                    PositionGetDouble(POSITION_SL));
      return riskDistance > 0.0 && VerifiedGlobalSet(RiskKey(ticket), riskDistance);
   }

   bool OpenPosition(const bool buy, const double atr)
   {
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol, tick) || atr <= 0.0)
         return false;
      double entryPrice = buy ? tick.ask : tick.bid;
      double structureHigh = 0.0, structureLow = 0.0;
      if(!ChannelBounds(1, InpATBStopLookbackBars, structureHigh, structureLow))
         return false;
      double stopLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      double rawStop = buy ? structureLow - InpATBStopBufferATR * atr
                           : structureHigh + InpATBStopBufferATR * atr;
      double stopDistance = buy ? entryPrice - rawStop : rawStop - entryPrice;
      double minimumDistance = MathMax(InpATBMinimumStopATR * atr, stopLevel + _Point);
      if(stopDistance < minimumDistance)
         stopDistance = minimumDistance;
      if(stopDistance <= 0.0 || stopDistance > InpATBMaximumStopATR * atr ||
         (InpATBMaximumStopPriceDistance > 0.0 &&
          stopDistance > InpATBMaximumStopPriceDistance))
         return false;
      double stopPrice = NormalizeDouble(buy ? entryPrice - stopDistance
                                              : entryPrice + stopDistance, _Digits);
      double takeProfit = NormalizeDouble(buy ? entryPrice + InpATBTakeProfitR * stopDistance
                                               : entryPrice - InpATBTakeProfitR * stopDistance, _Digits);
      double baseLots = LotsForRisk(buy, entryPrice, stopPrice,
                                    InpATBRiskPercent, InpATBMaximumPositionLots);
      if(baseLots <= 0.0)
         return false;
      double laneRiskPercent = RequestedLaneRiskPercent(InpATBRiskPercent,
                                                        InpATBMaximumEntryRiskPercent);
      double lots = LotsForRisk(buy, entryPrice, stopPrice,
                                laneRiskPercent, InpATBMaximumPositionLots);
      string exposureReason = "";
      if(lots <= 0.0 ||
         !AccountWideExposureAllows(buy, entryPrice, stopPrice, lots, exposureReason))
         return false;
      m_trade.SetExpertMagicNumber(InpATBMagicNumber);
      m_trade.SetDeviationInPoints(InpATBDeviationPoints);
      string comment = buy ? "ATB_H4_BUY" : "ATB_H4_SELL";
      bool opened = buy ? m_trade.Buy(lots, _Symbol, 0.0, stopPrice, takeProfit, comment)
                        : m_trade.Sell(lots, _Symbol, 0.0, stopPrice, takeProfit, comment);
      if(!opened || !TradeResultAllows(m_trade, false))
      {
         string rejectReason = "";
         return RejectPostFill(m_trade, InpATBMagicNumber, "adaptive-trend entry result", rejectReason);
      }
      ulong ticket = 0;
      string postFillReason = "";
      if(!PostFillReconcile(m_trade, InpATBMagicNumber, buy, laneRiskPercent,
                            InpATBMaximumPositionLots, ticket, postFillReason))
         return false;
      if(!RegisterRiskForPosition(ticket))
      {
         string rejectReason = "";
         return RejectPostFill(m_trade, InpATBMagicNumber, "adaptive-trend risk registration", rejectReason);
      }
      WriteEvidenceEvent(m_logHandle, "atb_h4_d1", "entry", ticket,
                         buy ? "buy" : "sell", lots, entryPrice, stopPrice, 0.0,
                         "adaptive H4 Donchian breakout with D1 trend alignment; requested risk " +
                         DoubleToString(laneRiskPercent, 4) + "%");
      return true;
   }

   bool TryChannelExit(const ulong ticket, const bool buy)
   {
      if(InpATBUseChannelExit)
      {
         double exitHigh = 0.0, exitLow = 0.0;
         if(ChannelBounds(2, InpATBExitLookbackBars, exitHigh, exitLow))
         {
            double closePrice = iClose(_Symbol, InpATBSignalTimeframe, 1);
            bool channelExit = buy ? closePrice < exitLow : closePrice > exitHigh;
            if(channelExit)
            {
               string closeReason = "";
               return CloseOwnedPosition(m_trade, ticket, InpATBMagicNumber, closeReason);
            }
         }
      }
      if(InpATBUseMomentumFailureExit)
      {
         int direction = MomentumDirection();
         if((buy && direction < 0) || (!buy && direction > 0))
         {
            string closeReason = "";
            return CloseOwnedPosition(m_trade, ticket, InpATBMagicNumber, closeReason);
         }
      }
      if(InpATBMaximumHoldBars > 0)
      {
         datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
         int openShift = iBarShift(_Symbol, InpATBSignalTimeframe, openTime, false);
         if(openShift >= InpATBMaximumHoldBars)
         {
            string closeReason = "";
            return CloseOwnedPosition(m_trade, ticket, InpATBMagicNumber, closeReason);
         }
      }
      return false;
   }

   void ImproveProtectiveStop(const ulong ticket, const bool buy)
   {
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double oldSl = PositionGetDouble(POSITION_SL);
      double takeProfit = PositionGetDouble(POSITION_TP);
      double current = buy ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                           : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double initialRisk = GlobalVariableCheck(RiskKey(ticket))
                           ? GlobalVariableGet(RiskKey(ticket))
                           : MathAbs(openPrice - oldSl);
      if(initialRisk <= 0.0 || current <= 0.0)
         return;
      double favorable = buy ? current - openPrice : openPrice - current;
      double r = favorable / initialRisk;
      double newSl = oldSl;
      if(InpATBUseBreakEven && r >= InpATBBreakEvenTriggerR)
      {
         double breakEven = buy ? openPrice + InpATBBreakEvenLockR * initialRisk
                                : openPrice - InpATBBreakEvenLockR * initialRisk;
         if((buy && breakEven > newSl) || (!buy && breakEven < newSl))
            newSl = breakEven;
      }
      newSl = NormalizeDouble(newSl, _Digits);
      double minimumDistance = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      bool valid = buy ? newSl > 0.0 && newSl < current - minimumDistance
                       : newSl > current + minimumDistance;
      bool improved = buy ? newSl > oldSl + _Point : newSl < oldSl - _Point;
      if(valid && improved)
      {
         string modifyReason = "";
         ModifyOwnedPosition(m_trade, ticket, InpATBMagicNumber,
                             newSl, takeProfit, modifyReason);
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
            (ulong)PositionGetInteger(POSITION_MAGIC) != InpATBMagicNumber)
            continue;
         bool buy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
         if(TryChannelExit(ticket, buy))
         {
            closed = true;
            continue;
         }
         if(PositionSelectByTicket(ticket))
            ImproveProtectiveStop(ticket, buy);
      }
      return closed;
   }

   void TryEntry(const double atr)
   {
      string safetyReason = "";
      if(!SafetyAllows(safetyReason))
         return;
      double channelHigh = 0.0, channelLow = 0.0;
      if(!ChannelBounds(2, InpATBEntryLookbackBars, channelHigh, channelLow))
         return;
      double close1 = iClose(_Symbol, InpATBSignalTimeframe, 1);
      double close2 = iClose(_Symbol, InpATBSignalTimeframe, 2);
      if(close1 <= 0.0 || close2 <= 0.0)
         return;
      double buffer = InpATBBreakoutBufferATR * atr;
      bool buyBreak = InpATBAllowBuy && close1 > channelHigh + buffer;
      bool sellBreak = InpATBAllowSell && close1 < channelLow - buffer;
      if(InpATBRequireFreshBreakout)
      {
         double priorHigh = 0.0, priorLow = 0.0;
         if(!ChannelBounds(3, InpATBEntryLookbackBars, priorHigh, priorLow))
            return;
         buyBreak = buyBreak && close2 <= priorHigh + buffer;
         sellBreak = sellBreak && close2 >= priorLow - buffer;
      }
      if(buyBreak && BreakoutQualityAllows(true, atr) && RegimeAllows(true, close1, atr))
         OpenPosition(true, atr);
      else if(sellBreak && BreakoutQualityAllows(false, atr) && RegimeAllows(false, close1, atr))
         OpenPosition(false, atr);
   }

public:
   CAdaptiveTrendBreakoutLane()
   {
      m_atrHandle = INVALID_HANDLE;
      m_trendAtrHandle = INVALID_HANDLE;
      m_trendFastEmaHandle = INVALID_HANDLE;
      m_trendSlowEmaHandle = INVALID_HANDLE;
      m_signalEmaHandle = INVALID_HANDLE;
      m_adxHandle = INVALID_HANDLE;
      m_logHandle = INVALID_HANDLE;
      m_lastSignalBar = 0;
   }

   bool Init()
   {
      if(!InpATBEnabled)
         return true;
      m_atrHandle = iATR(_Symbol, InpATBSignalTimeframe, InpATBATRPeriod);
      m_trendAtrHandle = iATR(_Symbol, InpATBMomentumTimeframe, InpATBATRPeriod);
      m_trendFastEmaHandle = iMA(_Symbol, InpATBMomentumTimeframe,
                                 InpATBTrendFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_trendSlowEmaHandle = iMA(_Symbol, InpATBMomentumTimeframe,
                                 InpATBTrendSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_signalEmaHandle = iMA(_Symbol, InpATBSignalTimeframe,
                              InpATBSignalEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_adxHandle = iADX(_Symbol, InpATBSignalTimeframe, InpATBADXPeriod);
      if(m_atrHandle == INVALID_HANDLE || m_trendAtrHandle == INVALID_HANDLE ||
         m_trendFastEmaHandle == INVALID_HANDLE || m_trendSlowEmaHandle == INVALID_HANDLE ||
         m_signalEmaHandle == INVALID_HANDLE || m_adxHandle == INVALID_HANDLE)
         return false;
      m_trade.SetExpertMagicNumber(InpATBMagicNumber);
      m_trade.SetDeviationInPoints(InpATBDeviationPoints);
      m_trade.SetAsyncMode(false);
      m_trade.SetTypeFillingBySymbol(_Symbol);
      m_logHandle = OpenEvidenceFile(InpATBLogFileName);
      return !InpLogTrades || m_logHandle != INVALID_HANDLE;
   }

   void Deinit()
   {
      if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
      if(m_trendAtrHandle != INVALID_HANDLE) IndicatorRelease(m_trendAtrHandle);
      if(m_trendFastEmaHandle != INVALID_HANDLE) IndicatorRelease(m_trendFastEmaHandle);
      if(m_trendSlowEmaHandle != INVALID_HANDLE) IndicatorRelease(m_trendSlowEmaHandle);
      if(m_signalEmaHandle != INVALID_HANDLE) IndicatorRelease(m_signalEmaHandle);
      if(m_adxHandle != INVALID_HANDLE) IndicatorRelease(m_adxHandle);
      if(m_logHandle != INVALID_HANDLE) FileClose(m_logHandle);
   }

   void OnTick()
   {
      if(!InpATBEnabled)
         return;
      datetime currentBar = iTime(_Symbol, InpATBSignalTimeframe, 0);
      if(currentBar <= 0 || currentBar == m_lastSignalBar)
         return;
      m_lastSignalBar = currentBar;
      double atr = 0.0;
      if(!BufferValue(m_atrHandle, 0, 1, atr) || atr <= 0.0)
         return;
      bool closed = ManagePositionOnBar();
      if(!closed && ManagedPositionCount() == 0)
         TryEntry(atr);
   }

   void OnTradeTransaction(const MqlTradeTransaction &transaction)
   {
      if(transaction.type != TRADE_TRANSACTION_DEAL_ADD || !HistoryDealSelect(transaction.deal))
         return;
      if(HistoryDealGetString(transaction.deal, DEAL_SYMBOL) != _Symbol ||
         (ulong)HistoryDealGetInteger(transaction.deal, DEAL_MAGIC) != InpATBMagicNumber)
         return;
      long entryType = HistoryDealGetInteger(transaction.deal, DEAL_ENTRY);
      if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY && entryType != DEAL_ENTRY_INOUT)
         return;
      if(transaction.position > 0)
         VerifiedGlobalDelete(RiskKey(transaction.position));
      double profit = HistoryDealGetDouble(transaction.deal, DEAL_PROFIT) +
                      HistoryDealGetDouble(transaction.deal, DEAL_SWAP) +
                      HistoryDealGetDouble(transaction.deal, DEAL_COMMISSION);
      WriteEvidenceEvent(m_logHandle, "atb_h4_d1", "exit", transaction.deal, "close",
                         HistoryDealGetDouble(transaction.deal, DEAL_VOLUME),
                         HistoryDealGetDouble(transaction.deal, DEAL_PRICE), 0.0, profit,
                         HistoryDealGetString(transaction.deal, DEAL_COMMENT));
   }
};

CReversionLane g_reversion;
CMomentumLane g_momentum;
CAdaptiveTrendBreakoutLane g_adaptiveTrend;

bool InputsValid()
{
   if(InpRVMagicNumber == InpMOMagicNumber ||
      InpRVMagicNumber == InpATBMagicNumber ||
      InpMOMagicNumber == InpATBMagicNumber ||
      InpPortfolioMagic == InpRVMagicNumber ||
      InpPortfolioMagic == InpMOMagicNumber ||
      InpPortfolioMagic == InpATBMagicNumber ||
      InpMaximumPortfolioOpenRiskPercent <= 0.0 ||
      InpMaximumAccountPositions < 1 ||
      (InpUseInitialBalanceContract && InpExpectedInitialBalance <= 0.0) ||
      InpInitialBalanceTolerancePercent < 0.0 ||
      (InpUseAccountCurrencyLock && StringLen(InpRequiredAccountCurrency) < 3) ||
      InpMaximumPortfolioDailyLossPercent < 0.0 ||
      InpMaximumPortfolioWeeklyLossPercent < 0.0 ||
      InpMaximumPortfolioMonthlyLossPercent < 0.0 ||
      (InpMaximumPortfolioWeeklyLossPercent > 0.0 &&
       InpMaximumPortfolioDailyLossPercent > 0.0 &&
       InpMaximumPortfolioWeeklyLossPercent < InpMaximumPortfolioDailyLossPercent) ||
      (InpMaximumPortfolioMonthlyLossPercent > 0.0 &&
       InpMaximumPortfolioWeeklyLossPercent > 0.0 &&
       InpMaximumPortfolioMonthlyLossPercent < InpMaximumPortfolioWeeklyLossPercent) ||
      InpMaximumPortfolioConsecutiveLosses < 0 ||
      InpPortfolioLossCooldownHours < 0 ||
      InpMinimumMarginLevelPercent < 0.0 ||
      InpMaximumQuoteAgeSeconds < 0 ||
      InpMaximumStopsLevelPoints < 0.0 ||
      InpMaximumFreezeLevelPoints < 0.0 ||
      InpPostFillRiskTolerancePercent < 0.0 ||
      InpPostFillRiskTolerancePercent > 0.05 ||
      InpRVRiskPercent <= 0.0 || InpRVRiskPercent > 2.0 ||
      InpMORiskPercent <= 0.0 || InpMORiskPercent > 2.0 ||
      InpATBRiskPercent <= 0.0 || InpATBRiskPercent > 2.0 ||
      InpResidualRiskReservePercent < 0.0 ||
      InpResidualRiskReservePercent >= InpMaximumPortfolioOpenRiskPercent ||
      InpRVMaximumEntryRiskPercent < InpRVRiskPercent ||
      InpRVMaximumEntryRiskPercent > InpMaximumPortfolioOpenRiskPercent ||
      InpMOMaximumEntryRiskPercent < InpMORiskPercent ||
      InpMOMaximumEntryRiskPercent > InpMaximumPortfolioOpenRiskPercent ||
      InpATBMaximumEntryRiskPercent < InpATBRiskPercent ||
      InpATBMaximumEntryRiskPercent > InpMaximumPortfolioOpenRiskPercent ||
      InpRVRiskPercent + InpMORiskPercent + InpATBRiskPercent > InpMaximumPortfolioOpenRiskPercent + 1e-9)
      return false;
   if(InpRVATRPeriod < 2 || InpRVADXPeriod < 2 || InpRVRSIPeriod < 2 ||
      InpRVBollingerPeriod < 2 || InpRVBollingerDeviation <= 0.0 ||
      InpRVVWAPLookbackBars < 5 || InpRVStopLookbackBars < 2 ||
      (InpRVUseD1MomentumCap &&
       (InpRVD1MomentumLookbackBars < 20 ||
        InpRVMaximumAbsoluteD1MomentumPercent <= 0.0 ||
        InpRVMaximumAbsoluteD1MomentumPercent > 100.0)))
      return false;
   if(InpMOMomentumLookbackBars < 20 || InpMOEntryLookbackBars < 3 ||
      InpMOStopLookbackBars < 2 || InpMOExitLookbackBars < 2 ||
      InpMOATRPeriod < 2 || InpMOStopBufferATR < 0.0 ||
      InpMOMinimumStopATR <= 0.0 || InpMOMaximumStopATR < InpMOMinimumStopATR ||
      InpMOTakeProfitR <= 0.0 || InpMOMaximumHoldBars < 0 ||
      InpMOSessionStartHour < 0 || InpMOSessionStartHour > 23 ||
      InpMOSessionEndHour < 0 || InpMOSessionEndHour > 23)
      return false;
   if(InpATBMomentumLookbackBars < 20 || InpATBEntryLookbackBars < 3 ||
      InpATBStopLookbackBars < 2 || InpATBExitLookbackBars < 2 ||
      InpATBATRPeriod < 2 || InpATBStopBufferATR < 0.0 ||
      InpATBTrendFastEMAPeriod < 2 || InpATBTrendSlowEMAPeriod <= InpATBTrendFastEMAPeriod ||
      InpATBTrendSlopeLookbackBars < 1 || InpATBMinimumTrendSlopeATR < 0.0 ||
      InpATBSignalEMAPeriod < 2 || InpATBSignalEMASlopeLookbackBars < 1 ||
      InpATBMinimumSignalSlopeATR < 0.0 || InpATBADXPeriod < 2 ||
      InpATBMinimumADX < 0.0 || (InpATBMaximumADX > 0.0 && InpATBMaximumADX < InpATBMinimumADX) ||
      InpATBMinimumBreakoutBodyPercent < 0.0 || InpATBMinimumBreakoutBodyPercent > 100.0 ||
      InpATBMinimumBreakoutCloseLocationPercent < 0.0 || InpATBMinimumBreakoutCloseLocationPercent > 100.0 ||
      InpATBMinimumBreakoutRangeATR < 0.0 ||
      (InpATBMaximumBreakoutRangeATR > 0.0 && InpATBMaximumBreakoutRangeATR < InpATBMinimumBreakoutRangeATR) ||
      InpATBTickVolumeLookbackBars < 2 || InpATBMinimumTickVolumeRatio < 0.0 ||
      InpATBMinimumStopATR <= 0.0 || InpATBMaximumStopATR < InpATBMinimumStopATR ||
      InpATBTakeProfitR <= 0.0 || InpATBMaximumHoldBars < 0 ||
      InpATBSessionStartHour < 0 || InpATBSessionStartHour > 23 ||
      InpATBSessionEndHour < 0 || InpATBSessionEndHour > 23)
      return false;
   return true;
}

void UpdateDashboard()
{
   if(!InpShowDashboard)
      return;
   string safety = "";
   bool allowed = SharedSafetyAllows(safety);
   bool unprotected = false;
   int positions = 0;
   double openRisk = AccountWideOpenRiskPercent(unprotected, positions);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double drawdown = g_peakEquity > 0.0 ? 100.0 * (g_peakEquity - equity) / g_peakEquity : 0.0;
   RefreshPortfolioRiskState();
   Comment("XAUUSD Transferable Portfolio\n",
           "State: ", allowed ? "READY" : "LOCKED", " (", safety, ")\n",
           "Equity: ", DoubleToString(equity, 2),
           "  Drawdown: ", DoubleToString(drawdown, 2), "%\n",
           "Spread: ", DoubleToString(SpreadPoints(), 1), " pts",
           "  Positions: ", IntegerToString(positions),
           "  Open risk: ", DoubleToString(openRisk, 2), "%\n",
           "Closed P/L: D ", DoubleToString(g_cachedDailyProfit, 2),
           "  W ", DoubleToString(g_cachedWeeklyProfit, 2),
           "  M ", DoubleToString(g_cachedMonthlyProfit, 2), "\n",
           "Loss streak: ", IntegerToString(g_cachedPortfolioLossStreak),
           "  Margin: ", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 1), "%\n",
           "Lane risk: RV ", DoubleToString(InpRVRiskPercent, 2),
           "% + MOM ", DoubleToString(InpMORiskPercent, 2),
           "% + ATB ", DoubleToString(InpATBRiskPercent, 2), "%");
}

int OnInit()
{
   if(!InputsValid())
      return INIT_PARAMETERS_INCORRECT;
   g_persistenceHealthy = true;
   string accountReason = "";
   if(!StaticSafetyAllows(accountReason))
   {
      Print("SAFETY: initialization blocked by ", accountReason);
      return INIT_FAILED;
   }
   if(!InitialAccountContractAllows(accountReason))
   {
      Print("SAFETY: initialization blocked by ", accountReason);
      return INIT_FAILED;
   }
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(!MQLInfoInteger(MQL_TESTER) && GlobalVariableCheck(PeakEquityKey()))
      g_peakEquity = MathMax(g_peakEquity, GlobalVariableGet(PeakEquityKey()));
   RefreshDayState();
   g_portfolioRiskStateDirty = true;
   g_guardTrade.SetAsyncMode(false);
   g_guardTrade.SetExpertMagicNumber(InpPortfolioMagic);
   g_guardTrade.SetDeviationInPoints((ulong)MathMax(MathMax(InpRVDeviationPoints,
                                                            InpMODeviationPoints),
                                                    InpATBDeviationPoints));
   g_guardTrade.SetTypeFillingBySymbol(_Symbol);
   if(!AuditManagedOrders())
      return INIT_FAILED;
   if(!g_reversion.Init())
      return INIT_FAILED;
   if(!g_momentum.Init())
   {
      g_reversion.Deinit();
      return INIT_FAILED;
   }
   if(!g_adaptiveTrend.Init())
   {
      g_momentum.Deinit();
      g_reversion.Deinit();
      return INIT_FAILED;
   }
   if(!MQLInfoInteger(MQL_TESTER))
      EventSetTimer(5);
   else if(InpShowDashboard)
      EventSetTimer(1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   g_reversion.Deinit();
   g_momentum.Deinit();
   g_adaptiveTrend.Deinit();
   Comment("");
}

void OnTick()
{
   RefreshDayState();
   AuditManagedOrders();
   AuditManagedPositionProtection();
   string reason = "";
   SharedSafetyAllows(reason);
   g_sharedSafetyReason = reason;
   g_reversion.OnTick();
   g_momentum.OnTick();
   g_adaptiveTrend.OnTick();
}

void OnTimer()
{
   AuditManagedOrders();
   AuditManagedPositionProtection();
   UpdateDashboard();
}

void OnTradeTransaction(const MqlTradeTransaction &transaction,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   g_portfolioRiskStateDirty = true;
   g_accountHistoryStateDirty = true;
   g_reversion.OnTradeTransaction(transaction);
   g_momentum.OnTradeTransaction(transaction);
   g_adaptiveTrend.OnTradeTransaction(transaction);
}

double OnTester()
{
   double profit = TesterStatistics(STAT_PROFIT);
   double drawdown = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);
   double trades = TesterStatistics(STAT_TRADES);
   if(trades < 330.0)
      return profit - (330.0 - trades) * 1000.0;
   return profit * MathMax(0.0, MathMin(5.0, profitFactor)) /
          (1.0 + MathMax(0.0, drawdown));
}

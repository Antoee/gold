#property strict
#property version   "1.10"
#property description "Read-only dedicated-account heartbeat for the rc2 XAUUSD forward demo"

input group "Frozen Forward Identity"
input string InpExpectedSymbol = "XAUUSD";
input string InpExpectedCurrency = "USD";
input ulong  InpPortfolioMagic = 26071781;
input ulong  InpRVMagicNumber = 26071721;
input ulong  InpMOMagicNumber = 26071761;
input string InpRunLabel = "operational_hardening_rc2_forward_frozen";
input string InpEvidenceSourceHash = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302";
input string InpEvidenceProfileHash = "8B3A06E9776EA99C1DDE02A14F098B0837653B34B0AAD56491D0FE0248FEEC57";

input group "Read-Only Heartbeat"
input string InpHeartbeatFileName = "OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL.csv";
input int    InpHeartbeatSeconds = 60;

bool IsCandidateMagic(const ulong magic)
{
   return magic == InpPortfolioMagic || magic == InpRVMagicNumber || magic == InpMOMagicNumber;
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

bool AccountHistorySnapshot(int &fundingAdjustmentCount, int &foreignTradeCount)
{
   fundingAdjustmentCount = 0;
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
         fundingAdjustmentCount++;
         continue;
      }
      if(dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL)
      {
         string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         ulong magic = (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC);
         if(symbol != InpExpectedSymbol || !IsCandidateMagic(magic))
            foreignTradeCount++;
      }
   }
   return true;
}

string AccountTradeModeText()
{
   ENUM_ACCOUNT_TRADE_MODE mode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(mode == ACCOUNT_TRADE_MODE_DEMO) return "demo";
   if(mode == ACCOUNT_TRADE_MODE_CONTEST) return "contest";
   if(mode == ACCOUNT_TRADE_MODE_REAL) return "real";
   return "unknown";
}

string MarginModeText()
{
   ENUM_ACCOUNT_MARGIN_MODE mode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   if(mode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) return "hedging";
   if(mode == ACCOUNT_MARGIN_MODE_RETAIL_NETTING) return "retail_netting";
   if(mode == ACCOUNT_MARGIN_MODE_EXCHANGE) return "exchange";
   return "unknown";
}

bool PositionRiskMoney(const ulong ticket, double &riskMoney, bool &unprotected)
{
   riskMoney = 0.0;
   unprotected = false;
   if(ticket == 0 || !PositionSelectByTicket(ticket))
      return false;

   string symbol = PositionGetString(POSITION_SYMBOL);
   double volume = PositionGetDouble(POSITION_VOLUME);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double stopPrice = PositionGetDouble(POSITION_SL);
   long positionType = PositionGetInteger(POSITION_TYPE);
   if(StringLen(symbol) <= 0 || volume <= 0.0 || openPrice <= 0.0 || stopPrice <= 0.0)
   {
      unprotected = true;
      return true;
   }

   ENUM_ORDER_TYPE orderType;
   if(positionType == POSITION_TYPE_BUY)
   {
      if(stopPrice >= openPrice)
         return true;
      orderType = ORDER_TYPE_BUY;
   }
   else if(positionType == POSITION_TYPE_SELL)
   {
      if(stopPrice <= openPrice)
         return true;
      orderType = ORDER_TYPE_SELL;
   }
   else
   {
      unprotected = true;
      return true;
   }

   double stopProfit = 0.0;
   if(!OrderCalcProfit(orderType, symbol, volume, openPrice, stopPrice, stopProfit))
   {
      unprotected = true;
      return false;
   }
   riskMoney = MathAbs(stopProfit);
   return MathIsValidNumber(riskMoney);
}

void PositionSnapshot(int &allPositions,
                      int &candidatePositions,
                      int &allUnprotected,
                      int &candidateUnprotected,
                      double &candidateRiskMoney)
{
   allPositions = PositionsTotal();
   candidatePositions = 0;
   allUnprotected = 0;
   candidateUnprotected = 0;
   candidateRiskMoney = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      bool candidate = IsCandidateMagic(magic);
      if(candidate)
         candidatePositions++;

      double riskMoney = 0.0;
      bool unprotected = false;
      PositionRiskMoney(ticket, riskMoney, unprotected);
      if(unprotected)
      {
         allUnprotected++;
         if(candidate)
            candidateUnprotected++;
      }
      if(candidate)
         candidateRiskMoney += riskMoney;
   }
}

bool WriteHeartbeat()
{
   int allPositions = 0;
   int candidatePositions = 0;
   int allUnprotected = 0;
   int candidateUnprotected = 0;
   double candidateRiskMoney = 0.0;
   PositionSnapshot(allPositions, candidatePositions, allUnprotected,
                    candidateUnprotected, candidateRiskMoney);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double candidateOpenRiskPercent = equity > 0.0
                                     ? 100.0 * candidateRiskMoney / equity
                                     : -1.0;
   int fundingAdjustmentCount = 0;
   int foreignTradeCount = 0;
   bool historyAvailable = AccountHistorySnapshot(fundingAdjustmentCount, foreignTradeCount);
   int handle = FileOpen(InpHeartbeatFileName,
                         FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_ANSI,
                         '\t');
   if(handle == INVALID_HANDLE)
      return false;

   FileWrite(handle,
             "local_time", "server_time", "run_label", "source_sha256",
             "profile_sha256", "account_trade_mode", "margin_mode",
             "account_currency", "history_available", "funding_adjustment_count",
             "foreign_trade_count",
             "connected", "terminal_trade_allowed", "account_trade_allowed",
             "account_expert_allowed", "mql_trade_allowed", "expected_symbol",
             "balance", "equity", "all_positions", "candidate_positions",
             "all_unprotected_positions", "candidate_unprotected_positions",
             "candidate_open_risk_percent");
   FileWrite(handle,
             TimeToString(TimeLocal(), TIME_DATE | TIME_SECONDS),
             TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
             InpRunLabel,
             InpEvidenceSourceHash,
             InpEvidenceProfileHash,
             AccountTradeModeText(),
             MarginModeText(),
             AccountInfoString(ACCOUNT_CURRENCY),
             historyAvailable ? "true" : "false",
             IntegerToString(fundingAdjustmentCount),
             IntegerToString(foreignTradeCount),
             TerminalInfoInteger(TERMINAL_CONNECTED) ? "true" : "false",
             TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ? "true" : "false",
             AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ? "true" : "false",
             AccountInfoInteger(ACCOUNT_TRADE_EXPERT) ? "true" : "false",
             MQLInfoInteger(MQL_TRADE_ALLOWED) ? "true" : "false",
             InpExpectedSymbol,
             DoubleToString(balance, 2),
             DoubleToString(equity, 2),
             IntegerToString(allPositions),
             IntegerToString(candidatePositions),
             IntegerToString(allUnprotected),
             IntegerToString(candidateUnprotected),
             DoubleToString(candidateOpenRiskPercent, 4));
   FileFlush(handle);
   FileClose(handle);
   return true;
}

int OnInit()
{
   if(StringLen(InpHeartbeatFileName) <= 0 || StringLen(InpRunLabel) <= 0 ||
      StringLen(InpExpectedCurrency) < 3 ||
      StringLen(InpEvidenceSourceHash) != 64 || StringLen(InpEvidenceProfileHash) != 64 ||
      InpHeartbeatSeconds < 10)
      return INIT_PARAMETERS_INCORRECT;
   if(!EventSetTimer(InpHeartbeatSeconds))
      return INIT_FAILED;
   if(!WriteHeartbeat())
      return INIT_FAILED;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
}

void OnTimer()
{
   WriteHeartbeat();
}

void OnTradeTransaction(const MqlTradeTransaction &transaction,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   WriteHeartbeat();
}

void OnTick()
{
}

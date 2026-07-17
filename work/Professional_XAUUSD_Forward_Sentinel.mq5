#property strict
#property version   "1.00"
#property description "Read-only operational heartbeat for the frozen XAUUSD forward demo"

input group "Frozen Forward Identity"
input string InpExpectedSymbol = "XAUUSD";
input ulong  InpRVMagicNumber = 26071721;
input ulong  InpMOMagicNumber = 26071761;
input string InpRunLabel = "frozen_forward_20260717";
input string InpEvidenceSourceHash = "5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3";
input string InpEvidenceProfileHash = "CB1A4A78834C9780267F9EA06DB24E656FFAE87DC466D4442926F55562F3321D";

input group "Read-Only Heartbeat"
input string InpHeartbeatFileName = "TRANSFERABLE_FORWARD_SENTINEL.csv";
input int    InpHeartbeatSeconds = 60;

bool IsCandidateMagic(const ulong magic)
{
   return magic == InpRVMagicNumber || magic == InpMOMagicNumber;
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
   int handle = FileOpen(InpHeartbeatFileName,
                         FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_ANSI,
                         '\t');
   if(handle == INVALID_HANDLE)
      return false;

   FileWrite(handle,
             "local_time", "server_time", "run_label", "source_sha256",
             "profile_sha256", "account_trade_mode", "margin_mode",
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

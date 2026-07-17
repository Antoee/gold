#property strict
#property version   "1.00"
#property description "No-trading broker-accurate capital-feasibility probe for XAUUSD H4 channel signals"

input group "Safety"
input string InpAllowedSymbol = "XAUUSD";
input bool   InpUseSymbolSafetyLock = true;
input bool   InpUseRealAccountSafetyLock = true;

input group "Signal Contract"
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_H4;
input int    InpEntryLookbackBars = 55;
input bool   InpRequireFreshBreakout = true;
input double InpBreakoutBufferATR = 0.00;
input int    InpATRPeriod = 20;
input double InpInitialStopATR = 2.00;
input bool   InpUseVolatilityFilter = true;
input double InpMinimumATRPercent = 0.20;
input double InpMaximumATRPercent = 5.00;

input group "Capital Contract"
input double InpAssumedEquity = 10000.00;
input double InpRiskPercent = 0.10;

input group "Evidence"
input string InpProbeId = "h4ct_capital_55";
input string InpSourceSha256 = "";
input string InpOutputFileName = "XAUUSD_H4_Channel_Capital_Feasibility.csv";

int      g_atrHandle = INVALID_HANDLE;
datetime g_lastSignalBar = 0;
double   g_requiredEquity[];
double   g_stopDistance[];
int      g_signalYear[];
int      g_failureYear[];

bool BufferValue(const int handle, const int shift, double &value)
{
   double values[];
   ArraySetAsSeries(values, true);
   if(handle == INVALID_HANDLE || CopyBuffer(handle, 0, shift, 1, values) != 1)
      return false;
   value = values[0];
   return MathIsValidNumber(value) && value != EMPTY_VALUE;
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

void AppendDouble(double &values[], const double value)
{
   int size = ArraySize(values);
   ArrayResize(values, size + 1);
   values[size] = value;
}

void AppendInt(int &values[], const int value)
{
   int size = ArraySize(values);
   ArrayResize(values, size + 1);
   values[size] = value;
}

double Percentile(const double &values[], const double percentile)
{
   int count = ArraySize(values);
   if(count <= 0)
      return 0.0;
   double sorted[];
   ArrayCopy(sorted, values);
   ArraySort(sorted);
   double bounded = MathMax(0.0, MathMin(1.0, percentile));
   double position = bounded * (count - 1);
   int lower = (int)MathFloor(position);
   int upper = (int)MathCeil(position);
   if(lower == upper)
      return sorted[lower];
   double weight = position - lower;
   return sorted[lower] * (1.0 - weight) + sorted[upper] * weight;
}

double Mean(const double &values[])
{
   int count = ArraySize(values);
   if(count <= 0)
      return 0.0;
   double total = 0.0;
   for(int i = 0; i < count; ++i)
      total += values[i];
   return total / count;
}

int SignalYear(const int index)
{
   if(index < 0 || index >= ArraySize(g_signalYear))
      return 0;
   return g_signalYear[index];
}

void ValuesForYear(const int year, double &required[], double &stops[])
{
   ArrayResize(required, 0);
   ArrayResize(stops, 0);
   for(int i = 0; i < ArraySize(g_requiredEquity); ++i)
   {
      if(year != 0 && SignalYear(i) != year)
         continue;
      AppendDouble(required, g_requiredEquity[i]);
      AppendDouble(stops, g_stopDistance[i]);
   }
}

int FailuresForYear(const int year)
{
   int count = 0;
   for(int i = 0; i < ArraySize(g_failureYear); ++i)
   {
      if(year == 0 || g_failureYear[i] == year)
         count++;
   }
   return count;
}

int YearFromTime(const datetime value)
{
   MqlDateTime parts;
   if(!TimeToStruct(value, parts))
      return 0;
   return parts.year;
}

bool CurrentBreakoutSignal(const double atr, bool &buy)
{
   double channelHigh = 0.0;
   double channelLow = 0.0;
   if(!ChannelBounds(2, InpEntryLookbackBars, channelHigh, channelLow))
      return false;
   double close1 = iClose(_Symbol, InpSignalTimeframe, 1);
   double close2 = iClose(_Symbol, InpSignalTimeframe, 2);
   if(close1 <= 0.0 || close2 <= 0.0)
      return false;
   if(InpUseVolatilityFilter)
   {
      double atrPercent = 100.0 * atr / close1;
      if(atrPercent < InpMinimumATRPercent || atrPercent > InpMaximumATRPercent)
         return false;
   }
   double buffer = InpBreakoutBufferATR * atr;
   bool buyBreak = close1 > channelHigh + buffer;
   bool sellBreak = close1 < channelLow - buffer;
   if(InpRequireFreshBreakout)
   {
      double priorHigh = 0.0;
      double priorLow = 0.0;
      if(!ChannelBounds(3, InpEntryLookbackBars, priorHigh, priorLow))
         return false;
      buyBreak = buyBreak && close2 <= priorHigh + buffer;
      sellBreak = sellBreak && close2 >= priorLow - buffer;
   }
   if(buyBreak == sellBreak)
      return false;
   buy = buyBreak;
   return true;
}

void RecordSignal(const bool buy, const double atr, const int year)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
   {
      AppendInt(g_failureYear, year);
      return;
   }
   double minimumVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double entryPrice = buy ? tick.ask : tick.bid;
   double stopDistance = InpInitialStopATR * atr;
   double stopPrice = buy ? entryPrice - stopDistance : entryPrice + stopDistance;
   double stopProfit = 0.0;
   ENUM_ORDER_TYPE orderType = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(minimumVolume <= 0.0 || stopPrice <= 0.0 ||
      !OrderCalcProfit(orderType, _Symbol, minimumVolume, entryPrice, stopPrice, stopProfit))
   {
      AppendInt(g_failureYear, year);
      return;
   }
   double minimumLotLoss = MathAbs(stopProfit);
   double riskFraction = InpRiskPercent / 100.0;
   if(minimumLotLoss <= 0.0 || riskFraction <= 0.0)
   {
      AppendInt(g_failureYear, year);
      return;
   }
   AppendDouble(g_requiredEquity, minimumLotLoss / riskFraction);
   AppendDouble(g_stopDistance, stopDistance);
   AppendInt(g_signalYear, year);
}

void WriteEvidenceRow(const int handle, const int year)
{
   double required[];
   double stops[];
   ValuesForYear(year, required, stops);
   int signals = ArraySize(required);
   int feasible = 0;
   for(int i = 0; i < signals; ++i)
   {
      if(required[i] <= InpAssumedEquity + 1e-8)
         feasible++;
   }
   double feasiblePercent = signals > 0 ? 100.0 * feasible / signals : 0.0;
   string rowType = year == 0 ? "summary" : "year";
   FileWrite(handle,
             rowType,
             InpProbeId,
             year,
             InpSourceSha256,
             _Symbol,
             EnumToString(InpSignalTimeframe),
             InpEntryLookbackBars,
             InpATRPeriod,
             DoubleToString(InpInitialStopATR, 2),
             DoubleToString(InpRiskPercent, 4),
             DoubleToString(InpAssumedEquity, 2),
             DoubleToString(InpAssumedEquity * InpRiskPercent / 100.0, 2),
             DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), 4),
             DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP), 4),
             signals,
             feasible,
             DoubleToString(feasiblePercent, 4),
             FailuresForYear(year),
             DoubleToString(Percentile(required, 0.00), 2),
             DoubleToString(Mean(required), 2),
             DoubleToString(Percentile(required, 0.50), 2),
             DoubleToString(Percentile(required, 0.75), 2),
             DoubleToString(Percentile(required, 0.90), 2),
             DoubleToString(Percentile(required, 0.95), 2),
             DoubleToString(Percentile(required, 1.00), 2),
             DoubleToString(Percentile(stops, 0.00), _Digits),
             DoubleToString(Mean(stops), _Digits),
             DoubleToString(Percentile(stops, 0.50), _Digits),
             DoubleToString(Percentile(stops, 0.95), _Digits),
             DoubleToString(Percentile(stops, 1.00), _Digits));
}

void WriteEvidence()
{
   bool fileExisted = FileIsExist(InpOutputFileName, FILE_COMMON);
   int handle = FileOpen(InpOutputFileName,
                         FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_SHARE_READ | FILE_SHARE_WRITE,
                         ',');
   if(handle == INVALID_HANDLE)
   {
      Print("CAPITAL_FEASIBILITY_FILE_ERROR code=", GetLastError());
      return;
   }
   if(!fileExisted || FileSize(handle) <= 0)
   {
      FileWrite(handle,
                "row_type", "probe_id", "year", "source_sha256", "symbol", "timeframe",
                "entry_lookback", "atr_period", "stop_atr", "risk_percent", "assumed_equity",
                "risk_budget", "minimum_volume", "volume_step", "signals", "feasible_signals",
                "feasible_percent", "order_calc_failures", "required_equity_min", "required_equity_mean",
                "required_equity_p50", "required_equity_p75", "required_equity_p90", "required_equity_p95",
                "required_equity_max", "stop_distance_min", "stop_distance_mean", "stop_distance_p50",
                "stop_distance_p95", "stop_distance_max");
   }
   FileSeek(handle, 0, SEEK_END);
   WriteEvidenceRow(handle, 0);
   for(int year = 2010; year <= 2035; ++year)
   {
      bool found = false;
      for(int i = 0; i < ArraySize(g_signalYear); ++i)
      {
         if(g_signalYear[i] == year)
         {
            found = true;
            break;
         }
      }
      if(found || FailuresForYear(year) > 0)
         WriteEvidenceRow(handle, year);
   }
   FileFlush(handle);
   FileClose(handle);
}

int OnInit()
{
   if(InpEntryLookbackBars < 10 || InpATRPeriod < 2 || InpInitialStopATR <= 0.0 ||
      InpAssumedEquity <= 0.0 || InpRiskPercent <= 0.0)
      return INIT_PARAMETERS_INCORRECT;
   if(InpUseSymbolSafetyLock && StringFind(_Symbol, InpAllowedSymbol) < 0)
      return INIT_FAILED;
   ENUM_ACCOUNT_TRADE_MODE mode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(InpUseRealAccountSafetyLock && mode == ACCOUNT_TRADE_MODE_REAL)
      return INIT_FAILED;
   g_atrHandle = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);
   return g_atrHandle == INVALID_HANDLE ? INIT_FAILED : INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   WriteEvidence();
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
}

void OnTick()
{
   datetime currentBar = iTime(_Symbol, InpSignalTimeframe, 0);
   if(currentBar <= 0 || currentBar == g_lastSignalBar)
      return;
   g_lastSignalBar = currentBar;
   double atr = 0.0;
   if(!BufferValue(g_atrHandle, 1, atr) || atr <= 0.0)
      return;
   bool buy = false;
   if(!CurrentBreakoutSignal(atr, buy))
      return;
   int year = YearFromTime(iTime(_Symbol, InpSignalTimeframe, 1));
   RecordSignal(buy, atr, year);
}

double OnTester()
{
   int signals = ArraySize(g_requiredEquity);
   if(signals <= 0)
      return 0.0;
   int feasible = 0;
   for(int i = 0; i < signals; ++i)
   {
      if(g_requiredEquity[i] <= InpAssumedEquity + 1e-8)
         feasible++;
   }
   return 100.0 * feasible / signals;
}

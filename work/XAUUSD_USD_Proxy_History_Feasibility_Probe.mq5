#property strict
#property version   "1.00"
#property description "No-trading pre-2021 XAUUSD/USD-proxy M15 history-alignment feasibility probe"

input group "Safety"
input string InpAllowedSymbol = "XAUUSD";
input bool   InpUseSymbolSafetyLock = true;
input bool   InpUseRealAccountSafetyLock = true;

input group "History Contract"
input string InpReferenceSymbol = "EURUSD";
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_M15;
input int    InpMaximumAlignmentSeconds = 900;
input int    InpRequiredLookbackBars = 32;

input group "Evidence"
input string InpProbeId = "xau_usd_proxy_history_feasibility";
input string InpSourceSha256 = "";
input string InpOutputFileName = "XAUUSD_USD_Proxy_History_Feasibility.csv";

#define FIRST_EVIDENCE_YEAR 2010
#define LAST_EVIDENCE_YEAR  2035
#define EVIDENCE_YEAR_COUNT (LAST_EVIDENCE_YEAR - FIRST_EVIDENCE_YEAR + 1)

datetime g_lastSignalBar = 0;
int      g_xauBars[EVIDENCE_YEAR_COUNT];
int      g_alignedBars[EVIDENCE_YEAR_COUNT];
int      g_lookbackReadyBars[EVIDENCE_YEAR_COUNT];
int      g_missingBars[EVIDENCE_YEAR_COUNT];
long     g_maxAlignmentSeconds[EVIDENCE_YEAR_COUNT];
datetime g_firstAlignedBar[EVIDENCE_YEAR_COUNT];
datetime g_lastAlignedBar[EVIDENCE_YEAR_COUNT];

int YearFromTime(const datetime value)
{
   MqlDateTime parts;
   if(!TimeToStruct(value, parts))
      return 0;
   return parts.year;
}

int YearIndex(const int year)
{
   if(year < FIRST_EVIDENCE_YEAR || year > LAST_EVIDENCE_YEAR)
      return -1;
   return year - FIRST_EVIDENCE_YEAR;
}

datetime YearStart(const int year)
{
   return StringToTime(IntegerToString(year) + ".01.01 00:00");
}

void RecordClosedBar()
{
   datetime xauTime = iTime(_Symbol, InpSignalTimeframe, 1);
   if(xauTime <= 0)
      return;
   int index = YearIndex(YearFromTime(xauTime));
   if(index < 0)
      return;

   g_xauBars[index]++;
   int referenceShift = iBarShift(InpReferenceSymbol, InpSignalTimeframe, xauTime, false);
   if(referenceShift < 0)
   {
      g_missingBars[index]++;
      return;
   }

   datetime referenceTime = iTime(InpReferenceSymbol, InpSignalTimeframe, referenceShift);
   double referenceClose = iClose(InpReferenceSymbol, InpSignalTimeframe, referenceShift);
   long alignmentSeconds = (long)MathAbs((double)(xauTime - referenceTime));
   if(referenceTime <= 0 || referenceClose <= 0.0 || alignmentSeconds > InpMaximumAlignmentSeconds)
   {
      g_missingBars[index]++;
      return;
   }

   g_alignedBars[index]++;
   g_maxAlignmentSeconds[index] = MathMax(g_maxAlignmentSeconds[index], alignmentSeconds);
   if(g_firstAlignedBar[index] == 0 || xauTime < g_firstAlignedBar[index])
      g_firstAlignedBar[index] = xauTime;
   if(xauTime > g_lastAlignedBar[index])
      g_lastAlignedBar[index] = xauTime;

   double lookbackClose = iClose(InpReferenceSymbol,
                                 InpSignalTimeframe,
                                 referenceShift + InpRequiredLookbackBars);
   if(lookbackClose > 0.0)
      g_lookbackReadyBars[index]++;
}

void WriteEvidenceRow(const int handle, const int year)
{
   int index = YearIndex(year);
   if(index < 0)
      return;
   int xauBars = g_xauBars[index];
   int alignedBars = g_alignedBars[index];
   double alignmentPercent = xauBars > 0 ? 100.0 * alignedBars / xauBars : 0.0;
   double lookbackReadyPercent = alignedBars > 0
                                 ? 100.0 * g_lookbackReadyBars[index] / alignedBars
                                 : 0.0;
   int brokerReferenceBars = Bars(InpReferenceSymbol,
                                  InpSignalTimeframe,
                                  YearStart(year),
                                  YearStart(year + 1) - 1);
   FileWrite(handle,
             InpProbeId,
             year,
             InpSourceSha256,
             _Symbol,
             InpReferenceSymbol,
             EnumToString(InpSignalTimeframe),
             xauBars,
             brokerReferenceBars,
             alignedBars,
             g_missingBars[index],
             DoubleToString(alignmentPercent, 4),
             g_lookbackReadyBars[index],
             DoubleToString(lookbackReadyPercent, 4),
             g_maxAlignmentSeconds[index],
             TimeToString(g_firstAlignedBar[index], TIME_DATE | TIME_MINUTES),
             TimeToString(g_lastAlignedBar[index], TIME_DATE | TIME_MINUTES),
             IntegerToString((int)SymbolInfoInteger(InpReferenceSymbol, SYMBOL_DIGITS)),
             DoubleToString(SymbolInfoDouble(InpReferenceSymbol, SYMBOL_POINT), 8),
             DoubleToString(SymbolInfoDouble(InpReferenceSymbol, SYMBOL_VOLUME_MIN), 4));
}

void WriteEvidence()
{
   bool fileExisted = FileIsExist(InpOutputFileName, FILE_COMMON);
   int handle = FileOpen(InpOutputFileName,
                         FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_SHARE_READ | FILE_SHARE_WRITE,
                         ',');
   if(handle == INVALID_HANDLE)
   {
      Print("XAU_USD_PROXY_HISTORY_FILE_ERROR code=", GetLastError());
      return;
   }
   if(!fileExisted || FileSize(handle) <= 0)
   {
      FileWrite(handle,
                "probe_id", "year", "source_sha256", "trade_symbol", "reference_symbol", "timeframe",
                "xau_closed_bars", "broker_reference_bars", "aligned_bars", "missing_bars",
                "alignment_percent", "lookback_ready_bars", "lookback_ready_percent",
                "maximum_alignment_seconds", "first_aligned_bar", "last_aligned_bar",
                "reference_digits", "reference_point", "reference_minimum_volume");
   }
   FileSeek(handle, 0, SEEK_END);
   for(int year = FIRST_EVIDENCE_YEAR; year <= LAST_EVIDENCE_YEAR; ++year)
   {
      int index = YearIndex(year);
      if(index >= 0 && g_xauBars[index] > 0)
         WriteEvidenceRow(handle, year);
   }
   FileFlush(handle);
   FileClose(handle);
}

int OnInit()
{
   if(StringLen(InpReferenceSymbol) <= 0 || InpMaximumAlignmentSeconds < 0 || InpRequiredLookbackBars < 1)
      return INIT_PARAMETERS_INCORRECT;
   if(InpUseSymbolSafetyLock && StringFind(_Symbol, InpAllowedSymbol) < 0)
      return INIT_FAILED;
   ENUM_ACCOUNT_TRADE_MODE mode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(InpUseRealAccountSafetyLock && mode == ACCOUNT_TRADE_MODE_REAL)
      return INIT_FAILED;
   if(!SymbolSelect(InpReferenceSymbol, true))
   {
      Print("XAU_USD_PROXY_HISTORY_SYMBOL_SELECT_ERROR symbol=", InpReferenceSymbol, " code=", GetLastError());
      return INIT_FAILED;
   }
   iClose(InpReferenceSymbol, InpSignalTimeframe, 1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   WriteEvidence();
}

void OnTick()
{
   datetime currentBar = iTime(_Symbol, InpSignalTimeframe, 0);
   if(currentBar <= 0 || currentBar == g_lastSignalBar)
      return;
   g_lastSignalBar = currentBar;
   RecordClosedBar();
}

double OnTester()
{
   long totalXau = 0;
   long totalAligned = 0;
   for(int i = 0; i < EVIDENCE_YEAR_COUNT; ++i)
   {
      totalXau += g_xauBars[i];
      totalAligned += g_alignedBars[i];
   }
   return totalXau > 0 ? 100.0 * totalAligned / totalXau : 0.0;
}

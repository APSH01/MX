#property copyright "ForexAssistant"
#property version   "1.004"
#property strict
#property description "MT5 bridge - analysis plus optional manual close actions"

input string BridgeHost = "127.0.0.1";
input int    BridgePort = 5555;
input int    ReconnectSeconds = 3;
input int    ConnectTimeoutMs = 5000;
input bool   EnableTradeActions = false;
input ulong  CloseDeviationPoints = 50;

#include <Trade/Trade.mqh>

CTrade g_trade;
int g_socket = INVALID_HANDLE;
uint g_last_connect_attempt = 0;
string g_receive_buffer = "";

bool SendLine(string text)
{
   if(g_socket == INVALID_HANDLE || !SocketIsConnected(g_socket)) return false;
   string message = text + "\n";
   uchar data[];
   int length = StringToCharArray(message, data, 0, WHOLE_ARRAY, CP_UTF8) - 1;
   if(length <= 0) return false;
   return SocketSend(g_socket, data, (uint)length) == length;
}

void CloseBridge()
{
   if(g_socket != INVALID_HANDLE) { SocketClose(g_socket); g_socket = INVALID_HANDLE; }
   g_receive_buffer = "";
}

void SendHello()
{
   SendLine("HELLO");
   SendLine("PLATFORM=MT5");
   SendLine("BROKER=" + AccountInfoString(ACCOUNT_COMPANY));
   SendLine("SERVER=" + AccountInfoString(ACCOUNT_SERVER));
   SendLine(StringFormat("LOGIN=%I64d", AccountInfoInteger(ACCOUNT_LOGIN)));
   SendLine(StringFormat("BALANCE=%.2f", AccountInfoDouble(ACCOUNT_BALANCE)));
   SendLine(StringFormat("EQUITY=%.2f", AccountInfoDouble(ACCOUNT_EQUITY)));
   SendLine("CURRENCY=" + AccountInfoString(ACCOUNT_CURRENCY));
   SendLine("END");
}

bool ConnectBridge()
{
   Print("------------------------------------------------------------");
   Print("ForexAssistant Bridge 1.004: connection attempt");
   Print("Program type=", (int)MQLInfoInteger(MQL_PROGRAM_TYPE),
         " tester=", (int)MQLInfoInteger(MQL_TESTER),
         " trade_allowed=", (int)MQLInfoInteger(MQL_TRADE_ALLOWED),
         " terminal_connected=", (int)TerminalInfoInteger(TERMINAL_CONNECTED));
   Print("Target=", BridgeHost, ":", BridgePort, " timeout_ms=", ConnectTimeoutMs);

   CloseBridge();

   ResetLastError();
   g_socket = SocketCreate();
   int create_error = GetLastError();

   if(g_socket == INVALID_HANDLE)
   {
      Print("ForexAssistant: SocketCreate FAILED, error=", create_error);
      Comment("ForexAssistant Bridge DISCONNECTED\n",
              "stage=SocketCreate\n",
              BridgeHost, ":", BridgePort,
              "\nerror=", create_error);
      return false;
   }

   Print("ForexAssistant: SocketCreate OK, handle=", g_socket,
         " last_error=", create_error);

   ResetLastError();
   bool connected = SocketConnect(g_socket, BridgeHost,
                                  (uint)BridgePort,
                                  (uint)ConnectTimeoutMs);
   int connect_error = GetLastError();

   if(!connected)
   {
      Print("ForexAssistant: SocketConnect FAILED, target=", BridgeHost,
            ":", BridgePort, " error=", connect_error);

      if(connect_error == 4014)
      {
         Print("ForexAssistant DIAG: error 4014 = function not allowed.");
         Print("ForexAssistant DIAG: add 127.0.0.1 to Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL.");
         Print("ForexAssistant DIAG: EA must run on a normal chart, not in Strategy Tester and not as an indicator.");
      }
      else if(connect_error == 5272)
      {
         Print("ForexAssistant DIAG: error 5272 = cannot connect. Start Delphi listener and verify host/port/firewall.");
      }

      Comment("ForexAssistant Bridge DISCONNECTED\n",
              "stage=SocketConnect\n",
              BridgeHost, ":", BridgePort,
              "\nerror=", connect_error,
              (connect_error == 4014 ? "\nAdd 127.0.0.1 to allowed URLs" : ""));
      CloseBridge();
      return false;
   }

   ResetLastError();
   bool timeouts_ok = SocketTimeouts(g_socket, 1000, 1000);
   int timeout_error = GetLastError();
   Print("ForexAssistant: SocketConnect OK, handle=", g_socket);
   Print("ForexAssistant: SocketTimeouts result=", timeouts_ok,
         " error=", timeout_error);

   SendHello();
   Print("ForexAssistant Bridge CONNECTED to ", BridgeHost, ":", BridgePort);
   Comment("ForexAssistant Bridge CONNECTED\n",
           BridgeHost, ":", BridgePort,
           "\nRead only");
   return true;
}

ENUM_TIMEFRAMES ParseTimeFrame(string v)
{
   if(v=="M1") return PERIOD_M1; if(v=="M5") return PERIOD_M5; if(v=="M15") return PERIOD_M15;
   if(v=="M30") return PERIOD_M30; if(v=="H1") return PERIOD_H1; if(v=="H4") return PERIOD_H4;
   if(v=="D1") return PERIOD_D1; if(v=="W1") return PERIOD_W1; if(v=="MN1") return PERIOD_MN1;
   return PERIOD_M15;
}

void SendError(string message)
{
   SendLine("ERROR"); SendLine("MESSAGE=" + message); SendLine("END");
}

void SendCandles(string symbol, string tf_text, int requested)
{
   if(requested < 1) requested=1; if(requested > 2000) requested=2000;
   if(!SymbolSelect(symbol,true)) { SendError("Symbol not available: " + symbol); return; }
   MqlRates rates[]; int copied=CopyRates(symbol,ParseTimeFrame(tf_text),0,requested,rates);
   if(copied<=0) { SendError(StringFormat("CopyRates failed: %d",GetLastError())); return; }
   Print("ForexAssistant: sending candles symbol=",symbol," tf=",tf_text," count=",copied);
   SendLine("CANDLES"); SendLine("SYMBOL="+symbol); SendLine("TIMEFRAME="+tf_text); SendLine(StringFormat("COUNT=%d",copied));
   for(int i=0;i<copied;i++)
      SendLine(StringFormat("CANDLE|%I64d|%.10f|%.10f|%.10f|%.10f|%I64d",(long)rates[i].time,rates[i].open,rates[i].high,rates[i].low,rates[i].close,(long)rates[i].tick_volume));
   SendLine("END");
}

void SendSymbols()
{
   int total=SymbolsTotal(true);
   SendLine("SYMBOLS");
   SendLine(StringFormat("COUNT=%d",total));

   for(int i=0;i<total;i++)
   {
      string symbol=SymbolName(i,true);
      if(symbol!="")
         SendLine("SYMBOL|"+symbol);
   }

   SendLine("END");
   Print("ForexAssistant: sending Market Watch symbols count=",total);
}


void SendRecentEntries(int minutes)
{
   if(minutes < 1) minutes = 1;
   if(minutes > 1440) minutes = 1440;

   datetime to_time = TimeCurrent();
   datetime from_time = to_time - minutes * 60;

   if(!HistorySelect(from_time, to_time))
   {
      SendError(StringFormat("HistorySelect failed: %d", GetLastError()));
      return;
   }

   int total = HistoryDealsTotal();
   int count = 0;

   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;

      long entry_kind = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      long deal_type = HistoryDealGetInteger(ticket, DEAL_TYPE);

      if(entry_kind != DEAL_ENTRY_IN && entry_kind != DEAL_ENTRY_INOUT)
         continue;

      if(deal_type != DEAL_TYPE_BUY && deal_type != DEAL_TYPE_SELL)
         continue;

      count++;
   }

   SendLine("ENTRIES");
   SendLine(StringFormat("COUNT=%d", count));
   SendLine(StringFormat("MINUTES=%d", minutes));

   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;

      long entry_kind = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      long deal_type = HistoryDealGetInteger(ticket, DEAL_TYPE);

      if(entry_kind != DEAL_ENTRY_IN && entry_kind != DEAL_ENTRY_INOUT)
         continue;

      if(deal_type != DEAL_TYPE_BUY && deal_type != DEAL_TYPE_SELL)
         continue;

      string side = (deal_type == DEAL_TYPE_SELL ? "SELL" : "BUY");
      string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
      double volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
      long deal_time = HistoryDealGetInteger(ticket, DEAL_TIME);
      double price = HistoryDealGetDouble(ticket, DEAL_PRICE);

      SendLine(StringFormat(
         "ENTRY|%I64u|%s|%s|%.4f|%I64d|%.10f",
         ticket, symbol, side, volume, deal_time, price));
   }

   SendLine("END");
   Print("ForexAssistant: sending recent entries minutes=", minutes,
         " count=", count);
}

void SendPositions()
{
   int total=PositionsTotal(); Print("ForexAssistant: sending positions count=",total);
   SendLine("POSITIONS"); SendLine(StringFormat("COUNT=%d",total));
   for(int i=0;i<total;i++) {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      string side=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL ? "SELL" : "BUY");
      SendLine(StringFormat("POSITION|%I64u|%s|%s|%.4f|%I64d|%.10f|%.10f|%.10f|%.10f|%.2f",
         ticket,PositionGetString(POSITION_SYMBOL),side,PositionGetDouble(POSITION_VOLUME),(long)PositionGetInteger(POSITION_TIME),
         PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_PRICE_CURRENT),PositionGetDouble(POSITION_SL),
         PositionGetDouble(POSITION_TP),PositionGetDouble(POSITION_PROFIT)));
   }
   SendLine("END");
}

void SendActionResult(string command, bool success,
                      int closed_count, int failed_count,
                      string message)
{
   SendLine("ACTION");
   SendLine("COMMAND=" + command);
   SendLine(StringFormat("SUCCESS=%d", success ? 1 : 0));
   SendLine(StringFormat("CLOSED=%d", closed_count));
   SendLine(StringFormat("FAILED=%d", failed_count));
   SendLine("MESSAGE=" + message);
   SendLine("END");
}

bool TradeActionsAllowed(string command)
{
   if(!EnableTradeActions)
   {
      SendActionResult(command, false, 0, 0,
         "Trade actions are disabled in EA inputs.");
      return false;
   }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED) ||
      !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      SendActionResult(command, false, 0, 0,
         "Algorithmic trading is not allowed in MT5.");
      return false;
   }

   return true;
}

void CloseMatchingPositions(string command, string symbol,
                            int side_filter, bool use_side_filter)
{
   if(!TradeActionsAllowed(command))
      return;

   if(symbol == "")
   {
      SendActionResult(command, false, 0, 0, "Symbol is empty.");
      return;
   }

   g_trade.SetDeviationInPoints((int)CloseDeviationPoints);
   g_trade.SetAsyncMode(false);

   int closed_count = 0;
   int failed_count = 0;
   string last_error = "";

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      string position_symbol = PositionGetString(POSITION_SYMBOL);
      int position_type = (int)PositionGetInteger(POSITION_TYPE);

      if(position_symbol != symbol)
         continue;

      if(use_side_filter && position_type != side_filter)
         continue;

      ResetLastError();
      bool closed = g_trade.PositionClose(ticket);
      if(closed)
      {
         closed_count++;
      }
      else
      {
         failed_count++;
         last_error = StringFormat(
            "ticket=%I64u retcode=%u %s error=%d",
            ticket,
            g_trade.ResultRetcode(),
            g_trade.ResultRetcodeDescription(),
            GetLastError());
         Print("ForexAssistant close failed: ", last_error);
      }
   }

   bool success = (closed_count > 0 && failed_count == 0);
   string message;

   if(closed_count == 0 && failed_count == 0)
      message = "No matching open positions.";
   else if(failed_count == 0)
      message = StringFormat("Closed positions: %d", closed_count);
   else
      message = StringFormat("Closed: %d, failed: %d. %s",
                             closed_count, failed_count, last_error);

   SendActionResult(command, success, closed_count, failed_count, message);
}

void HandleCommand(string command)
{
   StringTrimLeft(command); StringTrimRight(command);
   if(command=="" || command=="HELLO_ACK") return;
   string p[]; int n=StringSplit(command,'|',p);
   Print("ForexAssistant RX: ",command);
   if(n>=4 && p[0]=="GET_CANDLES") { SendCandles(p[1],p[2],(int)StringToInteger(p[3])); return; }
   if(command=="GET_SYMBOLS") { SendSymbols(); return; }
   if(n>=2 && p[0]=="GET_ENTRIES")
   {
      SendRecentEntries((int)StringToInteger(p[1]));
      return;
   }
   if(command=="GET_POSITIONS") { SendPositions(); return; }
   if(n>=3 && p[0]=="CLOSE_SIDE")
   {
      int side = (p[2]=="SELL" ? POSITION_TYPE_SELL : POSITION_TYPE_BUY);
      CloseMatchingPositions("CLOSE_SIDE", p[1], side, true);
      return;
   }
   if(n>=2 && p[0]=="CLOSE_ALL")
   {
      CloseMatchingPositions("CLOSE_ALL", p[1],
                             POSITION_TYPE_BUY, false);
      return;
   }
   if(command=="PING") { SendLine("PONG"); return; }
   if(command=="GET_ACCOUNT") { SendHello(); return; }
   SendError("Unknown command: "+command);
}

void ReadCommands()
{
   if(g_socket==INVALID_HANDLE || !SocketIsConnected(g_socket)) return;
   uint available=SocketIsReadable(g_socket); if(available==0) return;
   uchar data[]; int read=SocketRead(g_socket,data,available,100); if(read<=0) return;
   g_receive_buffer += CharArrayToString(data,0,read,CP_UTF8);
   while(true) {
      int nl=StringFind(g_receive_buffer,"\n"); if(nl<0) break;
      string line=StringSubstr(g_receive_buffer,0,nl); g_receive_buffer=StringSubstr(g_receive_buffer,nl+1);
      StringReplace(line,"\r",""); HandleCommand(line);
   }
}

int OnInit()
{
   Print("ForexAssistant Bridge 1.004 starting. Target ",BridgeHost,":",BridgePort);
   if(!EventSetMillisecondTimer(100))
      Print("ForexAssistant: EventSetMillisecondTimer error=",GetLastError());
   ConnectBridge();
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason){ Print("ForexAssistant Bridge stopped, reason=",reason); EventKillTimer(); CloseBridge(); Comment(""); }
void OnTimer(){
   if(g_socket==INVALID_HANDLE || !SocketIsConnected(g_socket)) {
      uint now=GetTickCount(); if(now-g_last_connect_attempt >= (uint)(ReconnectSeconds*1000)) { g_last_connect_attempt=now; ConnectBridge(); }
      return;
   }
   ReadCommands();
}
void OnTick(){}

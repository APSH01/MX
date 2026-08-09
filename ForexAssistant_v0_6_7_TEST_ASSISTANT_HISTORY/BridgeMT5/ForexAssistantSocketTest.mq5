#property copyright "ForexAssistant"
#property version   "1.100"
#property strict
#property description "Minimal MT5 socket test"

input string Host = "127.0.0.1";
input ushort Port = 5555;
input uint TimeoutMs = 5000;

int g_socket = INVALID_HANDLE;

void ShowStatus(const string state, const int error_code = 0)
{
   string text =
      "ForexAssistant SocketTest 1.1\n" +
      "Host: " + Host + ":" + IntegerToString((int)Port) + "\n" +
      "State: " + state;

   if(error_code != 0)
      text += "\nError: " + IntegerToString(error_code);

   Comment(text);
   Print(text);
}

bool SendUtf8Line(const string value)
{
   string message = value + "\n";
   uchar data[];

   int bytes = StringToCharArray(message, data, 0, WHOLE_ARRAY, CP_UTF8);
   if(bytes <= 1)
      return false;

   bytes--; // bez koncowego znaku zero
   ResetLastError();

   int sent = SocketSend(g_socket, data, (uint)bytes);
   if(sent != bytes)
   {
      ShowStatus("SocketSend FAILED", GetLastError());
      return false;
   }

   Print("TX: ", value);
   return true;
}

string ReceiveUtf8Line()
{
   uchar data[256];
   string result = "";
   uint started = GetTickCount();

   while((GetTickCount() - started) < TimeoutMs)
   {
      if(!SocketIsConnected(g_socket))
         break;

      uint available = SocketIsReadable(g_socket);
      if(available > 0)
      {
         uint to_read = MathMin(available, (uint)ArraySize(data));
         ResetLastError();

         int received = SocketRead(g_socket, data, to_read, 250);
         if(received < 0)
         {
            ShowStatus("SocketRead FAILED", GetLastError());
            return "";
         }

         if(received > 0)
         {
            result += CharArrayToString(data, 0, received, CP_UTF8);

            int new_line = StringFind(result, "\n");
            if(new_line >= 0)
               return StringSubstr(result, 0, new_line);
         }
      }

      Sleep(50);
   }

   return result;
}

int OnInit()
{
   Comment("");
   ResetLastError();

   g_socket = SocketCreate();
   if(g_socket == INVALID_HANDLE)
   {
      ShowStatus("SocketCreate FAILED", GetLastError());
      return INIT_FAILED;
   }

   ShowStatus("SocketCreate OK - connecting...");

   ResetLastError();
   if(!SocketConnect(g_socket, Host, Port, TimeoutMs))
   {
      int err = GetLastError();
      ShowStatus("SocketConnect FAILED", err);
      SocketClose(g_socket);
      g_socket = INVALID_HANDLE;
      return INIT_FAILED;
   }

   ShowStatus("SocketConnect OK");

   if(!SendUtf8Line("HELLO"))
      return INIT_FAILED;

   string reply = ReceiveUtf8Line();
   Print("RX: ", reply);

   if(reply == "OK")
      ShowStatus("TEST PASSED - RX: OK");
   else if(reply == "")
      ShowStatus("CONNECTED, but no reply");
   else
      ShowStatus("CONNECTED - RX: " + reply);

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(g_socket != INVALID_HANDLE)
   {
      SocketClose(g_socket);
      g_socket = INVALID_HANDLE;
   }

   Comment("");
}

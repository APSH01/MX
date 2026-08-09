FOREX ASSISTANT 0.3 - MT5 LIVE
==============================

CEL TEJ WERSJI
--------------
Program pobiera z uruchomionego terminala MT5 prawdziwe świece OHLC
przez lokalny Bridge i odświeża wykres co 2 sekundy.
Bridge jest tylko do odczytu. Nie ma w nim żadnej funkcji handlowej.

WYMAGANIA
---------
- Delphi 11.1
- Indy (standardowo instalowane z Delphi)
- MetaTrader 5 / MetaEditor 5

URUCHOMIENIE DELPHI
-------------------
1. Otwórz ForexAssistant.dpr.
2. Skompiluj Win32 lub Win64.
3. Uruchom program.
4. Kliknij "Połącz MT5". Program zacznie nasłuchiwać na 127.0.0.1:5555.

INSTALACJA BRIDGE W MT5
-----------------------
1. W MT5 wybierz File -> Open Data Folder.
2. Skopiuj BridgeMT5\ForexAssistantBridge.mq5 do:
   MQL5\Experts\ForexAssistant\ForexAssistantBridge.mq5
3. Otwórz plik w MetaEditorze i skompiluj F7.
4. W MT5: Tools -> Options -> Expert Advisors.
5. Dodaj/admituj adres 127.0.0.1 do listy dozwolonych adresów sieciowych,
   jeżeli Twoja wersja MT5 tego wymaga dla funkcji SocketConnect.
6. Włącz Algo Trading (Bridge nie handluje, ale Expert musi mieć prawo działać).
7. Przeciągnij ForexAssistantBridge na dowolny wykres.
8. Na wykresie MT5 powinien pojawić się napis CONNECTED.
9. ForexAssistant automatycznie pobierze wybrany symbol/interwał.

WAŻNE: NAZWY SYMBOLI
--------------------
Broker może używać sufiksów/prefiksów, np. XAUUSD.a, GOLD, EURUSD#.
Pole Symbol w ForexAssistant jest edytowalne. Wpisz dokładną nazwę widoczną
w Market Watch w MT5.

PROTOKÓŁ
--------
Delphi -> MT5:
GET_CANDLES|XAUUSD|M15|120

MT5 -> Delphi:
Jednoliniowy JSON UTF-8 zawierający tablicę świec.

BEZPIECZEŃSTWO
--------------
Połączenie działa wyłącznie lokalnie na 127.0.0.1:5555.
Bridge nie zawiera OrderSend, CTrade ani żadnych poleceń BUY/SELL.
Login i hasło do rachunku nie są przesyłane. MT5 jest już zalogowany.

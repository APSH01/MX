ForexAssistant v0.5 Beta FIX2

Zmiany diagnostyczne:
- Bridge MQL5 1.001.
- osobne logi SocketCreate i SocketConnect,
- log typu programu, Strategy Tester i stanu terminala,
- opis błędów 4014 oraz 5272,
- komunikat etapu błędu bezpośrednio na wykresie MT5,
- Delphi Bridge Monitor pokazuje CLIENT CONNECTED TCP natychmiast po zaakceptowaniu połączenia.

Dla błędu 4014 dodaj w MT5:
Tools -> Options -> Expert Advisors
Allow WebRequest for listed URL:
127.0.0.1

Następnie zdejmij EA z wykresu i dodaj ponownie.

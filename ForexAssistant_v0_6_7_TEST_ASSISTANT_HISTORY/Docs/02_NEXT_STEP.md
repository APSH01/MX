# Następny etap

1. Delphi uruchamia serwer TCP na `127.0.0.1:5555`.
2. Expert Advisor w MT5 łączy się jako klient.
3. Bridge przesyła wiadomość `ACCOUNT` w JSON Lines.
4. ForexAssistant pokazuje status i dane konta.
5. Bridge pozostaje tylko do odczytu — bez funkcji tradingowych.

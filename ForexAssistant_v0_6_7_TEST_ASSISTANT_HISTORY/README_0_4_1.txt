ForexAssistant 0.4.1 - Bridge Monitor

Cel tego buildu: diagnostyka pustego wykresu.

1. Poprawiono ParsePositions: tekst BUY/SELL jest mapowany na TPositionSide.
2. Dodano Bridge Monitor na dole okna.
3. Monitor pokazuje SERVER LISTEN, HELLO, RX, TX, timeouty oraz liczbę sparsowanych świec i pozycji.
4. Dodano nazwy symboli GOLD#, XAUUSD#, XAUUSD.a i SILVER#.
5. Bridge 0.41 zapisuje w zakładce Experts każdą odebraną komendę i liczbę wysyłanych świec.

Po skompilowaniu Delphi podmień i ponownie skompiluj BridgeMT5\ForexAssistantBridge.mq5.
Następnie wybierz dokładny symbol używany przez brokera, np. GOLD# w XM.

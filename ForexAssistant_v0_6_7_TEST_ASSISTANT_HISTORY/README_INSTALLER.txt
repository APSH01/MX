ForexAssistant 0.3.6 - instalator Bridge MT5
============================================

Nowy przycisk na górnym panelu:
  Instaluj Bridge

Działanie:
1. Skanuje katalog:
   %APPDATA%\MetaQuotes\Terminal\*\MQL5
2. Pokazuje wszystkie znalezione terminale MT5.
3. Pozwala wybrać brokera i port:
   XM             5555
   IC Trading     5556
   Fusion Markets 5557
4. Kopiuje ForexAssistantBridge.mq5 do:
   MQL5\Experts\ForexAssistant\
5. W kopii ustawia wybrany port jako domyślny.
6. Przycisk Kompiluj próbuje uruchomić MetaEditor z poleceniem /compile.

Po instalacji:
- w MT5 odśwież listę Expert Advisors,
- przeciągnij ForexAssistantBridge na dowolny wykres,
- włącz Algo Trading dla pierwszego testu,
- uruchom listener w ForexAssistant przyciskiem Połącz.

Uwaga:
Instalator nie zmienia danych logowania i nie wysyła zleceń.
Bridge jest tylko do odczytu.

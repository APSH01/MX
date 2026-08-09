ForexAssistant 0.5.4 Beta — symbole pobierane z MT5
=====================================================

Zmiany:

- usunięto stałą tablicę 40 nazw instrumentów z FillSelectors,
- po połączeniu Bridge program wysyła GET_SYMBOLS,
- EA zwraca symbole widoczne w Market Watch terminala MT5,
- cbSymbol jest wypełniany wyłącznie rzeczywistymi symbolami brokera,
- zachowywany jest ostatnio wybrany symbol, o ile nadal istnieje,
- gdy zapisany symbol nie istnieje, program szuka GOLD#/GOLD/XAUUSD,
- ostatecznym fallbackiem jest pierwszy symbol z Market Watch,
- przed połączeniem pozostaje bezpieczny symbol startowy GOLD#,
- interwały pozostają stałe,
- Bridge podniesiony do wersji 1.002.

WAŻNE:
Po skopiowaniu paczki trzeba ponownie skompilować i podmienić EA:
BridgeMT5/ForexAssistantBridge.mq5

Lista pochodzi z Market Watch. Aby instrument pojawił się w ForexAssistant,
musi być widoczny w Market Watch terminala MT5.

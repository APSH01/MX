ForexAssistant 0.6.7 TEST — Assistant History
=================================================

Poprawka kolorów:
- tylko opisy pozycji BUY/SELL na wykresie pozostają białe,
- panel Pozycje wrócił do poprzednich kolorów,
- BUY Score jest zielony,
- SELL Score jest czerwony.

Nowe funkcje:

1. Historia zmian sugestii
   - zapis do SQLite,
   - wyświetlanie 12 ostatnich zmian,
   - godzina,
   - sugestia,
   - BUY Score,
   - SELL Score,
   - Confidence,
   - Data Quality.

   Identyczny wynik nie jest zapisywany przy każdym odświeżeniu.
   Nowy wpis powstaje dopiero po zmianie sugestii albo wyniku
   o co najmniej 5 punktów.

2. Filtrowanie Behaviour i Timeline po aktualnym symbolu
   - GOLD nie miesza się z EURUSD,
   - analiza rytmu dotyczy instrumentu wybranego w cbSymbol,
   - do session_timeline zapisywane są wejścia wybranego symbolu.

3. Nowa tabela SQLite:
   assistant_history

Bridge:
- bez zmian,
- wystarcza wersja 1.004.

Nie mam lokalnie Delphi 11.1 i DevExpress 25.1.5.
Pierwsza kompilacja pozostaje po Twojej stronie.

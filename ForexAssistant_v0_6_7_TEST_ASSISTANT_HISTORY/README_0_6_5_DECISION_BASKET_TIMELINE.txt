ForexAssistant 0.6.5 TEST
Decision Engine + Basket Analyzer + Trader Timeline
===================================================

Pakiet łączy zakres planowanych wersji 0.6.3, 0.6.4 i 0.6.5.

0.6.3 — Decision Engine
-----------------------
Market Assistant pokazuje teraz osobne składowe:
- Trend,
- Alignment (zgodność interwałów),
- Location (położenie w zakresie H1),
- Volatility,
- Room (miejsce w aktualnym zakresie).

Nadal pokazuje:
- BUY Score,
- SELL Score,
- Confidence,
- Data Quality,
- argumenty za i przeciw.

Silnik jest jawny i regułowy. Nie otwiera pozycji.

0.6.4 — Basket Analyzer
-----------------------
Panel pozycji korzysta z osobnego analizatora koszyka:
- liczba pozycji BUY/SELL,
- wolumen obu stron,
- średnia cena BUY i SELL,
- ekspozycja netto,
- łączny P/L,
- prosty stan ryzyka LOW / MEDIUM / HIGH.

Stan ryzyka opisuje strukturę koszyka, a nie prognozę rynku.

0.6.5 — Trader Timeline
-----------------------
Nowa sekcja w panelu Market Assistant:
- wejścia z ostatnich 60 minut,
- godzina,
- BUY/SELL,
- wolumen,
- cena,
- stan rytmu,
- tempo wejść.

Wpisy są również zapisywane w SQLite do tabeli:
  session_timeline

Duplikaty są eliminowane po deal_ticket.

Bridge
------
Wystarcza Bridge 1.004 z wcześniejszego buildu.
Nie trzeba ponownie kompilować EA, jeśli działa GET_ENTRIES.

Uwaga
-----
Nie mam lokalnie Delphi 11.1 ani DevExpress 25.1.5.
Projekt został sprawdzony strukturalnie. Pierwsza kompilacja i test UI
pozostają po Twojej stronie.

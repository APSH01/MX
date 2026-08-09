ForexAssistant 0.6.0 TEST — Basket + Behaviour
================================================

To jest wersja testowa oparta na działającym 0.5.4.

Nowe funkcje:

1. Rozszerzony panel pozycji
   - liczba pozycji BUY i SELL,
   - łączny wolumen obu stron,
   - średnia ważona cena BUY,
   - średnia ważona cena SELL,
   - różnica pomiędzy średnimi cenami,
   - ekspozycja netto,
   - wiek najstarszej otwartej pozycji,
   - łączny wynik koszyka.

2. Monitor rytmu sesji
   - liczba nowych wejść z ostatnich 10 i 30 minut,
   - wolumen wejść,
   - średni odstęp czasowy,
   - zmiana tempa względem wcześniejszych 20 minut,
   - neutralne stany:
       STABILNY
       ZMIANA RYTMU
       SZYBKIE DECYZJE

Program nie próbuje określać emocji tradera i nie blokuje decyzji.
Pokazuje wyłącznie zmianę danych opisujących sesję.

3. Bridge MT5 1.003
   - nowa komenda GET_ENTRIES|MINUTES,
   - odczyt wejść z historii terminala,
   - nadal brak otwierania, modyfikowania i zamykania pozycji.

WAŻNE:
Podmień i skompiluj ponownie:
BridgeMT5\ForexAssistantBridge.mq5

W MT5 nadal wymagany jest dokładny wpis:
Tools -> Options -> Experts
127.0.0.1:5555

Uwagi:
- Nie mam w tym środowisku Delphi 11.1 ani DevExpress 25.1.5.
- Kod został sprawdzony strukturalnie, ale pierwsza kompilacja jest po Twojej stronie.

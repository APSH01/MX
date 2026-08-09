ForexAssistant 0.6.2 TEST — Market Assistant
=================================================

Zmiany względem 0.6.1:

1. Lewy panel Bridge Monitor
   - domyślnie zwinięty,
   - przycisk "Monitor" na górnym panelu rozwija i zwija log,
   - wykres otrzymuje więcej miejsca.

2. Automatyczny zapis układu do ForexAssistant.ini
   - pozycja i rozmiar okna,
   - stan maksymalizacji,
   - szerokość Bridge Monitor,
   - szerokość panelu kontekstu,
   - szerokość Market Assistant,
   - ostatni symbol i interwał nadal są zapisywane automatycznie.
   Użytkownik nie edytuje INI ręcznie.

3. Usunięto z głównego interfejsu akcje:
   - Zamknij BUY,
   - Zamknij SELL,
   - Zamknij wszystko.
   MT5 pozostaje miejscem zarządzania transakcjami.

4. Nowy panel całkiem po prawej: Market Assistant
   - osobny BUY Score,
   - osobny SELL Score,
   - sugestia: ROZWAŻ BUY / ROZWAŻ SELL / BRAK WYRAŹNEJ PRZEWAGI,
   - Confidence,
   - Data Quality,
   - argumenty za,
   - argumenty przeciw.

Silnik jest jawny i regułowy. Nie przewiduje przyszłości i niczego
samodzielnie nie otwiera. Wynik powstaje z kierunku M15/H1/H4/D1,
położenia ceny względem wsparcia/oporu H1 oraz zmienności.

Bridge:
- można pozostawić wersję 1.004 z poprzedniej paczki,
- w tej wersji aplikacja nie udostępnia przycisków zamykania pozycji.

Uwaga:
Nie mam lokalnie Delphi 11.1 ani DevExpress 25.1.5.
Kod został sprawdzony strukturalnie; pierwszy test kompilacji jest po Twojej stronie.

ForexAssistant 0.5.2 Beta — Market Context
==============================================

Najważniejsze zmiany:

1. Bridge Monitor przeniesiony pionowo na lewą stronę.
   - pionowy splitter,
   - nie zabiera wysokości wykresu,
   - pełny log pozostaje dostępny.

2. Panel po prawej:
   - Market Context u góry,
   - sesje rynkowe poniżej.

3. Market Context:
   - analiza M15, H1, H4 i D1,
   - opis kierunku na każdym interwale,
   - główny kierunek,
   - najbliższe wsparcie i opór H1,
   - położenie ceny w zakresie H1,
   - przybliżona zmienność,
   - prosty komentarz ostrzegawczy.

To NIE jest automat ani sygnał BUY/SELL. To opis sytuacji.

4. Lista sesji:
   - poprawione szerokości kolumn,
   - zielony wskaźnik: rynek otwarty,
   - czerwony wskaźnik: rynek zamknięty,
   - żółty wskaźnik: zamknięcie w ciągu 2 godzin.

5. Komunikacja:
   - bez zmian w działającym protokole MT5,
   - wymagany wpis w MT5:
     Tools -> Options -> Experts
     127.0.0.1:5555

Uwaga:
Market Context odświeża się przy pierwszym pobraniu danych oraz później
co około 5 minut, żeby nie przeciążać Bridge dodatkowymi żądaniami.

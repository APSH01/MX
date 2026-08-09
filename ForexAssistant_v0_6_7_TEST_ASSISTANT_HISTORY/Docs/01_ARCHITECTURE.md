# ForexAssistant — architektura bazowa

## Zasada główna

Aplikacja analizuje i prezentuje dane. Domyślnie działa tylko do odczytu.
Opcjonalnie może wykonać ręcznie zatwierdzone zamknięcie pozycji.
Nie otwiera pozycji i nie uruchamia samodzielnych strategii.

## Warstwy

- `Core` — modele rynku i kontrakty providerów.
- `Providers` — źródła danych, obecnie provider demonstracyjny.
- `Charts` — prezentacja świec i narzędzi wykresu.
- `Forms` — interfejs użytkownika.
- `Utils` — ustawienia i logger.
- `BridgeMT5` — zostanie dodany w następnym etapie.
- `BridgeCTrader` — zostanie dodany później z tym samym protokołem.

## Kierunek zależności

UI -> IMarketDataProvider -> konkretny provider

UI nie powinien znać szczegółów komunikacji z MT5 ani cTrader.

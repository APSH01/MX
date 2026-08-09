FOREX ASSISTANT 0.3.3 - MT5 LIVE + SESJE + SQLITE
===========================

Stała baza projektu do dalszego rozwijania krok po kroku.

Środowisko:
- Delphi 11.1 Alexandria
- VCL
- Win32 lub Win64
- bez dodatkowych komponentów wymaganych do kompilacji

Uruchomienie:
1. Otwórz ForexAssistant.dpr.
2. Ustaw Win32 lub Win64.
3. Build / Run.

Aktualnie działa:
- główne okno aplikacji,
- formularz danych konta: platforma, broker, login, hasło, serwer,
- zapis ustawień do ForexAssistant.ini,
- wybór symbolu i interwału,
- przykładowy provider danych,
- wykres świecowy i poziomy Fibonacci,
- log zdarzeń do ForexAssistant.log.

Istotne:
- przycisk Połącz korzysta jeszcze z Providers.Mock,
- nie ma jeszcze komunikacji z MT5 ani cTrader,
- dane konta w tej wersji służą przygotowaniu UI i konfiguracji,
- hasło jest zapisane jawnie w INI; przed kontem realnym zastosujemy DPAPI.

Kolejny mały etap:
- Bridge MT5 tylko do odczytu,
- TCP localhost,
- odczyt broker/server/login/balance/equity,
- bez wysyłania zleceń.

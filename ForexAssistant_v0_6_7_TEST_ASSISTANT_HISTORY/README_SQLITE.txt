FOREX ASSISTANT 0.3.2 - SQLITE
=============================

Co dodano
---------
1. FireDAC + SQLite.
2. Automatyczne utworzenie katalogu Data.
3. Automatyczne utworzenie pliku:

   Data\ForexAssistant.db

4. Automatyczne utworzenie tabel:

   app_settings
   candles
   signals
   trade_journal

5. Każde 120 świec odebranych z MT5 jest zapisywane przez
   INSERT OR REPLACE, więc te same świece nie są dublowane.

Wymagania
---------
Projekt korzysta z FireDAC, który masz w Delphi 11.1.

Do uruchomienia SQLite potrzebna jest biblioteka sqlite3.dll zgodna
z platformą kompilacji:

- Win64 -> sqlite3.dll 64-bit
- Win32 -> sqlite3.dll 32-bit

Najprościej skopiować właściwy sqlite3.dll obok ForexAssistant.exe.
Nie mieszaj wersji 32- i 64-bitowej.

Typowe położenie bibliotek z instalacji RAD Studio może zależeć od
wybranych opcji instalatora. Jeżeli FireDAC znajduje bibliotekę w PATH,
kopiowanie obok EXE nie jest konieczne.

Pierwszy test
-------------
1. Ustaw Win64.
2. Skompiluj projekt.
3. Skopiuj 64-bitowy sqlite3.dll obok EXE, jeśli nie jest już dostępny.
4. Uruchom program.
5. Na dole powinno pojawić się: Baza: SQLite OK.
6. Powinien powstać plik Data\ForexAssistant.db.
7. Po pobraniu świec status pokaże: zapisano do SQLite.

Uwaga
-----
Login i hasło nadal są zapisywane w INI zgodnie z wcześniejszym
założeniem. W następnej wersji warto przenieść ustawienia do SQLite,
a hasło zabezpieczyć Windows DPAPI zamiast zapisywać jawnie.

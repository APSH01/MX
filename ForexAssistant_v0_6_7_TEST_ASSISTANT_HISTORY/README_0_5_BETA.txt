FOREX ASSISTANT 0.5 BETA

Zakres tej wersji:
- diagnostyka połączenia Delphi <-> MT5,
- automatyczne ponawianie połączenia co 3 sekundy,
- logowanie GET_CANDLES, CANDLES, GET_POSITIONS i błędów,
- poprawiony numer wersji EA dla MetaEditora (0.500),
- poprawione rozmieszczenie etykiet w pnlBottom,
- pliki Delphi zapisane jako UTF-8 z BOM, aby zachować polskie znaki.

KOLEJNOŚĆ URUCHOMIENIA:
1. Uruchom ForexAssistant.exe i kliknij Połącz.
2. W MT5 dołącz ForexAssistantBridge do wykresu.
3. Otwórz Toolbox -> Experts i obserwuj log.
4. Bridge Monitor w Delphi powinien pokazać RX HELLO, TX HELLO_ACK, a następnie dane świec.

Jeżeli MT5 zgłosi błąd 4014:
Tools -> Options -> Expert Advisors
Dodaj 127.0.0.1 do listy dozwolonych adresów.

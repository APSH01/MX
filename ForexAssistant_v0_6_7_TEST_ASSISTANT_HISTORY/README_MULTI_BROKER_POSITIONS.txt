ForexAssistant 0.3.4 - MULTI BROKER + LIVE POSITIONS
====================================================

1. Górny pasek jest zwykłym TPanel.
2. Polecenia są na TSpeedButton: Połącz i Odśwież.
3. Broker wybierany jest z ComboBox:
   - XM             127.0.0.1:5555
   - IC Trading     127.0.0.1:5556
   - Fusion Markets 127.0.0.1:5557
4. Lista brokerów jest w SQLite, tabela BROKERS.
5. Zmiana brokera:
   - zatrzymuje poprzedni listener,
   - uruchamia listener na porcie wybranego brokera,
   - czeka na odpowiedni terminal MT5.
6. Bridge obsługuje GET_CANDLES i GET_POSITIONS.
7. Otwarte pozycje dla wybranego symbolu są rysowane na wykresie
   jako poziome linie z kierunkiem, wolumenem, ceną wejścia i P/L.
8. Bridge jest tylko do odczytu. Nie ma poleceń handlowych.

KONFIGURACJA TERMINALI MT5
--------------------------
W każdym terminalu uruchom osobną kopię ForexAssistantBridge.ex5 i ustaw:

XM:
  BridgeHost = 127.0.0.1
  BridgePort = 5555

IC Trading:
  BridgeHost = 127.0.0.1
  BridgePort = 5556

Fusion Markets:
  BridgeHost = 127.0.0.1
  BridgePort = 5557

Wystarczy uruchamiać tylko terminal, którego aktualnie potrzebujesz.
Jeżeli kilka terminali jest uruchomionych jednocześnie, każdy łączy się
na własny port.

UWAGA
-----
Po aktualizacji należy ponownie skompilować plik:
BridgeMT5\ForexAssistantBridge.mq5

Projekt przygotowany dla Delphi 11.1 VCL, Indy, FireDAC SQLite i
DevExpress VCL 25.1.5.

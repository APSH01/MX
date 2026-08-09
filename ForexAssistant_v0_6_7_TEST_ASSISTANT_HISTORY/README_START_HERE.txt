FOREX ASSISTANT 0.4.0 - TEXT PROTOCOL

Ta wersja zastępuje JSON prostym protokołem tekstowym.

1. Skompiluj ForexAssistant.dpr w Delphi 11.1.
2. Uruchom program i wybierz brokera/port.
3. Kliknij Instaluj Bridge, wybierz właściwy terminal MT5 oraz port.
4. Kliknij Kompiluj albo otwórz plik ForexAssistantBridge.mq5 w MetaEditorze i naciśnij F7.
5. W MT5 przeciągnij ForexAssistantBridge na dowolny wykres.
6. Parametr BridgePort musi być zgodny z portem w ForexAssistant.
7. W zakładce Experts powinno być: ForexAssistant Bridge connected...
8. W programie status zmieni się z OCZEKIWANIE NA BRIDGE na MT5 POLACZONY.

Porty domyślne:
XM             5555
IC Trading     5556
Fusion Markets 5557

Protokół:
HELLO ... END
CANDLES ... END
POSITIONS ... END
ERROR ... END
PING / PONG

Bridge jest tylko do odczytu. Nie ma żadnych funkcji handlowych.

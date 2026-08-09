# MT5 Bridge protocol 0.4

UTF-8, jedna linia = jeden rekord, LF jako separator.

## Komendy Delphi -> MT5

- `PING`
- `GET_ACCOUNT`
- `GET_POSITIONS`
- `GET_CANDLES|SYMBOL|TIMEFRAME|COUNT`

## Bloki MT5 -> Delphi

Każdy blok zaczyna się nazwą i kończy `END`.

### HELLO

```
HELLO
PLATFORM=MT5
BROKER=...
SERVER=...
LOGIN=...
BALANCE=...
EQUITY=...
CURRENCY=...
END
```

### CANDLES

```
CANDLES
SYMBOL=XAUUSD
TIMEFRAME=M15
COUNT=2
CANDLE|unix_time|open|high|low|close|volume
END
```

### POSITIONS

```
POSITIONS
COUNT=1
POSITION|ticket|symbol|BUY/SELL|volume|unix_time|open|current|sl|tp|profit
END
```


## GET_SYMBOLS

Delphi:

```text
GET_SYMBOLS
```

MT5:

```text
SYMBOLS
COUNT=3
SYMBOL|GOLD#
SYMBOL|EURUSD
SYMBOL|GBPUSD
END
```

Zwracane są symbole widoczne w Market Watch terminala.


## GET_ENTRIES

Delphi:

```text
GET_ENTRIES|60
```

MT5 odpowiada wejściami otwartymi w podanym zakresie minut:

```text
ENTRIES
COUNT=2
MINUTES=60
ENTRY|deal_ticket|symbol|BUY/SELL|volume|unix_time|price
END
```

Zwracane są tylko deale typu `DEAL_ENTRY_IN` oraz `DEAL_ENTRY_INOUT`.
Moduł służy do obserwacji rytmu decyzji, nie do oceny emocji.


## Opcjonalne ręczne zamykanie pozycji

Funkcja jest domyślnie wyłączona po obu stronach.

W EA należy ustawić:

```text
EnableTradeActions = true
```

W ForexAssistant trzeba dodatkowo zaznaczyć:

```text
Włącz akcje zamykania
```

Komendy:

```text
CLOSE_SIDE|GOLD#|BUY
CLOSE_SIDE|GOLD#|SELL
CLOSE_ALL|GOLD#
```

Odpowiedź:

```text
ACTION
COMMAND=CLOSE_SIDE
SUCCESS=1
CLOSED=2
FAILED=0
MESSAGE=Closed positions: 2
END
```

Każda akcja wymaga potwierdzenia w interfejsie.
Program zamyka wyłącznie pozycje aktualnie wybranego symbolu.

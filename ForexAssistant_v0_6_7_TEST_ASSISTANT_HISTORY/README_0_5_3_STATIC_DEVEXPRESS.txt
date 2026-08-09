ForexAssistant 0.5.3 Beta — stały interfejs DevExpress
=======================================================

Najważniejsze zmiany:

- kontrolki głównego okna zostały przeniesione do DFM,
- log Bridge jest stałym TcxMemo po lewej stronie,
- prawy panel jest stałym układem kontrolek DevExpress,
- lista sesji została przeniesiona na TcxGrid,
- fonty grida są dziedziczone spójnie z formularza,
- pierwsza kolumna sesji zawiera wyłącznie kolorową kropkę:
  zielona = otwarta,
  żółta = zamknięcie w ciągu 2 godzin,
  czerwona = zamknięta,
- żaden cały wiersz nie jest kolorowany,
- dodano stały panel podsumowania pozycji:
  BUY, SELL i wynik łączny,
- wykres pozostaje własnym komponentem Canvas i jest osadzany w stałym pnlChartHost,
- komunikacja z MT5 oraz Market Context nie zostały zmienione.

Konfiguracja MT5:
Tools -> Options -> Experts
127.0.0.1:5555

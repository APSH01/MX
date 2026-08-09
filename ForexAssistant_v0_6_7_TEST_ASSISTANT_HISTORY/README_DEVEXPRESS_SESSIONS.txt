ForexAssistant 0.3.3 - DevExpress Sessions Panel
================================================

Zmiany:
- panel sesji przeniesiony z dołu na prawą stronę,
- panel i lista są tworzone na DevExpress VCL (TcxGroupBox + TcxGrid),
- 14 centrów rynkowych,
- wskaźniki stanu:
    🟢 OTWARTA
    🟡 ZAMKNIĘCIE WKRÓTCE (30 minut lub mniej)
    🔴 ZAMKNIĘTA
- aktualizacja co 60 sekund,
- lista bez edycji, filtrowania i sortowania,
- obsługa półgodzinnych godzin otwarcia (np. Mumbai, Hong Kong, Toronto),
- podstawowa obsługa DST dla Sydney, Europy i Ameryki Północnej.

Wymagania:
- Delphi 11.1 Alexandria,
- DevExpress VCL 25.1.5,
- FireDAC SQLite jak w poprzedniej wersji.

Uwaga:
Godziny w tej wersji są domyślnymi oknami sesji do wizualizacji aktywności.
Nie zastępują godzin handlu konkretnym symbolem u brokera. Godziny GOLD#,
BRENTCash# itd. pobierzemy później z MT5 i pokażemy osobno.

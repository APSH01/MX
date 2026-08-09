unit Core.Trading.Behaviour;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  Core.Market.Types;

type
  TTradingBehaviourState = (
    tbsNoData,
    tbsStable,
    tbsChanged,
    tbsFastDecisions
  );

  TTradingBehaviourResult = record
    State: TTradingBehaviourState;
    StateText: string;
    Entries10Min: Integer;
    Entries30Min: Integer;
    Previous20Min: Integer;
    Volume10Min: Double;
    Volume30Min: Double;
    AverageIntervalSeconds: Integer;
    PriceRange10Min: Double;
    RateRatio: Double;
    Description: string;
  end;

  TTradingBehaviourAnalyzer = class
  private
    class function StateToText(const AState: TTradingBehaviourState): string; static;
  public
    class function Analyze(const AEntries: TTradeEntryList;
      const ANow: TDateTime): TTradingBehaviourResult; static;
  end;

implementation

class function TTradingBehaviourAnalyzer.StateToText(
  const AState: TTradingBehaviourState): string;
begin
  case AState of
    tbsStable:        Result := 'STABILNY';
    tbsChanged:       Result := 'ZMIANA RYTMU';
    tbsFastDecisions: Result := 'SZYBKIE DECYZJE';
  else
    Result := 'BRAK DANYCH';
  end;
end;

class function TTradingBehaviourAnalyzer.Analyze(
  const AEntries: TTradeEntryList; const ANow: TDateTime):
  TTradingBehaviourResult;
var
  I, IntervalCount: Integer;
  E: TTradeEntry;
  AgeMinutes: Double;
  MinPrice, MaxPrice: Double;
  PreviousEntryTime: TDateTime;
  IntervalSum: Int64;
  BaselinePer10Min: Double;
begin
  Result := Default(TTradingBehaviourResult);
  Result.State := tbsNoData;
  Result.StateText := StateToText(Result.State);
  Result.AverageIntervalSeconds := 0;
  MinPrice := MaxDouble;
  MaxPrice := -MaxDouble;
  PreviousEntryTime := 0;
  IntervalSum := 0;
  IntervalCount := 0;

  if not Assigned(AEntries) or (AEntries.Count = 0) then
  begin
    Result.Description := 'Brak nowych wejść w analizowanym okresie.';
    Exit;
  end;

  for I := 0 to AEntries.Count - 1 do
  begin
    E := AEntries[I];
    AgeMinutes := MinuteSpan(ANow, E.EntryTime);

    if AgeMinutes <= 30 then
    begin
      Inc(Result.Entries30Min);
      Result.Volume30Min := Result.Volume30Min + E.Volume;
    end;

    if (AgeMinutes > 10) and (AgeMinutes <= 30) then
      Inc(Result.Previous20Min);

    if AgeMinutes <= 10 then
    begin
      Inc(Result.Entries10Min);
      Result.Volume10Min := Result.Volume10Min + E.Volume;
      MinPrice := Min(MinPrice, E.Price);
      MaxPrice := Max(MaxPrice, E.Price);

      if PreviousEntryTime > 0 then
      begin
        IntervalSum := IntervalSum +
          Abs(SecondsBetween(E.EntryTime, PreviousEntryTime));
        Inc(IntervalCount);
      end;
      PreviousEntryTime := E.EntryTime;
    end;
  end;

  if IntervalCount > 0 then
    Result.AverageIntervalSeconds := Round(IntervalSum / IntervalCount);

  if Result.Entries10Min > 0 then
    Result.PriceRange10Min := Max(0, MaxPrice - MinPrice);

  BaselinePer10Min := Result.Previous20Min / 2.0;
  if BaselinePer10Min < 0.5 then
    BaselinePer10Min := 0.5;
  Result.RateRatio := Result.Entries10Min / BaselinePer10Min;

  if (Result.Entries10Min >= 6) and
     ((Result.AverageIntervalSeconds = 0) or
      (Result.AverageIntervalSeconds <= 90)) then
    Result.State := tbsFastDecisions
  else if (Result.Entries10Min >= 3) and
          (Result.RateRatio >= 2.0) then
    Result.State := tbsChanged
  else
    Result.State := tbsStable;

  Result.StateText := StateToText(Result.State);

  case Result.State of
    tbsStable:
      Result.Description :=
        'Bieżący rytm nie odbiega wyraźnie od wcześniejszej części sesji.';
    tbsChanged:
      Result.Description :=
        'Tempo nowych wejść wzrosło względem poprzednich 20 minut.';
    tbsFastDecisions:
      Result.Description :=
        'W krótkim czasie pojawiła się seria nowych wejść.';
  else
    Result.Description := 'Brak danych do porównania.';
  end;
end;

end.

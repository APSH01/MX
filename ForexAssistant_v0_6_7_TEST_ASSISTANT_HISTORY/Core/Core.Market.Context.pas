unit Core.Market.Context;

interface

uses
  System.SysUtils,
  System.Math,
  Core.Market.Types;

type
  TTrendDirection = (tdStrongDown, tdDown, tdSideways, tdUp, tdStrongUp);

  TTimeFrameContext = record
    TimeFrameText: string;
    Direction: TTrendDirection;
    DirectionText: string;
    LastPrice: Double;
    Support: Double;
    Resistance: Double;
    ATR: Double;
  end;

  TMarketContextResult = record
    M15: TTimeFrameContext;
    H1: TTimeFrameContext;
    H4: TTimeFrameContext;
    D1: TTimeFrameContext;
    MainDirectionText: string;
    PriceLocationText: string;
    VolatilityText: string;
    DecisionText: string;
    Support: Double;
    Resistance: Double;
  end;

  TMarketContextAnalyzer = class
  private
    class function AverageClose(const ACandles: TCandleList;
      const AStartIndex, ACount: Integer): Double; static;
    class function AverageRange(const ACandles: TCandleList;
      const AStartIndex, ACount: Integer): Double; static;
    class function DirectionToText(const ADirection: TTrendDirection): string; static;
  public
    class function AnalyzeTimeFrame(const ATimeFrameText: string;
      const ACandles: TCandleList): TTimeFrameContext; static;
    class function Combine(const AM15, AH1, AH4, AD1: TTimeFrameContext):
      TMarketContextResult; static;
  end;

implementation

class function TMarketContextAnalyzer.AverageClose(const ACandles: TCandleList;
  const AStartIndex, ACount: Integer): Double;
var
  I, FirstIndex, LastIndex, N: Integer;
begin
  Result := 0;
  if not Assigned(ACandles) or (ACandles.Count = 0) or (ACount <= 0) then
    Exit;

  FirstIndex := Max(0, AStartIndex);
  LastIndex := Min(ACandles.Count - 1, FirstIndex + ACount - 1);
  N := 0;
  for I := FirstIndex to LastIndex do
  begin
    Result := Result + ACandles[I].ClosePrice;
    Inc(N);
  end;
  if N > 0 then
    Result := Result / N;
end;

class function TMarketContextAnalyzer.AverageRange(const ACandles: TCandleList;
  const AStartIndex, ACount: Integer): Double;
var
  I, FirstIndex, LastIndex, N: Integer;
begin
  Result := 0;
  if not Assigned(ACandles) or (ACandles.Count = 0) or (ACount <= 0) then
    Exit;

  FirstIndex := Max(0, AStartIndex);
  LastIndex := Min(ACandles.Count - 1, FirstIndex + ACount - 1);
  N := 0;
  for I := FirstIndex to LastIndex do
  begin
    Result := Result + Abs(ACandles[I].HighPrice - ACandles[I].LowPrice);
    Inc(N);
  end;
  if N > 0 then
    Result := Result / N;
end;

class function TMarketContextAnalyzer.DirectionToText(
  const ADirection: TTrendDirection): string;
begin
  case ADirection of
    tdStrongDown: Result := 'silnie spadkowy';
    tdDown:       Result := 'spadkowy';
    tdSideways:   Result := 'boczny';
    tdUp:         Result := 'wzrostowy';
    tdStrongUp:   Result := 'silnie wzrostowy';
  else
    Result := 'brak danych';
  end;
end;

class function TMarketContextAnalyzer.AnalyzeTimeFrame(
  const ATimeFrameText: string; const ACandles: TCandleList): TTimeFrameContext;
var
  I, Start20, Start50, ZoneStart: Integer;
  SMA20, SMA20Old, SMA50, Range50, Delta, Threshold: Double;
begin
  Result := Default(TTimeFrameContext);
  Result.TimeFrameText := ATimeFrameText;
  Result.Direction := tdSideways;
  Result.DirectionText := 'brak danych';

  if not Assigned(ACandles) or (ACandles.Count < 25) then
    Exit;

  Result.LastPrice := ACandles[ACandles.Count - 1].ClosePrice;
  Start20 := Max(0, ACandles.Count - 20);
  Start50 := Max(0, ACandles.Count - 50);
  SMA20 := AverageClose(ACandles, Start20, ACandles.Count - Start20);
  SMA50 := AverageClose(ACandles, Start50, ACandles.Count - Start50);
  SMA20Old := AverageClose(ACandles, Max(0, Start20 - 5),
    Min(20, ACandles.Count - Max(0, Start20 - 5)));

  Range50 := AverageRange(ACandles, Start50, ACandles.Count - Start50);
  Result.ATR := AverageRange(ACandles, Max(0, ACandles.Count - 14),
    Min(14, ACandles.Count));

  Threshold := Max(Range50 * 0.18, Abs(Result.LastPrice) * 0.00005);
  Delta := (SMA20 - SMA50) + (SMA20 - SMA20Old) * 0.7;

  if Delta > Threshold * 2 then
    Result.Direction := tdStrongUp
  else if Delta > Threshold then
    Result.Direction := tdUp
  else if Delta < -Threshold * 2 then
    Result.Direction := tdStrongDown
  else if Delta < -Threshold then
    Result.Direction := tdDown
  else
    Result.Direction := tdSideways;

  Result.DirectionText := DirectionToText(Result.Direction);

  ZoneStart := Max(0, ACandles.Count - 30);
  Result.Support := ACandles[ZoneStart].LowPrice;
  Result.Resistance := ACandles[ZoneStart].HighPrice;
  for I := ZoneStart + 1 to ACandles.Count - 1 do
  begin
    Result.Support := Min(Result.Support, ACandles[I].LowPrice);
    Result.Resistance := Max(Result.Resistance, ACandles[I].HighPrice);
  end;
end;

class function TMarketContextAnalyzer.Combine(const AM15, AH1, AH4,
  AD1: TTimeFrameContext): TMarketContextResult;
var
  Score, BullCount, BearCount: Integer;
  Price, Span, PositionInRange, AvgAtr: Double;
begin
  Result := Default(TMarketContextResult);
  Result.M15 := AM15;
  Result.H1 := AH1;
  Result.H4 := AH4;
  Result.D1 := AD1;

  Score := 0;
  BullCount := 0;
  BearCount := 0;

  case AH1.Direction of
    tdStrongUp: Inc(Score, 2);
    tdUp: Inc(Score);
    tdStrongDown: Dec(Score, 2);
    tdDown: Dec(Score);
  end;
  case AH4.Direction of
    tdStrongUp: Inc(Score, 4);
    tdUp: Inc(Score, 2);
    tdStrongDown: Dec(Score, 4);
    tdDown: Dec(Score, 2);
  end;
  case AD1.Direction of
    tdStrongUp: Inc(Score, 3);
    tdUp: Inc(Score, 2);
    tdStrongDown: Dec(Score, 3);
    tdDown: Dec(Score, 2);
  end;

  if AM15.Direction in [tdUp, tdStrongUp] then Inc(BullCount);
  if AH1.Direction in [tdUp, tdStrongUp] then Inc(BullCount);
  if AH4.Direction in [tdUp, tdStrongUp] then Inc(BullCount);
  if AD1.Direction in [tdUp, tdStrongUp] then Inc(BullCount);

  if AM15.Direction in [tdDown, tdStrongDown] then Inc(BearCount);
  if AH1.Direction in [tdDown, tdStrongDown] then Inc(BearCount);
  if AH4.Direction in [tdDown, tdStrongDown] then Inc(BearCount);
  if AD1.Direction in [tdDown, tdStrongDown] then Inc(BearCount);

  if Score >= 6 then
    Result.MainDirectionText := 'WZROSTOWY'
  else if Score >= 2 then
    Result.MainDirectionText := 'lekko wzrostowy'
  else if Score <= -6 then
    Result.MainDirectionText := 'SPADKOWY'
  else if Score <= -2 then
    Result.MainDirectionText := 'lekko spadkowy'
  else
    Result.MainDirectionText := 'MIESZANY / BOCZNY';

  Result.Support := AH1.Support;
  Result.Resistance := AH1.Resistance;
  Price := AM15.LastPrice;
  Span := Result.Resistance - Result.Support;

  if Span > 0 then
  begin
    PositionInRange := (Price - Result.Support) / Span;
    if PositionInRange <= 0.20 then
      Result.PriceLocationText := 'blisko wsparcia H1'
    else if PositionInRange >= 0.80 then
      Result.PriceLocationText := 'blisko oporu H1'
    else
      Result.PriceLocationText := 'w środku zakresu H1';
  end
  else
    Result.PriceLocationText := 'brak zakresu H1';

  AvgAtr := (AM15.ATR + AH1.ATR / 4) / 2;
  if (AM15.ATR > 0) and (AvgAtr > 0) then
  begin
    if AM15.ATR > AvgAtr * 1.35 then
      Result.VolatilityText := 'podwyższona'
    else if AM15.ATR < AvgAtr * 0.70 then
      Result.VolatilityText := 'niska'
    else
      Result.VolatilityText := 'średnia';
  end
  else
    Result.VolatilityText := 'brak danych';

  if (BullCount >= 3) and (Result.PriceLocationText = 'blisko oporu H1') then
    Result.DecisionText := 'Trend wzrostowy, ale wejście BUY może być spóźnione.'
  else if (BearCount >= 3) and (Result.PriceLocationText = 'blisko wsparcia H1') then
    Result.DecisionText := 'Trend spadkowy, ale wejście SELL może być spóźnione.'
  else if BullCount >= 3 then
    Result.DecisionText := 'Przewaga wzrostowa na wielu interwałach.'
  else if BearCount >= 3 then
    Result.DecisionText := 'Przewaga spadkowa na wielu interwałach.'
  else
    Result.DecisionText := 'Brak pełnej zgodności interwałów — ostrożnie.';
end;

end.

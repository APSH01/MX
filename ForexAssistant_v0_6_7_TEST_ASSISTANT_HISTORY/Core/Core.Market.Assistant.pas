unit Core.Market.Assistant;

interface

uses
  System.SysUtils,
  System.Math,
  Core.Market.Context;

type
  TAssistantDirection = (adNone, adBuy, adSell);

  TMarketAssistantResult = record
    Direction: TAssistantDirection;
    SuggestionText: string;
    BuyScore: Integer;
    SellScore: Integer;
    Confidence: Integer;
    DataQualityText: string;

    TrendScore: Integer;
    AlignmentScore: Integer;
    LocationScore: Integer;
    VolatilityScore: Integer;
    RoomScore: Integer;

    ArgumentsFor: TArray<string>;
    ArgumentsAgainst: TArray<string>;
  end;

  TMarketAssistantEngine = class
  private
    class procedure AddArgument(var AItems: TArray<string>;
      const AText: string); static;
    class function TrendValue(const ADirection: TTrendDirection): Integer; static;
    class function ClampScore(const AValue: Integer): Integer; static;
  public
    class function Analyze(const AContext: TMarketContextResult):
      TMarketAssistantResult; static;
  end;

implementation

class procedure TMarketAssistantEngine.AddArgument(
  var AItems: TArray<string>; const AText: string);
var
  L: Integer;
begin
  L := Length(AItems);
  SetLength(AItems, L + 1);
  AItems[L] := AText;
end;

class function TMarketAssistantEngine.TrendValue(
  const ADirection: TTrendDirection): Integer;
begin
  case ADirection of
    tdStrongDown: Result := -2;
    tdDown:       Result := -1;
    tdSideways:   Result := 0;
    tdUp:         Result := 1;
    tdStrongUp:   Result := 2;
  else
    Result := 0;
  end;
end;

class function TMarketAssistantEngine.ClampScore(
  const AValue: Integer): Integer;
begin
  Result := EnsureRange(AValue, 0, 100);
end;

class function TMarketAssistantEngine.Analyze(
  const AContext: TMarketContextResult): TMarketAssistantResult;
var
  DirectionValue: Integer;
  BullishCount, BearishCount: Integer;
  BuyScore, SellScore, Difference: Integer;
  Price, Span, PositionInRange: Double;
begin
  Result := Default(TMarketAssistantResult);
  Result.Direction := adNone;
  Result.SuggestionText := 'BRAK WYRAŹNEJ PRZEWAGI';
  Result.DataQualityText := 'GOOD';

  DirectionValue :=
    TrendValue(AContext.M15.Direction) * 4 +
    TrendValue(AContext.H1.Direction) * 11 +
    TrendValue(AContext.H4.Direction) * 14 +
    TrendValue(AContext.D1.Direction) * 7;

  Result.TrendScore := ClampScore(50 + DirectionValue);

  BullishCount := 0;
  BearishCount := 0;

  if AContext.M15.Direction in [tdUp, tdStrongUp] then Inc(BullishCount);
  if AContext.H1.Direction in [tdUp, tdStrongUp] then Inc(BullishCount);
  if AContext.H4.Direction in [tdUp, tdStrongUp] then Inc(BullishCount);
  if AContext.D1.Direction in [tdUp, tdStrongUp] then Inc(BullishCount);

  if AContext.M15.Direction in [tdDown, tdStrongDown] then Inc(BearishCount);
  if AContext.H1.Direction in [tdDown, tdStrongDown] then Inc(BearishCount);
  if AContext.H4.Direction in [tdDown, tdStrongDown] then Inc(BearishCount);
  if AContext.D1.Direction in [tdDown, tdStrongDown] then Inc(BearishCount);

  if (BullishCount >= 3) or (BearishCount >= 3) then
    Result.AlignmentScore := 85
  else if (BullishCount = 2) or (BearishCount = 2) then
    Result.AlignmentScore := 60
  else
    Result.AlignmentScore := 35;

  Result.LocationScore := 50;
  Price := AContext.M15.LastPrice;
  Span := AContext.Resistance - AContext.Support;

  if Span > 0 then
  begin
    PositionInRange := EnsureRange(
      (Price - AContext.Support) / Span, 0.0, 1.0);

    if PositionInRange <= 0.20 then
    begin
      Result.LocationScore := 80;
      AddArgument(Result.ArgumentsFor, 'Cena znajduje się blisko wsparcia H1');
    end
    else if PositionInRange >= 0.80 then
    begin
      Result.LocationScore := 20;
      AddArgument(Result.ArgumentsAgainst, 'Cena znajduje się blisko oporu H1');
    end
    else
      Result.LocationScore := 55;

    Result.RoomScore := Round(100 * Abs(0.5 - PositionInRange) * 2);
    Result.RoomScore := ClampScore(100 - Result.RoomScore div 2);
  end
  else
  begin
    Result.LocationScore := 30;
    Result.RoomScore := 30;
    Result.DataQualityText := 'LOW';
    AddArgument(Result.ArgumentsAgainst, 'Brak poprawnego zakresu H1');
  end;

  if SameText(AContext.VolatilityText, 'średnia') then
    Result.VolatilityScore := 80
  else if SameText(AContext.VolatilityText, 'niska') then
  begin
    Result.VolatilityScore := 55;
    AddArgument(Result.ArgumentsAgainst, 'Zmienność jest niska');
  end
  else if SameText(AContext.VolatilityText, 'podwyższona') then
  begin
    Result.VolatilityScore := 45;
    Result.DataQualityText := 'CAUTION';
    AddArgument(Result.ArgumentsAgainst, 'Zmienność jest podwyższona');
  end
  else
  begin
    Result.VolatilityScore := 25;
    Result.DataQualityText := 'LOW';
  end;

  BuyScore := 50 + DirectionValue;
  SellScore := 50 - DirectionValue;

  if SameText(AContext.PriceLocationText, 'blisko wsparcia H1') then
  begin
    Inc(BuyScore, 10);
    Dec(SellScore, 5);
  end
  else if SameText(AContext.PriceLocationText, 'blisko oporu H1') then
  begin
    Inc(SellScore, 10);
    Dec(BuyScore, 5);
  end;

  if Result.AlignmentScore >= 80 then
  begin
    if BullishCount >= 3 then
      AddArgument(Result.ArgumentsFor,
        'Zgodność wzrostowa co najmniej trzech interwałów')
    else if BearishCount >= 3 then
      AddArgument(Result.ArgumentsFor,
        'Zgodność spadkowa co najmniej trzech interwałów');
  end
  else
    AddArgument(Result.ArgumentsAgainst,
      'Interwały nie pokazują pełnej zgodności');

  if AContext.H1.Direction in [tdUp, tdStrongUp] then
    AddArgument(Result.ArgumentsFor, 'H1: ' + AContext.H1.DirectionText)
  else if AContext.H1.Direction in [tdDown, tdStrongDown] then
    AddArgument(Result.ArgumentsFor, 'H1: ' + AContext.H1.DirectionText);

  if AContext.H4.Direction in [tdUp, tdStrongUp] then
    AddArgument(Result.ArgumentsFor, 'H4: ' + AContext.H4.DirectionText)
  else if AContext.H4.Direction in [tdDown, tdStrongDown] then
    AddArgument(Result.ArgumentsFor, 'H4: ' + AContext.H4.DirectionText);

  Result.BuyScore := ClampScore(BuyScore);
  Result.SellScore := ClampScore(SellScore);

  Difference := Abs(Result.BuyScore - Result.SellScore);
  Result.Confidence := ClampScore(
    25 + Difference + Result.AlignmentScore div 4);

  if (Result.BuyScore >= 65) and
     (Result.BuyScore >= Result.SellScore + 12) then
  begin
    Result.Direction := adBuy;
    Result.SuggestionText := 'ROZWAŻ BUY';
  end
  else if (Result.SellScore >= 65) and
          (Result.SellScore >= Result.BuyScore + 12) then
  begin
    Result.Direction := adSell;
    Result.SuggestionText := 'ROZWAŻ SELL';
  end;
end;

end.

unit Core.Trading.Basket;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  System.StrUtils,
  Core.Market.Types;

type
  TBasketRisk = (brNone, brLow, brMedium, brHigh);

  TBasketAnalysis = record
    PositionCount: Integer;
    BuyCount: Integer;
    SellCount: Integer;
    BuyVolume: Double;
    SellVolume: Double;
    NetVolume: Double;
    BuyAverage: Double;
    SellAverage: Double;
    CurrentPrice: Double;
    TotalProfit: Double;
    OldestPositionMinutes: Integer;
    SpreadBetweenAverages: Double;
    DistanceFromBuyAverage: Double;
    DistanceFromSellAverage: Double;
    Risk: TBasketRisk;
    RiskText: string;
    SummaryText: string;
  end;

  TBasketAnalyzer = class
  public
    class function Analyze(const APositions: TOpenPositionList):
      TBasketAnalysis; static;
  end;

implementation

class function TBasketAnalyzer.Analyze(
  const APositions: TOpenPositionList): TBasketAnalysis;
var
  P: TOpenPosition;
  BuyValue, SellValue: Double;
  OldestTime: TDateTime;
  GrossVolume, Imbalance: Double;
begin
  Result := Default(TBasketAnalysis);
  Result.Risk := brNone;
  Result.RiskText := 'BRAK';

  if not Assigned(APositions) or (APositions.Count = 0) then
  begin
    Result.SummaryText := 'Brak otwartych pozycji';
    Exit;
  end;

  Result.PositionCount := APositions.Count;
  BuyValue := 0;
  SellValue := 0;
  OldestTime := 0;

  for P in APositions do
  begin
    Result.TotalProfit := Result.TotalProfit + P.Profit;
    Result.CurrentPrice := P.CurrentPrice;

    if (OldestTime = 0) or (P.OpenTime < OldestTime) then
      OldestTime := P.OpenTime;

    if P.Side = psBuy then
    begin
      Inc(Result.BuyCount);
      Result.BuyVolume := Result.BuyVolume + P.Volume;
      BuyValue := BuyValue + P.OpenPrice * P.Volume;
    end
    else
    begin
      Inc(Result.SellCount);
      Result.SellVolume := Result.SellVolume + P.Volume;
      SellValue := SellValue + P.OpenPrice * P.Volume;
    end;
  end;

  if Result.BuyVolume > 0 then
    Result.BuyAverage := BuyValue / Result.BuyVolume;
  if Result.SellVolume > 0 then
    Result.SellAverage := SellValue / Result.SellVolume;

  Result.NetVolume := Result.BuyVolume - Result.SellVolume;

  if (Result.BuyAverage > 0) and (Result.CurrentPrice > 0) then
    Result.DistanceFromBuyAverage :=
      Result.CurrentPrice - Result.BuyAverage;

  if (Result.SellAverage > 0) and (Result.CurrentPrice > 0) then
    Result.DistanceFromSellAverage :=
      Result.SellAverage - Result.CurrentPrice;

  if (Result.BuyAverage > 0) and (Result.SellAverage > 0) then
    Result.SpreadBetweenAverages :=
      Abs(Result.BuyAverage - Result.SellAverage);

  if OldestTime > 0 then
    Result.OldestPositionMinutes := MinutesBetween(Now, OldestTime);

  GrossVolume := Result.BuyVolume + Result.SellVolume;
  if GrossVolume > 0 then
    Imbalance := Abs(Result.NetVolume) / GrossVolume
  else
    Imbalance := 0;

  if (Result.PositionCount >= 7) or
     (Imbalance >= 0.80) or
     (Result.OldestPositionMinutes >= 1440) then
    Result.Risk := brHigh
  else if (Result.PositionCount >= 4) or
          (Imbalance >= 0.50) or
          (Result.OldestPositionMinutes >= 360) then
    Result.Risk := brMedium
  else
    Result.Risk := brLow;

  case Result.Risk of
    brLow:    Result.RiskText := 'LOW';
    brMedium: Result.RiskText := 'MEDIUM';
    brHigh:   Result.RiskText := 'HIGH';
  else
    Result.RiskText := 'BRAK';
  end;

  Result.SummaryText :=
    Format('Pozycje: %d   BUY: %d / %.2f   SELL: %d / %.2f' + sLineBreak +
           'Śr. BUY: %s   Śr. SELL: %s' + sLineBreak +
           'Net: %s   P/L: %s   Risk: %s',
      [Result.PositionCount,
       Result.BuyCount, Result.BuyVolume,
       Result.SellCount, Result.SellVolume,
       IfThen(Result.BuyAverage > 0,
         FormatFloat('0.00000', Result.BuyAverage), '-'),
       IfThen(Result.SellAverage > 0,
         FormatFloat('0.00000', Result.SellAverage), '-'),
       FormatFloat('+#,##0.00;-#,##0.00;0.00', Result.NetVolume),
       FormatFloat('+#,##0.00;-#,##0.00;0.00', Result.TotalProfit),
       Result.RiskText]);
end;

end.

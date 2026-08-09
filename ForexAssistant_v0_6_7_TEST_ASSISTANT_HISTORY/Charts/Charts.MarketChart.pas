unit Charts.MarketChart;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics,
  Core.Market.Types;

type
  TMarketChart = class(TCustomControl)
  private
    FCandles: TCandleList;
    FPositions: TOpenPositionList;
    FShowFibonacci: Boolean;
    FSymbol: string;
    FTimeFrameText: string;
    procedure SetShowFibonacci(const Value: Boolean);
    procedure DrawGrid(const ARect: TRect);
    procedure DrawCandles(const ARect: TRect);
    procedure DrawFibonacci(const ARect: TRect; const AMinPrice, AMaxPrice: Double);
    procedure DrawPositions(const ARect: TRect; const AMinPrice, AMaxPrice: Double);
    function PriceToY(const APrice, AMinPrice, AMaxPrice: Double;
      const ARect: TRect): Integer;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetData(const ACandles: TCandleList; const ASymbol,
      ATimeFrameText: string);
    procedure SetPositions(const APositions: TOpenPositionList);
    property ShowFibonacci: Boolean read FShowFibonacci write SetShowFibonacci;
  end;

implementation

constructor TMarketChart.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
  Color := $00201F1F;
  ParentBackground := False;
  FCandles := TCandleList.Create;
  FPositions := TOpenPositionList.Create;
  FShowFibonacci := True;
  FSymbol := 'XAUUSD';
  FTimeFrameText := 'M15';
end;

destructor TMarketChart.Destroy;
begin
  FPositions.Free;
  FCandles.Free;
  inherited;
end;

procedure TMarketChart.SetData(const ACandles: TCandleList; const ASymbol,
  ATimeFrameText: string);
var
  C: TCandle;
begin
  FCandles.Clear;
  if Assigned(ACandles) then
    for C in ACandles do
      FCandles.Add(C);
  FSymbol := ASymbol;
  FTimeFrameText := ATimeFrameText;
  Invalidate;
end;

procedure TMarketChart.SetPositions(const APositions: TOpenPositionList);
var
  P: TOpenPosition;
begin
  FPositions.Clear;
  if Assigned(APositions) then
    for P in APositions do
      if SameText(P.Symbol, FSymbol) then
        FPositions.Add(P);
  Invalidate;
end;

procedure TMarketChart.SetShowFibonacci(const Value: Boolean);
begin
  if FShowFibonacci <> Value then
  begin
    FShowFibonacci := Value;
    Invalidate;
  end;
end;

function TMarketChart.PriceToY(const APrice, AMinPrice, AMaxPrice: Double;
  const ARect: TRect): Integer;
var
  Scale: Double;
begin
  if SameValue(AMaxPrice, AMinPrice) then
    Exit((ARect.Top + ARect.Bottom) div 2);
  Scale := (APrice - AMinPrice) / (AMaxPrice - AMinPrice);
  Result := ARect.Bottom - Round(Scale * (ARect.Bottom - ARect.Top));
end;

procedure TMarketChart.DrawGrid(const ARect: TRect);
var
  I, X, Y: Integer;
begin
  Canvas.Pen.Color := $00343434;
  Canvas.Pen.Width := 1;
  for I := 0 to 10 do
  begin
    X := ARect.Left + MulDiv(ARect.Right - ARect.Left, I, 10);
    Canvas.MoveTo(X, ARect.Top);
    Canvas.LineTo(X, ARect.Bottom);
  end;
  for I := 0 to 8 do
  begin
    Y := ARect.Top + MulDiv(ARect.Bottom - ARect.Top, I, 8);
    Canvas.MoveTo(ARect.Left, Y);
    Canvas.LineTo(ARect.Right, Y);
  end;
end;

procedure TMarketChart.DrawFibonacci(const ARect: TRect; const AMinPrice,
  AMaxPrice: Double);
const
  LEVELS: array[0..6] of Double = (0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0);
var
  I, Y: Integer;
  Price: Double;
  TextValue: string;
begin
  Canvas.Pen.Style := psDash;
  Canvas.Pen.Color := $0070C0E0;
  Canvas.Font.Color := $00D0E8F0;
  Canvas.Brush.Style := bsClear;
  for I := Low(LEVELS) to High(LEVELS) do
  begin
    Price := AMaxPrice - (AMaxPrice - AMinPrice) * LEVELS[I];
    Y := PriceToY(Price, AMinPrice, AMaxPrice, ARect);
    Canvas.MoveTo(ARect.Left, Y);
    Canvas.LineTo(ARect.Right, Y);
    TextValue := Format(' %.1f%%  %.5f', [LEVELS[I] * 100, Price]);
    if I = Low(LEVELS) then
      Canvas.TextOut(ARect.Left + 4, Y + 2, TextValue)
    else if I = High(LEVELS) then
      Canvas.TextOut(ARect.Left + 4,
        Y - Canvas.TextHeight(TextValue) - 2, TextValue)
    else
      Canvas.TextOut(ARect.Left + 4,
        Y - Canvas.TextHeight(TextValue), TextValue);
  end;
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Style := bsSolid;
end;

procedure TMarketChart.DrawPositions(const ARect: TRect; const AMinPrice,
  AMaxPrice: Double);
var
  P: TOpenPosition;
  Y: Integer;
  S, ProfitText: string;
  LineColor: TColor;
begin
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Style := [fsBold];
  for P in FPositions do
  begin
    Y := PriceToY(P.OpenPrice, AMinPrice, AMaxPrice, ARect);
    if P.Side = psBuy then
      LineColor := $00E0A040
    else
      LineColor := $004080E0;

    Canvas.Pen.Color := LineColor;
    Canvas.Pen.Width := 2;
    Canvas.Pen.Style := psDash;
    Canvas.MoveTo(ARect.Left, Y);
    Canvas.LineTo(ARect.Right, Y);

    ProfitText := FormatFloat('+#,##0.00;-#,##0.00;0.00', P.Profit);
    S := Format('%s %.2f  open %.5f  P/L %s',
      [PositionSideToText(P.Side), P.Volume, P.OpenPrice, ProfitText]);

    { Opis pozycji zawsze biały; kierunek pozostaje oznaczony
      kolorem linii pozycji. }
    Canvas.Font.Color := clWhite;
    Canvas.TextOut(ARect.Right - Canvas.TextWidth(S) - 6,
      EnsureRange(Y - Canvas.TextHeight(S), ARect.Top + 2,
        ARect.Bottom - Canvas.TextHeight(S) - 2), S);
  end;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  Canvas.Font.Style := [];
  Canvas.Brush.Style := bsSolid;
end;

procedure TMarketChart.DrawCandles(const ARect: TRect);
var
  C: TCandle;
  P: TOpenPosition;
  I, X, CandleWidth, YOpen, YClose, YHigh, YLow: Integer;
  MinPrice, MaxPrice, Margin: Double;
  BodyRect: TRect;
begin
  if FCandles.Count = 0 then Exit;

  MinPrice := FCandles[0].LowPrice;
  MaxPrice := FCandles[0].HighPrice;
  for C in FCandles do
  begin
    MinPrice := Min(MinPrice, C.LowPrice);
    MaxPrice := Max(MaxPrice, C.HighPrice);
  end;
  for P in FPositions do
  begin
    MinPrice := Min(MinPrice, P.OpenPrice);
    MaxPrice := Max(MaxPrice, P.OpenPrice);
  end;

  Margin := (MaxPrice - MinPrice) * 0.05;
  if Margin <= 0 then Margin := Max(0.00001, MaxPrice * 0.001);
  MinPrice := MinPrice - Margin;
  MaxPrice := MaxPrice + Margin;

  CandleWidth := Max(3, (ARect.Right - ARect.Left) div Max(1, FCandles.Count) - 2);
  for I := 0 to FCandles.Count - 1 do
  begin
    C := FCandles[I];
    X := ARect.Left + MulDiv(ARect.Right - ARect.Left,
      I * 2 + 1, FCandles.Count * 2);
    YOpen := PriceToY(C.OpenPrice, MinPrice, MaxPrice, ARect);
    YClose := PriceToY(C.ClosePrice, MinPrice, MaxPrice, ARect);
    YHigh := PriceToY(C.HighPrice, MinPrice, MaxPrice, ARect);
    YLow := PriceToY(C.LowPrice, MinPrice, MaxPrice, ARect);

    if C.ClosePrice >= C.OpenPrice then
      Canvas.Pen.Color := $0048D597
    else
      Canvas.Pen.Color := $005B6BEF;
    Canvas.Brush.Color := Canvas.Pen.Color;
    Canvas.MoveTo(X, YHigh);
    Canvas.LineTo(X, YLow);
    BodyRect := Rect(X - CandleWidth div 2, Min(YOpen, YClose),
      X + CandleWidth div 2 + 1, Max(YOpen, YClose) + 1);
    if BodyRect.Bottom - BodyRect.Top < 2 then
      BodyRect.Bottom := BodyRect.Top + 2;
    Canvas.Rectangle(BodyRect);
  end;

  if FShowFibonacci then DrawFibonacci(ARect, MinPrice, MaxPrice);
  DrawPositions(ARect, MinPrice, MaxPrice);
end;

procedure TMarketChart.Paint;
var
  R: TRect;
  CaptionText: string;
begin
  inherited;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  R := ClientRect;
  InflateRect(R, -12, -12);
  Inc(R.Top, 28);
  Dec(R.Right, 4);
  Dec(R.Bottom, 4);
  DrawGrid(R);
  DrawCandles(R);

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := clWhite;
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [fsBold];
  CaptionText := FSymbol + '  ' + FTimeFrameText;
  Canvas.TextOut(12, 8, CaptionText);
  Canvas.Brush.Style := bsSolid;
end;

end.

unit Core.Market.Types;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TMarketTimeFrame = (
    mtfM1, mtfM5, mtfM15, mtfM30,
    mtfH1, mtfH4,
    mtfD1, mtfW1, mtfMN1
  );

  TCandle = record
    Time: TDateTime;
    OpenPrice: Double;
    HighPrice: Double;
    LowPrice: Double;
    ClosePrice: Double;
    Volume: Int64;
  end;

  TCandleList = TList<TCandle>;

  TPositionSide = (psBuy, psSell);

  TOpenPosition = record
    Ticket: Int64;
    Symbol: string;
    Side: TPositionSide;
    Volume: Double;
    OpenTime: TDateTime;
    OpenPrice: Double;
    CurrentPrice: Double;
    StopLoss: Double;
    TakeProfit: Double;
    Profit: Double;
  end;

  TOpenPositionList = TList<TOpenPosition>;

  TTradeEntry = record
    DealTicket: Int64;
    Symbol: string;
    Side: TPositionSide;
    Volume: Double;
    EntryTime: TDateTime;
    Price: Double;
  end;

  TTradeEntryList = TList<TTradeEntry>;

function PositionSideToText(const ASide: TPositionSide): string;

function TimeFrameToText(const ATimeFrame: TMarketTimeFrame): string;
function TextToTimeFrame(const AText: string): TMarketTimeFrame;
function TimeFrameToMinutes(const ATimeFrame: TMarketTimeFrame): Integer;

implementation

function PositionSideToText(const ASide: TPositionSide): string;
begin
  case ASide of
    psBuy: Result := 'BUY';
    psSell: Result := 'SELL';
  else
    Result := '';
  end;
end;

function TimeFrameToText(const ATimeFrame: TMarketTimeFrame): string;
begin
  case ATimeFrame of
    mtfM1:  Result := 'M1';
    mtfM5:  Result := 'M5';
    mtfM15: Result := 'M15';
    mtfM30: Result := 'M30';
    mtfH1:  Result := 'H1';
    mtfH4:  Result := 'H4';
    mtfD1:  Result := 'D1';
    mtfW1:  Result := 'W1';
    mtfMN1: Result := 'MN1';
  else
    Result := 'M15';
  end;
end;

function TextToTimeFrame(const AText: string): TMarketTimeFrame;
var
  S: string;
begin
  S := UpperCase(Trim(AText));
  if S = 'M1' then Exit(mtfM1);
  if S = 'M5' then Exit(mtfM5);
  if S = 'M15' then Exit(mtfM15);
  if S = 'M30' then Exit(mtfM30);
  if S = 'H1' then Exit(mtfH1);
  if S = 'H4' then Exit(mtfH4);
  if S = 'D1' then Exit(mtfD1);
  if S = 'W1' then Exit(mtfW1);
  if S = 'MN1' then Exit(mtfMN1);
  Result := mtfM15;
end;

function TimeFrameToMinutes(const ATimeFrame: TMarketTimeFrame): Integer;
begin
  case ATimeFrame of
    mtfM1:  Result := 1;
    mtfM5:  Result := 5;
    mtfM15: Result := 15;
    mtfM30: Result := 30;
    mtfH1:  Result := 60;
    mtfH4:  Result := 240;
    mtfD1:  Result := 1440;
    mtfW1:  Result := 10080;
    mtfMN1: Result := 43200;
  else
    Result := 15;
  end;
end;

end.

unit Providers.Mock;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.DateUtils,
  Core.Market.Types,
  Core.Market.Provider;

type
  TMockMarketDataProvider = class(TInterfacedObject, IMarketDataProvider)
  private
    FConnected: Boolean;
    function BasePriceForSymbol(const ASymbol: string): Double;
  public
    function Connect(const ALogin, APassword, AServer: string): Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    function IsDataAvailable: Boolean;
    function ProviderName: string;
    function StatusText: string;
    function LoadSymbols: TStringList;
    function LoadCandles(const ASymbol: string;
      const ATimeFrame: TMarketTimeFrame;
      const ACount: Integer): TCandleList;
    function LoadOpenPositions: TOpenPositionList;
    function LoadRecentEntries(const AMinutes: Integer): TTradeEntryList;
    function SupportsTradeActions: Boolean;
    function ClosePositionsBySide(const ASymbol: string;
      const ASide: TPositionSide; out AMessage: string): Boolean;
    function CloseAllPositions(const ASymbol: string;
      out AMessage: string): Boolean;
  end;

implementation

function TMockMarketDataProvider.Connect(const ALogin, APassword,
  AServer: string): Boolean;
begin
  FConnected := True;
  Result := True;
end;

procedure TMockMarketDataProvider.Disconnect;
begin
  FConnected := False;
end;

function TMockMarketDataProvider.IsConnected: Boolean;
begin
  Result := FConnected;
end;

function TMockMarketDataProvider.IsDataAvailable: Boolean;
begin
  Result := FConnected;
end;

function TMockMarketDataProvider.ProviderName: string;
begin
  Result := 'Tryb demonstracyjny';
end;

function TMockMarketDataProvider.StatusText: string;
begin
  if FConnected then
    Result := 'POŁĄCZONO (Tryb demonstracyjny)'
  else
    Result := 'ROZŁĄCZONO';
end;

function TMockMarketDataProvider.LoadSymbols: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('GOLD#');
  Result.Add('EURUSD');
  Result.Add('GBPUSD');
  Result.Add('USDJPY');
end;

function TMockMarketDataProvider.BasePriceForSymbol(const ASymbol: string): Double;
var
  S: string;
begin
  S := UpperCase(ASymbol);
  if (S = 'XAUUSD') or (S = 'GOLD') then Exit(2350);
  if (S = 'XAGUSD') or (S = 'SILVER') then Exit(28);
  if Pos('JPY', S) > 0 then Exit(155);
  if Pos('BTC', S) > 0 then Exit(65000);
  if Pos('ETH', S) > 0 then Exit(3500);
  if Pos('US30', S) > 0 then Exit(39000);
  if Pos('NAS', S) > 0 then Exit(19000);
  if Pos('GER', S) > 0 then Exit(18500);
  Result := 1.10;
end;

function TMockMarketDataProvider.LoadCandles(const ASymbol: string;
  const ATimeFrame: TMarketTimeFrame; const ACount: Integer): TCandleList;
var
  I, Count, Minutes: Integer;
  C: TCandle;
  Price, Step, Delta, Wick: Double;
  Seed: Integer;
begin
  Result := TCandleList.Create;
  if not FConnected then Exit;

  Count := Max(10, ACount);
  Minutes := TimeFrameToMinutes(ATimeFrame);
  Price := BasePriceForSymbol(ASymbol);
  Step := Max(Price * 0.0015, 0.0002);
  Seed := Length(ASymbol) * 97 + Ord(ATimeFrame) * 1009;
  RandSeed := Seed;

  for I := Count - 1 downto 0 do
  begin
    C.Time := IncMinute(Now, -I * Minutes);
    C.OpenPrice := Price;
    Delta := (Random - 0.47) * Step * 2;
    C.ClosePrice := Max(0.00001, C.OpenPrice + Delta);
    Wick := Random * Step;
    C.HighPrice := Max(C.OpenPrice, C.ClosePrice) + Wick;
    C.LowPrice := Max(0.00001, Min(C.OpenPrice, C.ClosePrice) - Random * Step);
    C.Volume := 100 + Random(5000);
    Result.Add(C);
    Price := C.ClosePrice;
  end;
end;

function TMockMarketDataProvider.LoadOpenPositions: TOpenPositionList;
begin
  Result := TOpenPositionList.Create;
end;

function TMockMarketDataProvider.LoadRecentEntries(
  const AMinutes: Integer): TTradeEntryList;
begin
  Result := TTradeEntryList.Create;
end;

function TMockMarketDataProvider.SupportsTradeActions: Boolean;
begin
  Result := False;
end;

function TMockMarketDataProvider.ClosePositionsBySide(
  const ASymbol: string; const ASide: TPositionSide;
  out AMessage: string): Boolean;
begin
  AMessage := 'Provider demonstracyjny nie obsługuje akcji tradingowych.';
  Result := False;
end;

function TMockMarketDataProvider.CloseAllPositions(
  const ASymbol: string; out AMessage: string): Boolean;
begin
  AMessage := 'Provider demonstracyjny nie obsługuje akcji tradingowych.';
  Result := False;
end;

end.

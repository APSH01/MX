unit Core.Market.Provider;

interface

uses
  System.Classes,
  Core.Market.Types;

type
  IMarketDataProvider = interface
    ['{D33B223F-A835-4EE8-BFCF-0C70E12820B6}']
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

end.

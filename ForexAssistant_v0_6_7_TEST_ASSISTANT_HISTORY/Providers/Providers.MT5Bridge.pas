unit Providers.MT5Bridge;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.DateUtils,
  IdTCPServer, IdContext, IdGlobal, IdExceptionCore,
  Core.Market.Types, Core.Market.Provider;

type
  TMT5BridgeProvider = class(TInterfacedObject, IMarketDataProvider)
  private
    FServer: TIdTCPServer;
    FLock: TCriticalSection;
    FResponseEvent: TEvent;
    FClientContext: TIdContext;
    FBridgeConnected: Boolean;
    FLastResponse: string;
    FCurrentBlock: string;
    FBlockLines: TStringList;
    FBroker: string;
    FAccountServer: string;
    FAccountLogin: string;
    FHost: string;
    FPort: Integer;
    FDiagnostics: TStringList;
    procedure AddDiagnostic(const AText: string);
    procedure ServerExecute(AContext: TIdContext);
    procedure SetClientContext(AContext: TIdContext);
    procedure ClearClientContext(AContext: TIdContext);
    procedure ProcessLine(AContext: TIdContext; const ALine: string);
    procedure FinishBlock(AContext: TIdContext);
    procedure ProcessHelloBlock(const AText: string);
    procedure StoreResponse(const AText: string);
    function SendCommandAndWait(const ACommand: string; out AResponse: string;
      const ATimeoutMs: Cardinal): Boolean;
    function ParseSymbols(const AText: string): TStringList;
    function ParseCandles(const AText: string): TCandleList;
    function ParsePositions(const AText: string): TOpenPositionList;
    function ParseEntries(const AText: string): TTradeEntryList;
    function ExecuteTradeAction(const ACommand: string;
      out AMessage: string): Boolean;
  public
    constructor Create(const AHost: string = '127.0.0.1'; const APort: Integer = 5555);
    destructor Destroy; override;
    function Connect(const ALogin, APassword, AServer: string): Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    function IsDataAvailable: Boolean;
    function ProviderName: string;
    function StatusText: string;
    function LoadSymbols: TStringList;
    function LoadCandles(const ASymbol: string; const ATimeFrame: TMarketTimeFrame;
      const ACount: Integer): TCandleList;
    function LoadOpenPositions: TOpenPositionList;
    function LoadRecentEntries(const AMinutes: Integer): TTradeEntryList;
    function SupportsTradeActions: Boolean;
    function ClosePositionsBySide(const ASymbol: string;
      const ASide: TPositionSide; out AMessage: string): Boolean;
    function CloseAllPositions(const ASymbol: string;
      out AMessage: string): Boolean;
    procedure DrainDiagnostics(const ADestination: TStrings);
  end;

implementation

uses Utils.Logger;

constructor TMT5BridgeProvider.Create(const AHost: string; const APort: Integer);
begin
  inherited Create;
  FHost := AHost; FPort := APort;
  FLock := TCriticalSection.Create;
  FResponseEvent := TEvent.Create(nil, True, False, '');
  FBlockLines := TStringList.Create;
  FDiagnostics := TStringList.Create;
  FServer := TIdTCPServer.Create(nil);
  FServer.DefaultPort := FPort;
  FServer.OnExecute := ServerExecute;
end;

destructor TMT5BridgeProvider.Destroy;
begin
  Disconnect;
  FServer.Free; FDiagnostics.Free; FBlockLines.Free; FResponseEvent.Free; FLock.Free;
  inherited;
end;

procedure TMT5BridgeProvider.AddDiagnostic(const AText: string);
begin
  FLock.Acquire;
  try
    FDiagnostics.Add(FormatDateTime('hh:nn:ss.zzz', Now) + '  ' + AText);
    while FDiagnostics.Count > 500 do
      FDiagnostics.Delete(0);
  finally
    FLock.Release;
  end;
  TAppLogger.Write(AText);
end;

procedure TMT5BridgeProvider.DrainDiagnostics(const ADestination: TStrings);
begin
  if not Assigned(ADestination) then Exit;
  FLock.Acquire;
  try
    ADestination.AddStrings(FDiagnostics);
    FDiagnostics.Clear;
  finally
    FLock.Release;
  end;
end;

function TMT5BridgeProvider.Connect(const ALogin, APassword, AServer: string): Boolean;
begin
  if FServer.Active then Exit(True);
  try
    FServer.Bindings.Clear;
    with FServer.Bindings.Add do begin IP := FHost; Port := FPort; end;
    FServer.Active := True;
    AddDiagnostic(Format('SERVER LISTEN %s:%d', [FHost, FPort]));
    Result := True;
  except
    on E: Exception do begin AddDiagnostic('SERVER ERROR ' + E.Message); Result := False; end;
  end;
end;

procedure TMT5BridgeProvider.Disconnect;
begin
  FLock.Acquire;
  try
    if Assigned(FClientContext) then FClientContext.Connection.Disconnect;
    FClientContext := nil; FBridgeConnected := False;
    FCurrentBlock := ''; FBlockLines.Clear;
  finally FLock.Release; end;
  if FServer.Active then FServer.Active := False;
end;

function TMT5BridgeProvider.IsConnected: Boolean;
begin Result := FServer.Active; end;

function TMT5BridgeProvider.IsDataAvailable: Boolean;
begin
  FLock.Acquire;
  try Result := FBridgeConnected and Assigned(FClientContext) and FClientContext.Connection.Connected;
  finally FLock.Release; end;
end;

function TMT5BridgeProvider.ProviderName: string;
begin Result := 'MT5 Bridge text protocol'; end;

function TMT5BridgeProvider.StatusText: string;
begin
  if not FServer.Active then Exit('ROZLACZONO');
  if IsDataAvailable then begin
    Result := 'MT5 POLACZONY';
    if FBroker <> '' then Result := Result + ' - ' + FBroker;
    if FAccountLogin <> '' then Result := Result + ' [' + FAccountLogin + ']';
  end else Result := Format('OCZEKIWANIE NA BRIDGE (%s:%d)', [FHost, FPort]);
end;

procedure TMT5BridgeProvider.SetClientContext(AContext: TIdContext);
var
  IsNewClient: Boolean;
begin
  IsNewClient := False;
  FLock.Acquire;
  try
    if Assigned(FClientContext) and (FClientContext <> AContext) then
      FClientContext.Connection.Disconnect;
    IsNewClient := FClientContext <> AContext;
    FClientContext := AContext;
  finally
    FLock.Release;
  end;
  if IsNewClient then
    AddDiagnostic('CLIENT CONNECTED TCP');
end;

procedure TMT5BridgeProvider.ClearClientContext(AContext: TIdContext);
begin
  FLock.Acquire;
  try
    if FClientContext = AContext then begin FClientContext := nil; FBridgeConnected := False; end;
  finally FLock.Release; end;
end;

procedure TMT5BridgeProvider.ServerExecute(AContext: TIdContext);
var S: string;
begin
  SetClientContext(AContext);
  AContext.Connection.IOHandler.DefStringEncoding := IndyTextEncoding_UTF8;
  AContext.Connection.IOHandler.ReadTimeout := 1000;
  try
    try
      S := AContext.Connection.IOHandler.ReadLn;
      ProcessLine(AContext, S);
    except on E: EIdReadTimeout do Exit; end;
  except
    on E: Exception do begin AddDiagnostic('CLIENT CLOSED ' + E.Message); ClearClientContext(AContext); AContext.Connection.Disconnect; end;
  end;
end;

procedure TMT5BridgeProvider.ProcessLine(AContext: TIdContext; const ALine: string);
var S: string;
begin
  S := Trim(ALine);
  if S = '' then Exit;

  if S.StartsWith('CANDLE|', True) or S.StartsWith('POSITION|', True) or
     S.StartsWith('ENTRY|', True) then
    TAppLogger.Write('RX ' + S)
  else
    AddDiagnostic('RX ' + S);

  if FCurrentBlock = '' then begin
    if SameText(S, 'HELLO') or SameText(S, 'SYMBOLS') or SameText(S, 'CANDLES') or SameText(S, 'POSITIONS') or SameText(S, 'ENTRIES') or
       SameText(S, 'ACTION') or SameText(S, 'ACCOUNT') or
       SameText(S, 'ERROR') then begin
      FCurrentBlock := UpperCase(S); FBlockLines.Clear; Exit;
    end;
    if SameText(S, 'PONG') then StoreResponse('PONG');
    Exit;
  end;
  if SameText(S, 'END') then begin FinishBlock(AContext); Exit; end;
  FBlockLines.Add(S);
end;

procedure TMT5BridgeProvider.FinishBlock(AContext: TIdContext);
var Text, Kind: string;
begin
  Kind := FCurrentBlock;
  Text := Kind + sLineBreak + FBlockLines.Text;
  FCurrentBlock := ''; FBlockLines.Clear;
  if Kind = 'HELLO' then begin
    ProcessHelloBlock(Text);
    AContext.Connection.IOHandler.WriteLn('HELLO_ACK', IndyTextEncoding_UTF8);
    AddDiagnostic('TX HELLO_ACK');
  end else StoreResponse(Text);
end;

procedure TMT5BridgeProvider.ProcessHelloBlock(const AText: string);
var L: TStringList; I, P: Integer; K, V: string;
begin
  L := TStringList.Create;
  try
    L.Text := AText;
    for I := 0 to L.Count - 1 do begin
      P := Pos('=', L[I]); if P <= 0 then Continue;
      K := UpperCase(Copy(L[I], 1, P - 1)); V := Copy(L[I], P + 1, MaxInt);
      if K = 'BROKER' then FBroker := V else if K = 'SERVER' then FAccountServer := V else if K = 'LOGIN' then FAccountLogin := V;
    end;
    FLock.Acquire; try FBridgeConnected := True; finally FLock.Release; end;
    AddDiagnostic(Format('HELLO broker=%s server=%s login=%s', [FBroker, FAccountServer, FAccountLogin]));
  finally L.Free; end;
end;

procedure TMT5BridgeProvider.StoreResponse(const AText: string);
begin
  FLock.Acquire;
  try FLastResponse := AText; FResponseEvent.SetEvent;
  finally FLock.Release; end;
end;

function TMT5BridgeProvider.SendCommandAndWait(const ACommand: string; out AResponse: string; const ATimeoutMs: Cardinal): Boolean;
var C: TIdContext;
begin
  Result := False; AResponse := '';
  FLock.Acquire;
  try
    C := FClientContext; FLastResponse := ''; FResponseEvent.ResetEvent;
    if not Assigned(C) or not C.Connection.Connected then Exit;
    C.Connection.IOHandler.WriteLn(ACommand, IndyTextEncoding_UTF8);
    AddDiagnostic('TX ' + ACommand);
  finally FLock.Release; end;
  if FResponseEvent.WaitFor(ATimeoutMs) <> wrSignaled then
  begin
    AddDiagnostic(Format('TIMEOUT %s after %d ms', [ACommand, ATimeoutMs]));
    Exit;
  end;
  FLock.Acquire;
  try AResponse := FLastResponse; Result := AResponse <> '';
  finally FLock.Release; end;
end;

function TMT5BridgeProvider.ParseSymbols(const AText: string): TStringList;
var
  L: TStringList;
  I: Integer;
  SymbolName: string;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;

  L := TStringList.Create;
  try
    L.Text := AText;
    for I := 0 to L.Count - 1 do
      if L[I].StartsWith('SYMBOL|', True) then
      begin
        SymbolName := Trim(Copy(L[I], Length('SYMBOL|') + 1, MaxInt));
        if SymbolName <> '' then
          Result.Add(SymbolName);
      end;
  finally
    L.Free;
  end;
end;

function TMT5BridgeProvider.LoadSymbols: TStringList;
var
  R: string;
begin
  if not IsDataAvailable then
    Exit(TStringList.Create);

  if not SendCommandAndWait('GET_SYMBOLS', R, 10000) then
    raise Exception.Create('Brak odpowiedzi GET_SYMBOLS.');

  if R.StartsWith('ERROR') then
    raise Exception.Create(R);

  Result := ParseSymbols(R);
  AddDiagnostic(Format('PARSED SYMBOLS count=%d', [Result.Count]));
end;

function TMT5BridgeProvider.ParseCandles(const AText: string): TCandleList;
var L, P: TStringList; I: Integer; C: TCandle; U: Int64; FS: TFormatSettings;
begin
  Result := TCandleList.Create; FS := TFormatSettings.Invariant;
  L := TStringList.Create; P := TStringList.Create;
  try
    L.Text := AText; P.StrictDelimiter := True; P.Delimiter := '|';
    for I := 0 to L.Count - 1 do begin
      if not L[I].StartsWith('CANDLE|', True) then Continue;
      P.DelimitedText := L[I]; if P.Count < 7 then Continue;
      if not TryStrToInt64(P[1], U) then Continue;
      C := Default(TCandle);
      C.Time := UnixToDateTime(U, False);
      TryStrToFloat(P[2], C.OpenPrice, FS); TryStrToFloat(P[3], C.HighPrice, FS);
      TryStrToFloat(P[4], C.LowPrice, FS); TryStrToFloat(P[5], C.ClosePrice, FS);
      TryStrToInt64(P[6], C.Volume); Result.Add(C);
    end;
  finally P.Free; L.Free; end;
end;

function TMT5BridgeProvider.LoadCandles(const ASymbol: string; const ATimeFrame: TMarketTimeFrame; const ACount: Integer): TCandleList;
var R: string;
begin
  if not IsDataAvailable then Exit(TCandleList.Create);
  if not SendCommandAndWait(Format('GET_CANDLES|%s|%s|%d', [Trim(ASymbol), TimeFrameToText(ATimeFrame), ACount]), R, 10000) then
    raise Exception.Create('Brak odpowiedzi z MT5 Bridge.');
  if R.StartsWith('ERROR') then raise Exception.Create(R);
  Result := ParseCandles(R);
  AddDiagnostic(Format('PARSED CANDLES symbol=%s tf=%s count=%d',
    [Trim(ASymbol), TimeFrameToText(ATimeFrame), Result.Count]));
end;

function TMT5BridgeProvider.ParsePositions(const AText: string): TOpenPositionList;
var L, P: TStringList; I: Integer; X: TOpenPosition; U: Int64; FS: TFormatSettings;
begin
  Result := TOpenPositionList.Create; FS := TFormatSettings.Invariant;
  L := TStringList.Create; P := TStringList.Create;
  try
    L.Text := AText; P.StrictDelimiter := True; P.Delimiter := '|';
    for I := 0 to L.Count - 1 do begin
      if not L[I].StartsWith('POSITION|', True) then Continue;
      P.DelimitedText := L[I]; if P.Count < 11 then Continue;
      X := Default(TOpenPosition);
      if not TryStrToInt64(P[1], X.Ticket) then Continue;
      X.Symbol := P[2];
      if SameText(P[3], 'BUY') then
        X.Side := psBuy
      else if SameText(P[3], 'SELL') then
        X.Side := psSell
      else
        Continue;
      TryStrToFloat(P[4], X.Volume, FS); if TryStrToInt64(P[5], U) then X.OpenTime := UnixToDateTime(U, False);
      TryStrToFloat(P[6], X.OpenPrice, FS); TryStrToFloat(P[7], X.CurrentPrice, FS);
      TryStrToFloat(P[8], X.StopLoss, FS); TryStrToFloat(P[9], X.TakeProfit, FS);
      TryStrToFloat(P[10], X.Profit, FS); Result.Add(X);
    end;
  finally P.Free; L.Free; end;
end;

function TMT5BridgeProvider.ParseEntries(
  const AText: string): TTradeEntryList;
var
  L, P: TStringList;
  I: Integer;
  X: TTradeEntry;
  U: Int64;
  FS: TFormatSettings;
begin
  Result := TTradeEntryList.Create;
  FS := TFormatSettings.Invariant;
  L := TStringList.Create;
  P := TStringList.Create;
  try
    L.Text := AText;
    P.StrictDelimiter := True;
    P.Delimiter := '|';

    for I := 0 to L.Count - 1 do
    begin
      if not L[I].StartsWith('ENTRY|', True) then
        Continue;

      P.DelimitedText := L[I];
      if P.Count < 7 then
        Continue;

      X := Default(TTradeEntry);
      if not TryStrToInt64(P[1], X.DealTicket) then
        Continue;

      X.Symbol := P[2];
      if SameText(P[3], 'BUY') then
        X.Side := psBuy
      else if SameText(P[3], 'SELL') then
        X.Side := psSell
      else
        Continue;

      TryStrToFloat(P[4], X.Volume, FS);
      if TryStrToInt64(P[5], U) then
        X.EntryTime := UnixToDateTime(U, False);
      TryStrToFloat(P[6], X.Price, FS);

      Result.Add(X);
    end;
  finally
    P.Free;
    L.Free;
  end;
end;

function TMT5BridgeProvider.LoadRecentEntries(
  const AMinutes: Integer): TTradeEntryList;
var
  R: string;
  Minutes: Integer;
begin
  if not IsDataAvailable then
    Exit(TTradeEntryList.Create);

  Minutes := AMinutes;
  if Minutes < 1 then
    Minutes := 1;
  if Minutes > 1440 then
    Minutes := 1440;

  if not SendCommandAndWait(
    Format('GET_ENTRIES|%d', [Minutes]), R, 10000) then
    raise Exception.Create('Brak odpowiedzi GET_ENTRIES.');

  if R.StartsWith('ERROR') then
    raise Exception.Create(R);

  Result := ParseEntries(R);
  AddDiagnostic(Format('PARSED ENTRIES minutes=%d count=%d',
    [Minutes, Result.Count]));
end;

function TMT5BridgeProvider.SupportsTradeActions: Boolean;
begin
  Result := True;
end;

function TMT5BridgeProvider.ExecuteTradeAction(const ACommand: string;
  out AMessage: string): Boolean;
var
  R: string;
  Lines: TStringList;
  I, P: Integer;
  Key, Value: string;
  Success: Boolean;
begin
  Result := False;
  AMessage := '';

  if not IsDataAvailable then
  begin
    AMessage := 'Bridge MT5 nie jest połączony.';
    Exit;
  end;

  if not SendCommandAndWait(ACommand, R, 15000) then
  begin
    AMessage := 'Brak odpowiedzi na akcję zamykania.';
    Exit;
  end;

  if R.StartsWith('ERROR') then
  begin
    AMessage := R;
    Exit;
  end;

  Success := False;
  Lines := TStringList.Create;
  try
    Lines.Text := R;
    for I := 0 to Lines.Count - 1 do
    begin
      P := Pos('=', Lines[I]);
      if P <= 0 then
        Continue;

      Key := UpperCase(Trim(Copy(Lines[I], 1, P - 1)));
      Value := Trim(Copy(Lines[I], P + 1, MaxInt));

      if Key = 'SUCCESS' then
        Success := SameText(Value, '1') or SameText(Value, 'TRUE')
      else if Key = 'MESSAGE' then
        AMessage := Value;
    end;
  finally
    Lines.Free;
  end;

  if AMessage = '' then
  begin
    if Success then
      AMessage := 'Akcja została wykonana.'
    else
      AMessage := 'Akcja nie została wykonana.';
  end;

  Result := Success;
  AddDiagnostic(Format('TRADE ACTION command=%s success=%s message=%s',
    [ACommand, BoolToStr(Result, True), AMessage]));
end;

function TMT5BridgeProvider.ClosePositionsBySide(const ASymbol: string;
  const ASide: TPositionSide; out AMessage: string): Boolean;
begin
  Result := ExecuteTradeAction(
    Format('CLOSE_SIDE|%s|%s',
      [Trim(ASymbol), PositionSideToText(ASide)]), AMessage);
end;

function TMT5BridgeProvider.CloseAllPositions(const ASymbol: string;
  out AMessage: string): Boolean;
begin
  Result := ExecuteTradeAction(
    Format('CLOSE_ALL|%s', [Trim(ASymbol)]), AMessage);
end;

function TMT5BridgeProvider.LoadOpenPositions: TOpenPositionList;
var R: string;
begin
  if not IsDataAvailable then Exit(TOpenPositionList.Create);
  if not SendCommandAndWait('GET_POSITIONS', R, 5000) then raise Exception.Create('Brak odpowiedzi GET_POSITIONS.');
  if R.StartsWith('ERROR') then raise Exception.Create(R);
  Result := ParsePositions(R);
  AddDiagnostic(Format('PARSED POSITIONS count=%d', [Result.Count]));
end;

end.

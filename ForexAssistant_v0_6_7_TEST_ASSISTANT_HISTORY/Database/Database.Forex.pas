unit Database.Forex;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Comp.Client,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.DApt,
  Core.Market.Types,
  Core.Broker.Types;

type
  TForexDatabase = class
  private
    FConnection: TFDConnection;
    FDriverLink: TFDPhysSQLiteDriverLink;
    FDatabaseFile: string;
    procedure ConfigureConnection;
    procedure CreateSchema;
    procedure ExecuteDirect(const ASQL: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Initialize;
    procedure SaveCandles(const ASymbol: string;
      const ATimeFrame: TMarketTimeFrame; const ACandles: TCandleList);
    procedure SaveTradeEntries(const AEntries: TTradeEntryList);
    procedure SaveAssistantSnapshot(const ASymbol, ASuggestion: string;
      const ABuyScore, ASellScore, AConfidence: Integer;
      const ADataQuality: string);
    procedure LoadAssistantHistory(const ASymbol: string;
      const AOutput: TStrings; const ALimit: Integer = 12);
    procedure SetSetting(const AName, AValue: string);
    function GetSetting(const AName, ADefault: string): string;
    function LoadBrokers: TBrokerConfigArray;
    procedure SeedDefaultBrokers;

    property Connection: TFDConnection read FConnection;
    property DatabaseFile: string read FDatabaseFile;
  end;

implementation

uses
  System.IOUtils,
  Utils.Logger;

constructor TForexDatabase.Create;
begin
  inherited Create;
  FDriverLink := TFDPhysSQLiteDriverLink.Create(nil);
  FConnection := TFDConnection.Create(nil);
end;

destructor TForexDatabase.Destroy;
begin
  FConnection.Free;
  FDriverLink.Free;
  inherited Destroy;
end;

procedure TForexDatabase.ConfigureConnection;
var
  DataDirectory: string;
  LocalSQLiteDll: string;
begin
  DataDirectory := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Data');
  ForceDirectories(DataDirectory);
  FDatabaseFile := TPath.Combine(DataDirectory, 'ForexAssistant.db');

  // Jeśli sqlite3.dll leży obok EXE, FireDAC użyje właśnie tej biblioteki.
  // W przeciwnym razie zastosuje bibliotekę znalezioną w systemowej ścieżce.
  LocalSQLiteDll := TPath.Combine(ExtractFilePath(ParamStr(0)), 'sqlite3.dll');
  if TFile.Exists(LocalSQLiteDll) then
    FDriverLink.VendorLib := LocalSQLiteDll;

  FConnection.LoginPrompt := False;
  FConnection.Params.Clear;
  FConnection.Params.Values['DriverID'] := 'SQLite';
  FConnection.Params.Values['Database'] := FDatabaseFile;
  FConnection.Params.Values['OpenMode'] := 'CreateUTF8';
  FConnection.Params.Values['LockingMode'] := 'Normal';
  FConnection.Params.Values['Synchronous'] := 'Normal';
  FConnection.Params.Values['BusyTimeout'] := '5000';
  FConnection.ResourceOptions.SilentMode := True;
end;

procedure TForexDatabase.Initialize;
begin
  ConfigureConnection;
  FConnection.Connected := True;
  CreateSchema;
  TAppLogger.WriteFmt('SQLite initialized: %s', [FDatabaseFile]);
end;

procedure TForexDatabase.ExecuteDirect(const ASQL: string);
begin
  FConnection.ExecSQL(ASQL);
end;

procedure TForexDatabase.CreateSchema;
begin
  ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS app_settings (' +
    '  setting_name TEXT NOT NULL PRIMARY KEY,' +
    '  setting_value TEXT,' +
    '  modified_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP' +
    ')');

  ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS candles (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  symbol TEXT NOT NULL,' +
    '  timeframe TEXT NOT NULL,' +
    '  candle_time REAL NOT NULL,' +
    '  open_price REAL NOT NULL,' +
    '  high_price REAL NOT NULL,' +
    '  low_price REAL NOT NULL,' +
    '  close_price REAL NOT NULL,' +
    '  volume INTEGER NOT NULL DEFAULT 0,' +
    '  received_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    '  UNIQUE(symbol, timeframe, candle_time)' +
    ')');

  ExecuteDirect(
    'CREATE INDEX IF NOT EXISTS idx_candles_lookup ' +
    'ON candles(symbol, timeframe, candle_time)');

  ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS signals (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  symbol TEXT NOT NULL,' +
    '  timeframe TEXT NOT NULL,' +
    '  signal_time REAL NOT NULL,' +
    '  direction TEXT NOT NULL,' +
    '  confidence REAL NOT NULL DEFAULT 0,' +
    '  explanation TEXT,' +
    '  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP' +
    ')');

  ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS brokers (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL UNIQUE,' +
    '  platform TEXT NOT NULL DEFAULT ''MT5'',' +
    '  host TEXT NOT NULL DEFAULT ''127.0.0.1'',' +
    '  port INTEGER NOT NULL,' +
    '  enabled INTEGER NOT NULL DEFAULT 1,' +
    '  last_symbol TEXT,' +
    '  last_timeframe TEXT' +
    ')');

  SeedDefaultBrokers;

  ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS assistant_history (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  symbol TEXT NOT NULL,' +
    '  created_at REAL NOT NULL,' +
    '  suggestion TEXT NOT NULL,' +
    '  buy_score INTEGER NOT NULL,' +
    '  sell_score INTEGER NOT NULL,' +
    '  confidence INTEGER NOT NULL,' +
    '  data_quality TEXT NOT NULL' +
    ')');

  ExecuteDirect(
    'CREATE INDEX IF NOT EXISTS idx_assistant_history_symbol_time ' +
    'ON assistant_history(symbol, created_at DESC)');

  ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS session_timeline (' +
    '  deal_ticket INTEGER NOT NULL PRIMARY KEY,' +
    '  symbol TEXT NOT NULL,' +
    '  side TEXT NOT NULL,' +
    '  volume REAL NOT NULL,' +
    '  entry_time REAL NOT NULL,' +
    '  entry_price REAL NOT NULL,' +
    '  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP' +
    ')');

  ExecuteDirect(
    'CREATE INDEX IF NOT EXISTS idx_session_timeline_time ' +
    'ON session_timeline(entry_time)');

  ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS trade_journal (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  platform TEXT,' +
    '  account_no TEXT,' +
    '  position_no TEXT,' +
    '  symbol TEXT NOT NULL,' +
    '  side TEXT,' +
    '  volume REAL,' +
    '  open_time REAL,' +
    '  open_price REAL,' +
    '  close_time REAL,' +
    '  close_price REAL,' +
    '  profit REAL,' +
    '  trade_tag TEXT,' +
    '  notes TEXT,' +
    '  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP' +
    ')');
end;

procedure TForexDatabase.SaveCandles(const ASymbol: string;
  const ATimeFrame: TMarketTimeFrame; const ACandles: TCandleList);
var
  Query: TFDQuery;
  Candle: TCandle;
begin
  if (not FConnection.Connected) or (ACandles = nil) or
     (ACandles.Count = 0) then
    Exit;

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text :=
      'INSERT OR REPLACE INTO candles (' +
      'symbol, timeframe, candle_time, open_price, high_price, ' +
      'low_price, close_price, volume, received_at) ' +
      'VALUES (:symbol, :timeframe, :candle_time, :open_price, ' +
      ':high_price, :low_price, :close_price, :volume, CURRENT_TIMESTAMP)';

    FConnection.StartTransaction;
    try
      for Candle in ACandles do
      begin
        Query.ParamByName('symbol').AsString := UpperCase(Trim(ASymbol));
        Query.ParamByName('timeframe').AsString := TimeFrameToText(ATimeFrame);
        Query.ParamByName('candle_time').AsFloat := Candle.Time;
        Query.ParamByName('open_price').AsFloat := Candle.OpenPrice;
        Query.ParamByName('high_price').AsFloat := Candle.HighPrice;
        Query.ParamByName('low_price').AsFloat := Candle.LowPrice;
        Query.ParamByName('close_price').AsFloat := Candle.ClosePrice;
        Query.ParamByName('volume').AsLargeInt := Candle.Volume;
        Query.ExecSQL;
      end;
      FConnection.Commit;
    except
      FConnection.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure TForexDatabase.SaveTradeEntries(
  const AEntries: TTradeEntryList);
var
  Q: TFDQuery;
  E: TTradeEntry;
begin
  if not FConnection.Connected or not Assigned(AEntries) then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'INSERT OR IGNORE INTO session_timeline (' +
      'deal_ticket, symbol, side, volume, entry_time, entry_price) ' +
      'VALUES (:deal_ticket, :symbol, :side, :volume, :entry_time, :entry_price)';

    FConnection.StartTransaction;
    try
      for E in AEntries do
      begin
        Q.ParamByName('deal_ticket').AsLargeInt := E.DealTicket;
        Q.ParamByName('symbol').AsString := E.Symbol;
        Q.ParamByName('side').AsString := PositionSideToText(E.Side);
        Q.ParamByName('volume').AsFloat := E.Volume;
        Q.ParamByName('entry_time').AsFloat := E.EntryTime;
        Q.ParamByName('entry_price').AsFloat := E.Price;
        Q.ExecSQL;
      end;
      FConnection.Commit;
    except
      FConnection.Rollback;
      raise;
    end;
  finally
    Q.Free;
  end;
end;

procedure TForexDatabase.SaveAssistantSnapshot(
  const ASymbol, ASuggestion: string;
  const ABuyScore, ASellScore, AConfidence: Integer;
  const ADataQuality: string);
var
  Q: TFDQuery;
  LastSuggestion: string;
  LastBuy, LastSell: Integer;
begin
  if not FConnection.Connected then
    Exit;

  { Nie zapisujemy identycznego wyniku przy każdym odświeżeniu.
    Historia ma pokazywać zmianę, a nie szum timera. }
  LastSuggestion := '';
  LastBuy := -1;
  LastSell := -1;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT suggestion, buy_score, sell_score ' +
      'FROM assistant_history WHERE symbol = :symbol ' +
      'ORDER BY id DESC LIMIT 1';
    Q.ParamByName('symbol').AsString := ASymbol;
    Q.Open;
    if not Q.Eof then
    begin
      LastSuggestion := Q.FieldByName('suggestion').AsString;
      LastBuy := Q.FieldByName('buy_score').AsInteger;
      LastSell := Q.FieldByName('sell_score').AsInteger;
    end;
    Q.Close;

    if SameText(LastSuggestion, ASuggestion) and
       (Abs(LastBuy - ABuyScore) < 5) and
       (Abs(LastSell - ASellScore) < 5) then
      Exit;

    Q.SQL.Text :=
      'INSERT INTO assistant_history (' +
      'symbol, created_at, suggestion, buy_score, sell_score, ' +
      'confidence, data_quality) VALUES (' +
      ':symbol, :created_at, :suggestion, :buy_score, :sell_score, ' +
      ':confidence, :data_quality)';
    Q.ParamByName('symbol').AsString := ASymbol;
    Q.ParamByName('created_at').AsFloat := Now;
    Q.ParamByName('suggestion').AsString := ASuggestion;
    Q.ParamByName('buy_score').AsInteger := ABuyScore;
    Q.ParamByName('sell_score').AsInteger := ASellScore;
    Q.ParamByName('confidence').AsInteger := AConfidence;
    Q.ParamByName('data_quality').AsString := ADataQuality;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TForexDatabase.LoadAssistantHistory(
  const ASymbol: string; const AOutput: TStrings;
  const ALimit: Integer);
var
  Q: TFDQuery;
  LimitValue: Integer;
begin
  if not Assigned(AOutput) then
    Exit;

  AOutput.BeginUpdate;
  try
    AOutput.Clear;

    if not FConnection.Connected then
    begin
      AOutput.Add('Baza danych nie jest połączona.');
      Exit;
    end;

    LimitValue := ALimit;
    if LimitValue < 1 then
      LimitValue := 1;
    if LimitValue > 100 then
      LimitValue := 100;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'SELECT created_at, suggestion, buy_score, sell_score, ' +
        'confidence, data_quality FROM assistant_history ' +
        'WHERE symbol = :symbol ORDER BY id DESC LIMIT ' +
        IntToStr(LimitValue);
      Q.ParamByName('symbol').AsString := ASymbol;
      Q.Open;

      while not Q.Eof do
      begin
        AOutput.Add(
          Format('%s  %s  B:%d S:%d  C:%d%%  %s',
            [FormatDateTime('hh:nn:ss',
               Q.FieldByName('created_at').AsFloat),
             Q.FieldByName('suggestion').AsString,
             Q.FieldByName('buy_score').AsInteger,
             Q.FieldByName('sell_score').AsInteger,
             Q.FieldByName('confidence').AsInteger,
             Q.FieldByName('data_quality').AsString]));
        Q.Next;
      end;

      if AOutput.Count = 0 then
        AOutput.Add('Brak zapisanych zmian sugestii dla symbolu.');
    finally
      Q.Free;
    end;
  finally
    AOutput.EndUpdate;
  end;
end;

procedure TForexDatabase.SetSetting(const AName, AValue: string);
begin
  FConnection.ExecSQL(
    'INSERT OR REPLACE INTO app_settings ' +
    '(setting_name, setting_value, modified_at) ' +
    'VALUES (:name, :value, CURRENT_TIMESTAMP)',
    [AName, AValue]);
end;

function TForexDatabase.GetSetting(const AName, ADefault: string): string;
var
  Query: TFDQuery;
begin
  Result := ADefault;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text :=
      'SELECT setting_value FROM app_settings WHERE setting_name = :name';
    Query.ParamByName('name').AsString := AName;
    Query.Open;
    if not Query.Eof then
      Result := Query.Fields[0].AsString;
  finally
    Query.Free;
  end;
end;

procedure TForexDatabase.SeedDefaultBrokers;
begin
  FConnection.ExecSQL(
    'INSERT OR IGNORE INTO brokers(name, platform, host, port, enabled, last_symbol, last_timeframe) ' +
    'VALUES (''XM'', ''MT5'', ''127.0.0.1'', 5555, 1, ''GOLD#'', ''M15'')');
  FConnection.ExecSQL(
    'INSERT OR IGNORE INTO brokers(name, platform, host, port, enabled, last_symbol, last_timeframe) ' +
    'VALUES (''IC Trading'', ''MT5'', ''127.0.0.1'', 5556, 1, ''XAUUSD'', ''M15'')');
  FConnection.ExecSQL(
    'INSERT OR IGNORE INTO brokers(name, platform, host, port, enabled, last_symbol, last_timeframe) ' +
    'VALUES (''Fusion Markets'', ''MT5'', ''127.0.0.1'', 5557, 1, ''XAUUSD'', ''M15'')');
end;

function TForexDatabase.LoadBrokers: TBrokerConfigArray;
var
  Q: TFDQuery;
  I: Integer;
begin
  SetLength(Result, 0);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text :=
      'SELECT id, name, platform, host, port, enabled, last_symbol, last_timeframe ' +
      'FROM brokers WHERE enabled = 1 ORDER BY id';
    Q.Open;
    I := 0;
    while not Q.Eof do
    begin
      SetLength(Result, I + 1);
      Result[I].Id := Q.FieldByName('id').AsInteger;
      Result[I].Name := Q.FieldByName('name').AsString;
      Result[I].Platform := Q.FieldByName('platform').AsString;
      Result[I].Host := Q.FieldByName('host').AsString;
      Result[I].Port := Q.FieldByName('port').AsInteger;
      Result[I].Enabled := Q.FieldByName('enabled').AsInteger <> 0;
      Result[I].LastSymbol := Q.FieldByName('last_symbol').AsString;
      Result[I].LastTimeFrame := Q.FieldByName('last_timeframe').AsString;
      Inc(I);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.

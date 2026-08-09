unit Forms.BridgeInstaller;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Buttons,
  Vcl.Dialogs,
  Core.Broker.Types,
  Utils.MT5Installer;

type
  TfrmBridgeInstaller = class(TForm)
    pnlBottom: TPanel;
    lblTerminal: TLabel;
    cbTerminal: TComboBox;
    lblBroker: TLabel;
    cbBroker: TComboBox;
    lblPort: TLabel;
    edPort: TEdit;
    lblSource: TLabel;
    edSource: TEdit;
    btnScan: TButton;
    btnInstall: TButton;
    btnCompile: TButton;
    btnOpenFolder: TButton;
    btnClose: TButton;
    memInfo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure cbBrokerChange(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnInstallClick(Sender: TObject);
    procedure btnCompileClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FBrokers: TBrokerConfigArray;
    FTerminals: TMT5TerminalInfoArray;
    FLastInstalledFile: string;
    procedure LoadBrokers(const ABrokers: TBrokerConfigArray;
      const ASelectedBroker: Integer);
    procedure ScanTerminals;
    function SelectedTerminal(out ATerminal: TMT5TerminalInfo): Boolean;
    function SelectedPort: Integer;
  public
    class procedure Execute(AOwner: TComponent;
      const ABrokers: TBrokerConfigArray; const ASelectedBroker: Integer);
  end;

implementation

{$R *.dfm}

class procedure TfrmBridgeInstaller.Execute(AOwner: TComponent;
  const ABrokers: TBrokerConfigArray; const ASelectedBroker: Integer);
var
  Form: TfrmBridgeInstaller;
begin
  Form := TfrmBridgeInstaller.Create(AOwner);
  try
    Form.LoadBrokers(ABrokers, ASelectedBroker);
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TfrmBridgeInstaller.FormCreate(Sender: TObject);
begin
  edSource.Text := TMT5BridgeInstaller.FindBridgeSource;
  ScanTerminals;
  memInfo.Lines.Add('');
  memInfo.Lines.Add('Ważne: w MT5 otwórz Tools -> Options -> Experts');
  memInfo.Lines.Add('i dodaj do dozwolonych adresów dokładny adres z portem:');
  memInfo.Lines.Add('127.0.0.1:5555');
end;

procedure TfrmBridgeInstaller.LoadBrokers(const ABrokers: TBrokerConfigArray;
  const ASelectedBroker: Integer);
var
  I: Integer;
begin
  FBrokers := System.Copy(ABrokers, 0, Length(ABrokers));
  cbBroker.Items.BeginUpdate;
  try
    cbBroker.Items.Clear;
    for I := 0 to High(FBrokers) do
      cbBroker.Items.Add(Format('%s  [%s:%d]',
        [FBrokers[I].Name, FBrokers[I].Host, FBrokers[I].Port]));
  finally
    cbBroker.Items.EndUpdate;
  end;
  if (ASelectedBroker >= 0) and (ASelectedBroker < cbBroker.Items.Count) then
    cbBroker.ItemIndex := ASelectedBroker
  else if cbBroker.Items.Count > 0 then
    cbBroker.ItemIndex := 0;
  cbBrokerChange(nil);
end;

procedure TfrmBridgeInstaller.ScanTerminals;
var
  I: Integer;
begin
  FTerminals := TMT5BridgeInstaller.FindTerminals;
  cbTerminal.Items.BeginUpdate;
  try
    cbTerminal.Items.Clear;
    for I := 0 to High(FTerminals) do
      cbTerminal.Items.Add(FTerminals[I].DisplayName);
  finally
    cbTerminal.Items.EndUpdate;
  end;
  if cbTerminal.Items.Count > 0 then
    cbTerminal.ItemIndex := 0;
  memInfo.Lines.Add(Format('Znaleziono terminali MT5: %d',
    [Length(FTerminals)]));
end;

function TfrmBridgeInstaller.SelectedTerminal(
  out ATerminal: TMT5TerminalInfo): Boolean;
begin
  Result := (cbTerminal.ItemIndex >= 0) and
    (cbTerminal.ItemIndex <= High(FTerminals));
  if Result then
    ATerminal := FTerminals[cbTerminal.ItemIndex];
end;

function TfrmBridgeInstaller.SelectedPort: Integer;
begin
  if not TryStrToInt(Trim(edPort.Text), Result) or
     (Result < 1) or (Result > 65535) then
    raise Exception.Create('Nieprawidłowy port. Dozwolony zakres: 1..65535.');
end;

procedure TfrmBridgeInstaller.cbBrokerChange(Sender: TObject);
begin
  if (cbBroker.ItemIndex >= 0) and
     (cbBroker.ItemIndex <= High(FBrokers)) then
    edPort.Text := IntToStr(FBrokers[cbBroker.ItemIndex].Port);
end;

procedure TfrmBridgeInstaller.btnScanClick(Sender: TObject);
begin
  ScanTerminals;
end;

procedure TfrmBridgeInstaller.btnInstallClick(Sender: TObject);
var
  Terminal: TMT5TerminalInfo;
  Destination: string;
  Port: Integer;
begin
  try
    if not SelectedTerminal(Terminal) then
      raise Exception.Create('Nie wybrano terminala MT5.');
    if Trim(edSource.Text) = '' then
      raise Exception.Create('Nie znaleziono źródłowego pliku ForexAssistantBridge.mq5.');
    Port := SelectedPort;
    if TMT5BridgeInstaller.InstallBridge(Terminal, edSource.Text, Port,
      Destination) then
    begin
      FLastInstalledFile := Destination;
      memInfo.Lines.Add('Zainstalowano: ' + Destination);
      memInfo.Lines.Add(Format('Domyślny port Bridge: %d', [Port]));
      MessageDlg('Bridge został skopiowany.' + sLineBreak + Destination +
        sLineBreak + sLineBreak +
        'Teraz kliknij "Kompiluj" albo otwórz MetaEditor klawiszem F4.' +
        sLineBreak + sLineBreak +
        'Następnie w MT5: Tools -> Options -> Experts' + sLineBreak +
        'dodaj: 127.0.0.1:' + IntToStr(Port),
        mtInformation, [mbOK], 0);
    end;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmBridgeInstaller.btnCompileClick(Sender: TObject);
var
  Terminal: TMT5TerminalInfo;
  MessageText, BridgeFile: string;
begin
  if not SelectedTerminal(Terminal) then
  begin
    MessageDlg('Nie wybrano terminala MT5.', mtError, [mbOK], 0);
    Exit;
  end;
  BridgeFile := FLastInstalledFile;
  if BridgeFile = '' then
    BridgeFile := IncludeTrailingPathDelimiter(Terminal.MQL5Path) +
      'Experts\ForexAssistant\ForexAssistantBridge.mq5';
  if TMT5BridgeInstaller.CompileBridge(Terminal, BridgeFile, MessageText) then
    memInfo.Lines.Add(MessageText)
  else
    MessageDlg(MessageText, mtWarning, [mbOK], 0);
end;

procedure TfrmBridgeInstaller.btnOpenFolderClick(Sender: TObject);
var
  Terminal: TMT5TerminalInfo;
  Folder: string;
begin
  if not SelectedTerminal(Terminal) then
    Exit;
  Folder := IncludeTrailingPathDelimiter(Terminal.MQL5Path) +
    'Experts\ForexAssistant';
  TMT5BridgeInstaller.OpenFolder(Folder);
end;

procedure TfrmBridgeInstaller.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.

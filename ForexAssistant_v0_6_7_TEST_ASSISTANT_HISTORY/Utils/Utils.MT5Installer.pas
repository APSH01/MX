unit Utils.MT5Installer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Generics.Collections;

type
  TMT5TerminalInfo = record
    DataPath: string;
    MQL5Path: string;
    OriginPath: string;
    DisplayName: string;
  end;

  TMT5TerminalInfoArray = TArray<TMT5TerminalInfo>;

  TMT5BridgeInstaller = class
  private
    class function ReadFirstLine(const AFileName: string): string; static;
    class function NormalizePath(const APath: string): string; static;
  public
    class function FindTerminals: TMT5TerminalInfoArray; static;
    class function FindBridgeSource: string; static;
    class function InstallBridge(const ATerminal: TMT5TerminalInfo;
      const ASourceFile: string; const APort: Integer;
      out ADestinationFile: string): Boolean; static;
    class function FindMetaEditor(const ATerminal: TMT5TerminalInfo): string; static;
    class function CompileBridge(const ATerminal: TMT5TerminalInfo;
      const ABridgeFile: string; out AMessage: string): Boolean; static;
    class procedure OpenFolder(const AFolder: string); static;
  end;

implementation

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.IOUtils,
  System.StrUtils;

class function TMT5BridgeInstaller.NormalizePath(const APath: string): string;
begin
  Result := Trim(APath);
  if (Length(Result) >= 2) and (Result[1] = '"') and
     (Result[Length(Result)] = '"') then
    Result := Copy(Result, 2, Length(Result) - 2);
  while Result.EndsWith(PathDelim) do
    Delete(Result, Length(Result), 1);
end;

class function TMT5BridgeInstaller.ReadFirstLine(
  const AFileName: string): string;
var
  Lines: TStringList;
begin
  Result := '';
  if not FileExists(AFileName) then
    Exit;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFileName, TEncoding.UTF8);
    except
      Lines.LoadFromFile(AFileName);
    end;
    if Lines.Count > 0 then
      Result := NormalizePath(Lines[0]);
  finally
    Lines.Free;
  end;
end;

class function TMT5BridgeInstaller.FindTerminals: TMT5TerminalInfoArray;
var
  Root, Dir, Origin, Name: string;
  Dirs: TStringDynArray;
  Item: TMT5TerminalInfo;
  List: TList<TMT5TerminalInfo>;
begin
  Root := TPath.Combine(GetEnvironmentVariable('APPDATA'), 'MetaQuotes\Terminal');
  List := TList<TMT5TerminalInfo>.Create;
  try
    if not TDirectory.Exists(Root) then
      Exit(nil);

    Dirs := TDirectory.GetDirectories(Root);
    for Dir in Dirs do
    begin
      if not TDirectory.Exists(TPath.Combine(Dir, 'MQL5')) then
        Continue;

      Origin := ReadFirstLine(TPath.Combine(Dir, 'origin.txt'));
      if Origin <> '' then
        Name := ExtractFileName(Origin)
      else
        Name := ExtractFileName(Dir);

      Item.DataPath := Dir;
      Item.MQL5Path := TPath.Combine(Dir, 'MQL5');
      Item.OriginPath := Origin;
      Item.DisplayName := Format('%s  [%s]', [Name, ExtractFileName(Dir)]);
      List.Add(Item);
    end;
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

class function TMT5BridgeInstaller.FindBridgeSource: string;
var
  Base, Candidate: string;
  I: Integer;
begin
  Result := '';
  Base := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  for I := 0 to 6 do
  begin
    Candidate := TPath.Combine(TPath.Combine(Base, 'BridgeMT5'),
      'ForexAssistantBridge.mq5');
    if TFile.Exists(Candidate) then
      Exit(Candidate);
    Base := ExtractFileDir(Base);
    if Base = '' then
      Break;
  end;
end;

class function TMT5BridgeInstaller.InstallBridge(
  const ATerminal: TMT5TerminalInfo; const ASourceFile: string;
  const APort: Integer; out ADestinationFile: string): Boolean;
var
  TargetDir, SourceText, PortLine: string;
begin
  Result := False;
  ADestinationFile := '';
  if not TFile.Exists(ASourceFile) then
    raise Exception.CreateFmt('Nie znaleziono pliku Bridge: %s', [ASourceFile]);
  if not TDirectory.Exists(ATerminal.MQL5Path) then
    raise Exception.CreateFmt('Nie znaleziono katalogu MQL5: %s',
      [ATerminal.MQL5Path]);
  if (APort < 1) or (APort > 65535) then
    raise Exception.Create('Port musi być z zakresu 1..65535.');

  TargetDir := TPath.Combine(
    TPath.Combine(ATerminal.MQL5Path, 'Experts'), 'ForexAssistant');
  TDirectory.CreateDirectory(TargetDir);
  ADestinationFile := TPath.Combine(TargetDir, 'ForexAssistantBridge.mq5');

  SourceText := TFile.ReadAllText(ASourceFile, TEncoding.UTF8);
  PortLine := Format('input int    BridgePort = %d;', [APort]);
  SourceText := StringReplace(SourceText,
    'input int    BridgePort = 5555;', PortLine, []);
  SourceText := StringReplace(SourceText,
    '#property version   "0.40"', '#property version   "0.40"', []);
  TFile.WriteAllText(ADestinationFile, SourceText, TEncoding.UTF8);
  Result := TFile.Exists(ADestinationFile);
end;

class function TMT5BridgeInstaller.FindMetaEditor(
  const ATerminal: TMT5TerminalInfo): string;
var
  Candidate, Parent: string;
begin
  Result := '';
  if ATerminal.OriginPath = '' then
    Exit;

  Candidate := TPath.Combine(ATerminal.OriginPath, 'metaeditor64.exe');
  if TFile.Exists(Candidate) then
    Exit(Candidate);
  Candidate := TPath.Combine(ATerminal.OriginPath, 'metaeditor.exe');
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  Parent := ExtractFileDir(ATerminal.OriginPath);
  Candidate := TPath.Combine(Parent, 'metaeditor64.exe');
  if TFile.Exists(Candidate) then
    Exit(Candidate);
end;

class function TMT5BridgeInstaller.CompileBridge(
  const ATerminal: TMT5TerminalInfo; const ABridgeFile: string;
  out AMessage: string): Boolean;
var
  MetaEditor, Params: string;
  Code: HINST;
begin
  Result := False;
  AMessage := '';
  if not TFile.Exists(ABridgeFile) then
  begin
    AMessage := 'Najpierw zainstaluj plik Bridge.';
    Exit;
  end;

  MetaEditor := FindMetaEditor(ATerminal);
  if MetaEditor = '' then
  begin
    AMessage := 'Nie znaleziono metaeditor64.exe. Otwórz MT5, naciśnij F4 i skompiluj plik ręcznie.';
    Exit;
  end;

  Params := Format('/compile:"%s"', [ABridgeFile]);
  Code := ShellExecute(0, 'open', PChar(MetaEditor), PChar(Params),
    PChar(ExtractFileDir(MetaEditor)), SW_SHOWNORMAL);
  Result := Code > 32;
  if Result then
    AMessage := 'Uruchomiono MetaEditor z poleceniem kompilacji.'
  else
    AMessage := Format('Nie udało się uruchomić MetaEditora. Kod: %d',
      [NativeInt(Code)]);
end;

class procedure TMT5BridgeInstaller.OpenFolder(const AFolder: string);
begin
  if TDirectory.Exists(AFolder) then
    ShellExecute(0, 'open', PChar(AFolder), nil, nil, SW_SHOWNORMAL);
end;

end.

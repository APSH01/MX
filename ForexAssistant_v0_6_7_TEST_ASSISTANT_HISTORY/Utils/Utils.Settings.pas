unit Utils.Settings;

interface

uses
  System.SysUtils,
  System.IniFiles;

type
  TLoginSettings = record
    Platform: string;
    Broker: string;
    Login: string;
    Password: string;
    Server: string;
    Remember: Boolean;
  end;

  TWindowLayoutSettings = record
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
    Maximized: Boolean;
    MonitorWidth: Integer;
    RightPanelWidth: Integer;
    AssistantPanelWidth: Integer;
    MonitorVisible: Boolean;
  end;

  TAppSettings = class
  private
    class function IniFileName: string; static;
  public
    class procedure LoadLogin(out ASettings: TLoginSettings); static;
    class procedure SaveLogin(const ASettings: TLoginSettings); static;
    class procedure ClearLogin; static;
    class function LoadLastSymbol(const ADefault: string): string; static;
    class function LoadLastTimeFrame(const ADefault: string): string; static;
    class procedure SaveMarketSelection(const ASymbol, ATimeFrame: string); static;
    class procedure LoadWindowLayout(out ASettings: TWindowLayoutSettings); static;
    class procedure SaveWindowLayout(const ASettings: TWindowLayoutSettings); static;
  end;

implementation

class function TAppSettings.IniFileName: string;
begin
  Result := ChangeFileExt(ParamStr(0), '.ini');
end;

class procedure TAppSettings.LoadLogin(out ASettings: TLoginSettings);
var
  Ini: TIniFile;
begin
  ASettings.Platform := 'MT5';
  ASettings.Broker := 'IC Trading';
  ASettings.Login := '';
  ASettings.Password := '';
  ASettings.Server := '';
  ASettings.Remember := False;

  Ini := TIniFile.Create(IniFileName);
  try
    ASettings.Remember := Ini.ReadBool('Login', 'Remember', False);
    ASettings.Platform := Ini.ReadString('Login', 'Platform', ASettings.Platform);
    ASettings.Broker := Ini.ReadString('Login', 'Broker', ASettings.Broker);
    ASettings.Server := Ini.ReadString('Login', 'Server', '');
    if ASettings.Remember then
    begin
      ASettings.Login := Ini.ReadString('Login', 'User', '');
      ASettings.Password := Ini.ReadString('Login', 'Password', '');
    end;
  finally
    Ini.Free;
  end;
end;

class procedure TAppSettings.SaveLogin(const ASettings: TLoginSettings);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Ini.WriteBool('Login', 'Remember', ASettings.Remember);
    Ini.WriteString('Login', 'Platform', ASettings.Platform);
    Ini.WriteString('Login', 'Broker', ASettings.Broker);
    Ini.WriteString('Login', 'Server', ASettings.Server);
    if ASettings.Remember then
    begin
      Ini.WriteString('Login', 'User', ASettings.Login);
      Ini.WriteString('Login', 'Password', ASettings.Password);
    end
    else
    begin
      Ini.DeleteKey('Login', 'User');
      Ini.DeleteKey('Login', 'Password');
    end;
  finally
    Ini.Free;
  end;
end;

class procedure TAppSettings.ClearLogin;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Ini.EraseSection('Login');
  finally
    Ini.Free;
  end;
end;

class function TAppSettings.LoadLastSymbol(const ADefault: string): string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Result := Ini.ReadString('Market', 'Symbol', ADefault);
  finally
    Ini.Free;
  end;
end;

class function TAppSettings.LoadLastTimeFrame(const ADefault: string): string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Result := Ini.ReadString('Market', 'TimeFrame', ADefault);
  finally
    Ini.Free;
  end;
end;

class procedure TAppSettings.SaveMarketSelection(const ASymbol,
  ATimeFrame: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Ini.WriteString('Market', 'Symbol', ASymbol);
    Ini.WriteString('Market', 'TimeFrame', ATimeFrame);
  finally
    Ini.Free;
  end;
end;


class procedure TAppSettings.LoadWindowLayout(
  out ASettings: TWindowLayoutSettings);
var
  Ini: TIniFile;
begin
  ASettings.Left := -1;
  ASettings.Top := -1;
  ASettings.Width := 1800;
  ASettings.Height := 1000;
  ASettings.Maximized := False;
  ASettings.MonitorWidth := 300;
  ASettings.RightPanelWidth := 453;
  ASettings.AssistantPanelWidth := 390;
  ASettings.MonitorVisible := False;

  Ini := TIniFile.Create(IniFileName);
  try
    ASettings.Left := Ini.ReadInteger('Window', 'Left', ASettings.Left);
    ASettings.Top := Ini.ReadInteger('Window', 'Top', ASettings.Top);
    ASettings.Width := Ini.ReadInteger('Window', 'Width', ASettings.Width);
    ASettings.Height := Ini.ReadInteger('Window', 'Height', ASettings.Height);
    ASettings.Maximized := Ini.ReadBool('Window', 'Maximized', False);
    ASettings.MonitorWidth := Ini.ReadInteger('Layout', 'MonitorWidth',
      ASettings.MonitorWidth);
    ASettings.RightPanelWidth := Ini.ReadInteger('Layout', 'RightPanelWidth',
      ASettings.RightPanelWidth);
    ASettings.AssistantPanelWidth := Ini.ReadInteger('Layout',
      'AssistantPanelWidth', ASettings.AssistantPanelWidth);
    ASettings.MonitorVisible := Ini.ReadBool('Layout', 'MonitorVisible', False);
  finally
    Ini.Free;
  end;
end;

class procedure TAppSettings.SaveWindowLayout(
  const ASettings: TWindowLayoutSettings);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniFileName);
  try
    Ini.WriteInteger('Window', 'Left', ASettings.Left);
    Ini.WriteInteger('Window', 'Top', ASettings.Top);
    Ini.WriteInteger('Window', 'Width', ASettings.Width);
    Ini.WriteInteger('Window', 'Height', ASettings.Height);
    Ini.WriteBool('Window', 'Maximized', ASettings.Maximized);
    Ini.WriteInteger('Layout', 'MonitorWidth', ASettings.MonitorWidth);
    Ini.WriteInteger('Layout', 'RightPanelWidth', ASettings.RightPanelWidth);
    Ini.WriteInteger('Layout', 'AssistantPanelWidth',
      ASettings.AssistantPanelWidth);
    Ini.WriteBool('Layout', 'MonitorVisible', ASettings.MonitorVisible);
  finally
    Ini.Free;
  end;
end;

end.

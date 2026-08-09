unit Utils.Logger;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.IOUtils;

type
  TAppLogger = class
  strict private
    class var FLock: TCriticalSection;
    class function LogFileName: string; static;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Write(const AMessage: string); static;
    class procedure WriteFmt(const AFormat: string;
      const AArgs: array of const); static;
  end;

implementation

class constructor TAppLogger.Create;
begin
  FLock := TCriticalSection.Create;
end;

class destructor TAppLogger.Destroy;
begin
  FLock.Free;
end;

class function TAppLogger.LogFileName: string;
begin
  Result := ChangeFileExt(ParamStr(0), '.log');
end;

class procedure TAppLogger.Write(const AMessage: string);
var
  Line: string;
begin
  Line := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) +
    '  ' + AMessage + sLineBreak;
  FLock.Acquire;
  try
    TFile.AppendAllText(LogFileName, Line, TEncoding.UTF8);
  finally
    FLock.Release;
  end;
end;

class procedure TAppLogger.WriteFmt(const AFormat: string;
  const AArgs: array of const);
begin
  Write(Format(AFormat, AArgs));
end;

end.

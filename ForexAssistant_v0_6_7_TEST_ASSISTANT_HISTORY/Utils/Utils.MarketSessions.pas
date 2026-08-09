unit Utils.MarketSessions;

interface

uses
  System.SysUtils,
  System.DateUtils;

type
  TMarketSessionState = (mssClosed, mssOpen, mssClosingSoon);

  TMarketSessionInfo = record
    Name: string;
    LocalTimeText: string;
    StateText: string;
    ChangeText: string;
    IndicatorText: string;
    State: TMarketSessionState;
    IsOpen: Boolean;
  end;

  TMarketSessionInfoArray = TArray<TMarketSessionInfo>;

  TMarketSessionCalculator = class
  private
    class function FirstSunday(const AYear, AMonth: Word): TDateTime; static;
    class function SecondSunday(const AYear, AMonth: Word): TDateTime; static;
    class function LastSunday(const AYear, AMonth: Word): TDateTime; static;
    class function IsEuropeDST(const AUtc: TDateTime): Boolean; static;
    class function IsNorthAmericaDST(const AUtc: TDateTime): Boolean; static;
    class function IsSydneyDSTForLocalDate(
      const ALocalDate: TDateTime): Boolean; static;
    class function ZoneOffsetMinutes(const AZone: Integer;
      const AUtcOrLocalDate: TDateTime;
      const ADateIsLocal: Boolean): Integer; static;
    class function FormatRemaining(const AValue: TDateTime): string; static;
    class function BuildSession(const AName: string; const AZone,
      AOpenHour, AOpenMinute, ACloseHour, ACloseMinute: Integer;
      const ANowUtc: TDateTime): TMarketSessionInfo; static;
  public
    class function GetSessions(const ANowUtc: TDateTime):
      TMarketSessionInfoArray; static;
  end;

implementation

const
  ZONE_SYDNEY      = 0;
  ZONE_TOKYO       = 1;
  ZONE_HONG_KONG   = 2;
  ZONE_SINGAPORE   = 3;
  ZONE_MUMBAI      = 4;
  ZONE_DUBAI       = 5;
  ZONE_LONDON      = 6;
  ZONE_CENTRAL_EU  = 7;
  ZONE_NEW_YORK    = 8;
  ZONE_CHICAGO     = 9;

  CLOSING_SOON_MINUTES = 120;

class function TMarketSessionCalculator.FirstSunday(const AYear,
  AMonth: Word): TDateTime;
var
  D: TDateTime;
begin
  D := EncodeDate(AYear, AMonth, 1);
  while DayOfWeek(D) <> 1 do
    D := D + 1;
  Result := D;
end;

class function TMarketSessionCalculator.SecondSunday(const AYear,
  AMonth: Word): TDateTime;
begin
  Result := FirstSunday(AYear, AMonth) + 7;
end;

class function TMarketSessionCalculator.LastSunday(const AYear,
  AMonth: Word): TDateTime;
var
  D: TDateTime;
begin
  D := EndOfAMonth(AYear, AMonth);
  while DayOfWeek(D) <> 1 do
    D := D - 1;
  Result := Trunc(D);
end;

class function TMarketSessionCalculator.IsEuropeDST(
  const AUtc: TDateTime): Boolean;
var
  Y: Word;
  StartUtc, EndUtc: TDateTime;
begin
  Y := YearOf(AUtc);
  StartUtc := LastSunday(Y, 3) + EncodeTime(1, 0, 0, 0);
  EndUtc := LastSunday(Y, 10) + EncodeTime(1, 0, 0, 0);
  Result := (AUtc >= StartUtc) and (AUtc < EndUtc);
end;

class function TMarketSessionCalculator.IsNorthAmericaDST(
  const AUtc: TDateTime): Boolean;
var
  Y: Word;
  StartUtc, EndUtc: TDateTime;
begin
  Y := YearOf(AUtc);
  StartUtc := SecondSunday(Y, 3) + EncodeTime(7, 0, 0, 0);
  EndUtc := FirstSunday(Y, 11) + EncodeTime(6, 0, 0, 0);
  Result := (AUtc >= StartUtc) and (AUtc < EndUtc);
end;

class function TMarketSessionCalculator.IsSydneyDSTForLocalDate(
  const ALocalDate: TDateTime): Boolean;
var
  Y, M, D: Word;
  StartDate, EndDate: TDateTime;
begin
  DecodeDate(ALocalDate, Y, M, D);

  if M in [1, 2, 3] then
    Exit(True);
  if M in [5, 6, 7, 8, 9] then
    Exit(False);
  if M in [11, 12] then
    Exit(True);

  if M = 4 then
  begin
    EndDate := FirstSunday(Y, 4);
    Exit(Trunc(ALocalDate) < EndDate);
  end;

  StartDate := FirstSunday(Y, 10);
  Result := Trunc(ALocalDate) >= StartDate;
end;

class function TMarketSessionCalculator.ZoneOffsetMinutes(
  const AZone: Integer; const AUtcOrLocalDate: TDateTime;
  const ADateIsLocal: Boolean): Integer;
begin
  case AZone of
    ZONE_SYDNEY:
      if IsSydneyDSTForLocalDate(AUtcOrLocalDate) then
        Result := 11 * MinsPerHour
      else
        Result := 10 * MinsPerHour;

    ZONE_TOKYO:
      Result := 9 * MinsPerHour;

    ZONE_HONG_KONG,
    ZONE_SINGAPORE:
      Result := 8 * MinsPerHour;

    ZONE_MUMBAI:
      Result := 5 * MinsPerHour + 30;

    ZONE_DUBAI:
      Result := 4 * MinsPerHour;

    ZONE_LONDON:
      if IsEuropeDST(AUtcOrLocalDate) then
        Result := MinsPerHour
      else
        Result := 0;

    ZONE_CENTRAL_EU:
      if IsEuropeDST(AUtcOrLocalDate) then
        Result := 2 * MinsPerHour
      else
        Result := MinsPerHour;

    ZONE_NEW_YORK:
      if IsNorthAmericaDST(AUtcOrLocalDate) then
        Result := -4 * MinsPerHour
      else
        Result := -5 * MinsPerHour;

    ZONE_CHICAGO:
      if IsNorthAmericaDST(AUtcOrLocalDate) then
        Result := -5 * MinsPerHour
      else
        Result := -6 * MinsPerHour;
  else
    Result := 0;
  end;
end;

class function TMarketSessionCalculator.FormatRemaining(
  const AValue: TDateTime): string;
var
  TotalMinutes, Days, Hours, Minutes: Integer;
begin
  TotalMinutes := Round(AValue * MinsPerDay);
  if TotalMinutes < 0 then
    TotalMinutes := 0;

  Days := TotalMinutes div MinsPerDay;
  Hours := (TotalMinutes mod MinsPerDay) div MinsPerHour;
  Minutes := TotalMinutes mod MinsPerHour;

  if Days > 0 then
    Result := Format('%dd %02d:%02d', [Days, Hours, Minutes])
  else
    Result := Format('%02d:%02d', [Hours, Minutes]);
end;

class function TMarketSessionCalculator.BuildSession(const AName: string;
  const AZone, AOpenHour, AOpenMinute, ACloseHour, ACloseMinute: Integer;
  const ANowUtc: TDateTime): TMarketSessionInfo;
var
  I, OffsetMinutes, CurrentOffsetMinutes: Integer;
  BaseLocalDate, LocalDate: TDateTime;
  CandidateOpenUtc, CandidateCloseUtc: TDateTime;
  CurrentCloseUtc, NextOpenUtc, TimeToClose: TDateTime;
  HasCurrent, HasNext: Boolean;
begin
  Result.Name := AName;
  Result.IsOpen := False;
  Result.State := mssClosed;
  Result.StateText := 'ZAMKNIĘTA';
  Result.IndicatorText := 'CLOSED';
  Result.ChangeText := '';

  CurrentOffsetMinutes := ZoneOffsetMinutes(AZone, ANowUtc, False);
  Result.LocalTimeText := FormatDateTime('hh:nn',
    ANowUtc + CurrentOffsetMinutes / MinsPerDay);

  BaseLocalDate := Trunc(ANowUtc + CurrentOffsetMinutes / MinsPerDay);
  HasCurrent := False;
  HasNext := False;
  CurrentCloseUtc := 0;
  NextOpenUtc := 0;

  for I := -2 to 8 do
  begin
    LocalDate := BaseLocalDate + I;

    { Domyślnie pokazujemy dni robocze lokalnego rynku. }
    if not (DayOfWeek(LocalDate) in [2, 3, 4, 5, 6]) then
      Continue;

    OffsetMinutes := ZoneOffsetMinutes(AZone, LocalDate, True);
    CandidateOpenUtc := LocalDate +
      (AOpenHour * MinsPerHour + AOpenMinute) / MinsPerDay -
      OffsetMinutes / MinsPerDay;
    CandidateCloseUtc := LocalDate +
      (ACloseHour * MinsPerHour + ACloseMinute) / MinsPerDay -
      OffsetMinutes / MinsPerDay;

    if CandidateCloseUtc <= CandidateOpenUtc then
      CandidateCloseUtc := CandidateCloseUtc + 1;

    if (ANowUtc >= CandidateOpenUtc) and (ANowUtc < CandidateCloseUtc) then
    begin
      HasCurrent := True;
      CurrentCloseUtc := CandidateCloseUtc;
      Break;
    end;

    if (CandidateOpenUtc > ANowUtc) and
       ((not HasNext) or (CandidateOpenUtc < NextOpenUtc)) then
    begin
      HasNext := True;
      NextOpenUtc := CandidateOpenUtc;
    end;
  end;

  if HasCurrent then
  begin
    Result.IsOpen := True;
    TimeToClose := CurrentCloseUtc - ANowUtc;
    Result.ChangeText := 'zamknięcie za ' + FormatRemaining(TimeToClose);

    if TimeToClose <= CLOSING_SOON_MINUTES / MinsPerDay then
    begin
      Result.State := mssClosingSoon;
      Result.StateText := 'ZAMKNIĘCIE WKRÓTCE';
      Result.IndicatorText := 'SOON';
    end
    else
    begin
      Result.State := mssOpen;
      Result.StateText := 'OTWARTA';
      Result.IndicatorText := 'OPEN';
    end;
  end
  else if HasNext then
    Result.ChangeText := 'otwarcie za ' + FormatRemaining(NextOpenUtc - ANowUtc)
  else
    Result.ChangeText := 'brak terminu';
end;

class function TMarketSessionCalculator.GetSessions(
  const ANowUtc: TDateTime): TMarketSessionInfoArray;
begin
  SetLength(Result, 14);

  Result[0]  := BuildSession('Sydney',    ZONE_SYDNEY,     8,  0, 17,  0, ANowUtc);
  Result[1]  := BuildSession('Tokyo',     ZONE_TOKYO,      9,  0, 18,  0, ANowUtc);
  Result[2]  := BuildSession('Hong Kong', ZONE_HONG_KONG,  9, 30, 16,  0, ANowUtc);
  Result[3]  := BuildSession('Singapore', ZONE_SINGAPORE,  9,  0, 17,  0, ANowUtc);
  Result[4]  := BuildSession('Mumbai',    ZONE_MUMBAI,     9, 15, 15, 30, ANowUtc);
  Result[5]  := BuildSession('Dubai',     ZONE_DUBAI,     10,  0, 15,  0, ANowUtc);
  Result[6]  := BuildSession('Frankfurt', ZONE_CENTRAL_EU, 8,  0, 17,  0, ANowUtc);
  Result[7]  := BuildSession('London',    ZONE_LONDON,     8,  0, 17,  0, ANowUtc);
  Result[8]  := BuildSession('Paris',     ZONE_CENTRAL_EU, 9,  0, 17, 30, ANowUtc);
  Result[9]  := BuildSession('Zurich',    ZONE_CENTRAL_EU, 9,  0, 17, 30, ANowUtc);
  Result[10] := BuildSession('Warsaw',    ZONE_CENTRAL_EU, 9,  0, 17,  0, ANowUtc);
  Result[11] := BuildSession('New York',  ZONE_NEW_YORK,   8,  0, 17,  0, ANowUtc);
  Result[12] := BuildSession('Chicago',   ZONE_CHICAGO,    8,  0, 17,  0, ANowUtc);
  Result[13] := BuildSession('Toronto',   ZONE_NEW_YORK,   9, 30, 16,  0, ANowUtc);
end;

end.

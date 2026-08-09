unit Core.Trading.Timeline;

interface

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  Core.Market.Types,
  Core.Trading.Behaviour;

type
  TTradingTimelineBuilder = class
  public
    class procedure Build(const AEntries: TTradeEntryList;
      const ABehaviour: TTradingBehaviourResult;
      const AOutput: TStrings); static;
  end;

implementation

class procedure TTradingTimelineBuilder.Build(
  const AEntries: TTradeEntryList;
  const ABehaviour: TTradingBehaviourResult;
  const AOutput: TStrings);
var
  I: Integer;
  E: TTradeEntry;
begin
  if not Assigned(AOutput) then
    Exit;

  AOutput.BeginUpdate;
  try
    AOutput.Clear;

    if not Assigned(AEntries) or (AEntries.Count = 0) then
    begin
      AOutput.Add('Brak wejść z ostatnich 60 minut.');
      Exit;
    end;

    AOutput.Add('Ostatnie wejścia');
    AOutput.Add('');

    for I := 0 to AEntries.Count - 1 do
    begin
      E := AEntries[I];
      AOutput.Add(
        Format('%s  %s %.2f  @ %s',
          [FormatDateTime('hh:nn:ss', E.EntryTime),
           PositionSideToText(E.Side),
           E.Volume,
           FormatFloat('0.00000', E.Price)]));
    end;

    AOutput.Add('');
    AOutput.Add('---');
    AOutput.Add('Stan rytmu: ' + ABehaviour.StateText);
    AOutput.Add(
      Format('10 min: %d wejść, wolumen %.2f',
        [ABehaviour.Entries10Min, ABehaviour.Volume10Min]));

    if ABehaviour.AverageIntervalSeconds > 0 then
      AOutput.Add(
        Format('Średni odstęp: %d s',
          [ABehaviour.AverageIntervalSeconds]));

    AOutput.Add(
      Format('Zmiana tempa: %.1fx', [ABehaviour.RateRatio]));
  finally
    AOutput.EndUpdate;
  end;
end;

end.

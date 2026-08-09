program ForexAssistant;

uses
  Vcl.Forms,
  Forms.Main in 'Forms\Forms.Main.pas' {frmMain},
  Forms.Login in 'Forms\Forms.Login.pas' {frmLogin},
  Forms.BridgeInstaller in 'Forms\Forms.BridgeInstaller.pas' {frmBridgeInstaller},
  Core.Market.Types in 'Core\Core.Market.Types.pas',
  Core.Market.Context in 'Core\Core.Market.Context.pas',
  Core.Market.Assistant in 'Core\Core.Market.Assistant.pas',
  Core.Trading.Behaviour in 'Core\Core.Trading.Behaviour.pas',
  Core.Trading.Basket in 'Core\Core.Trading.Basket.pas',
  Core.Trading.Timeline in 'Core\Core.Trading.Timeline.pas',
  Core.Market.Provider in 'Core\Core.Market.Provider.pas',
  Core.Broker.Types in 'Core\Core.Broker.Types.pas',
  Providers.Mock in 'Providers\Providers.Mock.pas',
  Providers.MT5Bridge in 'Providers\Providers.MT5Bridge.pas',
  Charts.MarketChart in 'Charts\Charts.MarketChart.pas',
  Utils.Settings in 'Utils\Utils.Settings.pas',
  Utils.Logger in 'Utils\Utils.Logger.pas',
  Utils.MarketSessions in 'Utils\Utils.MarketSessions.pas',
  Utils.MT5Installer in 'Utils\Utils.MT5Installer.pas',
  Database.Forex in 'Database\Database.Forex.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

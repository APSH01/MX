unit Forms.Login;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Utils.Settings;

type
  TfrmLogin = class(TForm)
    lblInfo: TLabel;
    lblPlatform: TLabel;
    lblBroker: TLabel;
    lblLogin: TLabel;
    lblPassword: TLabel;
    lblServer: TLabel;
    cbPlatform: TComboBox;
    cbBroker: TComboBox;
    edtLogin: TEdit;
    edtPassword: TEdit;
    edtServer: TEdit;
    chkRemember: TCheckBox;
    btnLogin: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnLoginClick(Sender: TObject);
    procedure cbBrokerChange(Sender: TObject);
  private
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ApplyBrokerDefault;
  public
    function Execute(out ALogin, APassword, AServer: string): Boolean;
  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.dfm}

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  cbPlatform.Items.Add('MT5');
  cbPlatform.Items.Add('cTrader');

  cbBroker.Items.Add('IC Trading');
  cbBroker.Items.Add('XM');
  cbBroker.Items.Add('Fusion Markets');
  cbBroker.Items.Add('Inny');

  LoadSettings;
end;

procedure TfrmLogin.LoadSettings;
var
  S: TLoginSettings;
begin
  TAppSettings.LoadLogin(S);

  cbPlatform.ItemIndex := cbPlatform.Items.IndexOf(S.Platform);
  if cbPlatform.ItemIndex < 0 then
    cbPlatform.ItemIndex := 0;

  cbBroker.ItemIndex := cbBroker.Items.IndexOf(S.Broker);
  if cbBroker.ItemIndex < 0 then
    cbBroker.ItemIndex := 0;

  edtLogin.Text := S.Login;
  edtPassword.Text := S.Password;
  edtServer.Text := S.Server;
  chkRemember.Checked := S.Remember;

  if Trim(edtServer.Text) = '' then
    ApplyBrokerDefault;
end;

procedure TfrmLogin.SaveSettings;
var
  S: TLoginSettings;
begin
  S.Platform := cbPlatform.Text;
  S.Broker := cbBroker.Text;
  S.Login := edtLogin.Text;
  S.Password := edtPassword.Text;
  S.Server := edtServer.Text;
  S.Remember := chkRemember.Checked;
  TAppSettings.SaveLogin(S);
end;

procedure TfrmLogin.ApplyBrokerDefault;
begin
  if SameText(cbBroker.Text, 'IC Trading') then
    edtServer.Text := 'ICTrading-Demo'
  else if SameText(cbBroker.Text, 'XM') then
    edtServer.Text := 'XMGlobal-MT5 Demo'
  else if SameText(cbBroker.Text, 'Fusion Markets') then
    edtServer.Text := 'FusionMarkets-Demo'
  else
    edtServer.Text := '';
end;

procedure TfrmLogin.cbBrokerChange(Sender: TObject);
begin
  ApplyBrokerDefault;
end;

procedure TfrmLogin.btnLoginClick(Sender: TObject);
begin
  if Trim(edtLogin.Text) = '' then
  begin
    edtLogin.SetFocus;
    Exit;
  end;

  if edtPassword.Text = '' then
  begin
    edtPassword.SetFocus;
    Exit;
  end;

  SaveSettings;
  ModalResult := mrOk;
end;

function TfrmLogin.Execute(out ALogin, APassword, AServer: string): Boolean;
begin
  Result := ShowModal = mrOk;
  if Result then
  begin
    ALogin := edtLogin.Text;
    APassword := edtPassword.Text;
    AServer := edtServer.Text;
  end;
end;

end.

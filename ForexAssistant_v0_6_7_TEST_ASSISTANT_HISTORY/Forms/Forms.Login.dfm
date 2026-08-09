object frmLogin: TfrmLogin
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Połączenie z kontem demo'
  ClientHeight = 350
  ClientWidth = 470
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblInfo: TLabel
    Left = 24
    Top = 16
    Width = 420
    Height = 34
    AutoSize = False
    Caption = 'Dane są zapisywane w ForexAssistant.ini. Ta wersja nadal używa danych demonstracyjnych; połączenie z terminalem dodamy przez Bridge.'
    WordWrap = True
  end
  object lblPlatform: TLabel
    Left = 24
    Top = 67
    Width = 50
    Height = 15
    Caption = 'Platforma'
  end
  object lblBroker: TLabel
    Left = 24
    Top = 105
    Width = 36
    Height = 15
    Caption = 'Broker'
  end
  object lblLogin: TLabel
    Left = 24
    Top = 143
    Width = 32
    Height = 15
    Caption = 'Login'
  end
  object lblPassword: TLabel
    Left = 24
    Top = 181
    Width = 31
    Height = 15
    Caption = 'Hasło'
  end
  object lblServer: TLabel
    Left = 24
    Top = 219
    Width = 37
    Height = 15
    Caption = 'Serwer'
  end
  object cbPlatform: TComboBox
    Left = 120
    Top = 63
    Width = 322
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object cbBroker: TComboBox
    Left = 120
    Top = 101
    Width = 322
    Height = 23
    Style = csDropDownList
    TabOrder = 1
    OnChange = cbBrokerChange
  end
  object edtLogin: TEdit
    Left = 120
    Top = 139
    Width = 322
    Height = 23
    TabOrder = 2
  end
  object edtPassword: TEdit
    Left = 120
    Top = 177
    Width = 322
    Height = 23
    PasswordChar = '*'
    TabOrder = 3
  end
  object edtServer: TEdit
    Left = 120
    Top = 215
    Width = 322
    Height = 23
    TabOrder = 4
  end
  object chkRemember: TCheckBox
    Left = 120
    Top = 254
    Width = 250
    Height = 21
    Caption = 'Zapamiętaj login i hasło w pliku INI'
    TabOrder = 5
  end
  object btnLogin: TButton
    Left = 262
    Top = 298
    Width = 87
    Height = 29
    Caption = 'Połącz'
    Default = True
    TabOrder = 6
    OnClick = btnLoginClick
  end
  object btnCancel: TButton
    Left = 355
    Top = 298
    Width = 87
    Height = 29
    Cancel = True
    Caption = 'Anuluj'
    ModalResult = 2
    TabOrder = 7
  end
end

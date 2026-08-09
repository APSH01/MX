object frmBridgeInstaller: TfrmBridgeInstaller
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Instalator Bridge MT5'
  ClientHeight = 430
  ClientWidth = 720
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblTerminal: TLabel
    Left = 16
    Top = 20
    Width = 74
    Height = 15
    Caption = 'Terminal MT5'
  end
  object lblBroker: TLabel
    Left = 16
    Top = 70
    Width = 36
    Height = 15
    Caption = 'Broker'
  end
  object lblPort: TLabel
    Left = 560
    Top = 70
    Width = 23
    Height = 15
    Caption = 'Port'
  end
  object lblSource: TLabel
    Left = 16
    Top = 120
    Width = 68
    Height = 15
    Caption = 'Plik źródłowy'
  end
  object cbTerminal: TComboBox
    Left = 16
    Top = 40
    Width = 600
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object btnScan: TButton
    Left = 624
    Top = 39
    Width = 80
    Height = 25
    Caption = 'Skanuj'
    TabOrder = 1
    OnClick = btnScanClick
  end
  object cbBroker: TComboBox
    Left = 16
    Top = 90
    Width = 520
    Height = 23
    Style = csDropDownList
    TabOrder = 2
    OnChange = cbBrokerChange
  end
  object edPort: TEdit
    Left = 560
    Top = 90
    Width = 144
    Height = 23
    NumbersOnly = True
    TabOrder = 3
    Text = '5555'
  end
  object edSource: TEdit
    Left = 16
    Top = 140
    Width = 688
    Height = 23
    ReadOnly = True
    TabOrder = 4
  end
  object memInfo: TMemo
    Left = 16
    Top = 176
    Width = 688
    Height = 190
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 5
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 382
    Width = 720
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 6
    object btnInstall: TButton
      Left = 16
      Top = 10
      Width = 110
      Height = 28
      Caption = 'Zainstaluj'
      TabOrder = 0
      OnClick = btnInstallClick
    end
    object btnCompile: TButton
      Left = 134
      Top = 10
      Width = 110
      Height = 28
      Caption = 'Kompiluj'
      TabOrder = 1
      OnClick = btnCompileClick
    end
    object btnOpenFolder: TButton
      Left = 252
      Top = 10
      Width = 120
      Height = 28
      Caption = 'Otwórz folder'
      TabOrder = 2
      OnClick = btnOpenFolderClick
    end
    object btnClose: TButton
      Left = 594
      Top = 10
      Width = 110
      Height = 28
      Cancel = True
      Caption = 'Zamknij'
      ModalResult = 2
      TabOrder = 3
      OnClick = btnCloseClick
    end
  end
end

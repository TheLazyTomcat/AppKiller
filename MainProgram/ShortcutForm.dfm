object fShortcutForm: TfShortcutForm
  Left = 904
  Top = 602
  BorderStyle = bsToolWindow
  Caption = 'Termination shortcut'
  ClientHeight = 120
  ClientWidth = 360
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblHintText: TLabel
    Left = 8
    Top = 8
    Width = 344
    Height = 26
    Alignment = taCenter
    Caption = 
      'Select key combination used to start the termination. You can se' +
      'lect any combination of control, alt and shift with any other ke' +
      'y.'
    Constraints.MaxWidth = 344
    Constraints.MinWidth = 344
    WordWrap = True
  end
  object pnlShortcutPanel: TPanel
    Left = 8
    Top = 40
    Width = 345
    Height = 41
    BevelOuter = bvLowered
    Caption = ' - waiting for input -'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object btnCancel: TButton
    Left = 280
    Top = 88
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 3
    OnClick = btnCancelClick
  end
  object btnAccept: TButton
    Left = 200
    Top = 88
    Width = 75
    Height = 25
    Caption = 'Accept'
    TabOrder = 2
    OnClick = btnAcceptClick
  end
  object btnRetry: TButton
    Left = 120
    Top = 88
    Width = 75
    Height = 25
    Caption = 'New input'
    TabOrder = 1
    OnClick = btnRetryClick
  end
end

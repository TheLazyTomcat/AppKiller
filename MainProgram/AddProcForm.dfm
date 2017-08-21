object fAddProcForm: TfAddProcForm
  Left = 406
  Top = 119
  BorderStyle = bsSingle
  Caption = 'Add process'
  ClientHeight = 496
  ClientWidth = 856
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    856
    496)
  PixelsPerInch = 96
  TextHeight = 13
  object blvMainHorSplitTop: TBevel
    Left = 8
    Top = 56
    Width = 841
    Height = 9
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
  end
  object lblRunningProcs: TLabel
    Left = 8
    Top = 64
    Width = 94
    Height = 13
    Caption = 'Running processes:'
  end
  object lblLoading: TLabel
    Left = 800
    Top = 64
    Width = 3
    Height = 13
  end
  object blvMainHorSplitBottom: TBevel
    Left = 7
    Top = 456
    Width = 841
    Height = 9
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsTopLine
  end
  object leProcessName: TLabeledEdit
    Left = 8
    Top = 24
    Width = 816
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 70
    EditLabel.Height = 13
    EditLabel.Caption = 'Process name:'
    TabOrder = 0
    OnKeyPress = leProcessNameKeyPress
  end
  object btnBrowse: TButton
    Left = 824
    Top = 24
    Width = 25
    Height = 21
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 1
    OnClick = btnBrowseClick
  end
  object lvRunningProcesses: TListView
    Left = 8
    Top = 80
    Width = 841
    Height = 337
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'Process'
        Width = 150
      end
      item
        Alignment = taRightJustify
        Caption = 'Bits'
        Width = 55
      end
      item
        Alignment = taRightJustify
        Caption = 'PID'
      end
      item
        Caption = 'Description'
        Width = 220
      end
      item
        Caption = 'Company name'
        Width = 200
      end
      item
        Caption = 'Path'
        Width = 140
      end>
    HideSelection = False
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    SmallImages = imglIcons
    TabOrder = 2
    ViewStyle = vsReport
    OnColumnClick = lvRunningProcessesColumnClick
    OnCompare = lvRunningProcessesCompare
    OnDblClick = lvRunningProcessesDblClick
    OnDeletion = lvRunningProcessesDeletion
    OnResize = lvRunningProcessesResize
  end
  object btnRefresh: TButton
    Left = 664
    Top = 424
    Width = 185
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Refresh list of running processes'
    TabOrder = 4
    OnClick = btnRefreshClick
  end
  object cbShowAll: TCheckBox
    Left = 8
    Top = 428
    Width = 169
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Show limited-access processes'
    TabOrder = 3
    OnClick = cbShowAllClick
  end
  object btnCancel: TButton
    Left = 760
    Top = 464
    Width = 89
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    TabOrder = 6
    OnClick = btnCancelClick
  end
  object btnAccept: TButton
    Left = 664
    Top = 464
    Width = 89
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Accept'
    TabOrder = 5
    OnClick = btnAcceptClick
  end
  object diaBrowse: TOpenDialog
    Filter = 'Executable binary (*.exe)|*.exe|All files (*.*)|*.*'
    Left = 760
  end
  object tmrLoadingTimer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrLoadingTimerTimer
    Left = 792
  end
  object imglIcons: TImageList
    Left = 824
  end
end

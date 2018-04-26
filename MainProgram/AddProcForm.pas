{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit AddProcForm;

{$INCLUDE 'Source\APK_Defs.inc'}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, {$IFNDEF FPC}ImgList, {$ENDIF}
  APK_ProcEnum;

type
  TArrowState = (asNone,asAscending,asDescending);

	{ TfAddProcForm }

  TfAddProcForm = class(TForm)
    leProcessName: TLabeledEdit;
    btnBrowse: TButton;
    blvMainHorSplitTop: TBevel;
    lblRunningProcs: TLabel;
    lblLoading: TLabel;
    lvRunningProcesses: TListView;
    cbShowAll: TCheckBox;
    btnRefresh: TButton;
    blvMainHorSplitBottom: TBevel;
    btnAccept: TButton;
    btnCancel: TButton;
    imglIcons: TImageList;
    diaBrowse: TOpenDialog;
    tmrLoadingTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure leProcessNameKeyPress(Sender: TObject; var Key: Char);
    procedure btnBrowseClick(Sender: TObject);
    procedure lvRunningProcessesResize(Sender: TObject);
    procedure lvRunningProcessesDeletion(Sender: TObject; Item: TListItem);
    procedure lvRunningProcessesDblClick(Sender: TObject);
    procedure cbShowAllClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnAcceptClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);  
    procedure tmrLoadingTimerTimer(Sender: TObject);
    procedure lvRunningProcessesColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvRunningProcessesCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
  private
    fSelectedProcesses: TStringList;
  protected
    Enumerator:     TAPKProcessEnumerator;
    PreviousCtrl:   TWinControl;
    ActiveCtrl:     TWinControl;
    SrtDescending:  Boolean;
    SrtColumnIdx:   Integer;
    procedure OnEnumerated(Sender: TOBject);
    procedure ActiveControlChange(Sender: TObject);
    procedure ShowColumnArrow(Column: Integer; ArrowState: TArrowState);
  public
    Function ShowAsPrompt(const WindowCaption: String): Boolean;
    property SelectedProcesses: TStringList read fSelectedProcesses;
  end;

var
  fAddProcForm: TfAddProcForm;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
  CommCtrl;

{$IFDEF FPC_DisableWarns}
  {$WARN 5024 OFF} // Parameter "$1" not used
  {$WARN 5057 OFF} // Local variable "$1" does not seem to be initialized
{$ENDIF}

procedure TfAddProcForm.OnEnumerated(Sender: TOBject);
var
  i:  Integer;
begin
lvRunningProcesses.SortType := stNone;
ShowColumnArrow(SrtColumnIdx,asNone);
If Sender is TAPKProcessEnumerator then
  begin
    lvRunningProcesses.Items.BeginUpdate;
    try
      lvRunningProcesses.Clear;
      //imglIcons.Clear;
    {
      TImageList.Clear is causing problems, images added after it are not shown.
    }
      For i := Pred(imglIcons.Count) downto 0 do
        imglIcons.Delete(i);
      For i := 0 to Pred(Enumerator.ProcessCount) do
        If cbShowAll.Checked or not Enumerator.Processes[i].LimitedAccess then
         with lvRunningProcesses.Items.Add,Enumerator.Processes[i] do
            begin
              Data := New(PInteger);
              PInteger(Data)^ := i;
              Caption := ProcessName;
              If Assigned(Icon) then
                ImageIndex := imglIcons.Add(Icon,nil)
              else
                ImageIndex := -1;
              SubItems.Add(ProcessBitsToString(ProcessBits));
              SubItems.Add(IntToStr(ProcessID));
              SubItems.Add(Description);
              SubItems.Add(CompanyName);
              SubItems.Add(ProcessPath);
          end;
    finally
      lvRunningProcesses.Items.EndUpdate;
    end;
  end;
tmrLoadingTimer.Enabled := False;
lblLoading.Caption := '';
If SrtColumnIdx >= 0 then
  begin
    i := SrtColumnIdx;
    SrtColumnIdx := -2;
    lvRunningProcesses.OnColumnClick(lvRunningProcesses,lvRunningProcesses.Column[i]);
  end;
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.ActiveControlChange(Sender: TObject);
begin
PreviousCtrl := ActiveCtrl;
ActiveCtrl := ActiveControl;
end;

//------------------------------------------------------------------------------

const
  HDF_SORTUP   = $0400;
  HDF_SORTDOWN = $0200;

procedure TfAddProcForm.ShowColumnArrow(Column: Integer; ArrowState: TArrowState);
var
  Header: HWND;
  Item:   THDItem;
begin
If Column >= 0 then
  begin
    Header := ListView_GetHeader(lvRunningProcesses.Handle);
    FillChar(Item,SizeOf(Item),0);
    Item.Mask := HDI_FORMAT;
    Header_GetItem(Header,Column,Item);
    Item.fmt := Item.fmt and not (HDF_SORTUP or HDF_SORTDOWN);
    case ArrowState of
      asAscending:  Item.fmt := Item.fmt or HDF_SORTDOWN and not HDF_SORTUP;
      asDescending: Item.fmt := Item.fmt or HDF_SORTUP and not HDF_SORTDOWN;
    else
      Item.fmt := Item.fmt and not (HDF_SORTUP or HDF_SORTDOWN);
    end;
    Header_SetItem(Header,Column,Item);
  end;
end;

//------------------------------------------------------------------------------

Function TfAddProcForm.ShowAsPrompt(const WindowCaption: String): Boolean;
var
  i:  Integer;
begin
Caption := WindowCaption;
leProcessName.Text := '';
For i := 0 to Pred(lvRunningProcesses.Items.Count) do
   lvRunningProcesses.Items[i].Selected := False;
btnRefresh.OnClick(nil);
fSelectedProcesses.Clear;
ShowModal;
Result := fSelectedProcesses.Count > 0;
end;

//==============================================================================

procedure TfAddProcForm.FormCreate(Sender: TObject);
begin
lvRunningProcesses.DoubleBuffered := True;
Enumerator := TAPKProcessEnumerator.Create;
Enumerator.OnEnumerationDone := OnEnumerated;
{$IFDEF FPC}
Enumerator.IconBackground := lvRunningProcesses.GetDefaultColor(dctBrush);
{$ELSE}
Enumerator.IconBackground := lvRunningProcesses.Color;
{$ENDIF}
Screen.OnActiveControlChange := ActiveControlChange;
fSelectedProcesses := TStringList.Create;
SrtDescending := False;
SrtColumnIdx := -1;
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.FormDestroy(Sender: TObject);
begin
fSelectedProcesses.Free;
Screen.OnActiveControlChange := nil;
Enumerator.Free;
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.leProcessNameKeyPress(Sender: TObject; var Key: Char);
begin
If Key = #13 then
  begin
    Key := #0;
    btnAccept.OnClick(nil);
  end;
end;
 
//------------------------------------------------------------------------------

procedure TfAddProcForm.btnBrowseClick(Sender: TObject);
begin
If diaBrowse.Execute then
  leProcessName.Text := ExtractFileName(diaBrowse.FileName);
end;
 
//------------------------------------------------------------------------------

procedure TfAddProcForm.lvRunningProcessesResize(Sender: TObject);
var
  i:        Integer;
  NewWidth: Integer;
begin
NewWidth := lvRunningProcesses.Width - (2 * GetSystemMetrics(SM_CXEDGE)) - GetSystemMetrics(SM_CXVSCROLL);
For i := 0 to (lvRunningProcesses.Columns.Count - 2) do
  Dec(NewWidth,lvRunningProcesses.Columns[i].Width);
lvRunningProcesses.Columns[5].Width := NewWidth;
{$IFNDEF FPC}
lvRunningProcesses.Scroll(0,0);
{$ENDIF}
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.lvRunningProcessesDeletion(Sender: TObject; Item: TListItem);
begin
Dispose(PInteger(Item.Data));
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.lvRunningProcessesDblClick(Sender: TObject);
begin
If lvRunningProcesses.ItemIndex >= 0 then
  begin
    SelectedProcesses.Add(lvRunningProcesses.Items[lvRunningProcesses.ItemIndex].Caption);
    Close;
  end;
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.cbShowAllClick(Sender: TObject);
begin
OnEnumerated(Enumerator);
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.btnRefreshClick(Sender: TObject);
begin
tmrLoadingTimer.Enabled := True;
Enumerator.Enumerate(True);
end;
 
//------------------------------------------------------------------------------

procedure TfAddProcForm.btnAcceptClick(Sender: TObject);
var
  i:  Integer;
begin
If PreviousCtrl = lvRunningProcesses then
  begin
    If lvRunningProcesses.SelCount > 0 then
      begin
        For i := 0 to Pred(lvRunningProcesses.Items.Count) do
          If lvRunningProcesses.Items[i].Selected then
            SelectedProcesses.Add(lvRunningProcesses.Items[i].Caption);
        Close;
      end
    else MessageDlg('No process selected.',mtError,[mbOK],0);
  end
else
  begin
    If leProcessName.Text <> '' then
      begin
        SelectedProcesses.Add(leProcessName.Text);
        Close;
      end
    else MessageDlg('Process name cannot be empty.',mtError,[mbOK],0);
  end;
end;
 
//------------------------------------------------------------------------------

procedure TfAddProcForm.btnCancelClick(Sender: TObject);
begin
Close;
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.tmrLoadingTimerTimer(Sender: TObject);
begin
lblLoading.Caption := 'Loading' + StringOfChar('.',tmrLoadingTimer.Tag);
If tmrLoadingTimer.Tag > 2 then
  tmrLoadingTimer.Tag := 0
else
  tmrLoadingTimer.Tag := tmrLoadingTimer.Tag + 1;
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.lvRunningProcessesColumnClick(Sender: TObject;
  Column: TListColumn);
begin
TListView(Sender).SortType := stNone;
If Column.Index <> SrtColumnIdx then
  begin
    ShowColumnArrow(SrtColumnIdx,asNone);
    If SrtColumnIdx >= -1 then
      SrtDescending := False;
    SrtColumnIdx := Column.Index;
  end
else SrtDescending := not SrtDescending;
TListView(Sender).SortType := stText;
If SrtDescending then
  ShowColumnArrow(SrtColumnIdx,asDescending)
else
  ShowColumnArrow(SrtColumnIdx,asAscending);
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.lvRunningProcessesCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
case SrtColumnIdx of
  0:  Compare := AnsiCompareText(Item1.Caption,Item2.Caption);
  2:  Compare := StrToIntDef(Item1.SubItems[SrtColumnIdx - 1],0) -
                 StrToIntDef(Item2.SubItems[SrtColumnIdx - 1],0);
else
  Compare := AnsiCompareText(Item1.SubItems[SrtColumnIdx - 1], Item2.SubItems[SrtColumnIdx - 1]);
end;
If SrtDescending then Compare := -Compare;
end;

end.

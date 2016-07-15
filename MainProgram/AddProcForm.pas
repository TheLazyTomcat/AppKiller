unit AddProcForm;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, ImgList,
  APK_ProcEnum;

type
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
  private
    fSelectedProcesses: TStringList;
  protected
    Enumerator:   TAPKProcessEnumerator;
    PreviousCtrl: TWinControl;
    ActiveCtrl:   TWinControl;
    procedure OnEnumerated(Sender: TOBject);
    procedure ActiveControlChange(Sender: TObject);
  public
    Function ShowAsPrompt: Boolean;
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

procedure TfAddProcForm.OnEnumerated(Sender: TOBject);
var
  i:  Integer;
begin
If Sender is TAPKProcessEnumerator then
  begin
    lvRunningProcesses.Items.BeginUpdate;
    try
      lvRunningProcesses.Clear;
      imglIcons.Clear;
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
end;

//------------------------------------------------------------------------------

procedure TfAddProcForm.ActiveControlChange(Sender: TObject);
begin
PreviousCtrl := ActiveCtrl;
ActiveCtrl := ActiveControl;
end;

//------------------------------------------------------------------------------

Function TfAddProcForm.ShowAsPrompt: Boolean;
var
  i:  Integer;
begin
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

end.

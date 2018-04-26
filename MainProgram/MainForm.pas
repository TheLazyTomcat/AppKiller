{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit MainForm;

{$INCLUDE 'Source\APK_Defs.inc'}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, Spin, ExtCtrls, ComCtrls, Menus,
  APK_Manager;

type
  TfMainForm = class(TForm)
    shpHeader: TShape;
    imgLogo: TImage;
    lblProgramName: TLabel;
    lblProgramNameShadow: TLabel;
    lblProgramVersion: TLabel;
    lblCopyright: TLabel;
    bvlHeader: TBevel;
    grbGeneralSettings: TGroupBox;
    cbRunAtStart: TCheckBox;
    bvlGSHorSplit: TBevel;
    cbEndForegroundWnd: TCheckBox;
    cbEndByList: TCheckBox;
    cbEndUnresponsive: TCheckBox;
    lblTimeout: TLabel;
    seTimeout: TSpinEdit;
    grbLists: TGroupBox;
    lblProcTerm: TLabel;
    clbProcTerm: TCheckListBox;
    bvlPLVertSplit: TBevel;
    lblProcNoTerm: TLabel;
    clbProcNoTerm: TCheckListBox;
    grbLog: TGroupBox;
    meLog: TMemo;
    btnChangeShortcut: TButton;
    btnStartTermination: TButton;
    sbStatusBar: TStatusBar;
    pmnTermList: TPopupMenu;
    pmniTermList_Add: TMenuItem;
    pmniTermList_Remove: TMenuItem;
    TermList_N1: TMenuItem;
    pmniTermList_MarkAll: TMenuItem;
    pmniTermList_UnmarkAll: TMenuItem;
    pmniTermList_Invert: TMenuItem;
    TermList_N2: TMenuItem;
    pmniTermList_MoveUp: TMenuItem;
    pmniTermList_MoveDown: TMenuItem;
    pmnNoTermList: TPopupMenu;
    pmniNoTermList_Add: TMenuItem;
    pmniNoTermList_Remove: TMenuItem;
    NoTermList_N1: TMenuItem;
    pmniNoTermList_MarkAll: TMenuItem;
    pmniNoTermList_UnmarkAll: TMenuItem;
    pmniNoTermList_Invert: TMenuItem;
    NoTermList_N2: TMenuItem;
    pmniNoTermList_MoveUp: TMenuItem;
    pmniNoTermList_MoveDown: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure clbProcTermDblClick(Sender: TObject);
    procedure clbProcNoTermDblClick(Sender: TObject);
    procedure btnStartTerminationClick(Sender: TObject);
    procedure btnChangeShortcutClick(Sender: TObject);
    procedure pmnTermListPopup(Sender: TObject);
    procedure pmnTermListClose(Sender: TObject);
    procedure pmniTermList_AddClick(Sender: TObject);
    procedure pmniTermList_RemoveClick(Sender: TObject);
    procedure pmniTermList_MarkAllClick(Sender: TObject);
    procedure pmniTermList_UnmarkAllClick(Sender: TObject);
    procedure pmniTermList_InvertClick(Sender: TObject);
    procedure pmniTermList_MoveUpClick(Sender: TObject);
    procedure pmniTermList_MoveDownClick(Sender: TObject);
    procedure pmnNoTermListPopup(Sender: TObject);
    procedure pmnNoTermListClose(Sender: TObject);
    procedure pmniNoTermList_AddClick(Sender: TObject);
    procedure pmniNoTermList_RemoveClick(Sender: TObject);
    procedure pmniNoTermList_MarkAllClick(Sender: TObject);
    procedure pmniNoTermList_UnmarkAllClick(Sender: TObject);
    procedure pmniNoTermList_InvertClick(Sender: TObject);
    procedure pmniNoTermList_MoveUpClick(Sender: TObject);
    procedure pmniNoTermList_MoveDownClick(Sender: TObject);
  private
    AppKillerManager: TAPKManager;
    ForceClose:       Boolean;
  protected
    procedure OnTrayMenuItem(Sender: TObject; aAction: Integer);
    procedure OnSettingsUpdateRequired(Sender: TObject);
    procedure FormToSettings;
    procedure SettingsToForm;
    procedure ShortcutChanged;
    procedure UpdateListsStyle;
  public
    procedure SessionEndProcess;
  end;

var
  fMainForm: TfMainForm;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
  APK_System, APK_Strings, APK_TrayIcon, APK_Keyboard, APK_Settings,
  AddProcForm, ShortcutForm;

{$IFDEF FPC_DisableWarns}
  {$WARN 5024 OFF} // Parameter "$1" not used
{$ENDIF}

var
  WindowFunc: Pointer;

Function WndCallback(Window: HWND; uMsg: UINT; wParam: WParam; lParam: LParam): LRESULT; stdcall;
begin
If uMsg = WM_QUERYENDSESSION then
  fMainForm.SessionEndProcess;
Result := CallWindowProc(WindowFunc,Window,uMsg,WParam,LParam);
end;

//==============================================================================

procedure TfMainForm.OnTrayMenuItem(Sender: TObject; aAction: Integer);
begin
case aAction of
  TI_MI_ACTION_Restore:
    If not Visible then Show;
  TI_MI_ACTION_Start:
    btnStartTermination.OnClick(nil);
  TI_MI_ACTION_Close:
    begin
      ForceClose := True;
      try
        If MessageDlg('Are you sure you want to close the AppKiller?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
          Close;
      finally
        ForceClose := False;
      end;
    end;
end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.OnSettingsUpdateRequired(Sender: TObject);
begin
FormToSettings;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.FormToSettings;
var
  i:  Integer;
begin
AppKillerManager.Settings.SettingsPtr^.GeneralSettings.RunAtSystemStart := cbRunAtStart.Checked;
AppKillerManager.Settings.SettingsPtr^.GeneralSettings.TerminateForegroundWnd := cbEndForegroundWnd.Checked;
AppKillerManager.Settings.SettingsPtr^.GeneralSettings.TerminateByList := cbEndByList.Checked;
AppKillerManager.Settings.SettingsPtr^.GeneralSettings.TerminateUnresponsive := cbEndUnresponsive.Checked;
AppKillerManager.Settings.SettingsPtr^.GeneralSettings.ResponseTimeout := seTimeout.Value;
SetLength(AppKillerManager.Settings.SettingsPtr^.ProcListTerminate,clbProcTerm.Count);
For i := 0 to Pred(clbProcTerm.Count) do
  with AppKillerManager.Settings.SettingsPtr^.ProcListTerminate[i] do
    begin
      Active := clbProcTerm.Checked[i];
      ProcessName := clbProcTerm.Items[i];
    end;
SetLength(AppKillerManager.Settings.SettingsPtr^.ProcListNeverTerminate,clbProcNoTerm.Count);    
For i := 0 to Pred(clbProcNoTerm.Count) do
  with AppKillerManager.Settings.SettingsPtr^.ProcListNeverTerminate[i] do
    begin
      Active := clbProcNoTerm.Checked[i];
      ProcessName := clbProcNoTerm.Items[i];
    end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.SettingsToForm;
var
  i:  Integer;
begin
cbRunAtStart.Checked := AppKillerManager.Settings.Settings.GeneralSettings.RunAtSystemStart;
cbEndForegroundWnd.Checked := AppKillerManager.Settings.Settings.GeneralSettings.TerminateForegroundWnd;
cbEndByList.Checked := AppKillerManager.Settings.Settings.GeneralSettings.TerminateByList;
cbEndUnresponsive.Checked := AppKillerManager.Settings.Settings.GeneralSettings.TerminateUnresponsive;
seTimeout.Value := AppKillerManager.Settings.Settings.GeneralSettings.ResponseTimeout;
clbProcTerm.Items.BeginUpdate;
try
  clbProcTerm.Items.Clear;
  For i := Low(AppKillerManager.Settings.Settings.ProcListTerminate) to
           High(AppKillerManager.Settings.Settings.ProcListTerminate) do
    with AppKillerManager.Settings.Settings.ProcListTerminate[i] do
      clbProcTerm.Checked[clbProcTerm.Items.Add(ProcessName)] := Active;
finally
  clbProcTerm.Items.EndUpdate;
end; 
clbProcNoTerm.Items.BeginUpdate;
try
  clbProcNoTerm.Items.Clear;
  For i := Low(AppKillerManager.Settings.Settings.ProcListNeverTerminate) to
           High(AppKillerManager.Settings.Settings.ProcListNeverTerminate) do
    with AppKillerManager.Settings.Settings.ProcListNeverTerminate[i] do
      clbProcNoTerm.Checked[clbProcNoTerm.Items.Add(ProcessName)] := Active;
finally
  clbProcNoTerm.Items.EndUpdate;
end;
UpdateListsStyle;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.ShortcutChanged;
begin
sbStatusBar.Panels[0].Text := Format(APKSTR_MW_SB_KeyboardShortcut,[TAPKKeyboard.ShortcutAsText(AppKillerManager.Keyboard.Shortcut)]);
AppKillerManager.TrayIcon.SetTipText(Format(APKSTR_TI_HintText,[TAPKKeyboard.ShortcutAsText(AppKillerManager.Keyboard.Shortcut)]));
end;

//------------------------------------------------------------------------------

procedure TfMainForm.UpdateListsStyle;
begin
{$IFNDEF FPC}
If clbProcTerm.Count > 0 then
  clbProcTerm.ControlStyle := clbProcTerm.ControlStyle - [csClickEvents]
else
  clbProcTerm.ControlStyle := clbProcTerm.ControlStyle + [csClickEvents];
If clbProcNoTerm.Count > 0 then
  clbProcNoTerm.ControlStyle := clbProcNoTerm.ControlStyle - [csClickEvents]
else
  clbProcNoTerm.ControlStyle := clbProcNoTerm.ControlStyle + [csClickEvents];
{$ENDIF}
end;

//------------------------------------------------------------------------------

procedure TfMainForm.SessionEndProcess;
begin
FormToSettings;
AppKillerManager.Finalize;
end;

//==============================================================================

procedure TfMainForm.FormCreate(Sender: TObject);
begin
WindowFunc := APK_System.SetWindowLongPtr(Handle,GWL_WNDPROC,@WndCallback);
ForceClose := False;
// Get debug privilege if available
SetPrivilege('SeDebugPrivilege',True);
// Set dynamic captions
lblProgramName.Caption := APKSTR_MW_HD_Title;
lblProgramNameShadow.Caption := APKSTR_MW_HD_Title;
lblProgramVersion.Caption := APKSTR_MW_HD_Version;
lblCopyright.Caption := APKSTR_MW_HD_Copyright;
// Set menu shortcuts
pmniTermList_MoveUp.ShortCut := Shortcut(VK_UP,[ssShift]);
pmniTermList_MoveDown.ShortCut := Shortcut(VK_DOWN,[ssShift]);
pmniNoTermList_MoveUp.ShortCut := Shortcut(VK_UP,[ssShift]);
pmniNoTermList_MoveDown.ShortCut := Shortcut(VK_DOWN,[ssShift]);
// Initialize manager
AppKillerManager := TAPKManager.Create;
AppKillerManager.OnSettingsUpdateRequired := OnSettingsUpdateRequired;
AppKillerManager.TrayIcon.OnPopupMenuItem := OnTrayMenuItem;
{$IFDEF FPC}
InitializeWnd;
{$ENDIF}
AppKillerManager.Log.ExternalLogAdd(meLog.Lines);
AppKillerManager.Initialize;
SettingsToForm;
ShortcutChanged;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.FormDestroy(Sender: TObject);
begin
FormToSettings;
AppKillerManager.Finalize;
AppKillerManager.Free;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
If not ForceClose then
  begin
    FormToSettings;
    AppKillerManager.Settings.Save(False);
    CanClose := False;
    If Visible then Hide;
  end
else CanClose := True;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.clbProcTermDblClick(Sender: TObject);
begin
pmniTermList_Add.OnClick(nil);
end;

//------------------------------------------------------------------------------

procedure TfMainForm.clbProcNoTermDblClick(Sender: TObject);
begin
pmniNoTermList_Add.OnClick(nil);
end;

//------------------------------------------------------------------------------

procedure TfMainForm.btnStartTerminationClick(Sender: TObject);
begin
AppKillerManager.Log.AddLog('Termination started from GUI...');
AppKillerManager.Terminate;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.btnChangeShortcutClick(Sender: TObject);
begin
AppKillerManager.Keyboard.Mode := kmNone;
try
  If fShortcutForm.ShowAsPrompt(AppKillerManager.Keyboard) then
    begin
      AppKillerManager.Keyboard.Shortcut := fShortcutForm.Shortcut;
      ShortcutChanged;
    end;
finally
  AppKillerManager.Keyboard.Mode := kmIntercept;
end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmnTermListPopup(Sender: TObject);
begin
pmniTermList_Remove.Enabled := clbProcTerm.ItemIndex >= 0;
pmniTermList_MarkAll.Enabled := clbProcTerm.Count > 0;
pmniTermList_UnmarkAll.Enabled := clbProcTerm.Count > 0;
pmniTermList_Invert.Enabled := clbProcTerm.Count > 0;
pmniTermList_MoveUp.Enabled := clbProcTerm.ItemIndex > 0;
pmniTermList_MoveDown.Enabled := (clbProcTerm.ItemIndex >= 0) and (clbProcTerm.ItemIndex < Pred(clbProcTerm.Count));
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmnTermListClose(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(pmnTermList.Items.Count) do
  pmnTermList.Items[i].Enabled := True;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniTermList_AddClick(Sender: TObject);
var
  i:  Integer;
begin
If fAddProcForm.ShowAsPrompt('Add process to "for termination" list') then
  For i := 0 to Pred(fAddProcForm.SelectedProcesses.Count) do
    If (fAddProcForm.SelectedProcesses[i] <> '') and (clbProcTerm.Items.IndexOf(fAddProcForm.SelectedProcesses[i]) < 0) then
      clbProcTerm.Checked[clbProcTerm.Items.Add(fAddProcForm.SelectedProcesses[i])] := True;
UpdateListsStyle;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniTermList_RemoveClick(Sender: TObject);
begin
If clbProcTerm.ItemIndex >= 0 then
  clbProcTerm.Items.Delete(clbProcTerm.ItemIndex);
UpdateListsStyle;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniTermList_MarkAllClick(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(clbProcTerm.Count) do
  clbProcTerm.Checked[i] := True;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniTermList_UnmarkAllClick(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(clbProcTerm.Count) do
  clbProcTerm.Checked[i] := False;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniTermList_InvertClick(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(clbProcTerm.Count) do
  clbProcTerm.Checked[i] := not clbProcTerm.Checked[i];
end;
 
//------------------------------------------------------------------------------

procedure TfMainForm.pmniTermList_MoveUpClick(Sender: TObject);
begin
If clbProcTerm.ItemIndex > 0 then
  begin
    clbProcTerm.Items.Exchange(clbProcTerm.ItemIndex - 1,clbProcTerm.ItemIndex);
  {$IFDEF FPC}
    clbProcTerm.ItemIndex := clbProcTerm.ItemIndex - 1;
  {$ENDIF}
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniTermList_MoveDownClick(Sender: TObject);
begin
If (clbProcTerm.ItemIndex >= 0) and (clbProcTerm.ItemIndex < Pred(clbProcTerm.Count)) then
  begin
    clbProcTerm.Items.Exchange(clbProcTerm.ItemIndex + 1,clbProcTerm.ItemIndex);
  {$IFDEF FPC}
    clbProcTerm.ItemIndex := clbProcTerm.ItemIndex + 1;
  {$ENDIF}
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmnNoTermListPopup(Sender: TObject);
begin
pmniNoTermList_Remove.Enabled := clbProcNoTerm.ItemIndex >= 0;
pmniNoTermList_MarkAll.Enabled := clbProcNoTerm.Count > 0;
pmniNoTermList_UnmarkAll.Enabled := clbProcNoTerm.Count > 0;
pmniNoTermList_Invert.Enabled := clbProcNoTerm.Count > 0;
pmniNoTermList_MoveUp.Enabled := clbProcNoTerm.ItemIndex > 0;
pmniNoTermList_MoveDown.Enabled := (clbProcNoTerm.ItemIndex >= 0) and (clbProcNoTerm.ItemIndex < Pred(clbProcNoTerm.Count));
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmnNoTermListClose(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(pmnNoTermList.Items.Count) do
  pmnNoTermList.Items[i].Enabled := True;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniNoTermList_AddClick(Sender: TObject);
var
  i:  Integer;
begin
If fAddProcForm.ShowAsPrompt('Add process to "never terminate" list') then
  For i := 0 to Pred(fAddProcForm.SelectedProcesses.Count) do
    If (fAddProcForm.SelectedProcesses[i] <> '') and (clbProcNoTerm.Items.IndexOf(fAddProcForm.SelectedProcesses[i]) < 0) then
      clbProcNoTerm.Checked[clbProcNoTerm.Items.Add(fAddProcForm.SelectedProcesses[i])] := True;
UpdateListsStyle;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniNoTermList_RemoveClick(Sender: TObject);
begin
If clbProcNoTerm.ItemIndex >= 0 then
  clbProcNoTerm.Items.Delete(clbProcNoTerm.ItemIndex);
UpdateListsStyle;  
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniNoTermList_MarkAllClick(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(clbProcNoTerm.Count) do
  clbProcNoTerm.Checked[i] := True;
end;
 
//------------------------------------------------------------------------------

procedure TfMainForm.pmniNoTermList_UnmarkAllClick(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(clbProcNoTerm.Count) do
  clbProcNoTerm.Checked[i] := False;
end;
 
//------------------------------------------------------------------------------

procedure TfMainForm.pmniNoTermList_InvertClick(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(clbProcNoTerm.Count) do
  clbProcNoTerm.Checked[i] := not clbProcNoTerm.Checked[i];
end;
 
//------------------------------------------------------------------------------

procedure TfMainForm.pmniNoTermList_MoveUpClick(Sender: TObject);
begin
If clbProcNoTerm.ItemIndex > 0 then
  begin
    clbProcNoTerm.Items.Exchange(clbProcNoTerm.ItemIndex - 1,clbProcNoTerm.ItemIndex);
  {$IFDEF FPC}
    clbProcNoTerm.ItemIndex := clbProcNoTerm.ItemIndex - 1;
  {$ENDIF}
  end;
end;
 
//------------------------------------------------------------------------------

procedure TfMainForm.pmniNoTermList_MoveDownClick(Sender: TObject);
begin
If (clbProcNoTerm.ItemIndex >= 0) and (clbProcNoTerm.ItemIndex < Pred(clbProcNoTerm.Count)) then
  begin
    clbProcNoTerm.Items.Exchange(clbProcNoTerm.ItemIndex + 1,clbProcNoTerm.ItemIndex);
  {$IFDEF FPC}
    clbProcNoTerm.ItemIndex := clbProcNoTerm.ItemIndex + 1;
  {$ENDIF}
  end;
end;

end.

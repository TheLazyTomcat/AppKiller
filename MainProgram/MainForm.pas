unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan, StdCtrls, CheckLst, Spin, ExtCtrls, ComCtrls, Menus,
  APK_Manager;

type
  TfMainForm = class(TForm)
    oXPManifest: TXPManifest;
    shpHeader: TShape;
    grbGeneralSettings: TGroupBox;
    cbRunAtStart: TCheckBox;
    bvlGSHorSplit: TBevel;
    cbEndForegroundWnd: TCheckBox;
    cbEndByList: TCheckBox;
    cbEndUnresponsive: TCheckBox;
    seTimeout: TSpinEdit;
    lblTimeout: TLabel;
    grbLists: TGroupBox;
    clbProcTerm: TCheckListBox;
    lblProcTerm: TLabel;
    clbProcNoTerm: TCheckListBox;
    lblProcNoTerm: TLabel;
    bvlPLVertSplit: TBevel;
    bvlHeader: TBevel;
    btnChangeShortcut: TButton;
    btnStartTermination: TButton;
    sbStatusBar: TStatusBar;
    grbLog: TGroupBox;
    meLog: TMemo;
    imgLogo: TImage;
    lblProgramNameShadow: TLabel;
    lblProgramName: TLabel;
    lblProgramVersion: TLabel;
    lblCopyright: TLabel;
    pmnLists: TPopupMenu;
    pmniLists_Add: TMenuItem;
    pmniLists_Remove: TMenuItem;
    N1: TMenuItem;
    pmniLists_MarkAll: TMenuItem;
    pmniLists_UnmarkAll: TMenuItem;
    pmniLists_Invert: TMenuItem;
    N2: TMenuItem;
    pmniLists_MoveUp: TMenuItem;
    pmniLists_MoveDown: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure pmnListsPopup(Sender: TObject);
    procedure pmniLists_AddClick(Sender: TObject);
    procedure pmniLists_RemoveClick(Sender: TObject);
    procedure pmniLists_MarkAllClick(Sender: TObject);
    procedure pmniLists_UnmarkAllClick(Sender: TObject);
    procedure pmniLists_InvertClick(Sender: TObject);
    procedure pmniLists_MoveUpClick(Sender: TObject);
    procedure pmniLists_MoveDownClick(Sender: TObject);
    procedure btnChangeShortcutClick(Sender: TObject);
    procedure btnStartTerminationClick(Sender: TObject);
  private
    AppKillerManager:  TAPKManager;
    ForceClose:        Boolean;
  protected
    procedure OnTrayMenuItem(Sender: TObject; Action: Integer);
    procedure OnSettingsUpdateRequired(Sender: TObject);
    procedure FormToSettings;
    procedure SettingsToForm;
    procedure ShortcutChange;
  public
    { Public declarations }
  end;

var
  fMainForm: TfMainForm;

implementation

{$R *.dfm}

uses
  APK_System, APK_Strings, APK_TrayIcon, APK_Keyboard,
  AddProcForm, ShortcutForm;

procedure TfMainForm.OnTrayMenuItem(Sender: TObject; Action: Integer);
begin
case Action of
  TI_MI_ACTION_Restore:
    Show;
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
end;

//------------------------------------------------------------------------------

procedure TfMainForm.ShortcutChange;
begin
sbStatusBar.Panels[0].Text := Format(APKSTR_MW_SB_KeyboardShortcut,[TAPKKeyboard.ShortcutAsText(AppKillerManager.Keyboard.Shortcut)]);
AppKillerManager.TrayIcon.SetTipText(Format(APKSTR_TI_HintText,[TAPKKeyboard.ShortcutAsText(AppKillerManager.Keyboard.Shortcut)]));
end;

//==============================================================================

procedure TfMainForm.FormCreate(Sender: TObject);
begin
ForceClose := False;
// Get debug privilege if available
SetPrivilege('SeDebugPrivilege',True);
// Set dynamic captions
lblProgramName.Caption := APKSTR_MW_HD_Title;
lblProgramNameShadow.Caption := APKSTR_MW_HD_Title;
lblProgramVersion.Caption := APKSTR_MW_HD_Version;
lblCopyright.Caption := APKSTR_MW_HD_Copyright;
// Initialize manager
AppKillerManager := TAPKManager.Create;
AppKillerManager.OnSettingsUpdateRequired := OnSettingsUpdateRequired;
AppKillerManager.TrayIcon.OnPopupMenuItem := OnTrayMenuItem;
AppKillerManager.Log.ExternalLogAdd(meLog.Lines);
AppKillerManager.Initialize;
SettingsToForm;
ShortcutChange;
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
If Visible and not ForceClose then
  begin
    FormToSettings;
    AppKillerManager.Settings.Save;
    CanClose := False;
    Hide;
  end
else CanClose := True;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmnListsPopup(Sender: TObject);
var
  PopupList:  TCheckListBox;
begin
PopupList := (Sender as TPopupMenu).PopupComponent as TCheckListBox;
pmniLists_Remove.Enabled := PopupList.ItemIndex >= 0;
pmniLists_MarkAll.Enabled := PopupList.Count > 0;
pmniLists_UnmarkAll.Enabled := PopupList.Count > 0;
pmniLists_Invert.Enabled := PopupList.Count > 0;
pmniLists_MoveUp.Enabled := PopupList.ItemIndex > 0;
pmniLists_MoveDown.Enabled := (PopupList.ItemIndex >= 0) and (PopupList.ItemIndex < Pred(PopupList.Count));
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniLists_AddClick(Sender: TObject);
begin
If fAddProcForm.ShowAsPrompt then
  case ((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent.Tag of
    1:  clbProcTerm.Checked[clbProcTerm.Items.Add(fAddProcForm.leProcessName.Text)] := True;
    2:  clbProcNoTerm.Checked[clbProcNoTerm.Items.Add(fAddProcForm.leProcessName.Text)] := True;
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniLists_RemoveClick(Sender: TObject);
begin
case ((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent.Tag of
  1:  clbProcTerm.Items.Delete(clbProcTerm.ItemIndex); 
  2:  clbProcNoTerm.Items.Delete(clbProcTerm.ItemIndex);
end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniLists_MarkAllClick(Sender: TObject);
var
  i:  Integer;
begin
case ((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent.Tag of
  1:  For i := 0 to Pred(clbProcTerm.Count) do
        clbProcTerm.Checked[i] := True;
  2:  For i := 0 to Pred(clbProcNoTerm.Count) do
        clbProcNoTerm.Checked[i] := True;
end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniLists_UnmarkAllClick(Sender: TObject);
var
  i:  Integer;
begin
case ((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent.Tag of
  1:  For i := 0 to Pred(clbProcTerm.Count) do
        clbProcTerm.Checked[i] := False;
  2:  For i := 0 to Pred(clbProcNoTerm.Count) do
        clbProcNoTerm.Checked[i] := False;
end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniLists_InvertClick(Sender: TObject);
var
  i:  Integer;
begin
case ((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent.Tag of
  1:  For i := 0 to Pred(clbProcTerm.Count) do
        clbProcTerm.Checked[i] := not clbProcTerm.Checked[i];
  2:  For i := 0 to Pred(clbProcNoTerm.Count) do
        clbProcNoTerm.Checked[i] := not clbProcNoTerm.Checked[i];
end;
end;
 
//------------------------------------------------------------------------------

procedure TfMainForm.pmniLists_MoveUpClick(Sender: TObject);
begin
case ((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent.Tag of
  1:  clbProcTerm.Items.Exchange(clbProcTerm.ItemIndex - 1,clbProcTerm.ItemIndex);
  2:  clbProcNoTerm.Items.Exchange(clbProcTerm.ItemIndex - 1,clbProcTerm.ItemIndex);
end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmniLists_MoveDownClick(Sender: TObject);
begin
case ((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent.Tag of
  1:  clbProcTerm.Items.Exchange(clbProcTerm.ItemIndex + 1,clbProcTerm.ItemIndex);
  2:  clbProcNoTerm.Items.Exchange(clbProcTerm.ItemIndex + 1,clbProcTerm.ItemIndex);
end;
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
      ShortcutChange;
    end;
finally
  AppKillerManager.Keyboard.Mode := kmIntercept;
end;
end;

end.

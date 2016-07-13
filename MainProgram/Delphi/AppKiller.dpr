program AppKiller;

uses
  Forms,
  
  MainForm     in '..\MainForm.pas' {fMainForm},
  AddProcForm  in '..\AddProcForm.pas' {fAddProcForm},
  ShortcutForm in '..\ShortcutForm.pas' {fShortcutForm},

  APK_InstanceControl in '..\Source\APK_InstanceControl.pas',
  APK_Keyboard        in '..\Source\APK_Keyboard.pas',
  APK_Manager         in '..\Source\APK_Manager.pas',
  APK_ProcEnum        in '..\Source\APK_ProcEnum.pas',
  APK_Settings        in '..\Source\APK_Settings.pas',
  APK_Strings         in '..\Source\APK_Strings.pas',
  APK_System          in '..\Source\APK_System.pas',
  APK_Terminator      in '..\Source\APK_Terminator.pas',
  APK_TrayIcon        in '..\Source\APK_TrayIcon.pas';

{$R *.res}

begin
with TAPKInstanceControl.Create do
try
  If SingleInstance then
    begin
      Application.Initialize;
      Application.ShowMainForm := False;
      Application.Title := 'AppKiller';
      Application.CreateForm(TfMainForm, fMainForm);
      Application.CreateForm(TfAddProcForm, fAddProcForm);
      Application.CreateForm(TfShortcutForm, fShortcutForm);
      Application.Run;
    end;
finally
  Free;
end;
end.

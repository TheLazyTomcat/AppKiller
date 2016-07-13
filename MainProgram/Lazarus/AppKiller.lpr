program AppKiller;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,

  MainForm,
  AddProcForm,
  ShortcutForm,

  APK_InstanceControl,
  APK_Strings,
  APK_Keyboard,
  APK_ProcEnum,
  APK_Settings,
  APK_System,
  APK_Terminator,
  APK_TrayIcon,
  APK_Manager;

{$R *.res}

begin
with TAPKInstanceControl.Create do
try
  If SingleInstance then
    begin
      RequireDerivedFormResource := True;
      Application.Initialize;
      Application.ShowMainForm := False;
      Application.CreateForm(TfMainForm, fMainForm);
      Application.CreateForm(TfAddProcForm, fAddProcForm);
      Application.CreateForm(TfShortcutForm, fShortcutForm);
      Application.Run;
    end;
finally
  Free;
end;
end.


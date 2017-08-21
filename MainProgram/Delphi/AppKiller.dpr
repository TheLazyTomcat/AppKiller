{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program AppKiller;

{$INCLUDE '..\Source\APK_Defs.inc'}

{$R '..\Resources\uac_manifest.res'}

uses
  Forms,

  MainForm     in '..\MainForm.pas' {fMainForm},
  AddProcForm  in '..\AddProcForm.pas' {fAddProcForm},
  ShortcutForm in '..\ShortcutForm.pas' {fShortcutForm},

  APK_System          in '..\Source\APK_System.pas',
  APK_Strings         in '..\Source\APK_Strings.pas',
  APK_InstanceControl in '..\Source\APK_InstanceControl.pas',
  APK_TrayIcon        in '..\Source\APK_TrayIcon.pas',
  APK_Settings        in '..\Source\APK_Settings.pas',
  APK_Keyboard        in '..\Source\APK_Keyboard.pas',
  APK_ProcEnum        in '..\Source\APK_ProcEnum.pas',
  APK_Terminator      in '..\Source\APK_Terminator.pas',
  APK_Manager         in '..\Source\APK_Manager.pas';

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

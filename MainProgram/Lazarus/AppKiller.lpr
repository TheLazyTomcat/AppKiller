{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program AppKiller;

{$INCLUDE '..\Source\APK_Defs.inc'}

uses
  Interfaces,
  Forms,

  MainForm,
  AddProcForm,
  ShortcutForm,

  APK_System,
  APK_Strings,
  APK_InstanceControl,
  APK_TrayIcon,
  APK_Settings,
  APK_Keyboard,
  APK_ProcEnum,
  APK_Terminator,
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


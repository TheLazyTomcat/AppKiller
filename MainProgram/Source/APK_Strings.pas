unit APK_Strings;

{$INCLUDE APK_Defs.inc}

interface

const
  // Common
  APKSTR_CM_ProgramTitle = 'AppKiller';
var
  APKSTR_CM_VersionShort: String = '';
  APKSTR_CM_VersionLong:  String = '';
  APKSTR_CM_VersionFull:  String = '';

const
  // Instance control
  APKSTR_IC_MutexName = 'AppKiller_Mutex_1CD03ECD-5B3A-4707-827F-406587FC8032';

  // Tray icon
  APKSTR_TI_HintText    = APKSTR_CM_ProgramTitle + sLineBreak + 'Press [%s] to start the ternimation';
  APKSTR_TI_MessageName = 'AppKiller_TrayIcon_B306D82D-6F23-443D-99C1-9116C7FA5412';

  // Tray icon popup menu items
  APKSTR_TI_MI_Splitter = '-';
  APKSTR_TI_MI_Restore  = 'Show settings window...';
  APKSTR_TI_MI_Start    = 'Start termination';
  APKSTR_TI_MI_Close    = 'Close AppKiller';

  // Main window header
  APKSTR_MW_HD_Title     = APKSTR_CM_ProgramTitle;
var
  APKSTR_MW_HD_Version:   String = 'Version of the program: %s';
  APKSTR_MW_HD_Copyright: String = '%s, all rights reserved';

const
  // Main window's status bar
  APKSTR_MW_SB_KeyboardShortcut = 'Press following key combination to start the termination: [%s]';

  // Shortcut selection
  APKSTR_SW_ShortcutSelect = ' - waiting for input -';

implementation

uses
  SysUtils, WinFileInfo;

//------------------------------------------------------------------------------

procedure Initialize;
begin
with TWinFileInfo.Create(WFI_LS_VersionInfoAndFFI) do
try
  If VersionInfoTranslationCount > 0 then
    APKSTR_MW_HD_Copyright := Format(APKSTR_MW_HD_Copyright,[VersionInfoValues[VersionInfoTranslations[0].LanguageStr,'LegalCopyright']]);
  with VersionInfoFixedFileInfoDecoded.FileVersionMembers do
    begin
      APKSTR_CM_VersionShort := Format('%d.%d',[Major,Minor]);
      APKSTR_CM_VersionLong := Format('%d.%d.%d.%d',[Major,Minor,Release,Build]);
      APKSTR_CM_VersionFull := Format('%d.%d.%d %s%s #%d%s',[Major,Minor,Release,
        {$IFDEF FPC}'L'{$ELSE}'D'{$ENDIF},{$IFDEF 64bit}'64'{$ELSE}'32'{$ENDIF},Build,
        {$IFDEF Debug}' debug'{$ELSE}''{$ENDIF}]);
      APKSTR_MW_HD_Version := Format(APKSTR_MW_HD_Version,[APKSTR_CM_VersionFull]);
    end;
finally
  Free;
end;
end;

//------------------------------------------------------------------------------

initialization
  Initialize;

end.

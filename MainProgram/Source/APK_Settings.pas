{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit APK_Settings;

{$INCLUDE APK_Defs.inc}

interface

uses
  AuxTypes,
  APK_Keyboard;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                 TAPKSettings                                 }
{------------------------------------------------------------------------------}
{==============================================================================}

type
  TAPKProcessListItem = record
    Active:       Boolean;  
    ProcessName:  String;
  end;

  TAPKProcessList = array of TAPKProcessListItem;

  TAPKSettingsGeneral = record
    RunAtSystemStart:       Boolean;
    TerminateForegroundWnd: Boolean;
    TerminateByList:        Boolean;
    TerminateUnresponsive:  Boolean;
    ResponseTimeout:        Integer;
    Shortcut:               UInt32;
  end;

  TAPKSettingsStruct = record
    GeneralSettings:        TAPKSettingsGeneral;
    ProcListTerminate:      TAPKProcessList;
    ProcListNeverTerminate: TAPKProcessList;
  end;
  PAPKSettingsStruct = ^TAPKSettingsStruct;

{==============================================================================}
{   TAPKSettings - declaration                                                 }
{==============================================================================}

  TAPKSettings = class(TObject)
  private
    fSettings:  TAPKSettingsStruct;
    Function GetSettingsPtr: PAPKSettingsStruct;
  public
    class Function RunAtSystemStartIsActive: Boolean; virtual;
    class Function RunAtSystemStartDelete: Boolean; virtual;
    class Function RunAtSystemStartActivate: Boolean; virtual;
    constructor Create;
    constructor CreateCopy(Source: TAPKSettings);
    procedure LoadDefaultSettings; virtual;
    procedure SaveToIni(const FileName: String); virtual;
    procedure LoadFromIni(const FileName: String); virtual;
    procedure Save(Final: Boolean); virtual;
    procedure Load; virtual;
    Function GetShortcut: TAPKShortcut; virtual;
    procedure SetShortcut(Shortcut: TAPKShortcut); virtual;
    property Settings: TAPKSettingsStruct read fSettings;
    property SettingsPtr: PAPKSettingsStruct read GetSettingsPtr;
  end;

implementation

uses
  Windows, SysUtils, IniFiles, ActiveX, DateUtils,
  RawInputKeyboard, StrRect, WinTaskScheduler;

{==============================================================================}
{   Auxiliary and external functions                                           }
{==============================================================================}

type
{$MINENUMSIZE 4}
  EXTENDED_NAME_FORMAT = (
    NameUnknown          = 0,
    NameFullyQualifiedDN = 1,
    NameSamCompatible    = 2,
    NameDisplay          = 3,
    NameUniqueId         = 6,
    NameCanonical        = 7,
    NameUserPrincipal    = 8,
    NameCanonicalEx      = 9,
    NameServicePrincipal = 10,
    NameDnsDomain        = 12);

Function GetUserNameExW(NameFormat: EXTENDED_NAME_FORMAT; lpNameBuffer: PWideChar; lpnSize: PULONG): ByteBool; stdcall; external 'secur32.dll';
Function GetUserNameExA(NameFormat: EXTENDED_NAME_FORMAT; lpNameBuffer: PAnsiChar; lpnSize: PULONG): ByteBool; stdcall; external 'secur32.dll';
Function GetUserNameEx(NameFormat: EXTENDED_NAME_FORMAT; lpNameBuffer: PChar; lpnSize: PULONG): ByteBool; stdcall; external 'secur32.dll' name {$IFDEF Unicode} 'GetUserNameExW'{$ELSE} 'GetUserNameExA'{$ENDIF};


Function GetAccountName: WideString;
var
  AccountNameLen: ULONG;
begin
AccountNameLen := 0;
GetUserNameExW(NameSamCompatible,nil,@AccountNameLen);
SetLength(Result,AccountNameLen);
If not GetUserNameExW(NameSamCompatible,PWideChar(Result),@AccountNameLen) then
  raise Exception.CreateFmt('Cannot obtain account name (0x%.8x).',[GetLastError]);
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                 TAPKSettings                                 }
{------------------------------------------------------------------------------}
{==============================================================================}

const
  DefaultSettings: TAPKSettingsStruct = (
    GeneralSettings: (
      RunAtSystemStart:       True;
      TerminateForegroundWnd: True;
      TerminateByList:        True;
      TerminateUnresponsive:  True;
      ResponseTimeout:        1000;
      Shortcut:               $00030003);
    ProcListTerminate:      nil;
    ProcListNeverTerminate: nil);

{==============================================================================}
{   TAPKSettings - implementation                                              }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKSettings - private methods                                             }
{------------------------------------------------------------------------------}

Function TAPKSettings.GetSettingsPtr: PAPKSettingsStruct;
begin
Result := Addr(fSettings);
end;

{------------------------------------------------------------------------------}
{   TAPKSettings - public methods                                              }
{------------------------------------------------------------------------------}

const
  TaskName    = WideString('AppKiller 3 autorun');
  TaskComment = WideString('Automatic starting of AppKiller at system startup (user logon).');

//------------------------------------------------------------------------------

class Function TAPKSettings.RunAtSystemStartIsActive: Boolean;
var
  TaskScheduler:  ITaskScheduler;
  Task:           ITask;
begin
Result := False;
If Succeeded(CoInitialize(nil)) then
try
  If Succeeded(CoCreateInstance(CLSID_CTaskScheduler,nil,CLSCTX_INPROC_SERVER,IID_ITaskScheduler,TaskScheduler)) then
  try
    Result := Succeeded(TaskScheduler.Activate(LPCWSTR(TaskName),@IID_ITask,@Task));
    Task := nil;  // Task.Release
  finally
    TaskScheduler := nil; // TaskScheduler.Release
  end;
finally
  CoUninitialize;
end;
end;

//------------------------------------------------------------------------------

class Function TAPKSettings.RunAtSystemStartDelete: Boolean;
var
  TaskScheduler:  ITaskScheduler;
begin
Result := False;
If Succeeded(CoInitialize(nil)) then
try
  If Succeeded(CoCreateInstance(CLSID_CTaskScheduler,nil,CLSCTX_INPROC_SERVER,IID_ITaskScheduler,TaskScheduler)) then
  try
    Result := Succeeded(TaskScheduler.Delete(LPCWSTR(TaskName)));
  finally
    TaskScheduler := nil; // TaskScheduler.Release
  end;
finally
  CoUninitialize;
end;
end;

//------------------------------------------------------------------------------

class Function TAPKSettings.RunAtSystemStartActivate: Boolean;
var
  TaskScheduler:  ITaskScheduler;
  Task:           ITask;
  PersistFile:    IPersistFile;
  TriggerID:      Word;
  Trigger:        ITaskTrigger;
  TriggerData:    TASK_TRIGGER;
  CurrDate:       TDateTime;
begin
Result := False;
If Succeeded(CoInitialize(nil)) then
try
  If Succeeded(CoCreateInstance(CLSID_CTaskScheduler,nil,CLSCTX_INPROC_SERVER,IID_ITaskScheduler,TaskScheduler)) then
  try
    If Succeeded(TaskScheduler.NewWorkItem(LPCWSTR(TaskName),@CLSID_Ctask,@IID_ITask,@Task)) then
      try
        Task.SetApplicationName(LPCWSTR(StrToWide(RTLToStr(ParamStr(0)))));
        Task.SetWorkingDirectory(LPCWSTR(StrToWide(ExtractFilePath(RTLToStr(ParamStr(0))))));
        Task.SetComment(LPCWSTR(TaskComment));
        Task.SetFlags(TASK_FLAG_RUN_ONLY_IF_LOGGED_ON);
        Task.SetAccountInformation(LPCWSTR(GetAccountName),nil);
        If Succeeded(Task.CreateTrigger(@TriggerID,@Trigger)) then
        try
          FillChar({%H-}TriggerData,SizeOf(TriggerData),0);
          TriggerData.cbTriggerSize := SizeOf(TriggerData);
          CurrDate := Now;
          TriggerData.wBeginYear := YearOf(CurrDate);
          TriggerData.wBeginMonth := MonthOf(CurrDate);
          TriggerData.wBeginDay := DayOf(CurrDate);
          TriggerData.TriggerType := TASK_EVENT_TRIGGER_AT_LOGON;
          Trigger.SetTrigger(@TriggerData);
          If Succeeded(Task.QueryInterface(IID_IPersistFile,PersistFile)) then
          try
            Result := Succeeded(PersistFile.Save(nil,True));
          finally
            PersistFile := nil; // PersistFile.Release
          end;
        finally
          Trigger := nil; // Trigger.Release
        end;
      finally
        Task := nil; //Task.Release
      end;
  finally
    TaskScheduler := nil; // TaskScheduler.Release
  end;
finally
  CoUninitialize;
end;
end;

//------------------------------------------------------------------------------

constructor TAPKSettings.Create;
begin
inherited Create;
LoadDefaultSettings;
end;

//------------------------------------------------------------------------------

constructor TAPKSettings.CreateCopy(Source: TAPKSettings);
var
  i:  Integer;
begin
inherited Create;
fSettings.GeneralSettings := Source.Settings.GeneralSettings;
SetLength(fSettings.ProcListTerminate,Length(Source.Settings.ProcListTerminate));
For i := Low(fSettings.ProcListTerminate) to High(fSettings.ProcListTerminate) do
  begin
    fSettings.ProcListTerminate[i] := Source.Settings.ProcListTerminate[i];
    UniqueString(fSettings.ProcListTerminate[i].ProcessName);
  end;
SetLength(fSettings.ProcListNeverTerminate,Length(Source.Settings.ProcListNeverTerminate));
For i := Low(fSettings.ProcListNeverTerminate) to High(fSettings.ProcListNeverTerminate) do
  begin
    fSettings.ProcListNeverTerminate[i] := Source.Settings.ProcListNeverTerminate[i];
    UniqueString(fSettings.ProcListNeverTerminate[i].ProcessName);
  end;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.LoadDefaultSettings;
begin
fSettings := DefaultSettings;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.SaveToIni(const FileName: String);
var
  Ini:  TMemIniFile;
  i:    Integer;
begin
Ini := TMemIniFile.Create(FileName);
try
  Ini.WriteBool('Settings','RunAtSystemStart',fSettings.GeneralSettings.RunAtSystemStart);
  Ini.WriteBool('Settings','TerminateForegroundWnd',fSettings.GeneralSettings.TerminateForegroundWnd);
  Ini.WriteBool('Settings','TerminateByList',fSettings.GeneralSettings.TerminateByList);
  Ini.WriteBool('Settings','TerminateUnresponsive',fSettings.GeneralSettings.TerminateUnresponsive);
  Ini.WriteInteger('Settings','ResponseTimeout',fSettings.GeneralSettings.ResponseTimeout);
  Ini.WriteString('Settings','Shortcut',IntToHex(fSettings.GeneralSettings.Shortcut,8));
  Ini.WriteInteger('ProcListTerminate','Count',Length(fSettings.ProcListTerminate));
  For i := Low(fSettings.ProcListTerminate) to High(fSettings.ProcListTerminate) do
    begin
      Ini.WriteBool('ProcListTerminate',Format('Item[%d].Active',[i]),fSettings.ProcListTerminate[i].Active);
      Ini.WriteString('ProcListTerminate',Format('Item[%d].ProcessName',[i]),fSettings.ProcListTerminate[i].ProcessName);
    end;
  i := Length(fSettings.ProcListTerminate);
  while Ini.ValueExists('ProcListTerminate',Format('Item[%d].Active',[i])) or
    Ini.ValueExists('ProcListTerminate',Format('Item[%d].ProcessName',[i])) do
    begin
      Ini.DeleteKey('ProcListTerminate',Format('Item[%d].Active',[i]));
      Ini.DeleteKey('ProcListTerminate',Format('Item[%d].ProcessName',[i]));
      Inc(i);
    end; 
  Ini.WriteInteger('ProcListNeverTerminate','Count',Length(fSettings.ProcListNeverTerminate));
  For i := Low(fSettings.ProcListNeverTerminate) to High(fSettings.ProcListNeverTerminate) do
    begin
      Ini.WriteBool('ProcListNeverTerminate',Format('Item[%d].Active',[i]),fSettings.ProcListNeverTerminate[i].Active);
      Ini.WriteString('ProcListNeverTerminate',Format('Item[%d].ProcessName',[i]),fSettings.ProcListNeverTerminate[i].ProcessName);
    end;
  i := Length(fSettings.ProcListNeverTerminate);
  while Ini.ValueExists('ProcListNeverTerminate',Format('Item[%d].Active',[i])) or
    Ini.ValueExists('ProcListNeverTerminate',Format('Item[%d].ProcessName',[i])) do
    begin
      Ini.DeleteKey('ProcListNeverTerminate',Format('Item[%d].Active',[i]));
      Ini.DeleteKey('ProcListNeverTerminate',Format('Item[%d].ProcessName',[i]));
      Inc(i);
    end;
  Ini.UpdateFile;  
finally
  Ini.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.LoadFromIni(const FileName: String);
var
  Ini:  TMemIniFile;
  i:    Integer;
begin
Ini := TMemIniFile.Create(FileName);
try
  fSettings.GeneralSettings.RunAtSystemStart := Ini.ReadBool('Settings','RunAtSystemStart',DefaultSettings.GeneralSettings.RunAtSystemStart);
  fSettings.GeneralSettings.TerminateForegroundWnd := Ini.ReadBool('Settings','TerminateForegroundWnd',DefaultSettings.GeneralSettings.TerminateForegroundWnd);
  fSettings.GeneralSettings.TerminateByList := Ini.ReadBool('Settings','TerminateByList',DefaultSettings.GeneralSettings.TerminateByList);
  fSettings.GeneralSettings.TerminateUnresponsive := Ini.ReadBool('Settings','TerminateUnresponsive',DefaultSettings.GeneralSettings.TerminateUnresponsive);
  fSettings.GeneralSettings.ResponseTimeout := Ini.ReadInteger('Settings','ResponseTimeout',DefaultSettings.GeneralSettings.ResponseTimeout);
  fSettings.GeneralSettings.Shortcut := StrToIntDef('$' + Ini.ReadString('Settings','Shortcut',IntToHex(DefaultSettings.GeneralSettings.Shortcut,8)),DefaultSettings.GeneralSettings.Shortcut);
  SetLength(fSettings.ProcListTerminate,Ini.ReadInteger('ProcListTerminate','Count',0));
  For i := Low(fSettings.ProcListTerminate) to High(fSettings.ProcListTerminate) do
    begin
      fSettings.ProcListTerminate[i].Active := Ini.ReadBool('ProcListTerminate',Format('Item[%d].Active',[i]),False);
      fSettings.ProcListTerminate[i].ProcessName := Ini.ReadString('ProcListTerminate',Format('Item[%d].ProcessName',[i]),'');
    end;
  SetLength(fSettings.ProcListNeverTerminate,Ini.ReadInteger('ProcListNeverTerminate','Count',0));
  For i := Low(fSettings.ProcListNeverTerminate) to High(fSettings.ProcListNeverTerminate) do
    begin
      fSettings.ProcListNeverTerminate[i].Active := Ini.ReadBool('ProcListNeverTerminate',Format('Item[%d].Active',[i]),False);
      fSettings.ProcListNeverTerminate[i].ProcessName := Ini.ReadString('ProcListNeverTerminate',Format('Item[%d].ProcessName',[i]),'');
    end;
finally
  Ini.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.Save(Final: Boolean);
begin
SaveToIni(ExtractFilePath(RTLToStr(ParamStr(0))) + 'AppKiller.ini');
If Final then
  begin
    If fSettings.GeneralSettings.RunAtSystemStart then
      begin
        If RunAtSystemStartIsActive then
          RunAtSystemStartdelete;
        RunAtSystemStartActivate;
      end
    else RunAtSystemStartDelete;
  end;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.Load;
begin
LoadFromIni(ExtractFilePath(RTLToStr(ParamStr(0))) + 'AppKiller.ini');
end;

//------------------------------------------------------------------------------

Function TAPKSettings.GetShortcut: TAPKShortcut;
begin
Result.MainKey := fSettings.GeneralSettings.Shortcut shr 16;
Result.ShiftStates := [];
If fSettings.GeneralSettings.Shortcut and 1 <> 0 then
  Include(Result.ShiftStates,kssControl);
If fSettings.GeneralSettings.Shortcut and 2 <> 0 then
  Include(Result.ShiftStates,kssAlt);
If fSettings.GeneralSettings.Shortcut and 4 <> 0 then
  Include(Result.ShiftStates,kssShift);
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.SetShortcut(Shortcut: TAPKShortcut);
begin
fSettings.GeneralSettings.Shortcut := Shortcut.MainKey shl 16;
If kssControl in Shortcut.ShiftStates then
  fSettings.GeneralSettings.Shortcut := fSettings.GeneralSettings.Shortcut or 1;
If kssAlt in Shortcut.ShiftStates then
  fSettings.GeneralSettings.Shortcut := fSettings.GeneralSettings.Shortcut or 2;
If kssShift in Shortcut.ShiftStates then
  fSettings.GeneralSettings.Shortcut := fSettings.GeneralSettings.Shortcut or 4;
end;

end.

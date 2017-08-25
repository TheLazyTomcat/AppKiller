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
    fSettings:      TAPKSettingsStruct;
    fWinVistaPlus:  Boolean;
    Function GetSettingsPtr: PAPKSettingsStruct;
  public
    class Function RunAtSystemStartDelete_TS1: Boolean; virtual;
    class Function RunAtSystemStartAdd_TS1: Boolean; virtual;
    class Function RunAtSystemStartDelete_TS2: Boolean; virtual;
    class Function RunAtSystemStartAdd_TS2: Boolean; virtual;
    constructor Create;
    constructor CreateCopy(Source: TAPKSettings);
    procedure LoadDefaultSettings; virtual;
    procedure SaveToIni(const FileName: String); virtual;
    procedure LoadFromIni(const FileName: String); virtual;
    procedure Save(Final: Boolean); virtual;
    procedure Load; virtual;
    Function RunAtSystemStartDelete: Boolean; virtual;
    Function RunAtSystemStartAdd: Boolean; virtual;
    Function GetShortcut: TAPKShortcut; virtual;
    procedure SetShortcut(Shortcut: TAPKShortcut); virtual;
    property Settings: TAPKSettingsStruct read fSettings;
    property SettingsPtr: PAPKSettingsStruct read GetSettingsPtr;
  end;

implementation

uses
  Windows, SysUtils, IniFiles, ActiveX, Variants, DateUtils,
  RawInputKeyboard, StrRect, WinTaskScheduler,
  APK_Strings, APK_System;

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

class Function TAPKSettings.RunAtSystemStartDelete_TS1: Boolean;
var
  TaskScheduler:  ITaskScheduler;
begin
Result := False;
If Succeeded(CoInitialize(nil)) then
try
  If Succeeded(CoCreateInstance(CLSID_CTaskScheduler,nil,CLSCTX_INPROC_SERVER,IID_ITaskScheduler,TaskScheduler)) then
  try
    Result := Succeeded(TaskScheduler.Delete(LPCWSTR(APKSTR_ST_TaskName)));
  finally
    TaskScheduler := nil; // TaskScheduler.Release
  end;
finally
  CoUninitialize;
end;
end;

//------------------------------------------------------------------------------

class Function TAPKSettings.RunAtSystemStartAdd_TS1: Boolean;
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
    TaskScheduler.Delete(APKSTR_ST_TaskName); // if the task already exists, remove it
    If Succeeded(TaskScheduler.NewWorkItem(LPCWSTR(APKSTR_ST_TaskName),@CLSID_Ctask,@IID_ITask,@Task)) then
      try
        Task.SetApplicationName(LPCWSTR(StrToWide(RTLToStr(ParamStr(0)))));
        Task.SetWorkingDirectory(LPCWSTR(StrToWide(ExtractFilePath(RTLToStr(ParamStr(0))))));
        Task.SetComment(LPCWSTR(APKSTR_ST_TaskComment));
        Task.SetFlags(TASK_FLAG_RUN_ONLY_IF_LOGGED_ON);
        Task.SetAccountInformation(LPCWSTR(GetAccountName),nil);
        Task.SetMaxRunTime(INFINITE);
        If Succeeded(Task.CreateTrigger(@TriggerID,@Trigger)) then
        try
          FillChar({%H-}TriggerData,SizeOf(TriggerData),0);
          TriggerData.cbTriggerSize := SizeOf(TriggerData);
          CurrDate := Now;
          TriggerData.wBeginYear := YearOf(CurrDate);
          TriggerData.wBeginMonth := MonthOf(CurrDate);
          TriggerData.wBeginDay := DayOf(CurrDate);
          TriggerData.TriggerType := TASK_EVENT_TRIGGER_AT_LOGON;
          If Succeeded(Trigger.SetTrigger(@TriggerData)) then
            If Succeeded(Task.QueryInterface(IID_IPersistFile,PersistFile)) then
            try
              Result := Succeeded(PersistFile.Save(nil,True));
            finally
              PersistFile := nil;
            end;
        finally
          Trigger := nil;
        end;
      finally
        Task := nil;
      end;
  finally
    TaskScheduler := nil;
  end;
finally
  CoUninitialize;
end;
end;

//------------------------------------------------------------------------------

class Function TAPKSettings.RunAtSystemStartDelete_TS2: Boolean;
var
  TaskService:  ITaskService;
  RootFolder:   ITaskFolder;
begin
Result := False;
If Succeeded(CoInitialize(nil)) then
try
  If Succeeded(CoInitializeSecurity(nil,-1,nil,nil,RPC_C_AUTHN_LEVEL_PKT_PRIVACY,RPC_C_IMP_LEVEL_IMPERSONATE,nil,0,nil)) then
    If Succeeded(CoCreateInstance(CLSID_TaskScheduler,nil,CLSCTX_INPROC_SERVER,IID_ITaskService,TaskService)) then
    try
      If Succeeded(TaskService.Connect('','','','')) then
        If Succeeded(TaskService.GetFolder(BSTR(WideString('\')),@RootFolder)) then
        try
          Result := Succeeded(RootFolder.DeleteTask(BSTR(APKSTR_ST_TaskName),0));
        finally
          RootFolder := nil;
        end;
    finally
      TaskService := nil;
    end;
finally
  CoUninitialize;
end;
end;

//------------------------------------------------------------------------------

class Function TAPKSettings.RunAtSystemStartAdd_TS2: Boolean;
var
  TaskService:    ITaskService;
  RootFolder:     ITaskFolder;
  Task:           ITaskDefinition;
  RegInfo:        IRegistrationInfo;
  Settings:       ITaskSettings;
  Triggers:       ITriggerCollection;
  Trigger:        ITrigger;
  LogonTrigger:   ILogonTrigger;
  Actions:        IActionCollection;
  Action:         IAction;
  ExecAction:     IExecAction;
  Principal:      IPrincipal;
  RegisteredTask: IRegisteredTask;
begin
Result := False;
If Succeeded(CoInitialize(nil)) then
try
  If Succeeded(CoInitializeSecurity(nil,-1,nil,nil,RPC_C_AUTHN_LEVEL_PKT_PRIVACY,RPC_C_IMP_LEVEL_IMPERSONATE,nil,0,nil)) then
    If Succeeded(CoCreateInstance(CLSID_TaskScheduler,nil,CLSCTX_INPROC_SERVER,IID_ITaskService,TaskService)) then
    try
      If Succeeded(TaskService.Connect('','','','')) then
        If Succeeded(TaskService.GetFolder(BSTR(StrToWide('\')),@RootFolder)) then
        try
          RootFolder.DeleteTask(BSTR(APKSTR_ST_TaskName),0);
          If Succeeded(TaskService.NewTask(0,@Task)) then
          try
            // fill registration information
            RegInfo := Task.RegistrationInfo;
            try
              RegInfo.Author := BSTR(StrToWide('AppKiller 3'));
              RegInfo.Description := BSTR(APKSTR_ST_TaskComment);
              RegInfo.Date := BSTR(StrToWide(FormatDateTime('YYYY-MM-DD"T"HH:NN:SS',Now)));
            finally
              RegInfo := nil;
            end;
            // fill task settings
            Settings := Task.Settings;
            try
              Settings.AllowDemandStart := True;
              Settings.StopIfGoingOnBatteries := False;
              Settings.DisallowStartIfOnBatteries := False;
              Settings.AllowHardTerminate := False;
              Settings.ExecutionTimeLimit := BSTR(StrToWide('PT0S'));
              Settings.Enabled := True;
            finally
              Settings := nil;
            end;
            // create and set up trigger
            Triggers := Task.Triggers;
            try
              If Succeeded(Triggers.Create(TASK_TRIGGER_LOGON,@Trigger)) then
              try
                If Succeeded(Trigger.QueryInterface(IID_ILogonTrigger,LogonTrigger)) then
                try
                  LogonTrigger.UserId := BSTR(GetAccountName);
                  LogonTrigger.Enabled := True;
                finally
                  LogonTrigger := nil;
                end;
              finally
                Trigger := nil;
              end;
            finally
              Triggers := nil;  // release
            end;
            // create and set up action
            Actions := Task.Actions;
            try
              If Succeeded(Actions.Create(TASK_ACTION_EXEC,@Action)) then
              try
                If Succeeded(Action.QueryInterface(IID_IExecAction,ExecAction)) then
                try
                  ExecAction.Path := BSTR(StrToWide(RTLToStr(ParamStr(0))));
                  ExecAction.WorkingDirectory := BSTR(StrToWide(ExtractFilePath(RTLToStr(ParamStr(0)))));
                finally
                  ExecAction := nil;
                end;
              finally
                Action := nil;
              end;
            finally
              Actions := nil;
            end;
            // set up principal
            Principal := Task.Principal;
            try
              Principal.RunLevel := TASK_RUNLEVEL_HIGHEST;
              Principal.LogonType := TASK_LOGON_GROUP;
            finally
              Principal := nil;
            end;
            // register the task
            If Succeeded(RootFolder.RegisterTaskDefinition(
              BSTR(APKSTR_ST_TaskName),Task,LONG(TASK_CREATE_OR_UPDATE),
              'Builtin\Administrators',null,TASK_LOGON_GROUP,'',@RegisteredTask)) then
            try
              Result := True;
            finally
              RegisteredTask := nil;
            end;
          finally
            Task := nil;
          end;
        finally
          RootFolder := nil;
        end;
    finally
      TaskService := nil;
    end;
finally
  CoUninitialize;
end;
end;

//==============================================================================

constructor TAPKSettings.Create;
begin
inherited Create;
fWinVistaPlus := Win32MajorVersion >= 6;
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
If Final then
  begin
    If fSettings.GeneralSettings.RunAtSystemStart then
      begin
        If not RunAtSystemStartAdd then
          fSettings.GeneralSettings.RunAtSystemStart := False;
      end
    else RunAtSystemStartDelete;
  end;
SaveToIni(ExtractFilePath(RTLToStr(ParamStr(0))) + 'AppKiller.ini');
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

//------------------------------------------------------------------------------

Function TAPKSettings.RunAtSystemStartDelete: Boolean;
begin
If fWinVistaPlus then
  Result := RunAtSystemStartDelete_TS2
else
  Result := RunAtSystemStartDelete_TS1;
end;

//------------------------------------------------------------------------------

Function TAPKSettings.RunAtSystemStartAdd: Boolean;
begin
If fWinVistaPlus then
  Result := RunAtSystemStartAdd_TS2
else
  Result := RunAtSystemStartAdd_TS1;
end;

end.

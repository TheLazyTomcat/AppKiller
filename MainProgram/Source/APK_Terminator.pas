unit APK_Terminator;

{$INCLUDE APK_Defs.inc}

interface

uses
  Classes,
  APK_Settings;

type
  TAPKLogWriteEvent = procedure(Sender: TObject; const Text: String) of object;

  TAPKTerminatorThread = class(TThread)
  private
    fTerminatingList: TStringList;
    fLocalSettings:   TAPKSettings;
    fOnEnd:           TNotifyEvent;
    fOnLogWriteText:  String;
    fOnLogWrite:      TAPKLogWriteEvent;
  protected
    procedure sync_LogWrite; virtual;
    procedure sync_End; virtual;
    procedure WriteToLog(const Text: String); virtual;
    Function GetProcessName(ProcessHandle: THandle; out ProcessName: String): Boolean; virtual;
    Function IsInTerminatingList(const ProcessName: String): Boolean; virtual;
    Function IsInTerminateList(const ProcessName: String): Boolean; virtual;
    Function IsInNeverTerminateList(const ProcessName: String): Boolean; virtual;
    procedure TerminateForegroundWindow; virtual;
    procedure TerminateList; virtual;
    procedure TerminateUnresponsive; virtual;
    procedure Execute; override;
  public
    constructor Create(Settings: TAPKSettings);
    destructor Destroy; override;
    procedure StartTermination; virtual;
  published
    property OnEnd: TNotifyEvent read fOnEnd write fOnEnd;
    property OnLogWrite: TAPKLogWriteEvent read fOnLogWrite write fOnLogWrite;
  end;

  TAPKTerminatorState = (tsReady,tsWorking);

  TAPKTerminator = class(TObject)
  private
    fState:       TAPKTerminatorState;
    fWorkThread:  TAPKTerminatorThread;
    fOnLogWrite:  TAPKLogWriteEvent;
  protected
    procedure ThreadEndHandler(Sender: TObject); virtual;
    procedure LogWriteHandler(Sender: TObject; const Text: String); virtual;
    procedure FreeWorkingThread; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    Function StartTermination(Settings: TAPKSettings): Boolean; virtual;
  published
    property State: TAPKTerminatorState read fState;
    property OnLogWrite: TAPKLogWriteEvent read fOnLogWrite write fOnLogWrite;
  end;

implementation

uses
  Windows, Messages, PSApi, SysUtils,
  APK_ProcEnum;

procedure TAPKTerminatorThread.sync_LogWrite;
begin
If Assigned(fOnLogWrite) then fOnLogWrite(Self,fOnLogWriteText);
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.sync_End;
begin
If Assigned(fOnEnd) then fOnEnd(Self);
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.WriteToLog(const Text: String);
begin
fOnLogWriteText := Text;
Synchronize(sync_LogWrite);
end;

//------------------------------------------------------------------------------

Function TAPKTerminatorThread.GetProcessName(ProcessHandle: THandle; out ProcessName: String): Boolean;
begin
Result := False;
SetLength(ProcessName,MAX_PATH);
If GetModuleFileNameEx(ProcessHandle,0,PChar(ProcessName),Length(ProcessName)) > 0 then
  begin
    SetLength(ProcessName,StrLen(PChar(ProcessName)));
  {$IF Defined(FPC) and not Defined(Unicode)}
    ProcessName := ExtractFileName(WinCPToUTF8(ProcessName));
  {$ELSE}
    ProcessName := ExtractFileName(ProcessName);
  {$IFEND}
    Result := ProcessName <> '';
  end;
end;

//------------------------------------------------------------------------------

Function TAPKTerminatorThread.IsInTerminatingList(const ProcessName: String): Boolean;
begin
Result := fTerminatingList.IndexOf(ProcessName) >= 0;
end;

//------------------------------------------------------------------------------

Function TAPKTerminatorThread.IsInTerminateList(const ProcessName: String): Boolean;
var
  i:  Integer;
begin
Result := False;
with fLocalSettings.Settings do
  begin
    For i := Low(ProcListTerminate) to High(ProcListTerminate) do
      If AnsiSameText(ProcessName,ProcListTerminate[i].ProcessName) and
        ProcListTerminate[i].Active then
        begin
          Result := True;
          Break{For i};
        end;
  end;
end;

//------------------------------------------------------------------------------

Function TAPKTerminatorThread.IsInNeverTerminateList(const ProcessName: String): Boolean;
var
  i:  Integer;
begin
Result := False;
with fLocalSettings.Settings do
  begin
    For i := Low(ProcListNeverTerminate) to High(ProcListNeverTerminate) do
      If AnsiSameText(ProcessName,ProcListNeverTerminate[i].ProcessName) and
        ProcListNeverTerminate[i].Active then
        begin
          Result := True;
          Break{For i};
        end;
  end;
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.TerminateForegroundWindow;
var
  ForegroundWindow: HWND;
  ProcessID:        DWORD;
  ProcessHandle:    THandle;
  ProcessName:      String;
begin
ForegroundWindow := GetForegroundWindow;
If ForegroundWindow <> 0 then
  begin
    GetWindowThreadProcessId(ForegroundWindow,ProcessID);
    ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ or PROCESS_TERMINATE,False,ProcessID);
    If ProcessHandle <> 0 then
      try
        If GetProcessName(ProcessHandle,ProcessName) then
          begin
            If not IsInTerminatingList(ProcessName) and not IsInNeverTerminateList(ProcessName) then
              begin
                fTerminatingList.Add(ProcessName);
                If TerminateProcess(ProcessHandle,0) then
                  WriteToLog(Format('TFW: Terminated process - %s (%d)',[ProcessName,ProcessID]));
              end;
          end
        else WriteToLog('TFW: <ERROR> - Cannot obtain process name.');
      finally
        CloseHandle(ProcessHandle)
      end
    else WriteToLog('TFW: <ERROR> - Cannot obtain process handle.');
  end
else WriteToLog('TFW: <ERROR> - Cannot obtain handle to foreground window.');
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.TerminateList;
var
  Enumerator:     TAPKProcessEnumerator;
  i:              Integer;
  ProcessHandle:  THandle;
begin
Enumerator := TAPKProcessEnumerator.Create;
try
  Enumerator.Enumerate(False,False);
  For i := 0 to Pred(Enumerator.ProcessCount) do
    begin
      If IsInTerminateList(Enumerator[i].ProcessName) and
         not IsInTerminatingList(Enumerator[i].ProcessName) and
         not IsInNeverTerminateList(Enumerator[i].ProcessName) then
        begin
          ProcessHandle := OpenProcess(PROCESS_TERMINATE,False,Enumerator[i].ProcessID);
          If ProcessHandle <> 0 then
            try
              fTerminatingList.Add(Enumerator[i].ProcessName);
              If TerminateProcess(ProcessHandle,0) then
                WriteToLog(Format('TPL: Terminated process - %s (%d)',[Enumerator[i].ProcessName,Enumerator[i].ProcessID]));
            finally
              CloseHandle(ProcessHandle);
            end
          else WriteToLog(Format('TPL: <ERROR> - Cannot obtain handle to process - %s (%d).',
                                 [Enumerator[i].ProcessName,Enumerator[i].ProcessID]));
        end;
    end;
finally
  Enumerator.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.TerminateUnresponsive;
type
  TWindowHandles = array of HWND;
  PWindowHandles = ^TWindowHandles;
var
  Windows:        TWindowHandles;
  i:              Integer;
  MsgResult:      DWORD;
  ProcessID:      DWORD;
  ProcessHandle:  THandle;
  ProcessName:    String;
  TerminatingID:  array of DWORD;

  Function EnumWindowsCallback(hwnd: HWND; lParam: LPARAM): BOOL; stdcall;
  begin
    Result := True;
    If hwnd <> 0 then
      begin
        SetLength(PWindowHandles(lParam)^,Length(PWindowHandles(lParam)^) + 1);
        PWindowHandles(lParam)^[High(PWindowHandles(lParam)^)] := hwnd;
      end
  end;

  Function IsInTerminatingIDList(PID: DWORD): Boolean;
  var
    ii: Integer;
  begin
    Result := False;
    For ii := Low(TerminatingID) to High(TerminatingID) do
      If TerminatingID[ii] = PID then
        begin
          Result := True;
          Break{For ii};
        end;
  end;

begin
If EnumWindows(@EnumWindowsCallback,LPARAM(@Windows)) then
  For i := Low(Windows) to High(Windows) do
    begin
      If SendMessageTimeout(Windows[i],WM_NULL,0,0,SMTO_ABORTIFHUNG or SMTO_BLOCK,fLocalSettings.Settings.GeneralSettings.ResponseTimeout,MsgResult) = 0 then
        begin
          GetWindowThreadProcessId(Windows[i],ProcessID);
          If not IsInTerminatingIDList(ProcessID) then
            begin
              ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ or PROCESS_TERMINATE,False,ProcessID);
              If ProcessHandle <> 0 then
                try
                  If GetProcessName(ProcessHandle,ProcessName) then
                    begin
                      If not IsInTerminatingList(ProcessName) and not IsInNeverTerminateList(ProcessName) then
                        begin
                          fTerminatingList.Add(ProcessName);
                          SetLength(TerminatingID,Length(TerminatingID) + 1);
                          TerminatingID[High(TerminatingID)] := ProcessID;
                          If TerminateProcess(ProcessHandle,0) then
                            WriteToLog(Format('TUP: Terminated process - %s (%d)',[ProcessName,ProcessID]));
                        end;
                    end
                  else WriteToLog('TUP: <ERROR> - Cannot obtain process name.')
                finally
                  CloseHandle(ProcessHandle);
                end
              else WriteToLog('TUP: <ERROR> - Cannot obtain process handle.' + inttostr(processid));
            end;
        end;
    end;
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.Execute;
begin
If fLocalSettings.Settings.GeneralSettings.TerminateForegroundWnd and not Terminated then
  TerminateForegroundWindow;
If fLocalSettings.Settings.GeneralSettings.TerminateByList and not Terminated then
  TerminateList;
If fLocalSettings.Settings.GeneralSettings.TerminateUnresponsive and not Terminated then
  TerminateUnresponsive;
Synchronize(sync_End);
end;

//==============================================================================

constructor TAPKTerminatorThread.Create(Settings: TAPKSettings);
begin
inherited Create(True);
FreeOnTerminate := False;
fTerminatingList := TStringList.Create;
fLocalSettings := TAPKSettings.CreateCopy(Settings);
end;

//------------------------------------------------------------------------------

destructor TAPKTerminatorThread.Destroy;
begin
fLocalSettings.Free;
fTerminatingList.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.StartTermination;
begin
{$IFDEF DevMsgs}
  {$message 'D2010+ also deprecated Resume'}
{$ENDIF}
{$IFDEF FPC}
Start;
{$ELSE}
Resume;
{$ENDIF}
end;

//------------------------------------------------------------------------------
//==============================================================================
//------------------------------------------------------------------------------

procedure TAPKTerminator.ThreadEndHandler(Sender: TObject);
begin
fState := tsReady;
end;

//------------------------------------------------------------------------------

procedure TAPKTerminator.LogWriteHandler(Sender: TObject; const Text: String);
begin
If Assigned(fOnLogWrite) then fOnLogWrite(Self,Text);
end;

//------------------------------------------------------------------------------

procedure TAPKTerminator.FreeWorkingThread;
begin
If Assigned(fWorkThread) then
  begin
    fWorkThread.Terminate;
    fWorkThread.WaitFor;
    FreeAndNil(fWorkThread);
  end;
end;

//==============================================================================

constructor TAPKTerminator.Create;
begin
inherited Create;
fState := tsReady;
fWorkThread := nil;
end;

//------------------------------------------------------------------------------

destructor TAPKTerminator.Destroy;
begin
FreeWorkingThread;
inherited;
end;

//------------------------------------------------------------------------------

Function TAPKTerminator.StartTermination(Settings: TAPKSettings): Boolean;
begin
case fState of
  tsReady:
    begin
      FreeWorkingThread;
      fWorkThread := TAPKTerminatorThread.Create(Settings);
      fWorkThread.OnLogWrite := LogWriteHandler;
      fWorkThread.OnEnd := ThreadEndHandler;
      fWorkThread.StartTermination;
      fState := tsWorking;
      Result := True;
    end;
  tsWorking:
    Result := False;
else
  Result := False;
end;
end;

end.

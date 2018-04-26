{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit APK_Terminator;

{$INCLUDE APK_Defs.inc}

interface

uses
  Classes,
  APK_Settings;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                TAPKTerminator                                }
{------------------------------------------------------------------------------}
{==============================================================================}

type
  TAPKLogWriteEvent = procedure(Sender: TObject; const Text: String) of object;

  TAPKTerminatorState = (tsReady,tsWorking);

{==============================================================================}
{   TAPKTerminator - declaration                                               }
{==============================================================================}

  TAPKTerminator = class(TObject)
  private
    fState:       TAPKTerminatorState;
    fWorkThread:  TThread;
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
  Windows, Messages, SysUtils,{$IFDEF FPC} jwaPSApi{$ELSE} PSApi{$ENDIF}, 
  APK_ProcEnum, APK_System, StrRect, AuxTypes;

{$IFDEF FPC_DisableWarns}
  {$WARN 4055 OFF} // Conversion between ordinals and pointers is not portable
  {$WARN 5024 OFF} // Parameter "$1" not used
  {$WARN 5057 OFF} // Local variable "$1" does not seem to be initialized
{$ENDIF}

{==============================================================================}
{------------------------------------------------------------------------------}
{                             TAPKTerminatorThread                             }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKTerminatorThread - declaration                                         }
{==============================================================================}

type
  TAPKTerminatorThread = class(TThread)
  private
    fTerminatingList: array of DWORD;
    fLocalSettings:   TAPKSettings;
    fOnEnd:           TNotifyEvent;
    fOnLogWriteText:  String;
    fOnLogWrite:      TAPKLogWriteEvent;
  protected
    procedure sync_LogWrite; virtual;
    procedure sync_End; virtual;
    procedure WriteToLog(const Text: String); virtual;
    Function GetProcessName(ProcessHandle: THandle; out ProcessName: String): Boolean; virtual;
    Function TerminatingListIndexOf(ProcessID: DWORD): Integer; virtual;
    Function TerminatingListAdd(ProcessID: DWORD): Integer; virtual;
    procedure TerminatingListClear; virtual;
    Function IsInTerminatingList(ProcessID: DWORD): Boolean; virtual;
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

{==============================================================================}
{   TAPKTerminatorThread - implementation                                      }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKTerminatorThread - protected methods                                   }
{------------------------------------------------------------------------------}

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
    ProcessName := ExtractFileName(WinToStr(ProcessName));
    Result := ProcessName <> '';
  end;
end;
//------------------------------------------------------------------------------

Function TAPKTerminatorThread.TerminatingListIndexOf(ProcessID: DWORD): Integer;
var
  i:  Integer;
begin
For i := Low(fTerminatingList) to High(fTerminatingList) do
  If fTerminatingList[i] = ProcessID then
    begin
      Result := i;
      Exit;
    end;
Result := -1;
end;

//------------------------------------------------------------------------------

Function TAPKTerminatorThread.TerminatingListAdd(ProcessID: DWORD): Integer;
begin
SetLength(fTerminatingList,Length(fTerminatingList) + 1);
Result := High(fTerminatingList);
fTerminatingList[Result] := ProcessID;
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.TerminatingListClear;
begin
SetLength(fTerminatingList,0);
end;

//------------------------------------------------------------------------------

Function TAPKTerminatorThread.IsInTerminatingList(ProcessID: DWORD): Boolean;
begin
Result := TerminatingListIndexOf(ProcessID) >= 0;
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
    If not IsInTerminatingList(ProcessID) then
      begin
        ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ or PROCESS_TERMINATE,False,ProcessID);
        If ProcessHandle <> 0 then
          try
            If GetProcessName(ProcessHandle,ProcessName) then
              begin
                If not IsInNeverTerminateList(ProcessName) then
                  begin
                    TerminatingListAdd(ProcessID);
                    If TerminateProcess(ProcessHandle,0) then
                      WriteToLog(Format('TFW: Terminated process - %s [%d]',[ProcessName,ProcessID]));
                  end;
              end
            else WriteToLog(Format('TFW: <ERROR> - Cannot obtain process name (0x%.8x).',[GetLastError]));
          finally
            CloseHandle(ProcessHandle)
          end
        else WriteToLog(Format('TFW: <ERROR> - Cannot obtain process handle (0x%.8x).',[GetLastError]));
      end;
  end
else WriteToLog(Format('TFW: <ERROR> - Cannot obtain handle to foreground window (0x%.8x).',[GetLastError]));
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
         not IsInTerminatingList(Enumerator[i].ProcessID) and
         not IsInNeverTerminateList(Enumerator[i].ProcessName) then
        begin
          ProcessHandle := OpenProcess(PROCESS_TERMINATE,False,Enumerator[i].ProcessID);
          If ProcessHandle <> 0 then
            try
              TerminatingListAdd(Enumerator[i].ProcessID);
              If TerminateProcess(ProcessHandle,0) then
                WriteToLog(Format('TPL: Terminated process - %s [%d]',[Enumerator[i].ProcessName,Enumerator[i].ProcessID]));
            finally
              CloseHandle(ProcessHandle);
            end
          else WriteToLog(Format('TPL: <ERROR> - Cannot obtain handle to process - %s [%d] (0x%.8x).',
                                 [Enumerator[i].ProcessName,Enumerator[i].ProcessID,GetLastError]));
        end;
    end;
finally
  Enumerator.Free;
end;
end;

//------------------------------------------------------------------------------

type
  TWindowHandles = array of HWND;
  PWindowHandles = ^TWindowHandles;

Function EnumWindowsCallback(hwnd: HWND; lParam: LPARAM): BOOL; stdcall;
begin
  Result := False;
  If hwnd <> 0 then
    begin
      SetLength(PWindowHandles(lParam)^,Length(PWindowHandles(lParam)^) + 1);
      PWindowHandles(lParam)^[High(PWindowHandles(lParam)^)] := hwnd;
      Result := True;
    end;
end;

procedure TAPKTerminatorThread.TerminateUnresponsive;
var
  Windows:        TWindowHandles;
  i:              Integer;
  MsgResult:      PtrUInt;
  ProcessID:      DWORD;
  ProcessHandle:  THandle;
  ProcessName:    String;
begin
If EnumWindows(@EnumWindowsCallback,LPARAM(@Windows)) then
  For i := Low(Windows) to High(Windows) do
    begin
      If SendMessageTimeout(Windows[i],WM_NULL,0,0,SMTO_ABORTIFHUNG or SMTO_BLOCK,fLocalSettings.Settings.GeneralSettings.ResponseTimeout,@MsgResult) = 0 then
        begin
          ProcessID := 0;
          GetWindowThreadProcessId(Windows[i],ProcessID);
          If (ProcessID <> 0) and not IsInTerminatingList(ProcessID) then
            begin
              ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ or PROCESS_TERMINATE,False,ProcessID);
              If ProcessHandle <> 0 then
                try
                  If GetProcessName(ProcessHandle,ProcessName) then
                    begin
                      If not IsInNeverTerminateList(ProcessName) then
                        begin
                          TerminatingListAdd(ProcessID);
                          If TerminateProcess(ProcessHandle,0) then
                            WriteToLog(Format('TUP: Terminated process - %s [%d]',[ProcessName,ProcessID]));
                        end;
                    end
                  else WriteToLog(Format('TUP: <ERROR> - Cannot obtain process name (0x%.8x).',[GetLastError]))
                finally
                  CloseHandle(ProcessHandle);
                end
              else WriteToLog(Format('TUP: <ERROR> - Cannot obtain process handle [%d] (0x%.8x).',[ProcessID,GetLastError]));
            end;
        end;
    end;
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.Execute;
begin
TerminatingListClear;
If fLocalSettings.Settings.GeneralSettings.TerminateForegroundWnd and not Terminated then
  TerminateForegroundWindow;
If fLocalSettings.Settings.GeneralSettings.TerminateByList and not Terminated then
  TerminateList;
If fLocalSettings.Settings.GeneralSettings.TerminateUnresponsive and not Terminated then
  TerminateUnresponsive;
Synchronize(sync_End);
end;

{------------------------------------------------------------------------------}
{   TAPKTerminatorThread - protected methods                                   }
{------------------------------------------------------------------------------}

constructor TAPKTerminatorThread.Create(Settings: TAPKSettings);
begin
inherited Create(True);
FreeOnTerminate := False;
fLocalSettings := TAPKSettings.CreateCopy(Settings);
end;

//------------------------------------------------------------------------------

destructor TAPKTerminatorThread.Destroy;
begin
fLocalSettings.Free;
TerminatingListClear;
inherited;
end;

//------------------------------------------------------------------------------

procedure TAPKTerminatorThread.StartTermination;
begin
{$IF Defined(FPC) or (CompilerVersion >= 21)}
Start;
{$ELSE}
Resume;
{$IFEND}
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                                TAPKTerminator                                }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKTerminator - implementation                                            }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKTerminator - protected methods                                         }
{------------------------------------------------------------------------------}

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

{------------------------------------------------------------------------------}
{   TAPKTerminator - public methods                                            }
{------------------------------------------------------------------------------}

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
      TAPKTerminatorThread(fWorkThread).OnLogWrite := LogWriteHandler;
      TAPKTerminatorThread(fWorkThread).OnEnd := ThreadEndHandler;
      TAPKTerminatorThread(fWorkThread).StartTermination;
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

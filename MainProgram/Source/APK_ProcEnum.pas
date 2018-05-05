{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit APK_ProcEnum;

{$INCLUDE APK_Defs.inc}

interface

uses
  Windows, Graphics, Classes;

{==============================================================================}
{------------------------------------------------------------------------------}
{                             TAPKProcessEnumerator                            }
{------------------------------------------------------------------------------}
{==============================================================================}

type
  TAPKProcessBits = (pbUnknown,pb32bit,pb64bit);

  TAPKProcessEntry = record
    ProcessName:    String;
    ProcessID:      DWORD;
    ProcessBits:    TAPKProcessBits;
    ProcessPath:    String;
    Description:    String;
    CompanyName:    String;
    Icon:           TBitmap;
    LimitedAccess:  Boolean;
  end;

  TAPKProcessList = array of TAPKProcessEntry;

  TAPKEnumStage = (esReady,esEnumerating,esDone);

{==============================================================================}
{   TAPKProcessEnumerator - declaration                                        }
{==============================================================================}

  TAPKProcessEnumerator = class(TObject)
  private
    fProcesses:         TAPKProcessList;
    fEnumStage:         TAPKEnumStage;
    fEnumThread:        TThread;
    fIconBackground:    TColor;
    fOnEnumerationDone: TNotifyEvent;
    Function GetProcessCount: Integer;
    Function GetProcess(Index: Integer): TAPKProcessEntry;
  protected
    procedure ThreadEnumDoneHandler(Sender: TObject); virtual;
    procedure FreeEnumThread; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    Function IndexOf(const ProcessName: String): Integer; overload; virtual;
    Function IndexOf(const ProcessID: DWORD): Integer; overload; virtual;
    procedure Clear; virtual;
    procedure Enumerate(Threaded: Boolean; ObtainProcessImageInfo: Boolean = True); virtual;
    property Processes[Index: Integer]: TAPKProcessEntry read GetProcess; default;
  published
    property ProcessCount: Integer read GetProcessCount;
    property EnumStage: TAPKEnumStage read fEnumStage;
    property OnEnumerationDone: TNotifyEvent read fOnEnumerationDone write fOnEnumerationDone;
    property IconBackground: TColor read fIconBackground write fIconBackground;
  end;

{==============================================================================}
{   Auxiliary functions - declaration                                          }
{==============================================================================}

  Function ProcessBitsToString(ProcessBits: TAPKProcessBits): String;

implementation

uses
  SysUtils, StrUtils, {$IFDEF FPC} jwaTlHelp32{$ELSE} TlHelp32{$ENDIF},
  WinFileInfo, APK_System, StrRect;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
  {$PUSH}{$WARN 2005 OFF} // Comment level $1 found
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 30000)}
    {$DEFINE W5092:={$WARN 5092 OFF}} // Variable "$1" of a managed type does not seem to be initialized
  {$ELSE}
    {$DEFINE W5092:=}
  {$IFEND}
  {$POP}
{$ENDIF}

{==============================================================================}
{   Auxiliary functions - implementations                                      }
{==============================================================================}

Function ProcessBitsToString(ProcessBits: TAPKProcessBits): String;
begin
case ProcessBits of
  pb32bit:  Result := '32 bit';
  pb64bit:  Result := '64 bit';
else
 {pbUnknown}
  Result := 'unknown';
end;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                         TAPKProcessEnumeratorInternal                        }
{------------------------------------------------------------------------------}
{==============================================================================}

type
  TAPKDeviceEntry = record
    DrivePath:  String;
    DevicePath: String;
  end;

  TAPKDevicesList = array of TAPKDeviceEntry;

const
  IPE_RUNNING = 0;
  IPE_STOPPED = -1;

type
  TIsWoW64Process = Function(hProcess: THandle; Wow64Process: PBOOL): BOOL; stdcall;
  TWow64DisableWow64FsRedirection = Function(OldValue: PPointer): BOOL; stdcall;
  TWow64RevertWow64FsRedirection = Function(OldValue: Pointer): BOOL; stdcall;

{==============================================================================}
{   TAPKProcessEnumeratorInternal - declaration                                }
{==============================================================================}

  TAPKProcessEnumeratorInternal = class(TObject)
  private
    fEnumerationStopped:        Integer;
    fObtainProcessImageInfo:    Boolean;
    fIconBackground:            TColor;
    fProcesses:                 TAPKProcessList;
    fDevices:                   TAPKDevicesList;
    fFreeIcons:                 Boolean;
    fRunningInWin64:            Boolean;
    fIsWoW64ProcessProc:        Pointer;
    fDisableWoW64RedirectProc:  Pointer;
    fRevertWoW64RedirectProc:   Pointer;
    fWoW64RedirectValue:        Pointer;
    fOnEnumerationDone:         TNotifyEvent;
    Function GetEnumerationStopped: Boolean;
  protected
    procedure InitForWin64; virtual;
    Function DisableWoW64Redirection: Boolean; virtual;
    Function EnableWoW64Redirection: Boolean; virtual;
    procedure EnumerateDevices; virtual;
    Function GetProcessBits(ProcessHandle: THandle): TAPKProcessBits; virtual;
    Function GetProcessPath(ProcessHandle: THandle): String; virtual;
    Function ExtractIcon(const FileName: String): TBitmap; virtual;
    procedure GetProcessImageInfo(var ProcessEntry: TAPKProcessEntry); virtual;
  public
    constructor Create(IconBackground: TColor; ObtainProcessImageInfo: Boolean = True);
    destructor Destroy; override;
    procedure Enumerate; virtual;
    procedure FillProcessList(out List: TAPKProcessList); virtual;
    procedure StopEnumeration; virtual;
  published
    property EnumerationStopped: Boolean read GetEnumerationStopped;
    property OnEnumerationDone: TNotifyEvent read fOnEnumerationDone write fOnEnumerationDone;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                          TAPKProcessEnumeratorThread                         }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKProcessEnumeratorThread - declaration                                  }
{==============================================================================}

  TAPKProcessEnumeratorThread = class(TThread)
  private
    fEnumerator:        TAPKProcessEnumeratorInternal;
    fOnEnumerationDone: TNotifyEvent;
  protected
    procedure sync_DoEnumerationDone; virtual;
    procedure EnumerationDoneHandler(Sender: TObject); virtual;
    procedure Execute; override;
  public
    constructor Create(IconBackground: TColor; ObtainProcessImageInfo: Boolean = True);
    destructor Destroy; override;
    procedure Enumerate; virtual;
    procedure FillProcessList(out List: TAPKProcessList); virtual;
    procedure StopEnumeration; virtual;
  published
    property OnEnumerationDone: TNotifyEvent read fOnEnumerationDone write fOnEnumerationDone;
  end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                         TAPKProcessEnumeratorInternal                        }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKProcessEnumeratorInternal - implementation                             }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKProcessEnumeratorInternal - private methods                            }
{------------------------------------------------------------------------------}

Function TAPKProcessEnumeratorInternal.GetEnumerationStopped: Boolean;
begin
Result := InterlockedExchangeAdd(fEnumerationStopped,0) <> IPE_RUNNING;
end;

{------------------------------------------------------------------------------}
{   TAPKProcessEnumeratorInternal - protectec methods                          }
{------------------------------------------------------------------------------}

procedure TAPKProcessEnumeratorInternal.InitForWin64;
var
  ModuleHandle: THandle;
{$IFNDEF 64bit}
  ResultValue:  BOOL;
{$ENDIF}
begin
fRunningInWin64 := False;
ModuleHandle := GetModuleHandle('kernel32.dll');
If ModuleHandle <> 0 then
  begin
    fIsWoW64ProcessProc := GetProcAddress(ModuleHandle,'IsWow64Process');
  {$IFDEF 64bit}
    fRunningInWin64 := True;
  {$ELSE}
    If Assigned(fIsWoW64ProcessProc) then
      If TIsWoW64Process(fIsWoW64ProcessProc)(GetCurrentProcess,@ResultValue) then
        fRunningInWin64 := ResultValue;
  {$ENDIF}
    fDisableWoW64RedirectProc := GetProcAddress(ModuleHandle,'Wow64DisableWow64FsRedirection');
    fRevertWoW64RedirectProc := GetProcAddress(ModuleHandle,'Wow64RevertWow64FsRedirection');
  end
else raise Exception.CreateFmt('TProcessEnumeratorInternal.InitForWin64: Unable to load Kernell32.dll library (0x.8x).',[GetLastError]);
If not Assigned(fDisableWoW64RedirectProc) or not Assigned(fRevertWoW64RedirectProc) then
  begin
    fDisableWoW64RedirectProc := nil;
    fRevertWoW64RedirectProc := nil;
  end;
end;

//------------------------------------------------------------------------------

Function TAPKProcessEnumeratorInternal.EnableWoW64Redirection: Boolean;
begin
If Assigned(fDisableWoW64RedirectProc) and Assigned(fRevertWoW64RedirectProc) then
  Result := TWow64RevertWow64FsRedirection(fRevertWoW64RedirectProc)(fWoW64RedirectValue)
else Result := False;
end;

//------------------------------------------------------------------------------

Function TAPKProcessEnumeratorInternal.DisableWoW64Redirection: Boolean;
begin
If Assigned(fDisableWoW64RedirectProc) and Assigned(fRevertWoW64RedirectProc) then
  Result := TWow64DisableWow64FsRedirection(fDisableWoW64RedirectProc)(@fWoW64RedirectValue)
else Result := False;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5092{$ENDIF}
procedure TAPKProcessEnumeratorInternal.EnumerateDevices;
type
  AoStr = array of String;
var
  TempStr:      String;
  DrivePaths:   AoStr;
  DevicePaths:  AoStr;
  i,j:          Integer;
  ResLen:       DWORD;

  procedure ParseStrings(Str: String; out Paths: AoStr);
  var
    SubStrLen:  Integer;
  begin
    SetLength(Paths,0);
    repeat
      SubStrLen := StrLen(PChar(Str));
      If SubStrLen > 0 then
        begin
          SetLength(Paths,Length(Paths) + 1);
          Paths[High(Paths)] := Copy(Str,1,SubStrLen);
          Delete(Str,1,SubStrLen + 1);
        end;
    until SubStrLen <= 0;
  end;

begin
{$IFDEF DevMsgs}
  {$message 'Implement translation for network drives'}
{$ENDIF}  
SetLength(TempStr,GetLogicalDriveStrings(0,nil));
SetLength(TempStr,GetLogicalDriveStrings(Length(TempStr),PChar(TempStr)));
ParseStrings(WinToStr(TempStr),DrivePaths);
SetLength(fDevices,Length(DrivePaths));
For i := Low(DrivePaths) to High(DrivePaths) do
  begin
    fDevices[i].DrivePath := ExcludeTrailingPathDelimiter(DrivePaths[i]);
    SetLength(TempStr,0);
    repeat
      SetLength(TempStr,Length(TempStr) + 1024);
      ResLen := QueryDosDevice(PChar(StrToWin(fDevices[i].DrivePath)),PChar(TempStr),Length(TempStr));
    until GetLastError <> ERROR_INSUFFICIENT_BUFFER;
    SetLength(TempStr,ResLen);
    ParseStrings(WinToStr(TempStr),DevicePaths);
    If Length(DevicePaths) > 0 then
      fDevices[i].DevicePath := DevicePaths[Low(DevicePaths)]
    else
      fDevices[i].DevicePath := '';
  end;
// remove empty
For i := High(fDevices) downto Low(fDevices) do
  If (fDevices[i].DrivePath = '') or (fDevices[i].DevicePath = '') then
    begin
      For j := i to Pred(High(fDevices)) do
        fDevices[i] := fDevices[i + 1];
      SetLength(fDevices,Length(fDevices) - 1);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TAPKProcessEnumeratorInternal.GetProcessBits(ProcessHandle: THandle): TAPKProcessBits;
var
  ResultValue:  BOOL;
begin
If Assigned(fIsWow64ProcessProc) then
  begin
    If TIsWoW64Process(fIsWoW64ProcessProc)(ProcessHandle,@ResultValue) then
      begin
        If not ResultValue and fRunningInWin64 then
          Result := pb64bit
        else
          Result := pb32bit;
      end
    else Result := pbUnknown;
  end
else Result := pb32bit;
end;

//------------------------------------------------------------------------------

Function TAPKProcessEnumeratorInternal.GetProcessPath(ProcessHandle: THandle): String;
var
  i:  Integer;
begin
SetLength(Result,MAX_PATH + 1);
SetLength(Result,GetProcessImageFileName(ProcessHandle,PChar(Result),Length(Result)));
// number of chars copied into buffer can be larger than is actual length of the string...
If Length(Result) > 0 then
  SetLength(Result,StrLen(PChar(Result)));
Result := WinToStr(Result);
// translate from device path to drive path
If Length(Result) > 0 then
  For i := Low(fDevices) to High(fDevices) do
    If AnsiStartsText(fDevices[i].DevicePath,Result) then
      begin
        Result := fDevices[i].DrivePath + Copy(Result,Length(fDevices[i].DevicePath) + 1,Length(Result));
        Break{For i};
      end;
end;

//------------------------------------------------------------------------------

Function TAPKProcessEnumeratorInternal.ExtractIcon(const FileName: String): TBitmap;
var
  IconHandle: HICON;
begin
Result := nil;
If ExtractIconEx(PChar(StrToWin(FileName)),0,nil,@IconHandle,1) = 1 then
  If IconHandle <> 0 then
    begin
      Result := TBitmap.Create;
      try
        Result.Canvas.Lock;
        try
          Result.Width := GetSystemMetrics(SM_CXSMICON);
          Result.Height := GetSystemMetrics(SM_CYSMICON);
          Result.Canvas.Brush.Color := fIconBackground;
          Result.Canvas.Brush.Style := bsSolid;
          Result.Canvas.FillRect(Rect(0,0,Result.Width,Result.Height));
          If not DrawIconEx(Result.Canvas.Handle,0,0,IconHandle,Result.Width,Result.Height,0,0,DI_NORMAL) then
            FreeAndNil(Result);
         finally
           Result.Canvas.Unlock;
         end;
      except
        FreeAndNil(Result);
      end;
    end;
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumeratorInternal.GetProcessImageInfo(var ProcessEntry: TAPKProcessEntry);
var
  ProcessHandle:  THandle;
  i,Index:        Integer;
begin
If Win32MajorVersion >= 6 then
  ProcessHandle := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION,False,ProcessEntry.ProcessID)
else
  ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION,False,ProcessEntry.ProcessID);
If ProcessHandle <> 0 then
  try
    ProcessEntry.ProcessBits := GetProcessBits(ProcessHandle);
    ProcessEntry.ProcessPath := GetProcessPath(ProcessHandle);
    If ProcessEntry.ProcessPath <> '' then
      begin
        with TWinFileInfo.Create(ProcessEntry.ProcessPath,WFI_LS_VersionInfo) do
        try
          For i := Pred(VersionInfoStringTableCount) downto 0 do
            begin
              Index := IndexOfVersionInfoString(i,'FileDescription');
              If Index >= 0 then
                ProcessEntry.Description :=  VersionInfoString[i,Index].Value;
              Index := IndexOfVersionInfoString(i,'CompanyName');
              If Index >= 0 then
                ProcessEntry.CompanyName :=  VersionInfoString[i,Index].Value;
            end
        finally
           Free;
        end;
      end;
    ProcessEntry.Icon := ExtractIcon(ProcessEntry.ProcessPath);
    ProcessEntry.LimitedAccess := False;
  finally
    CloseHandle(ProcessHandle);
  end
else ProcessEntry.LimitedAccess := True;
end;

{------------------------------------------------------------------------------}
{   TAPKProcessEnumeratorInternal - public methods                             }
{------------------------------------------------------------------------------}

constructor TAPKProcessEnumeratorInternal.Create(IconBackground: TColor; ObtainProcessImageInfo: Boolean = True);
begin
inherited Create;
InterlockedExchange(fEnumerationStopped,IPE_RUNNING);
fObtainProcessImageInfo := ObtainProcessImageInfo;
fIconBackground := IconBackground;
SetLength(fProcesses,0);
SetLength(fDevices,0);
fFreeIcons := True;
fRunningInWin64 := False;
fIsWoW64ProcessProc := nil;
fDisableWoW64RedirectProc := nil;
fRevertWoW64RedirectProc := nil;
fWoW64RedirectValue := nil;
InitForWin64;
end;

//------------------------------------------------------------------------------

destructor TAPKProcessEnumeratorInternal.Destroy;
var
  i:  Integer;
begin
If fFreeIcons then
  For i := Low(fProcesses) to High(fProcesses) do
    FreeAndNil(fProcesses[i].Icon);
SetLength(fProcesses,0);
SetLength(fDevices,0);
inherited;
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumeratorInternal.Enumerate;
var
  SnapshotHandle: THandle;
  ProcessEntry32: TProcessEntry32;
begin
DisableWoW64Redirection;
try
  EnumerateDevices;
  SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  If SnapshotHandle <> INVALID_HANDLE_VALUE then
  try
    ProcessEntry32.dwSize := SizeOf(TProcessEntry32);
    If Process32First(SnapshotHandle,ProcessEntry32) then
      repeat
        SetLength(fProcesses,Length(fProcesses) + 1);
        fProcesses[High(fProcesses)].ProcessName := WinToStr(ProcessEntry32.szExeFile);
        fProcesses[High(fProcesses)].ProcessID := ProcessEntry32.th32ProcessID;
        If fObtainProcessImageInfo then
          GetProcessImageInfo(fProcesses[High(fProcesses)])
        else
          fProcesses[High(fProcesses)].LimitedAccess := False;
      until not Process32Next(SnapshotHandle,ProcessEntry32) or EnumerationStopped;
  finally
    CloseHandle(SnapshotHandle);
  end;
  If not EnumerationStopped then
    If Assigned(fOnEnumerationDone) then fOnEnumerationDone(Self);
finally
  EnableWoW64Redirection;
end;
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumeratorInternal.FillProcessList(out List: TAPKProcessList);
var
  i: Integer;
begin
SetLength(List,Length(fProcesses));
For i := Low(List) to High(List) do
  begin
    List[i] := fProcesses[i];
    UniqueString(List[i].ProcessName);
    UniqueString(List[i].ProcessPath);
    UniqueString(List[i].Description);
    UniqueString(List[i].CompanyName);
  end;
fFreeIcons := False;    
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumeratorInternal.StopEnumeration;
begin
InterlockedExchange(fEnumerationStopped,IPE_STOPPED);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                          TAPKProcessEnumeratorThread                         }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKProcessEnumeratorThread - declaration                                  }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKProcessEnumeratorThread - protected methods                            }
{------------------------------------------------------------------------------}

procedure TAPKProcessEnumeratorThread.sync_DoEnumerationDone;
begin
If Assigned(fOnEnumerationDone) then fOnEnumerationDone(fEnumerator);
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TAPKProcessEnumeratorThread.EnumerationDoneHandler(Sender: TObject);
begin
Synchronize(sync_DoEnumerationDone);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TAPKProcessEnumeratorThread.Execute;
begin
fEnumerator.Enumerate;
end;

{------------------------------------------------------------------------------}
{   TAPKProcessEnumeratorThread - public methods                               }
{------------------------------------------------------------------------------}

constructor TAPKProcessEnumeratorThread.Create(IconBackground: TColor; ObtainProcessImageInfo: Boolean = True);
begin
inherited Create(True);
FreeOnTerminate := False;
fEnumerator := TAPKProcessEnumeratorInternal.Create(IconBackground,ObtainProcessImageInfo);
fEnumerator.OnEnumerationDone := EnumerationDoneHandler;
end;

//------------------------------------------------------------------------------

destructor TAPKProcessEnumeratorThread.Destroy;
begin
fEnumerator.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumeratorThread.Enumerate;
begin
{$IF Defined(FPC) or (CompilerVersion >= 21)}
Start;
{$ELSE}
Resume;
{$IFEND}
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumeratorThread.FillProcessList(out List: TAPKProcessList);
begin
fEnumerator.FillProcessList(List);
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumeratorThread.StopEnumeration;
begin
inherited Terminate;
fEnumerator.StopEnumeration;
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                             TAPKProcessEnumerator                            }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKProcessEnumerator - declaration                                        }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKProcessEnumerator - private methods                                    }
{------------------------------------------------------------------------------}

Function TAPKProcessEnumerator.GetProcessCount: Integer;
begin
Result := Length(fProcesses);
end;

//------------------------------------------------------------------------------

Function TAPKProcessEnumerator.GetProcess(Index: Integer): TAPKProcessEntry;
begin
If (Index >= Low(fProcesses)) and (Index <= High(fProcesses)) then
  Result := fProcesses[Index]
else
  raise Exception.CreateFmt('TAPKProcessEnumerator.GetProcess: Index (%d) out of bounds.',[Index]);
end;

{------------------------------------------------------------------------------}
{   TAPKProcessEnumerator - protected methods                                  }
{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TAPKProcessEnumerator.ThreadEnumDoneHandler(Sender: TObject);
begin
Clear;
TAPKProcessEnumeratorThread(fEnumThread).FillProcessList(fProcesses);
fEnumStage := esDone;
If Assigned(fOnEnumerationDone) then fOnEnumerationDone(Self);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TAPKProcessEnumerator.FreeEnumThread;
begin
If Assigned(fEnumThread) then
  begin
    TAPKProcessEnumeratorThread(fEnumThread).StopEnumeration;
    fEnumThread.WaitFor;
    FreeAndNil(fEnumThread);
  end;
end;

{------------------------------------------------------------------------------}
{   TAPKProcessEnumerator - public methods                                     }
{------------------------------------------------------------------------------}

constructor TAPKProcessEnumerator.Create;
begin
inherited;
SetLength(fProcesses,0);
fEnumStage := esReady;
fIconBackground := clWhite;
end;

//------------------------------------------------------------------------------

destructor TAPKProcessEnumerator.Destroy;
begin
FreeEnumThread;
Clear;
inherited;
end;

//------------------------------------------------------------------------------

Function TAPKProcessEnumerator.IndexOf(const ProcessName: String): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(fProcesses) to High(fProcesses) do
  If AnsiSameText(ProcessName,fProcesses[i].ProcessName) then
    begin
      Result := i;
      Break;
    end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TAPKProcessEnumerator.IndexOf(const ProcessID: DWORD): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(fProcesses) to High(fProcesses) do
  If fProcesses[i].ProcessID = ProcessID then
    begin
      Result := i;
      Break;
    end;
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumerator.Clear;
var
  i:  Integer;
begin
For i := Low(fProcesses) to High(fProcesses) do
  FreeAndNil(fProcesses[i].Icon);
SetLength(fProcesses,0);
fEnumStage := esReady;
end;

//------------------------------------------------------------------------------

procedure TAPKProcessEnumerator.Enumerate(Threaded: Boolean; ObtainProcessImageInfo: Boolean = True);
var
  LocalEnumerator:  TAPKProcessEnumeratorInternal;
begin
If fEnumStage <> esEnumerating then
  begin
    If Threaded and (GetCurrentThreadID = MainThreadID) then
      begin
        FreeEnumThread;
        fEnumThread := TAPKProcessEnumeratorThread.Create(fIconBackground,ObtainProcessImageInfo);
        fEnumStage := esEnumerating;
        TAPKProcessEnumeratorThread(fEnumThread).OnEnumerationDone := ThreadEnumDoneHandler;
        TAPKProcessEnumeratorThread(fEnumThread).Enumerate;
      end
    else
      begin
        LocalEnumerator := TAPKProcessEnumeratorInternal.Create(fIconBackground,ObtainProcessImageInfo);
        try
          Clear;
          fEnumStage := esEnumerating;
          LocalEnumerator.Enumerate;
          LocalEnumerator.FillProcessList(fProcesses);
        finally
          LocalEnumerator.Free;
        end;
        fEnumStage := esDone;
        If Assigned(fOnEnumerationDone) then fOnEnumerationDone(Self);
      end;
  end;
end;

end.


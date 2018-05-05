{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  RawInput managing library

  RawInput manager class

  ©František Milt 2017-07-18

  Version 0.9.2

  Dependencies:
    AuxTypes       - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses     - github.com/ncs-sniper/Lib.AuxClasses    
    BitOps         - github.com/ncs-sniper/Lib.BitOps
    MulticastEvent - github.com/ncs-sniper/Lib.MulticastEvent
    WndAlloc       - github.com/ncs-sniper/Lib.WndAlloc
    WinRawInput    - github.com/ncs-sniper/Lib.WinRawInput
    BitVector      - github.com/ncs-sniper/Lib.BitVector
    UtilityWindow  - github.com/ncs-sniper/Lib.UtilityWindow
    DefRegistry    - github.com/ncs-sniper/Lib.DefRegistry
    StrRect        - github.com/ncs-sniper/Lib.StrRect
  * SimpleCPUID    - github.com/ncs-sniper/Lib.SimpleCPUID

  SimpleCPUID might not be needed, see BitOps library for details.

===============================================================================}
unit RawInputManager;

{$INCLUDE 'RawInput_defs.inc'}

interface

uses
  Windows, Messages, Classes,
  WinRawInput, UtilityWindow, AuxClasses,
  RawInputCommon, RawInputKeyboard;

{==============================================================================}
{------------------------------------------------------------------------------}
{                               TRawInputManager                               }
{------------------------------------------------------------------------------}
{==============================================================================}

type
  TRawInputManagerSettings = set of (
    rmoFlagNoLegacyMessages,
    rmoFlagNoHotKeys,
    rmoFlagAppKeys,
    rmoFlagCaptureMouse,
    rmoFlagInputSink,
    rmoRegisterForKeyboard,
    rmoRegisterForMouse,
    rmoAdditionalDeviceInfo,
    rmoPerDeviceProcessing,
    rmoChannelEventsToMaster);

{==============================================================================}
{   TRawInputManager - declaration                                             }
{==============================================================================}

  TRawInputManager = class(TCustomObject)
  private
    fTargetHWND:                    HWND;
    fActive:                        Boolean;
    fSettings:                      TRawInputManagerSettings;
    fRawInputBufferSize:            UINT;
    fRawInputBuffer:                Pointer;
    fWoW64Padding:                  Boolean;
    fDevices:                       TDeviceList;
    fRegisteredDevices:             TRegisteredDevicesList;
    fKeyboard:                      TRawInputKeyboardMaster;
  //fMouse:                         TRawInputMouseMaster;
  //fHID                            TRawInputHIDMaster;
    fOnDevicesListChange:           TNotifyEvent;
    fOnRegisteredDevicesListChange: TNotifyEvent;
    fOnRawInput:                    TRawInputEvent;
    Function GetDeviceCount: Integer;
    Function GetRegisteredDeviceCount: Integer;
    Function GetDevice(Index: Integer): TDeviceListItem;
    Function GetRegisteredDevice(Index: Integer): TRawInputDevice;
  protected
    procedure RegisterDevice(UsagePage,Usage: USHORT; Flags: DWORD); overload; virtual;
    procedure RegisterDevice(UsagePage,Usage: USHORT); overload; virtual;
    procedure UnregisterDevice(UsagePage,Usage: USHORT); virtual;
    procedure ProcessDevices; virtual;
    procedure RegisterRawInput; virtual;
    procedure UnregisterRawInput; virtual;
    procedure InitializeForWoW64; virtual;
    procedure InitializeObjects; virtual;
    procedure FinalizeObjects; virtual;
    procedure ProcessRawInput(RawInput: PRawInput); overload; virtual;
    procedure ProcessRawInput(lParam: lParam; wParam: wParam); overload; virtual;
    procedure ProcessRawInputDeviceChange(lParam: lParam; wParam: wParam); virtual;
    procedure UnknownDeviceIntercepted(Sender: TObject; DeviceHandle: THandle); virtual;
    procedure GetDeviceAdditionalInfo(const DeviceName: String; var AdditionalInfo: TAdditionalInfo); virtual;    
    procedure FillDeviceInfo(DeviceHandle: THandle; var DeviceInfo: TDeviceListItem); virtual;
  public
    constructor Create(Settings: TRawInputManagerSettings; TargetHWND: HWND = 0);
    destructor Destroy; override;
    Function ProcessBufferedInput: Integer; virtual;
    procedure EnumerateDevices; virtual;
    procedure EnumerateRegisteredDevices; virtual;
    Function IndexOfDevice(DeviceHandle: THandle): Integer; overload; virtual;
    Function IndexOfDevice(DeviceName: String): Integer; overload; virtual;
    Function RegisterHIDDevice(UsagePage, Usage: USHORT; Flags: DWORD = 0): Boolean; overload; virtual;
    Function RegisterHIDDevice(Index: Integer; Flags: DWORD = 0): Boolean; overload; virtual;
    procedure UnregisterHIDDevice(UsagePage, Usage: USHORT); overload; virtual;
    procedure UnregisterHIDDevice(Index: Integer); overload; virtual;
    property Devices[Index: Integer]: TDeviceListItem read GetDevice;
    property RegisteredDevices[Index: Integer]: TRawInputDevice read GetRegisteredDevice;
  published
    property TargetHWND: HWND read fTargetHWND;
    property Active: Boolean read fActive write fActive;
    property Settings: TRawInputManagerSettings read fSettings;
    property DeviceCount: Integer read GetDeviceCount;
    property RegisteredDeviceCount: Integer read GetRegisteredDeviceCount;
    property Keyboard: TRawInputKeyboardMaster read fKeyboard;
  //property Mouse: TRawInputMouseMaster read fMouse;
  //property HID: TRawInputHIDMaster read fHID;
    property OnDevicesListChange: TNotifyEvent read fOnDevicesListChange write fOnDevicesListChange;
    property OnRegisteredDevicesListChange: TNotifyEvent read fOnRegisteredDevicesListChange write fOnRegisteredDevicesListChange;
    property OnRawInput: TRawInputEvent read fOnRawInput write fOnRawInput;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                              TRawInputManagerEx                              }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputManagerEx - declaration                                           }
{==============================================================================}

  TRawInputManagerEx = class(TRawInputManager)
  private
    fOwnsUtilityWindow: Boolean;  
    fUtilityWindow:     TUtilityWindow;
  protected
    procedure MessagesHandler(var Msg: TMessage; var Handled: Boolean); virtual;
  public
    constructor Create(Settings: TRawInputManagerSettings; UtilityWindow: TUtilityWindow = nil);
    destructor Destroy; override;
  published
    property UtilityWindow: TUtilityWindow read fUtilityWindow;    
  end;


implementation

uses
  SysUtils, StrUtils, DefRegistry, StrRect;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{==============================================================================}
{------------------------------------------------------------------------------}
{                               TRawInputManager                               }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputManager - implementation                                          }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TRawInputManager - private methods                                         }
{------------------------------------------------------------------------------}

Function TRawInputManager.GetDeviceCount: Integer;
begin
Result := Length(fDevices);
end;

//------------------------------------------------------------------------------

Function TRawInputManager.GetRegisteredDeviceCount: Integer;
begin
Result := Length(fRegisteredDevices);
end;

//------------------------------------------------------------------------------

Function TRawInputManager.GetDevice(Index: Integer): TDeviceListItem;
begin
If (Index >= Low(fDevices)) and (Index <= High(fDevices)) then
  Result := fDevices[Index]
else
  raise Exception.CreateFmt('TRawInputManager.GetDevice: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TRawInputManager.GetRegisteredDevice(Index: Integer): TRawInputDevice;
begin
If (Index >= Low(fRegisteredDevices)) and (Index <= High(fRegisteredDevices)) then
  Result := fRegisteredDevices[Index]
else
  raise Exception.CreateFmt('TRawInputManager.GetRegisteredDevice: Index (%d) out of bounds.',[Index]);
end;

{------------------------------------------------------------------------------}
{   TRawInputManager - protected methods                                       }
{------------------------------------------------------------------------------}

procedure TRawInputManager.RegisterDevice(UsagePage,Usage: USHORT; Flags: DWORD);
var
  RawInputDevice:  PRawInputDevice;
begin
New(RawInputDevice);
try
  RawInputDevice^.usUsagePage := UsagePage;
  RawInputDevice^.usUsage := Usage;
  RawInputDevice^.dwFlags := Flags;
  RawInputDevice^.hwndTarget := TargetHWND;
  If not RegisterRawInputDevices(RawInputDevice,1,SizeOf(TRawInputDevice)) then
    raise Exception.CreateFmt('TRawInputManager.RegisterDevice: Raw input registration failed (0x%.8x).',[GetLastError]);
finally
  Dispose(RawInputDevice);
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TRawInputManager.RegisterDevice(UsagePage,Usage: USHORT);
var
  Flags:  DWORD;
begin
If Win32MajorVersion >= 6 {Vista+} then
  Flags := RIDEV_DEVNOTIFY
else
  Flags := 0;
If rmoFlagNoLegacyMessages in fSettings then
  Flags := Flags or RIDEV_NOLEGACY;
If (rmoFlagNoHotKeys in fSettings) and (UsagePage = $01) and (Usage = $06) then
  Flags := Flags or RIDEV_NOHOTKEYS;
If rmoFlagInputSink in fSettings then
  Flags := Flags or RIDEV_INPUTSINK;
If (rmoFlagAppKeys in fSettings) and (UsagePage = $01) and (Usage = $06) then
  Flags := Flags or RIDEV_APPKEYS;
If (rmoFlagCaptureMouse in fSettings) and (rmoFlagNoLegacyMessages in fSettings) and (UsagePage = $01) and (Usage = $02) then
  Flags := Flags or RIDEV_CAPTUREMOUSE;
RegisterDevice(UsagePage,Usage,Flags);
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.UnregisterDevice(UsagePage,Usage: USHORT);
var
  RawInputDevice:  PRawInputDevice;
begin
New(RawInputDevice);
try
  RawInputDevice^.usUsagePage := UsagePage;
  RawInputDevice^.usUsage := Usage;
  RawInputDevice^.dwFlags := RIDEV_REMOVE;
  RawInputDevice^.hwndTarget := 0;
  If not RegisterRawInputDevices(RawInputDevice,1,SizeOf(TRawInputDevice)) then
    raise Exception.CreateFmt('TRawInputManager.UnregisterRawInput.UnregisterDevice: Raw input unregistration failed (0x%.8x).',[GetLastError]);
finally
  Dispose(RawInputDevice);
end;
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.ProcessDevices;
var
  i:  Integer;
begin
For i := Low(fDevices) to High(fDevices) do
  case fDevices[i].Info.dwType of
    RIM_TYPEMOUSE:;
    RIM_TYPEKEYBOARD:
      If fKeyboard.IndexOfDevice(fDevices[i].Handle) < 0 then
        TRawInputKeyboardMasterInternal(fKeyboard).AddDevice(Addr(fDevices[i]),rmoChannelEventsToMaster in fSettings);
    RIM_TYPEHID:;
  end;
For i := Pred(fKeyboard.DeviceCount) downto 0 do
   If IndexOfDevice(fKeyboard[i].DeviceInfo.Handle) < 0 then
     TRawInputKeyboardMasterInternal(fKeyboard).DeleteDevice(i);
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.RegisterRawInput;
begin
If rmoRegisterForKeyboard in fSettings then
  RegisterDevice($01,$06);
If rmoRegisterForMouse in fSettings then
  RegisterDevice($01,$02);
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.UnregisterRawInput;
var
  i:  Integer;
begin
For i := 0 to Pred(RegisteredDeviceCount) do
  UnregisterDevice(RegisteredDevices[i].usUsagePage,RegisteredDevices[i].usUsage);
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.InitializeForWoW64;
type
  TIsWoW64Process = Function(hProcess: THandle; Wow64Process: PBOOL): BOOL; stdcall;
var
  ModuleHandle:   THandle;
  IsWow64Process: TIsWoW64Process;
  ResultValue:    BOOL;
begin
fWoW64Padding := False;
ModuleHandle := GetModuleHandle('kernel32.dll');
If ModuleHandle <> 0 then
  begin
    IsWoW64Process := GetProcAddress(ModuleHandle,'IsWow64Process');
    If Assigned(IsWoW64Process) then
      If IsWoW64Process(GetCurrentProcess,@ResultValue) then
        fWoW64Padding := ResultValue;
  end
else raise Exception.CreateFmt('TRawInputManager.InitializeForWoW64: Unable to get handle to module kernel32.dll (%.8x).',[GetLastError]);
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.InitializeObjects;
begin
fKeyboard := TRawInputKeyboardMasterInternal.Create;
If rmoPerDeviceProcessing in fSettings then
  TRawInputKeyboardMasterInternal(fKeyboard).OnUnknownDeviceIntercepted := UnknownDeviceIntercepted;
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.FinalizeObjects;
begin
fKeyboard.Free;
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.ProcessRawInput(RawInput: PRawInput);
begin
If Assigned(fOnRawInput) then fOnRawInput(Self,RawInput,RawInput^.header.dwSize);
case RawInput^.header.dwType of
  RIM_TYPEMOUSE:;
  RIM_TYPEKEYBOARD: fKeyboard.ProcessRawInput(RawInput);
  RIM_TYPEHID:;
else
  DefRawInputProc(@RawInput,1,SizeOf(RAWINPUTHEADER));
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TRawInputManager.ProcessRawInput(lParam: lParam; wParam: wParam);
var
  RawInputSize: UINT;
begin
If GetRawInputData(HRAWINPUT(lParam),RID_INPUT,nil,@RawInputSize,SizeOf(TRawInputHeader)) <> UINT(-1) then
  If RawInputSize > 0 then
    begin
      If RawInputSize > fRawInputBufferSize then
        begin
          fRawInputBufferSize := RawInputSize;
          ReallocMem(fRawInputBuffer,RawInputSize)
        end;
      If GetRawInputData(HRAWINPUT(lParam),RID_INPUT,fRawInputBuffer,@RawInputSize,SizeOf(TRawInputHeader)) = RawInputSize then
        ProcessRawInput(fRawInputBuffer);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TRawInputManager.ProcessRawInputDeviceChange(lParam: lParam; wParam: wParam);
var
  Index, i: Integer;
begin
case wParam of
  GIDC_ARRIVAL:
    If IndexOfDevice(THandle(lParam)) < 0 then
      begin
        SetLength(fDevices,Length(fDevices) + 1);
        FillDeviceInfo(THandle(lParam),fDevices[High(fDevices)]);
        ProcessDevices;
        If Assigned(fOnDevicesListChange) then fOnDevicesListChange(Self);
      end;
  GIDC_REMOVAL:
    begin
      Index := IndexOfDevice(THandle(lParam));
      If Index >= 0 then
        begin
          For i := Index to Pred(High(fDevices)) do
            fDevices[i] := fDevices[i + 1];
          SetLength(fDevices,Length(fDevices) - 1);
          ProcessDevices;
          If Assigned(fOnDevicesListChange) then fOnDevicesListChange(Self);
        end;
    end;
end; 
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TRawInputManager.UnknownDeviceIntercepted(Sender: TObject; DeviceHandle: THandle);
begin
If IndexOfDevice(DeviceHandle) < 0 then
  begin
    SetLength(fDevices,Length(fDevices) + 1);
    FillDeviceInfo(DeviceHandle,fDevices[High(fDevices)]);
    ProcessDevices;
    If Assigned(fOnDevicesListChange) then fOnDevicesListChange(Self);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TRawInputManager.GetDeviceAdditionalInfo(const DeviceName: String; var AdditionalInfo: TAdditionalInfo);
var
  BeginPos: Integer;
  EndPos:   Integer;
  Reg:      TDefRegistry;

  Function GetLastPosition(const Str: String; Char: Char): Integer;
  var
    i: Integer;
  begin
    Result := 0;
    For i := Length(Str) downto 1 do
      If Str[i] = Char then
        begin
          Result := i;
          Break;
        end;
  end;

  Function RectifyStr(const Str: String): String;
  begin
    If AnsiContainsText(Str,';') then
      Result := Copy(Str,Succ(GetLastPosition(Str,';')),Length(Str))
    else
      Result := Str;
  end;

begin
BeginPos := GetLastPosition(DeviceName,'\');
EndPos := GetLastPosition(DeviceName,'#');
If (BeginPos > 0) and (EndPos > 0) and (BeginPos < EndPos) then
  begin
    Reg := TDefRegistry.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      If Reg.OpenKeyReadOnly('System\CurrentControlSet\Enum\' + AnsiReplaceText(Copy(DeviceName,Succ(BeginPos),EndPos - BeginPos),'#','\')) then
        begin
          AdditionalInfo.Description := RectifyStr(Reg.ReadStringDef('DeviceDesc',''));
          AdditionalInfo.Manufacturer := RectifyStr(Reg.ReadStringDef('Mfg',''));
          AdditionalInfo.DeviceClass := Reg.ReadStringDef('Class','');
          AdditionalInfo.ClassGUID := StringToGUID(Reg.ReadStringDef('ClassGUID','{00000000-0000-0000-0000-000000000000}'));
          AdditionalInfo.Description := WinToStr(AdditionalInfo.Description);
          AdditionalInfo.Manufacturer := WinToStr(AdditionalInfo.Manufacturer);
          AdditionalInfo.DeviceClass := WinToStr(AdditionalInfo.DeviceClass);
          Reg.CloseKey;
        end;
    finally
      Reg.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.FillDeviceInfo(DeviceHandle: THandle; var DeviceInfo: TDeviceListItem);
var
  BufferSize: UINT;
begin
DeviceInfo.Handle := DeviceHandle;
GetRawInputDeviceInfo(DeviceHandle,RIDI_DEVICENAME,nil,@BufferSize);
SetLength(DeviceInfo.Name,BufferSize);
GetRawInputDeviceInfo(DeviceHandle,RIDI_DEVICENAME,PChar(DeviceInfo.Name),@BufferSize);
SetLength(DeviceInfo.Name,StrLen(PChar(DeviceInfo.Name)));
DeviceInfo.Name := WinToStr(DeviceInfo.Name);
BufferSize := SizeOf(RID_DEVICE_INFO);
DeviceInfo.Info.cbSize := SizeOf(RID_DEVICE_INFO);
GetRawInputDeviceInfo(DeviceHandle,RIDI_DEVICEINFO,Addr(DeviceInfo.Info),@BufferSize);
GetRawInputDeviceInfo(DeviceHandle,RIDI_PREPARSEDDATA,nil,@BufferSize);
SetLength(DeviceInfo.PreparsedData,BufferSize);
If Length(DeviceInfo.PreparsedData) > 0 then
  GetRawInputDeviceInfo(DeviceHandle,RIDI_PREPARSEDDATA,Addr(DeviceInfo.PreparsedData[0]),@BufferSize);
If rmoAdditionalDeviceInfo in fSettings then
  GetDeviceAdditionalInfo(DeviceInfo.Name,DeviceInfo.AdditionalInfo);
end;

{------------------------------------------------------------------------------}
{   TRawInputManager - public methods                                          }
{------------------------------------------------------------------------------}

constructor TRawInputManager.Create(Settings: TRawInputManagerSettings; TargetHWND: HWND = 0);
begin
inherited Create;
fTargetHWND := TargetHWND;
fActive := False;
fSettings := Settings;
fRawInputBufferSize := SizeOf(TRawInput) * 128;
fRawInputBuffer := AllocMem(fRawInputBufferSize);
InitializeForWoW64;
InitializeObjects;
EnumerateDevices;
RegisterRawInput;
EnumerateRegisteredDevices;
end;

//------------------------------------------------------------------------------

destructor TRawInputManager.Destroy;
begin
UnregisterRawInput;
FinalizeObjects;
FreeMem(fRawInputBuffer,fRawInputBufferSize);
inherited;
end;

//------------------------------------------------------------------------------

Function TRawInputManager.ProcessBufferedInput: Integer;
var
  BufferSize:     UINT;
  Count:          Integer;
  CurrentBuffer:  Pointer;
  i:              Integer;
begin
Result := 0;
repeat
  BufferSize := 0;
  If GetRawInputBuffer(nil,@BufferSize,SizeOf(RAWINPUTHEADER)) = 0 then
    If BufferSize > 0 then
      begin
        If BufferSize >= fRawInputBufferSize then
          begin
            fRawInputBufferSize := BufferSize * 2;
            ReallocMem(fRawInputBuffer,fRawInputBufferSize);
          end;
        Count := Integer(GetRawInputBuffer(fRawInputBuffer,@fRawInputBufferSize,SizeOf(RAWINPUTHEADER)));
        If Count > 0 then
          begin
            Inc(Result,Count);
            CurrentBuffer := fRawInputBuffer;
            For i := 1 to Count do
              begin
              {$IFDEF 32bit}
                If fWoW64Padding then
                  WoW64Conversion(CurrentBuffer);
              {$ENDIF}
                ProcessRawInput(PRAWINPUT(CurrentBuffer));
                CurrentBuffer := NEXTRAWINPUTBLOCK(CurrentBuffer);
              end; 
          end;
      end;
until BufferSize <= 0;
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.EnumerateDevices;
var
  DevicesCount: UINT;
  Devices:      PRAWINPUTDEVICELIST;
  DevicePtr:    PRAWINPUTDEVICELIST;
  i:            Integer;
begin
If GetRawInputDeviceList(nil,@DevicesCount,SizeOf(RAWINPUTDEVICELIST)) <> UINT(-1) then
  begin
    Devices := AllocMem(DevicesCount * SizeOf(RAWINPUTDEVICELIST));
    try
      If GetRawInputDeviceList(Devices,@DevicesCount,SizeOf(RAWINPUTDEVICELIST)) = DevicesCount then
        begin
          SetLength(fDevices,DevicesCount);
          DevicePtr := Devices;
          For i := Low(fDevices) to High(fDevices) do
            begin
              FillDeviceInfo(DevicePtr^.hDevice,fDevices[i]);
              Inc(DevicePtr);
            end;
          If Assigned(fOnDevicesListChange) then fOnDevicesListChange(Self);
        end
      else raise Exception.CreateFmt('TRawInputManager.EnumerateDevices: Cannot enumerate devices (0x%.8x).',[GetLastError]);
    finally
      FreeMem(Devices,DevicesCount * SizeOf(RAWINPUTDEVICELIST));
    end;
  end
else raise Exception.CreateFmt('TRawInputManager.EnumerateDevices: Cannot get number of devices (0x%.8x).',[GetLastError]);
If rmoPerDeviceProcessing in fSettings then ProcessDevices;
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.EnumerateRegisteredDevices;
var
  DevicesCount:   UINT;
  DevicesBuffer:  PRAWINPUTDEVICE;
  DevicePtr:      PRAWINPUTDEVICE;
  i:              Integer;
begin
GetRegisteredRawInputDevices(nil,@DevicesCount,SizeOf(RAWINPUTDEVICE));
DevicesBuffer := AllocMem(DevicesCount * SizeOf(RAWINPUTDEVICE));
try
  If GetRegisteredRawInputDevices(DevicesBuffer,@DevicesCount,SizeOf(RAWINPUTDEVICE)) = DevicesCount then
    begin
      SetLength(fRegisteredDevices,DevicesCount);
      DevicePtr := DevicesBuffer;
      For i := Low(fRegisteredDevices) to High(fRegisteredDevices) do
        begin
          fRegisteredDevices[i] := DevicePtr^;
          Inc(DevicePtr);
        end;
      If Assigned(fOnRegisteredDevicesListChange) then fOnRegisteredDevicesListChange(Self);
    end
  else raise Exception.CreateFmt('TRawInputManager.EnumerateRegisteredDevices: Cannot enumerate registered devices (0x%.8x).',[GetLastError]);
finally
  FreeMem(DevicesBuffer,DevicesCount * SizeOf(RAWINPUTDEVICE));
end;
end;

//------------------------------------------------------------------------------

Function TRawInputManager.IndexOfDevice(DeviceHandle: THandle): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(fDevices) to High(fDevices) do
  If fDevices[i].Handle = DeviceHandle then
    begin
      Result := i;
      Break;
    end;
end;

//------------------------------------------------------------------------------

Function TRawInputManager.IndexOfDevice(DeviceName: String): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(fDevices) to High(fDevices) do
  If AnsiSameText(fDevices[i].Name,DeviceName) then
    begin
      Result := i;
      Break;
    end;
end;

//------------------------------------------------------------------------------

Function TRawInputManager.RegisterHIDDevice(UsagePage, Usage: USHORT; Flags: DWORD = 0): Boolean;
begin
If (UsagePage <> 0) and (Usage <> 0) then
  begin
    RegisterDevice(UsagePage,Usage,Flags);
    EnumerateRegisteredDevices;
    Result := True;
  end
else Result := False;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TRawInputManager.RegisterHIDDevice(Index: Integer; Flags: DWORD = 0): Boolean;
begin
Result := False;
If (Index >= 0) and (Index < DeviceCount) then
  begin
    If Devices[Index].Info.dwType = RIM_TYPEHID then
      Result := RegisterHIDDevice(Devices[Index].Info.hid.usUsagePage,Devices[Index].Info.hid.usUsage,Flags);
  end
else raise Exception.CreateFmt('TRawInputManager.RegisterHIDDevice: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TRawInputManager.UnregisterHIDDevice(UsagePage, Usage: USHORT);
begin
UnregisterDevice(UsagePage,Usage);
EnumerateRegisteredDevices;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TRawInputManager.UnregisterHIDDevice(Index: Integer);
begin
If (Index >= 0) and (Index < RegisteredDeviceCount) then
  UnregisterHIDDevice(RegisteredDevices[Index].usUsagePage,RegisteredDevices[Index].usUsage)
else
  raise Exception.CreateFmt('TRawInputManager.UnregisterHIDDevice: Index (%d) out of bounds.',[Index]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                              TRawInputManagerEx                              }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputManagerEx - implementation                                        }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TRawInputManagerEx - protected methods                                     }
{------------------------------------------------------------------------------}

procedure TRawInputManagerEx.MessagesHandler(var Msg: TMessage; var Handled: Boolean);
begin
If Active then
  begin
    case Msg.Msg of
      WM_INPUT:
        begin
          ProcessRawInput(Msg.LParam,Msg.WParam);
          Msg.Result := 0;
          Handled := True;
        end;
      WM_INPUT_DEVICE_CHANGE:
        begin
          ProcessRawInputDeviceChange(Msg.LParam,Msg.WParam);
          Msg.Result := 0;
          Handled := True;
        end;
    else
      Handled := False;
    end;
  end
else Handled := False;
end;

{------------------------------------------------------------------------------}
{   TRawInputManagerEx - public methods                                        }
{------------------------------------------------------------------------------}

constructor TRawInputManagerEx.Create(Settings: TRawInputManagerSettings; UtilityWindow: TUtilityWindow = nil);
var
  TempObject: TUtilityWindow;
begin
If Assigned(UtilityWindow) then TempObject := UtilityWindow
  else TempObject := TUtilityWindow.Create;
try
  inherited Create(Settings,TempObject.WindowHandle);
except
  If not Assigned(UtilityWindow) then
    TempObject.Free;
  raise;
end;
fOwnsUtilityWindow := not Assigned(UtilityWindow);
fUtilityWindow := TempObject;
fUtilityWindow.OnMessage.Add(MessagesHandler);
end;

//------------------------------------------------------------------------------

destructor TRawInputManagerEx.Destroy;
begin
If Assigned(fUtilityWindow) then
  begin
    fUtilityWindow.OnMessage.Remove(MessagesHandler);
    If fOwnsUtilityWindow then
      fUtilityWindow.Free;
  end;
inherited;
end;

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  RawInput managing library

  Keyboard processing

  ©František Milt 2016-06-02

  Version 0.9.1

===============================================================================}
unit RawInputKeyboard;

{$Include 'RawInput_defs.inc'}

interface

uses
  Classes, Contnrs,
  WinRawInput, BitVector,
  RawInputCommon;

{==============================================================================}
{------------------------------------------------------------------------------}
{                               TRawInputKeyboard                              }
{------------------------------------------------------------------------------}
{==============================================================================}

const
  VK_NUMPADENTER = $0100;  

type
  TKeyboardShiftStates = set of (kssControl,kssLControl,kssRControl,
                                 kssAlt,kssLAlt,kssRAlt,
                                 kssShift,kssLShift,kssRShift);
                                 
  TKeyboardIndicators  = set of (kiNumLock,kiCapsLock,kiScrollLock);

  TRawKeyboardEvent = procedure(Sender: TObject; Input: TRawKeyboard) of object;
  TVirtualKeyEvent = procedure(Sender: TObject; VirtualKeyCode: USHORT) of object;

{==============================================================================}
{   TRawInputKeyboard - declaration                                            }
{==============================================================================}

  TRawInputKeyboard = class(TRawInputProcessingObject)
  private
    fDoInputCorrection:   Boolean;
    fDiscernSides:        Boolean;
    fAdditionalVKeys:     Boolean;
    fKeyStates:           TBitVector;
    fOnRawKeyboard:       TRawKeyboardEvent;
    fOnBeforeKeyPress:    TVirtualKeyEvent;
    fOnAfterKeyPress:     TVirtualKeyEvent;
    fOnBeforeKeyRelease:  TVirtualKeyEvent;
    fOnAfterKeyRelease:   TVirtualKeyEvent;
    fOnKeyPress:          TVirtualKeyEvent;
    fOnKeyRelease:        TVirtualKeyEvent;
  protected
    procedure ProcessRawInputSpecific(RawInput: PRawInput); override;
    Function InputCorrection(var Input: RawKeyboard): Boolean; virtual;
    procedure ProcessKeyPress(VirtualKeyCode: USHORT); virtual;
    procedure ProcessKeyRelease(VirtualKeyCode: USHORT); virtual;
    procedure DoRawKeyboard(Sender: TObject; Input: TRawKeyboard); virtual;
    procedure DoBeforeKeyPress(Sender: TObject; VirtualKeyCode: USHORT); virtual;
    procedure DoAfterKeyPress(Sender: TObject; VirtualKeyCode: USHORT); virtual;
    procedure DoBeforeKeyRelease(Sender: TObject; VirtualKeyCode: USHORT); virtual;
    procedure DoAfterKeyRelease(Sender: TObject; VirtualKeyCode: USHORT); virtual;
  public
    class Function GetVirtualKeyName(VirtualKeyCode: USHORT; NumberForUnknown: Boolean = True): String; virtual;
    class Function ShiftStatesToStr(ShiftStates: TKeyboardShiftStates; const Separator: String = ' '; DiscernSides: Boolean = False): String; virtual;
    constructor Create(DeviceInfo: PDeviceListItem = nil);
    destructor Destroy; override;
    procedure Invalidate; override;
    Function GetShiftStates: TKeyboardShiftStates; virtual;
    Function GetIndicators: TKeyboardIndicators; virtual;
  published
    property DoInputCorrection: Boolean read fDoInputCorrection write fDoInputCorrection;
    property DiscernSides: Boolean read fDiscernSides write fDiscernSides;
    property AdditionalVirtualKeys: Boolean read fAdditionalVKeys write fAdditionalVKeys;
    property KeyStates: TBitVector read fKeyStates;
    property OnRawKeyboard: TRawKeyboardEvent read fOnRawKeyboard write fOnRawKeyboard;
    property OnBeforeKeyPress: TVirtualKeyEvent read fOnBeforeKeyPress write fOnBeforeKeyPress;
    property OnAfterKeyPress: TVirtualKeyEvent read fOnAfterKeyPress write fOnAfterKeyPress;
    property OnBeforeKeyRelease: TVirtualKeyEvent read fOnBeforeKeyRelease write fOnBeforeKeyRelease;
    property OnAfterKeyRelease: TVirtualKeyEvent read fOnAfterKeyRelease write fOnAfterKeyRelease;
    property OnKeyPress: TVirtualKeyEvent read fOnKeyPress write fOnKeyPress;
    property OnKeyRelease: TVirtualKeyEvent read fOnKeyRelease write fOnKeyRelease;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TRawInputKeyboardMaster                           }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputKeyboardMaster - declaration                                      }
{==============================================================================}

  TRawInputKeyboardMaster = class(TRawInputKeyboard)
  private
    fDevices:         TObjectList;
    fOnDevicesChange: TNotifyEvent;
    Function GetDeviceCount: Integer;
    Function GetDevice(Index: Integer): TRawInputKeyboard;
  protected
    fOnUnknownDeviceIntercepted:  TUnknownDeviceEvent;
    procedure ProcessRawInputSpecific(RawInput: PRawInput); override;
    Function AddDeviceInternal(DeviceInfo: PDeviceListItem): Integer; virtual;
    procedure DeleteDeviceInternal(Index: Integer); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Invalidate; override;
    Function IndexOfDevice(DeviceHandle: THandle): Integer; virtual;    
    property Devices[Index: Integer]: TRawInputKeyboard read GetDevice; default;
  published
    property DeviceCount: Integer read GetDeviceCount;
    property OnDevicesChange: TNotifyEvent read fOnDevicesChange write fOnDevicesChange;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                        TRawInputKeyboardDeviceInternal                       }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputKeyboardDeviceInternal - declaration                              }
{==============================================================================}

  TRawInputKeyboardDeviceInternal = class(TRawInputKeyboard)
  private
    fOnRawKeyboardInternal:       TRawKeyboardEvent;
    fOnBeforeKeyPressInternal:    TVirtualKeyEvent;
    fOnAfterKeyPressInternal:     TVirtualKeyEvent;
    fOnBeforeKeyReleaseInternal:  TVirtualKeyEvent;
    fOnAfterKeyReleaseInternal:   TVirtualKeyEvent;
  protected
    procedure DoRawKeyboard(Sender: TObject; Input: TRawKeyboard); override;
    procedure DoBeforeKeyPress(Sender: TObject; VirtualKeyCode: USHORT); override;
    procedure DoAfterKeyPress(Sender: TObject; VirtualKeyCode: USHORT); override;
    procedure DoBeforeKeyRelease(Sender: TObject; VirtualKeyCode: USHORT); override;
    procedure DoAfterKeyRelease(Sender: TObject; VirtualKeyCode: USHORT); override;
  public
    property OnRawKeyboardInternal: TRawKeyboardEvent read fOnRawKeyboardInternal write fOnRawKeyboardInternal;
    property OnBeforeKeyPressInternal: TVirtualKeyEvent read fOnBeforeKeyPressInternal write fOnBeforeKeyPressInternal;
    property OnAfterKeyPressInternal: TVirtualKeyEvent read fOnAfterKeyPressInternal write fOnAfterKeyPressInternal;
    property OnBeforeKeyReleaseInternal: TVirtualKeyEvent read fOnBeforeKeyReleaseInternal write fOnBeforeKeyReleaseInternal;
    property OnAfterKeyReleaseInternal: TVirtualKeyEvent read fOnAfterKeyReleaseInternal write fOnAfterKeyReleaseInternal;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                        TRawInputKeyboardMasterInternal                       }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputKeyboardMasterInternal - declaration                              }
{==============================================================================}

  TRawInputKeyboardMasterInternal = class(TRawInputKeyboardMaster)
  public
    Function AddDevice(DeviceInfo: PDeviceListItem; AssignCallbacks: Boolean = False): Integer; virtual;
    Function RemoveDevice(DeviceHandle: THandle): Integer; virtual;
    procedure DeleteDevice(Index: Integer); virtual;
  published
    property OnUnknownDeviceIntercepted: TUnknownDeviceEvent read fOnUnknownDeviceIntercepted write fOnUnknownDeviceIntercepted;
  end;

implementation

uses
  Windows, SysUtils
{$IF Defined(FPC) and not Defined(Unicode)}
  , LazUTF8
{$IFEND};

const
{$IF not Declared(MAPVK_VK_TO_VSC)}
  MAPVK_VK_TO_VSC = 0;
{$IFEND}
{$IF not Declared(MAPVK_VSC_TO_VK_EX)}
  MAPVK_VSC_TO_VK_EX = 3;
{$IFEND}

{==============================================================================}
{------------------------------------------------------------------------------}
{                               TRawInputKeyboard                              }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputKeyboard - implementation                                         }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TRawInputKeyboard - protected methods                                      }
{------------------------------------------------------------------------------}

procedure TRawInputKeyboard.ProcessRawInputSpecific(RawInput: PRawInput);
begin
DoRawKeyboard(Self,RawInput^.keyboard);
If fDoInputCorrection then
  If not InputCorrection(RawInput^.keyboard) then Exit;
If (RawInput^.keyboard.Flags and RI_KEY_BREAK) <> 0 then
  ProcessKeyRelease(RawInput^.keyboard.VKey)
else
  ProcessKeyPress(RawInput^.keyboard.VKey);
end;

//------------------------------------------------------------------------------

Function TRawInputKeyboard.InputCorrection(var Input: RawKeyboard): Boolean;
var
  Flag_E0:  Boolean;
  Flag_E1:  Boolean;
begin
Result := True;
// Repair input (because raw input in Windows is bugged and generally weird)
Flag_E0 := (Input.Flags and RI_KEY_E0) <> 0;
Flag_E1 := (Input.Flags and RI_KEY_E1) <> 0;
case Input.VKey of
  VK_SHIFT:   If fDiscernSides then
                Input.VKey := MapVirtualKey(Input.MakeCode,MAPVK_VSC_TO_VK_EX);
  VK_CONTROL: If fDiscernSides then
                If Flag_E0 then Input.VKey := VK_RCONTROL
                  else Input.VKey := VK_LCONTROL;
  VK_MENU:    If fDiscernSides then
                If Flag_E0 then Input.VKey := VK_RMENU
                  else Input.VKey := VK_LMENU;
  VK_RETURN:  If fAdditionalVKeys then
                If Flag_E0 then Input.VKey := VK_NUMPADENTER; 
  VK_INSERT:  If not Flag_E0 then Input.VKey := VK_NUMPAD0;
  VK_DELETE:  If not Flag_E0 then Input.VKey := VK_DECIMAL;
  VK_HOME:    If not Flag_E0 then Input.VKey := VK_NUMPAD7;
  VK_END:     If not Flag_E0 then Input.VKey := VK_NUMPAD1;
  VK_PRIOR:   If not Flag_E0 then Input.VKey := VK_NUMPAD9;
  VK_NEXT:    If not Flag_E0 then Input.VKey := VK_NUMPAD3;
  VK_CLEAR:   If not Flag_E0 then Input.VKey := VK_NUMPAD5;
  VK_LEFT:    If not Flag_E0 then Input.VKey := VK_NUMPAD4;
  VK_RIGHT:   If not Flag_E0 then Input.VKey := VK_NUMPAD6;
  VK_UP:      If not Flag_E0 then Input.VKey := VK_NUMPAD8;
  VK_DOWN:    If not Flag_E0 then Input.VKey := VK_NUMPAD2;
  VK_NUMLOCK: Input.MakeCode := MapVirtualKey(Input.VKey,MAPVK_VK_TO_VSC) or $100;
  0,$FF..High(USHORT):  Result := False;
end;
If Flag_E1 then
  begin
    If Input.VKey = VK_PAUSE then
      Input.MakeCode := $45
    else
      Input.MakeCode := MapVirtualKey(Input.VKey,MAPVK_VK_TO_VSC);
  end;
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboard.ProcessKeyPress(VirtualKeyCode: USHORT);
begin
DoBeforeKeyPress(Self,VirtualKeyCode);
fKeyStates[Byte(VirtualKeyCode)] := True;
DoAfterKeyPress(Self,VirtualKeyCode);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboard.ProcessKeyRelease(VirtualKeyCode: USHORT);
begin
DoBeforeKeyRelease(Self,VirtualKeyCode);
fKeyStates[Byte(VirtualKeyCode)] := False;
DoAfterKeyRelease(Self,VirtualKeyCode);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboard.DoRawKeyboard(Sender: TObject; Input: TRawKeyboard);
begin
If Assigned(fOnRawKeyboard) then fOnRawKeyboard(Sender,Input);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboard.DoBeforeKeyPress(Sender: TObject; VirtualKeyCode: USHORT);
begin
If Assigned(fOnBeforeKeyPress) then fOnBeforeKeyPress(Sender,VirtualKeyCode);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboard.DoAfterKeyPress(Sender: TObject; VirtualKeyCode: USHORT);
begin
If Assigned(fOnAfterKeyPress) then fOnAfterKeyPress(Sender,VirtualKeyCode);
If Assigned(fOnKeyPress) then fOnKeyPress(Sender,VirtualKeyCode);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboard.DoBeforeKeyRelease(Sender: TObject; VirtualKeyCode: USHORT);
begin
If Assigned(fOnBeforeKeyRelease) then fOnBeforeKeyRelease(Sender,VirtualKeyCode);
If Assigned(fOnKeyRelease) then fOnKeyRelease(Sender,VirtualKeyCode);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboard.DoAfterKeyRelease(Sender: TObject; VirtualKeyCode: USHORT);
begin
If Assigned(fOnAfterKeyRelease) then fOnAfterKeyRelease(Sender,VirtualKeyCode);
end;

{------------------------------------------------------------------------------}
{   TRawInputKeyboard - public methods                                         }
{------------------------------------------------------------------------------}

class Function TRawInputKeyboard.GetVirtualKeyName(VirtualKeyCode: USHORT; NumberForUnknown: Boolean = True): String;
var
  Flag_E0:  Boolean;
  ScanCode: Integer;
begin
case VirtualKeyCode of
  VK_NUMLOCK,VK_RCONTROL,VK_RMENU,VK_LWIN,VK_RWIN,VK_INSERT,VK_DELETE,VK_HOME,
  VK_END,VK_PRIOR,VK_NEXT,VK_LEFT,VK_RIGHT,VK_UP,VK_DOWN,VK_DIVIDE,VK_APPS,
  VK_SNAPSHOT,VK_CLEAR,VK_CANCEL:  Flag_E0 := True;
  VK_NUMPADENTER:
    begin
      VirtualKeyCode := VK_RETURN;
      Flag_E0 := True;
    end;
else
  Flag_E0 := False;
end;
// MapVirtualKey(Ex) is unable to map following VK to SC, have to do it manually
case VirtualKeyCode of
  VK_PAUSE:     ScanCode := $45;
  VK_SNAPSHOT:  ScanCode := $37;
else
  ScanCode := MapVirtualKey(VirtualKeyCode,MAPVK_VK_TO_VSC);
end;
If Flag_E0 then ScanCode := ScanCode or $100;
SetLength(Result,32);
SetLength(Result,GetKeyNameText(ScanCode shl 16,PChar(Result),Length(Result)));
{$IF Defined(FPC) and not Defined(Unicode)}
Result := WinCPToUTF8(Result);
{$IFEND}
If (Length(Result) <= 0) and NumberForUnknown then
  Result := '0x' + IntToHex(VirtualKeyCode,2);
end;

//------------------------------------------------------------------------------

class Function TRawInputKeyboard.ShiftStatesToStr(ShiftStates: TKeyboardShiftStates; const Separator: String = ' '; DiscernSides: Boolean = False): String;

  procedure AddShiftStateStr(var Str: String; const ShiftStr: String);
  begin
    If Str <> '' then
      Str := Str + Separator + ShiftStr
    else
      Str := Str + ShiftStr;
  end;

begin
Result := '';
If DiscernSides then
  begin
    If kssLControl in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_LCONTROL));
    If kssRControl in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_RCONTROL));
    If kssLAlt in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_LMENU));
    If kssRAlt in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_RMENU));
    If kssLShift in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_LSHIFT));
    If kssRShift in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_RSHIFT));
  end
else
  begin
    If kssControl in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_CONTROL));
    If kssAlt in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_MENU));
    If kssShift in ShiftStates then AddShiftStateStr(Result,GetVirtualKeyName(VK_SHIFT));
  end;
end;

//------------------------------------------------------------------------------

constructor TRawInputKeyboard.Create(DeviceInfo: PDeviceListItem = nil);
begin
inherited Create(DeviceInfo);
fDoInputCorrection := True;
fDiscernSides := False;
fAdditionalVKeys := False;
fKeyStates := TBitVector.Create(High(Byte));
end;

//------------------------------------------------------------------------------

destructor TRawInputKeyboard.Destroy;
begin
fKeyStates.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboard.Invalidate;
begin
fKeyStates.Fill(False);
end;

//------------------------------------------------------------------------------

Function TRawInputKeyboard.GetShiftStates: TKeyboardShiftStates;
begin
Result := [];
If fKeyStates[VK_CONTROL] or fKeyStates[VK_RCONTROL] or fKeyStates[VK_LCONTROL] then
  Result := Result + [kssControl];
If fKeyStates[VK_MENU] or fKeyStates[VK_RMENU] or fKeyStates[VK_LMENU] then
  Result := Result + [kssAlt];
If fKeyStates[VK_SHIFT] or fKeyStates[VK_RSHIFT] or fKeyStates[VK_LSHIFT] then
  Result := Result + [kssShift];
If fDiscernSides then
  begin
    If fKeyStates[VK_RCONTROL] then
      Result := Result + [kssRControl];
    If fKeyStates[VK_LCONTROL] then
      Result := Result + [kssLControl];
    If fKeyStates[VK_RMENU] then
      Result := Result + [kssRAlt];
    If fKeyStates[VK_LMENU] then
      Result := Result + [kssLAlt];
    If fKeyStates[VK_RSHIFT] then
      Result := Result + [kssRShift];
    If fKeyStates[VK_LSHIFT] then
      Result := Result + [kssLShift];
  end;  
end;

//------------------------------------------------------------------------------

Function TRawInputKeyboard.GetIndicators: TKeyboardIndicators;
begin
Result := [];
If (GetKeyState(VK_NUMLOCK) and 1) <> 0 then
  Result := Result + [kiNumLock];
If (GetKeyState(VK_CAPITAL) and 1) <> 0 then
  Result := Result + [kiCapsLock];
If (GetKeyState(VK_SCROLL) and 1) <> 0 then
  Result := Result + [kiScrollLock];
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TRawInputKeyboardMaster                           }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputKeyboardMaster - implementation                                   }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TRawInputKeyboardMaster - private methods                                  }
{------------------------------------------------------------------------------}

Function TRawInputKeyboardMaster.GetDeviceCount: Integer;
begin
Result := fDevices.Count;
end;

//------------------------------------------------------------------------------

Function TRawInputKeyboardMaster.GetDevice(Index: Integer): TRawInputKeyboard;
begin
If (Index >= 0) and (Index < fDevices.Count) then
  Result := TRawInputKeyboard(fDevices[Index])
else
  raise Exception.CreateFmt('TRawInputKeyboardMaster.GetDevice: Index (%d) out of bounds.',[Index]);
end;

{------------------------------------------------------------------------------}
{   TRawInputKeyboardMaster - protected methods                                }
{------------------------------------------------------------------------------}

procedure TRawInputKeyboardMaster.ProcessRawInputSpecific(RawInput: PRawInput);
var
  Index:  Integer;
begin
If Assigned(fOnUnknownDeviceIntercepted) and (RawInput^.header.hDevice <> 0) then
  begin
    Index := IndexOfDevice(RawInput^.header.hDevice);
    If Index >= 0 then
      TRawInputKeyboard(fDevices[Index]).ProcessRawInput(RawInput)
    else
      begin
        fOnUnknownDeviceIntercepted(Self,RawInput^.header.hDevice);
        Index := IndexOfDevice(RawInput^.header.hDevice);
        If Index >= 0 then
          TRawInputKeyboard(fDevices[Index]).ProcessRawInput(RawInput);
      end;
  end;
inherited;
end;

//------------------------------------------------------------------------------

Function TRawInputKeyboardMaster.AddDeviceInternal(DeviceInfo: PDeviceListItem): Integer;
var
  TempObject: TRawInputKeyboardDeviceInternal;
  i:          Integer;
begin
TempObject := TRawInputKeyboardDeviceInternal.Create(DeviceInfo);
Result := fDevices.Add(TempObject);
If Result < 0 then
  TempObject.Free
else
  begin
    For i := 0 to Pred(fDevices.Count) do
      TRawInputKeyboardDeviceInternal(fDevices[i]).Index := i;
    If Assigned(fOnDevicesChange) then fOnDevicesChange(Self);
  end;
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboardMaster.DeleteDeviceInternal(Index: Integer);
var
  i:  Integer;
begin
If (Index >= 0) and (Index < fDevices.Count) then
  begin
    fDevices.Delete(Index);
    For i := 0 to Pred(fDevices.Count) do
      TRawInputKeyboardDeviceInternal(fDevices[i]).Index := i;
    If Assigned(fOnDevicesChange) then fOnDevicesChange(Self);  
  end
else
  raise Exception.CreateFmt('TRawInputKeyboardMaster.DeleteDeviceInternal: Index (%d) out of bounds.',[Index]);
end;

{------------------------------------------------------------------------------}
{   TRawInputKeyboardMaster - public methods                                   }
{------------------------------------------------------------------------------}

constructor TRawInputKeyboardMaster.Create;
begin
inherited Create(nil);
fDevices := TObjectList.Create(True);
end;

//------------------------------------------------------------------------------

destructor TRawInputKeyboardMaster.Destroy;
begin
fDevices.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboardMaster.Invalidate;
var
  i:  Integer;
begin
inherited;
For i := 0 to Pred(fDevices.Count) do
  TRawInputKeyboard(fDevices[i]).Invalidate;
end;

//------------------------------------------------------------------------------

Function TRawInputKeyboardMaster.IndexOfDevice(DeviceHandle: THandle): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := 0 to Pred(fDevices.Count) do
  If TRawInputKeyboard(fDevices[i]).DeviceInfo.Handle = DeviceHandle then
    begin
      Result := i;
      Break;
    end;
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                        TRawInputKeyboardDeviceInternal                       }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputKeyboardDeviceInternal - implementation                           }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TRawInputKeyboardDeviceInternal - protected methods                        }
{------------------------------------------------------------------------------}

procedure TRawInputKeyboardDeviceInternal.DoRawKeyboard(Sender: TObject; Input: TRawKeyboard);
begin
inherited;
If Assigned(fOnRawKeyboardInternal) then fOnRawKeyboardInternal(Sender,Input); 
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboardDeviceInternal.DoBeforeKeyPress(Sender: TObject; VirtualKeyCode: USHORT);
begin
inherited;
If Assigned(fOnBeforeKeyPressInternal) then fOnBeforeKeyPressInternal(Sender,VirtualKeyCode);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboardDeviceInternal.DoAfterKeyPress(Sender: TObject; VirtualKeyCode: USHORT);
begin
inherited;
If Assigned(fOnAfterKeyPressInternal) then fOnAfterKeyPressInternal(Sender,VirtualKeyCode);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboardDeviceInternal.DoBeforeKeyRelease(Sender: TObject; VirtualKeyCode: USHORT);
begin
inherited;
If Assigned(fOnBeforeKeyReleaseInternal) then fOnBeforeKeyReleaseInternal(Sender,VirtualKeyCode);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboardDeviceInternal.DoAfterKeyRelease(Sender: TObject; VirtualKeyCode: USHORT);
begin
inherited;
If Assigned(fOnAfterKeyReleaseInternal) then fOnAfterKeyReleaseInternal(Sender,VirtualKeyCode);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                        TRawInputKeyboardMasterInternal                       }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputKeyboardMasterInternal - implementation                           }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TRawInputKeyboardMasterInternal - public methods                           }
{------------------------------------------------------------------------------}

Function TRawInputKeyboardMasterInternal.AddDevice(DeviceInfo: PDeviceListItem; AssignCallbacks: Boolean = False): Integer;
begin
Result := AddDeviceInternal(DeviceInfo);
If (Result >= 0) and AssignCallbacks then
  with TRawInputKeyboardDeviceInternal(Devices[Result]) do
    begin
      OnRawKeyboardInternal := Self.DoRawKeyboard;
      OnBeforeKeyPressInternal := Self.DoBeforeKeyPress;
      OnAfterKeyPressInternal := Self.DoAfterKeyPress;
      OnBeforeKeyReleaseInternal := Self.DoBeforeKeyRelease;
      OnAfterKeyReleaseInternal := Self.DoAfterKeyRelease;
    end;
end;

//------------------------------------------------------------------------------

Function TRawInputKeyboardMasterInternal.RemoveDevice(DeviceHandle: THandle): Integer;
begin
Result := IndexOfDevice(DeviceHandle);
If Result >= 0 then DeleteDeviceInternal(Result);
end;

//------------------------------------------------------------------------------

procedure TRawInputKeyboardMasterInternal.DeleteDevice(Index: Integer);
begin
DeleteDeviceInternal(Index);
end;

end.

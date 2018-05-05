{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  RawInput managing library

  Common material and classes

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
unit RawInputCommon;

{$INCLUDE 'RawInput_defs.inc'}

interface

uses
  Windows, Classes,
  AuxClasses, WinRawInput;

type
  TPreparsedData = array of Byte;

  TAdditionalInfo = record
    Description:    String;
    Manufacturer:   String;
    DeviceClass:    String;
    ClassGUID:      TGUID;
  end;

  TDeviceListItem = record
    Handle:         THandle;  
    Name:           String;
    Info:           RID_DEVICE_INFO;
    PreparsedData:  TPreparsedData;
    AdditionalInfo: TAdditionalInfo;
  end;
  PDeviceListItem = ^TDeviceListItem;

  TDeviceList = array of TDeviceListItem;
  PDeviceList = ^TDeviceList;

  TRegisteredDevicesList = array of TRawInputDevice;
  PRegisteredDevicesList = ^TRegisteredDevicesList;

  TRawInputEvent = procedure(Sender: TObject; Data: Pointer; Size: UINT) of object;

  TUnknownDeviceEvent = procedure(Sender: TObject; DeviceHandle: THandle) of object;

{==============================================================================}
{------------------------------------------------------------------------------}
{                           TRawInputProcessingObject                          }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputProcessingObject - declaration                                    }
{==============================================================================}

  TRawInputProcessingObject = class(TCustomObject)
  private
    fActive:              Boolean;
    fDeviceInfo:          TDeviceListItem;
    fIndex:               Integer;
    fTag:                 Integer;
    fUserData:            Pointer;
    fOnRawInput:          TRawInputEvent;
    fOnDestroy:           TNotifyEvent;
  protected
    procedure ProcessRawInputSpecific(RawInput: PRawInput); virtual; abstract;
  public
    constructor Create(DeviceInfo: PDeviceListItem = nil);
    destructor Destroy; override;
    procedure ProcessRawInput(RawInput: PRawInput); virtual;
    procedure Invalidate; virtual; abstract;
    property UserData: Pointer read fUserData write fUserData;
    property DeviceInfo: TDeviceListItem read fDeviceInfo;
  published
    property Active: Boolean read fActive write fActive;
    property Index: Integer read fIndex write fIndex;
    property Tag: Integer read fTag write fTag;
    property OnRawInput: TRawInputEvent read fOnRawInput write fOnRawInput;
    property OnDestroy: TNotifyEvent read fOnDestroy write fOnDestroy;
  end;

implementation

{==============================================================================}
{------------------------------------------------------------------------------}
{                           TRawInputProcessingObject                          }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRawInputProcessingObject - implementation                                 }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TRawInputProcessingObject - public methods                                 }
{------------------------------------------------------------------------------}

constructor TRawInputProcessingObject.Create(DeviceInfo: PDeviceListItem = nil);
begin
inherited Create;
fActive := True;
If Assigned(DeviceInfo) then
  fDeviceInfo := DeviceInfo^
else
  FillChar(fDeviceInfo,SizeOf(TDeviceListItem),0);
fIndex := -1;
end;

//------------------------------------------------------------------------------

destructor TRawInputProcessingObject.Destroy;
begin
If Assigned(fOnDestroy) then fOnDestroy(Self);
inherited;
end;

//------------------------------------------------------------------------------

procedure TRawInputProcessingObject.ProcessRawInput(RawInput: PRawInput);
begin
If fActive then
  begin
    If Assigned(fOnRawInput) then fOnRawInput(Self,RawInput,RawInput^.header.dwSize);
    ProcessRawInputSpecific(RawInput);
  end;
end;

end.

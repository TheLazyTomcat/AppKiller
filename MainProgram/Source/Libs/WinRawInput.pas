{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  WinRawInput
  
  Constants, structures, external functions definitions and macros (here
  implemented as normal functions) used in handling of raw input in Windows OS.

  ©František Milt 2016-05-06

  Version 1.2

===============================================================================}
unit WinRawInput;

{$IF defined(CPU64) or defined(CPU64BITS)}
  {$DEFINE 64bit}
{$ELSEIF defined(CPU16)}
  {$MESSAGE FATAL 'Unsupported CPU.'}
{$ELSE}
  {$DEFINE 32bit}
{$IFEND}

{$IF not(defined(MSWINDOWS) or defined(WINDOWS))}
  {$MESSAGE FATAL 'Unsupported operating system.'}
{$IFEND}

interface

uses
  Windows;

{
  Basic types used in Raw Input structures and function parameters.
}
type
  USHORT = Word;
  LONG   = LongInt;
  INT    = Integer;
  HANDLE = THandle;
  QWORD  = UInt64;

  HRAWINPUT = THandle;

{==============================================================================}
{   Raw Input constants                                                        }
{==============================================================================}
const
{
  Codes of windows messages tied to raw input.
}
  WM_INPUT_DEVICE_CHANGE = $00FE;
  WM_INPUT               = $00FF;

{
  Possible values of wParam in WM_INPUT message.
}
  RIM_INPUT     = 0;
  RIM_INPUTSINK = 1;

{
  Possible values of wParam in WM_INPUT_DEVICE_CHANGEmessage.
}
  GIDC_ARRIVAL = 1;
  GIDC_REMOVAL = 2;

{
  Values for field RAWINPUTDEVICE.dwFlags.
}
  RIDEV_REMOVE       = $00000001;
  RIDEV_EXCLUDE      = $00000010;
  RIDEV_PAGEONLY     = $00000020;
  RIDEV_NOLEGACY     = $00000030;
  RIDEV_INPUTSINK    = $00000100;
  RIDEV_NOHOTKEYS    = $00000200;
  RIDEV_CAPTUREMOUSE = $00000200;
  RIDEV_APPKEYS      = $00000400;
  RIDEV_EXINPUTSINK  = $00001000;
  RIDEV_DEVNOTIFY    = $00002000;
  RIDEV_EXMODEMASK   = $000000F0;

{
  Values for fields RAWINPUTDEVICELIST.dwType, RAWINPUTHEADER.dwType and
  RID_DEVICE_INFO.dwType.
}
  RIM_TYPEMOUSE    = 0;
  RIM_TYPEKEYBOARD = 1;
  RIM_TYPEHID      = 2;
  RIM_TYPEMAX      = 2;

{
  Values for field RAWMOUSE.usFlags.
}
  MOUSE_MOVE_RELATIVE      = $00;
  MOUSE_MOVE_ABSOLUTE      = $01;
  MOUSE_VIRTUAL_DESKTOP    = $02;
  MOUSE_ATTRIBUTES_CHANGED = $04;
  MOUSE_MOVE_NOCOALESCE    = $08;

{
  Values for field RAWMOUSE.usButtonFlags.
}
  RI_MOUSE_LEFT_BUTTON_DOWN   = $0001;
  RI_MOUSE_LEFT_BUTTON_UP     = $0002;
  RI_MOUSE_RIGHT_BUTTON_DOWN  = $0004;
  RI_MOUSE_RIGHT_BUTTON_UP    = $0008;
  RI_MOUSE_MIDDLE_BUTTON_DOWN = $0010;
  RI_MOUSE_MIDDLE_BUTTON_UP   = $0020;
  RI_MOUSE_BUTTON_1_DOWN      = RI_MOUSE_LEFT_BUTTON_DOWN;
  RI_MOUSE_BUTTON_1_UP        = RI_MOUSE_LEFT_BUTTON_UP;
  RI_MOUSE_BUTTON_2_DOWN      = RI_MOUSE_RIGHT_BUTTON_DOWN;
  RI_MOUSE_BUTTON_2_UP        = RI_MOUSE_RIGHT_BUTTON_UP;
  RI_MOUSE_BUTTON_3_DOWN      = RI_MOUSE_MIDDLE_BUTTON_DOWN;
  RI_MOUSE_BUTTON_3_UP        = RI_MOUSE_MIDDLE_BUTTON_UP;
  RI_MOUSE_BUTTON_4_DOWN      = $0040;
  RI_MOUSE_BUTTON_4_UP        = $0080;
  RI_MOUSE_BUTTON_5_DOWN      = $0100;
  RI_MOUSE_BUTTON_5_UP        = $0200;
  RI_MOUSE_WHEEL              = $0400;
  RI_MOUSE_HWHEEL             = $0800;  // Windows Vista+

{
  Values for field RAWKEYBOARD.Flags.
}
  RI_KEY_MAKE            = 0;
  RI_KEY_BREAK           = 1;
  RI_KEY_E0              = 2;
  RI_KEY_E1              = 4;
  RI_KEY_TERMSRV_SET_LED = 8;
  RI_KEY_TERMSRV_SHADOW  = $10;

{
  Values for parameter uiCommand in function GetRawInputData.
}
  RID_INPUT  = $10000003;
  RID_HEADER = $10000005;

{
  Values for parameter uiCommand in function GetRawInputDeviceInfo.
}
  RIDI_PREPARSEDDATA = $20000005;
  RIDI_DEVICENAME    = $20000007;
  RIDI_DEVICEINFO    = $2000000b;

{
  Other raw input constants.
}
  KEYBOARD_OVERRUN_MAKE_CODE = $FF;


{==============================================================================}
{   Raw Input structures                                                       }
{==============================================================================}

type
{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645565(v=vs.85).aspx
}
  tagRAWINPUTDEVICE = record
    usUsagePage:  USHORT;
    usUsage:      USHORT;
    dwFlags:      DWORD;
    hwndTarget:   HWND;
  end;
  
   RAWINPUTDEVICE = tagRAWINPUTDEVICE;
  TRAWINPUTDEVICE = tagRAWINPUTDEVICE;   
  PRAWINPUTDEVICE = ^TRAWINPUTDEVICE;
 LPRAWINPUTDEVICE = ^TRAWINPUTDEVICE;

  TRAWINPUTDEVICEARRAY = array[0..High(Word)] of TRAWINPUTDEVICE;
  PRAWINPUTDEVICEARRAY = ^TRAWINPUTDEVICEARRAY;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645568(v=vs.85).aspx
}
  tagRAWINPUTDEVICELIST = record
    hDevice:  HANDLE;
    dwType:   DWORD;
  end;

   RAWINPUTDEVICELIST = tagRAWINPUTDEVICELIST;
  TRAWINPUTDEVICELIST = tagRAWINPUTDEVICELIST;
  PRAWINPUTDEVICELIST = ^TRAWINPUTDEVICELIST;

//------------------------------------------------------------------------------  

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645571(v=vs.85).aspx
}
  tagRAWINPUTHEADER = record
    dwType:   DWORD;
    dwSize:   DWORD;
    hDevice:  HANDLE;
    wParam:   WPARAM;
  end;

   RAWINPUTHEADER = tagRAWINPUTHEADER;
  TRAWINPUTHEADER = tagRAWINPUTHEADER;
  PRAWINPUTHEADER = ^TRAWINPUTHEADER;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645578(v=vs.85).aspx
}
  tagRAWMOUSE = record
    usFlags:  USHORT;
    case Integer of
      0:  (ulButtons:     ULONG);
      1:  (usButtonFlags: USHORT;
           usButtonsData: USHORT;
    ulRawButtons:       ULONG;
    lLastX:             LONG;
    lLastY:             LONG;
    ulExtraInformation: ULONG);
  end;

   RAWMOUSE = tagRAWMOUSE;
  TRAWMOUSE = tagRAWMOUSE;
  PRAWMOUSE = ^TRAWMOUSE;
 LPRAWMOUSE = ^TRAWMOUSE;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645575(v=vs.85).aspx
}
  tagRAWKEYBOARD = record
    MakeCode:         USHORT;
    Flags:            USHORT;
    Reserved:         USHORT;
    VKey:             USHORT;
    Message:          UINT;
    ExtraInformation: ULONG;
  end;

   RAWKEYBOARD = tagRAWKEYBOARD;
  TRAWKEYBOARD = tagRAWKEYBOARD;
  PRAWKEYBOARD = ^TRAWKEYBOARD;
 LPRAWKEYBOARD = ^TRAWKEYBOARD;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645549(v=vs.85).aspx
}
  tagRAWHID = record
    dwSizeHid:  DWORD;
    dwCount:    DWORD;
    bRawData:   Byte;   // this is actually a variable-length array of bytes
  end;

   RAWHID = tagRAWHID;
  TRAWHID = tagRAWHID;
  PRAWHID = ^TRAWHID;
 LPRAWHID = ^TRAWHID;

//------------------------------------------------------------------------------
 
{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645562(v=vs.85).aspx
}
  tagRAWINPUT = record
    header: RAWINPUTHEADER;
    case Integer of
      RIM_TYPEMOUSE:   (mouse:     RAWMOUSE);
      RIM_TYPEKEYBOARD:(keyboard:  RAWKEYBOARD);
      RIM_TYPEHID:     (hid:       RAWHID);
  end;
  
   RAWINPUT = tagRAWINPUT;
  TRAWINPUT = tagRAWINPUT;
  PRAWINPUT = ^TRAWINPUT;
 LPRAWINPUT = ^TRAWINPUT;

 PPRAWINPUT = ^PRAWINPUT;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645589(v=vs.85).aspx
}
  tagRID_DEVICE_INFO_MOUSE = record
    dwId:                 DWORD;
    dwNumberOfButtons:    DWORD;
    dwSampleRate:         DWORD;
    fHasHorizontalWheel:  BOOL;   // supported only from Windows Vista up
  end;

   RID_DEVICE_INFO_MOUSE = tagRID_DEVICE_INFO_MOUSE;
  TRID_DEVICE_INFO_MOUSE = tagRID_DEVICE_INFO_MOUSE;
  PRID_DEVICE_INFO_MOUSE = ^TRID_DEVICE_INFO_MOUSE;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645587(v=vs.85).aspx
}
  tagRID_DEVICE_INFO_KEYBOARD = record
    dwType:                 DWORD;
    dwSubType:              DWORD;
    dwKeyboardMode:         DWORD;
    dwNumberOfFunctionKeys: DWORD;
    dwNumberOfIndicators:   DWORD;
    dwNumberOfKeysTotal:    DWORD;
  end;

   RID_DEVICE_INFO_KEYBOARD = tagRID_DEVICE_INFO_KEYBOARD;
  TRID_DEVICE_INFO_KEYBOARD = tagRID_DEVICE_INFO_KEYBOARD;
  PRID_DEVICE_INFO_KEYBOARD = ^TRID_DEVICE_INFO_KEYBOARD;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645584(v=vs.85).aspx
}
  tagRID_DEVICE_INFO_HID = record
    dwVendorId:       DWORD;
    dwProductId:      DWORD;
    dwVersionNumber:  DWORD;
    usUsagePage:      USHORT;
    usUsage:          USHORT;
  end;

   RID_DEVICE_INFO_HID = tagRID_DEVICE_INFO_HID;
  TRID_DEVICE_INFO_HID = tagRID_DEVICE_INFO_HID;
  PRID_DEVICE_INFO_HID = ^TRID_DEVICE_INFO_HID;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645581(v=vs.85).aspx
}
  tagRID_DEVICE_INFO = record
    cbSize: DWORD;
    case dwType: DWORD of
      RIM_TYPEMOUSE:   (mouse:    RID_DEVICE_INFO_MOUSE);
      RIM_TYPEKEYBOARD:(keyboard: RID_DEVICE_INFO_KEYBOARD);
      RIM_TYPEHID:     (hid:      RID_DEVICE_INFO_HID);
  end;

   RID_DEVICE_INFO = tagRID_DEVICE_INFO;
  TRID_DEVICE_INFO = tagRID_DEVICE_INFO;
  PRID_DEVICE_INFO = ^TRID_DEVICE_INFO;
 LPRID_DEVICE_INFO = ^TRID_DEVICE_INFO;  

{==============================================================================}
{   Raw Input functions                                                        }
{==============================================================================}

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645594(v=vs.85).aspx
}
Function DefRawInputProc(
            paRawInput:   PPRAWINPUT;
            nInput:       INT;
            cbSizeHeader: UINT): LRESULT; stdcall; external user32;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645595(v=vs.85).aspx

  There are issues with memory alignment, see linked description for details.
}
Function GetRawInputBuffer(
            pData:        PRAWINPUT;
            pcbSize:      PUINT; 
            cbSizeHeader: UINT): UINT; stdcall; external user32;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645596(v=vs.85).aspx
}
Function GetRawInputData(
            hRawInput:    HRAWINPUT;
            uiCommand:    UINT;
            pData:        Pointer;  // must be aligned by 8 bytes on Win64
            pcbSize:      PUINT;
            cbSizeHeader: UINT): UINT; stdcall; external user32;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645597(v=vs.85).aspx
}
Function GetRawInputDeviceInfo(
            hDevice:    THandle;
            uiCommand:  UINT;
            pData:      Pointer;
            pcbSize:    PUINT): UINT; stdcall; external user32 name{$IFDEF UNICODE}'GetRawInputDeviceInfoW'{$ELSE}'GetRawInputDeviceInfoA'{$ENDIF};

Function GetRawInputDeviceInfoA(
            hDevice:    THandle;
            uiCommand:  UINT;
            pData:      Pointer;
            pcbSize:    PUINT): UINT; stdcall; external user32;

Function GetRawInputDeviceInfoW(
            hDevice:    THandle;
            uiCommand:  UINT;
            pData:      Pointer;
            pcbSize:    PUINT): UINT; stdcall; external user32;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645598(v=vs.85).aspx
}
Function GetRawInputDeviceList(
            pRawInputDeviceLis: PRAWINPUTDEVICELIST;
            puiNumDevices:      PUINT;
            cbSize:             UINT): UINT; stdcall; external user32;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645599(v=vs.85).aspx
}
Function GetRegisteredRawInputDevices(
            pRawInputDevices: PRAWINPUTDEVICE;
            puiNumDevices:    PUINT;
            cbSize:           UINT): UINT; stdcall; external user32;

//------------------------------------------------------------------------------

{
  https://msdn.microsoft.com/en-us/library/windows/desktop/ms645600(v=vs.85).aspx
}
Function RegisterRawInputDevices(
            pRawInputDevices: PRAWINPUTDEVICE;
            uiNumDevices:     UINT;
            cbSize:           UINT): BOOL; stdcall; external user32;

{==============================================================================}
{   Raw Input macros                                                           }
{==============================================================================}

Function GET_RAWINPUT_CODE_WPARAM(wParam: WPARAM): WPARAM;
Function RAWINPUT_ALIGN(x: Pointer): Pointer;
Function NEXTRAWINPUTBLOCK(ptr: PRAWINPUT): PRAWINPUT;
Function RIDEV_EXMODE(Mode: DWORD): DWORD;
Function GET_DEVICE_CHANGE_WPARAM(wParam: wParam): wParam;
Function GET_DEVICE_CHANGE_LPARAM(lParam: lParam): lParam;

{==============================================================================}
{   Auxiliary types and functions                                              }
{==============================================================================}

{$IFDEF 32bit}
type
{
  Structure that is designed to be used to access data returned by function
  GetRawInputBuffer in WoW64 (data structures in the array returned by mentioned
  function have different memory alignment in WoW64 then they have in native
  32bit OS).
}
  TRawInputWoW64 = record
    header:   RAWINPUTHEADER;
    padding:  Int64;
    case Integer of
      RIM_TYPEMOUSE:   (mouse:     RAWMOUSE);
      RIM_TYPEKEYBOARD:(keyboard:  RAWKEYBOARD);
      RIM_TYPEHID:     (hid:       RAWHID);
  end;
  PRawInputWoW64 = ^TRawInputWoW64;

{
  Converts RAWINPUT structure that have WoW64 memory alignment to normal 32bit
  structure.
}
Function WoW64Conversion(RawInput: TRawInputWoW64): RAWINPUT; overload;

{
  Performs in-place conversion from RAWINPUT structure with WoW64 memory
  aligment to normal 32bit structure - it shifts data (that is, field
  mouse/keyboard/hid) down by 8 bytes. When ChangeSize is true, the size stored
  in structure's header is decreased by 8, otherwise it is not changed.
  Data parameter MUST point to the start of TRawInputWoW64 structure.
}
procedure WoW64Conversion(Data: Pointer; ChangeSize: Boolean = False); overload;
{$ENDIF}


implementation

uses
  AuxTypes;

//------------------------------------------------------------------------------

Function GET_RAWINPUT_CODE_WPARAM(wParam: WPARAM): WPARAM;
begin
Result := wParam and $FF;
end;

//------------------------------------------------------------------------------

Function RAWINPUT_ALIGN(x: Pointer): Pointer;
begin
{$IFDEF 64bit}
Result := {%H-}Pointer(({%H-}PtrUInt(x) + (SizeOf(QWORD) - 1)) and not (SizeOf(QWORD) - 1));
{$ELSE}
Result := {%H-}Pointer(({%H-}PtrUInt(x) + (SizeOf(DWORD) - 1)) and not (SizeOf(DWORD) - 1));
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function NEXTRAWINPUTBLOCK(ptr: PRAWINPUT): PRAWINPUT;
begin
Result := PRAWINPUT(RAWINPUT_ALIGN({%H-}Pointer({%H-}PtrUInt(ptr) + ptr^.header.dwSize)));
end;

//------------------------------------------------------------------------------

Function RIDEV_EXMODE(Mode: DWORD): DWORD;
begin
Result := Mode and RIDEV_EXMODEMASK;
end;

//------------------------------------------------------------------------------

Function GET_DEVICE_CHANGE_WPARAM(wParam: wParam): wParam;
begin
Result := LoWord(wParam);
end;

//------------------------------------------------------------------------------

Function GET_DEVICE_CHANGE_LPARAM(lParam: lParam): lParam;
begin
Result := LoWord(lParam);
end;

//==============================================================================

{$IFDEF 32bit}
Function WoW64Conversion(RawInput: TRawInputWoW64): RAWINPUT;
begin
Result.header := RawInput.header;
Result.header.dwSize := SizeOf(RAWINPUT);
Result.mouse := RawInput.mouse;
end;
 
//------------------------------------------------------------------------------

procedure WoW64Conversion(Data: Pointer; ChangeSize: Boolean = False); 
var
  DataOffset: PtrUInt;
begin
DataOffset := {%H-}PtrUInt(Addr(TRawInputWoW64(nil^).mouse));
Move({%H-}Pointer({%H-}PtrUInt(Data) + DataOffset)^,Addr(PRawInput(Data)^.mouse)^,PRawInput(Data)^.header.dwSize - DataOffset);
If ChangeSize then
  Dec(PRawInput(Data)^.header.dwSize,8);
end;
{$ENDIF}

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit APK_Keyboard;

{$INCLUDE APK_Defs.inc}

interface

uses
  Classes,
  WinRawInput,
  RawInputManager, RawInputKeyboard;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                 TAPKKeyboard                                 }
{------------------------------------------------------------------------------}
{==============================================================================}

type
  TAPKShortcut = record
    MainKey:      USHORT;
    ShiftStates:  TKeyboardShiftStates;
  end;

  TAPKShortcutEvent = procedure(Sender: TObject; Shortcut: TAPKShortcut) of object;

  TAPKKeyboardMode = (kmNone,kmIntercept,kmSelect);

{==============================================================================}
{   TAPKKeyboard - declaration                                                 }
{==============================================================================}

  TAPKKeyboard = class(TOBject)
  private
    fMode:          TAPKKeyboardMode;
    fInputManager:  TRawInputManager;
    fShortcut:      TAPKShortcut;
    fOnTrigger:     TNotifyEvent;
    fOnShortcut:    TAPKShortcutEvent;
  protected
    procedure KeyEventHandler(Sender: TObject; VKey: USHORT); virtual;
  public
    class Function ShortcutAsText(Shortcut: TAPKShortcut): String; virtual;
    constructor Create;
    destructor Destroy; override;
    property Shortcut: TAPKShortcut read fShortcut write fShortcut;
  published
    property Mode: TAPKKeyboardMode read fMode write fMode;
    property InputManager: TRawInputManager read fInputManager;
    property OnTrigger: TNotifyEvent read fOnTrigger write fOnTrigger;
    property OnShortcut: TAPKShortcutEvent read fOnShortcut write fOnShortcut;
  end;

implementation

uses
  Windows;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                 TAPKKeyboard                                 }
{------------------------------------------------------------------------------}
{==============================================================================}

const
  DefaultShortcut: TAPKShortcut = (
    MainKey:      VK_CANCEL;
    ShiftStates:  [kssControl,kssAlt]);

{==============================================================================}
{   TAPKKeyboard - implementation                                              }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKKeyboard - protected methods                                           }
{------------------------------------------------------------------------------}

procedure TAPKKeyboard.KeyEventHandler(Sender: TObject; VKey: USHORT);
var
  TempShortcut: TAPKShortcut;
begin
case fMode of
  kmIntercept:
    If Assigned(fOnTrigger) and not (Vkey in [VK_SHIFT,VK_MENU,VK_CONTROL]) then
      If (VKey = fShortcut.MainKey) and (TRawInputKeyboard(Sender).GetShiftStates = fShortcut.ShiftStates) then
        fOnTrigger(Self);
  kmSelect:
    If Assigned(fOnShortcut) and not (Vkey in [VK_SHIFT,VK_MENU,VK_CONTROL]) then
      begin
        TempShortcut.MainKey := VKey;
        TempShortcut.ShiftStates := TRawInputKeyboard(Sender).GetShiftStates;
        fOnShortcut(Self,TempShortcut);
      end;
end;
end;

{------------------------------------------------------------------------------}
{   TAPKKeyboard - public methods                                              }
{------------------------------------------------------------------------------}

class Function TAPKKeyboard.ShortcutAsText(Shortcut: TAPKShortcut): String;
begin
If Shortcut.ShiftStates <> [] then
  Result := TRawInputKeyboard.ShiftStatesToStr(Shortcut.ShiftStates,' + ') + ' + ' + TRawInputKeyboard.GetVirtualKeyName(Shortcut.MainKey)
else
  Result := TRawInputKeyboard.GetVirtualKeyName(Shortcut.MainKey);
end;

//------------------------------------------------------------------------------

constructor TAPKKeyboard.Create;
begin
inherited;
fMode := kmNone;
fShortcut := DefaultShortcut;
fInputManager := TRawInputManagerEx.Create([rmoFlagInputSink,rmoRegisterForKeyboard]);
fInputManager.Keyboard.OnKeyPress := KeyEventHandler;
fInputManager.Active := True;
end;

//------------------------------------------------------------------------------

destructor TAPKKeyboard.Destroy;
begin
fInputManager.Free;
inherited;
end;

end.

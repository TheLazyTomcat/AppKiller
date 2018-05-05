{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit APK_Manager;

{$INCLUDE APK_Defs.inc}

interface

uses
  Classes,
  SimpleLog,
  APK_Settings, APK_TrayIcon, APK_Keyboard, APK_Terminator;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                 TAPKManager                                  }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKManager - declaration                                                  }
{==============================================================================}

type
  TAPKManager = class(TObject)
  private
    fTrayIcon:                  TAPKTrayIcon;
    fSettings:                  TAPKSettings;
    fLog:                       TSimpleLog;
    fKeyboard:                  TAPKKeyboard;
    fTerminator:                TAPKTerminator;
    fOnSettingsUpdateRequired:  TNotifyEvent;
  protected
    procedure TriggerHandler(Sender: TObject); virtual;
    procedure LogWriteHandler(Sender: TObject; const Text: String); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
    procedure Terminate; virtual;
  published
    property TrayIcon: TAPKTrayIcon read fTrayIcon;
    property Settings: TAPKSettings read fSettings;
    property Log: TSimpleLog read fLog;
    property Keyboard: TAPKKeyboard read fKeyboard;
    property Terminator: TAPKTerminator read fTerminator;
    property OnSettingsUpdateRequired: TNotifyEvent read fOnSettingsUpdateRequired write fOnSettingsUpdateRequired;
  end;

implementation

uses
  SysUtils, StrRect, APK_Strings;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{==============================================================================}
{------------------------------------------------------------------------------}
{                                 TAPKManager                                  }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKManager - imlementation                                                }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKManager - protected methods                                            }
{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TAPKManager.TriggerHandler(Sender: TObject);
begin
fLog.AddLog('Termination started by keybord shortcut...');
Terminate;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TAPKManager.LogWriteHandler(Sender: TObject; const Text: String);
begin
fLog.AddLog(Text);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}
{   TAPKManager - public methods                                               }
{------------------------------------------------------------------------------}

constructor TAPKManager.Create;
begin
inherited;
fSettings := TAPKSettings.Create;
fTrayIcon := TAPKTrayIcon.Create;
fLog := TSimpleLog.Create;
fLog.InternalLog := False;
fLog.StreamFileName := ExtractFilePath(RTLToStr(ParamStr(0))) + 'AppKiller.log';
fLog.StreamAppend := True;
fLog.StreamToFile := True;
fKeyboard := TAPKKeyboard.Create;
fKeyboard.OnTrigger := TriggerHandler;
fTerminator := TAPKTerminator.Create;
fTerminator.OnLogWrite := LogWriteHandler;
end;

//------------------------------------------------------------------------------

destructor TAPKManager.Destroy;
begin
fTerminator.Free;
fKeyboard.Free;
fLog.Free;
fTrayIcon.Free;
fSettings.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TAPKManager.Initialize;
begin
fSettings.Load;
fTrayIcon.SetTipText(APKSTR_CM_ProgramTitle); // default text, changed later
fTrayIcon.ShowTrayIcon;
fKeyboard.Shortcut := fSettings.GetShortcut;
fKeyboard.Mode := kmIntercept;
end;

//------------------------------------------------------------------------------

procedure TAPKManager.Finalize;
begin
fSettings.SetShortcut(fKeyboard.Shortcut);
fSettings.Save(True);
end;

//------------------------------------------------------------------------------

procedure TAPKManager.Terminate;
begin
If Assigned(fOnSettingsUpdateRequired) then fOnSettingsUpdateRequired(Self);
fTerminator.StartTermination(fSettings);
fTrayIcon.UpdateTrayIcon;
end;

end.

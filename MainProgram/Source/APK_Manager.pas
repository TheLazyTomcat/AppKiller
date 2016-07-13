unit APK_Manager;

{$INCLUDE APK_Defs.inc}

interface

uses
  Classes,
  SimpleLog,
  APK_Settings, APK_TrayIcon, APK_Keyboard, APK_Terminator;

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
  SysUtils,
  AuxTypes, RawInputKeyboard,
  APK_Strings
  {$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
  , LazUTF8
  {$IFEND};

procedure TAPKManager.TriggerHandler(Sender: TObject);
begin
fLog.AddLog('Termination started by keybord shortcut...');
Terminate;
end;

procedure TAPKManager.LogWriteHandler(Sender: TObject; const Text: String);
begin
fLog.AddLog(Text);
end;

//==============================================================================

constructor TAPKManager.Create;
begin
inherited;
fSettings := TAPKSettings.Create;
fTrayIcon := TAPKTrayIcon.Create;
fLog := TSimpleLog.Create;
fLog.InternalLog := False;
{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
fLog.StreamFileName := ExtractFilePath(SysToUTF8(ParamStr(0))) + 'AppKiller.log';
{$ELSE}
fLog.StreamFileName := ExtractFilePath(ParamStr(0)) + 'AppKiller.log';
{$IFEND}
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
var
  TempShortcut: TAPKShortcut;
begin
fSettings.Load;
fTrayIcon.SetTipText(APKSTR_CM_ProgramTitle); // default text, changed later
fTrayIcon.ShowTrayIcon;
TempShortcut.MainKey := fSettings.Settings.GeneralSettings.Shortcut shr 16;
TempShortcut.ShiftStates := [];
If fSettings.Settings.GeneralSettings.Shortcut and 1 <> 0 then
  Include(TempShortcut.ShiftStates,kssControl);
If fSettings.Settings.GeneralSettings.Shortcut and 2 <> 0 then
  Include(TempShortcut.ShiftStates,kssAlt);
If fSettings.Settings.GeneralSettings.Shortcut and 4 <> 0 then
  Include(TempShortcut.ShiftStates,kssShift);
fKeyboard.Shortcut := TempShortcut;
fKeyboard.Mode := kmIntercept;
end;

//------------------------------------------------------------------------------

procedure TAPKManager.Finalize;
var
  Temp: UInt32;
begin
Temp := fKeyboard.Shortcut.MainKey shl 16;
If kssControl in fKeyboard.Shortcut.ShiftStates then
  Temp := Temp or 1;
If kssAlt in fKeyboard.Shortcut.ShiftStates then
  Temp := Temp or 2;
If kssShift in fKeyboard.Shortcut.ShiftStates then
  Temp := Temp or 4;
fSettings.SettingsPtr^.GeneralSettings.Shortcut := Temp;
fSettings.Save;
end;

//------------------------------------------------------------------------------

procedure TAPKManager.Terminate;
begin
If Assigned(fOnSettingsUpdateRequired) then fOnSettingsUpdateRequired(Self);
fTerminator.StartTermination(fSettings);
fTrayIcon.UpdateTrayIcon;
end;

end.

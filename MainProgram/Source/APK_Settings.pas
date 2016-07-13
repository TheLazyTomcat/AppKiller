unit APK_Settings;

{$INCLUDE APK_Defs.inc}

interface

uses
  AuxTypes;

type
  TAPKProcessListItem = record
    Active:       Boolean;  
    ProcessName:  String;
  end;

  TAPKProcessList = array of TAPKProcessListItem;

  TAPKSettingsGeneral = record
    RunAtSystemStart:       Boolean;
    TerminateForegroundWnd: Boolean;
    TerminateByList:        Boolean;
    TerminateUnresponsive:  Boolean;
    ResponseTimeout:        Integer;
    Shortcut:               UInt32;
  end;

  TAPKSettingsStruct = record
    GeneralSettings:        TAPKSettingsGeneral;
    ProcListTerminate:      TAPKProcessList;
    ProcListNeverTerminate: TAPKProcessList;
  end;
  PAPKSettingsStruct = ^TAPKSettingsStruct;

  TAPKSettings = class(TObject)
  private
    fSettings:  TAPKSettingsStruct;
    Function GetSettingsPtr: PAPKSettingsStruct;
  protected
    procedure RunAtSystemStart(Activate: Boolean); virtual;
  public
    constructor Create;
    constructor CreateCopy(Source: TAPKSettings);
    procedure LoadDefaultSettings; virtual;
    procedure SaveToIni(const FileName: String); virtual;
    procedure LoadFromIni(const FileName: String); virtual;
    procedure Save; virtual;
    procedure Load; virtual;
    property Settings: TAPKSettingsStruct read fSettings;
    property SettingsPtr: PAPKSettingsStruct read GetSettingsPtr;
  published
  end;

implementation

uses
  Windows, SysUtils, IniFiles, DefRegistry
  {$IF Defined(FPC) and not Defined(Unicode)}, LazUTF8{$IFEND};

const
  DefaultSettings: TAPKSettingsStruct = (
    GeneralSettings: (
      RunAtSystemStart:       True;
      TerminateForegroundWnd: True;
      TerminateByList:        True;
      TerminateUnresponsive:  True;
      ResponseTimeout:        1000;
      Shortcut:               $00030003);
    ProcListTerminate:      nil;
    ProcListNeverTerminate: nil);

//==============================================================================

Function TAPKSettings.GetSettingsPtr: PAPKSettingsStruct;
begin
Result := Addr(fSettings);
end;

//==============================================================================

procedure TAPKSettings.RunAtSystemStart(Activate: Boolean);
var
  Reg:  TDefRegistry;
begin
Reg := TDefRegistry.Create;
try
  Reg.RootKey := HKEY_CURRENT_USER;
  If Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run',False) then
    begin
      If Activate then
      {$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION >= 20701)}
        Reg.WriteString('AppKiller 3',UTF8ToWinCP(ParamStr(0)))
      {$ELSE}
        Reg.WriteString('AppKiller 3',ParamStr(0))
      {$IFEND}
      else
        Reg.DeleteValue('AppKiller 3');
      Reg.CloseKey;
    end;
finally
  Reg.Free;
end;
end;

//==============================================================================

constructor TAPKSettings.Create;
begin
inherited Create;
LoadDefaultSettings;
end;

//------------------------------------------------------------------------------

constructor TAPKSettings.CreateCopy(Source: TAPKSettings);
var
  i:  Integer;
begin
inherited Create;
fSettings.GeneralSettings := Source.Settings.GeneralSettings;
SetLength(fSettings.ProcListTerminate,Length(Source.Settings.ProcListTerminate));
For i := Low(fSettings.ProcListTerminate) to High(fSettings.ProcListTerminate) do
  begin
    fSettings.ProcListTerminate[i] := Source.Settings.ProcListTerminate[i];
    UniqueString(fSettings.ProcListTerminate[i].ProcessName);
  end;
SetLength(fSettings.ProcListNeverTerminate,Length(Source.Settings.ProcListNeverTerminate));
For i := Low(fSettings.ProcListNeverTerminate) to High(fSettings.ProcListNeverTerminate) do
  begin
    fSettings.ProcListNeverTerminate[i] := Source.Settings.ProcListNeverTerminate[i];
    UniqueString(fSettings.ProcListNeverTerminate[i].ProcessName);
  end;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.LoadDefaultSettings;
begin
fSettings := DefaultSettings;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.SaveToIni(const FileName: String);
var
  Ini:  TMemIniFile;
  i:    Integer;
begin
Ini := TMemIniFile.Create(FileName);
try
  Ini.WriteBool('Settings','RunAtSystemStart',fSettings.GeneralSettings.RunAtSystemStart);
  Ini.WriteBool('Settings','TerminateForegroundWnd',fSettings.GeneralSettings.TerminateForegroundWnd);
  Ini.WriteBool('Settings','TerminateByList',fSettings.GeneralSettings.TerminateByList);
  Ini.WriteBool('Settings','TerminateUnresponsive',fSettings.GeneralSettings.TerminateUnresponsive);
  Ini.WriteInteger('Settings','ResponseTimeout',fSettings.GeneralSettings.ResponseTimeout);
  Ini.WriteString('Settings','Shortcut',IntToHex(fSettings.GeneralSettings.Shortcut,8));
  Ini.WriteInteger('ProcListTerminate','Count',Length(fSettings.ProcListTerminate));
  For i := Low(fSettings.ProcListTerminate) to High(fSettings.ProcListTerminate) do
    begin
      Ini.WriteBool('ProcListTerminate',Format('Item[%d].Active',[i]),fSettings.ProcListTerminate[i].Active);
      Ini.WriteString('ProcListTerminate',Format('Item[%d].ProcessName',[i]),fSettings.ProcListTerminate[i].ProcessName);
    end;
  i := Length(fSettings.ProcListTerminate);
  while Ini.ValueExists('ProcListTerminate',Format('Item[%d].Active',[i])) or
    Ini.ValueExists('ProcListTerminate',Format('Item[%d].ProcessName',[i])) do
    begin
      Ini.DeleteKey('ProcListTerminate',Format('Item[%d].Active',[i]));
      Ini.DeleteKey('ProcListTerminate',Format('Item[%d].ProcessName',[i]));
      Inc(i);
    end; 
  Ini.WriteInteger('ProcListNeverTerminate','Count',Length(fSettings.ProcListNeverTerminate));
  For i := Low(fSettings.ProcListNeverTerminate) to High(fSettings.ProcListNeverTerminate) do
    begin
      Ini.WriteBool('ProcListNeverTerminate',Format('Item[%d].Active',[i]),fSettings.ProcListNeverTerminate[i].Active);
      Ini.WriteString('ProcListNeverTerminate',Format('Item[%d].ProcessName',[i]),fSettings.ProcListNeverTerminate[i].ProcessName);
    end;
  i := Length(fSettings.ProcListNeverTerminate);
  while Ini.ValueExists('ProcListNeverTerminate',Format('Item[%d].Active',[i])) or
    Ini.ValueExists('ProcListNeverTerminate',Format('Item[%d].ProcessName',[i])) do
    begin
      Ini.DeleteKey('ProcListNeverTerminate',Format('Item[%d].Active',[i]));
      Ini.DeleteKey('ProcListNeverTerminate',Format('Item[%d].ProcessName',[i]));
      Inc(i);
    end;
  Ini.UpdateFile;  
finally
  Ini.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.LoadFromIni(const FileName: String);
var
  Ini:  TMemIniFile;
  i:    Integer;
begin
Ini := TMemIniFile.Create(FileName);
try
  fSettings.GeneralSettings.RunAtSystemStart := Ini.ReadBool('Settings','RunAtSystemStart',DefaultSettings.GeneralSettings.RunAtSystemStart);
  fSettings.GeneralSettings.TerminateForegroundWnd := Ini.ReadBool('Settings','TerminateForegroundWnd',DefaultSettings.GeneralSettings.TerminateForegroundWnd);
  fSettings.GeneralSettings.TerminateByList := Ini.ReadBool('Settings','TerminateByList',DefaultSettings.GeneralSettings.TerminateByList);
  fSettings.GeneralSettings.TerminateUnresponsive := Ini.ReadBool('Settings','TerminateUnresponsive',DefaultSettings.GeneralSettings.TerminateUnresponsive);
  fSettings.GeneralSettings.ResponseTimeout := Ini.ReadInteger('Settings','ResponseTimeout',DefaultSettings.GeneralSettings.ResponseTimeout);
  fSettings.GeneralSettings.Shortcut := StrToIntDef('$' + Ini.ReadString('Settings','Shortcut',IntToHex(DefaultSettings.GeneralSettings.Shortcut,8)),DefaultSettings.GeneralSettings.Shortcut);
  SetLength(fSettings.ProcListTerminate,Ini.ReadInteger('ProcListTerminate','Count',0));
  For i := Low(fSettings.ProcListTerminate) to High(fSettings.ProcListTerminate) do
    begin
      fSettings.ProcListTerminate[i].Active := Ini.ReadBool('ProcListTerminate',Format('Item[%d].Active',[i]),False);
      fSettings.ProcListTerminate[i].ProcessName := Ini.ReadString('ProcListTerminate',Format('Item[%d].ProcessName',[i]),'');
    end;
  SetLength(fSettings.ProcListNeverTerminate,Ini.ReadInteger('ProcListNeverTerminate','Count',0));
  For i := Low(fSettings.ProcListNeverTerminate) to High(fSettings.ProcListNeverTerminate) do
    begin
      fSettings.ProcListNeverTerminate[i].Active := Ini.ReadBool('ProcListNeverTerminate',Format('Item[%d].Active',[i]),False);
      fSettings.ProcListNeverTerminate[i].ProcessName := Ini.ReadString('ProcListNeverTerminate',Format('Item[%d].ProcessName',[i]),'');
    end;
finally
  Ini.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.Save;
begin
{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
SaveToIni(ExtractFilePath(SysToUTF8(ParamStr(0))) + 'AppKiller.ini');
{$ELSE}
SaveToIni(ExtractFilePath(ParamStr(0)) + 'AppKiller.ini');
{$IFEND}
RunAtSystemStart(fSettings.GeneralSettings.RunAtSystemStart);
end;

//------------------------------------------------------------------------------

procedure TAPKSettings.Load;
begin
{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
LoadFromIni(ExtractFilePath(SysToUTF8(ParamStr(0))) + 'AppKiller.ini');
{$ELSE}
LoadFromIni(ExtractFilePath(ParamStr(0)) + 'AppKiller.ini');
{$IFEND}
end;

end.

unit APK_InstanceControl;

{$INCLUDE APK_Defs.inc}

interface

type
  TAPKInstanceControl = class(TObject)
  private
    fSingleInstance:  Boolean;
    fMutexHandle:     THandle;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property SingleInstance: Boolean read fSingleInstance;
  end;

implementation

uses
  Windows,
  APK_Strings;

constructor TAPKInstanceControl.Create;
begin
inherited;
fMutexHandle := CreateMutex(nil,False,PChar(APKSTR_IC_MutexName));
If fMutexHandle <> 0 then
  fSingleInstance := GetLastError <> ERROR_ALREADY_EXISTS
else
  fSingleInstance := False;
end;

//------------------------------------------------------------------------------

destructor TAPKInstanceControl.Destroy;
begin
CloseHandle(fMutexHandle);
inherited;
end;

end.

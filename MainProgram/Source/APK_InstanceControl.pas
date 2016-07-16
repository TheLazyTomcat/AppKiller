{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit APK_InstanceControl;

{$INCLUDE APK_Defs.inc}

interface

{==============================================================================}
{------------------------------------------------------------------------------}
{                              TAPKInstanceControl                             }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKInstanceControl - declaration                                          }
{==============================================================================}

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

{==============================================================================}
{------------------------------------------------------------------------------}
{                              TAPKInstanceControl                             }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAPKInstanceControl - implementation                                       }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAPKInstanceControl - public methods                                       }
{------------------------------------------------------------------------------}

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

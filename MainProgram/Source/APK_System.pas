unit APK_System;

{$INCLUDE APK_Defs.inc}

interface

Function SetPrivilege(const PrivilegeName: String; Enable: Boolean): Boolean;

implementation

uses
  Windows;

type
  HANDLE = THandle;
  PTOKEN_PRIVILEGES = ^TOKEN_PRIVILEGES;

Function AdjustTokenPrivileges(
  TokenHandle:          HANDLE;
  DisableAllPrivileges: BOOL;
  NewState:             PTOKEN_PRIVILEGES;
  BufferLength:         DWORD;
  PreviousState:        PTOKEN_PRIVILEGES;
  ReturnLength:         PDWORD): BOOL; stdcall; external advapi32;

//------------------------------------------------------------------------------  

Function SetPrivilege(const PrivilegeName: String; Enable: Boolean): Boolean;
var
  Token:            THandle;
  TokenPrivileges:  TTokenPrivileges;
begin
Result := False;
If OpenProcessToken(GetCurrentProcess,TOKEN_QUERY or TOKEN_ADJUST_PRIVILEGES,{%H-}Token) then
try
  If LookupPrivilegeValue(nil,PChar(PrivilegeName),{%H-}TokenPrivileges.Privileges[0].Luid) then
    begin
      TokenPrivileges.PrivilegeCount := 1;
      TokenPrivileges.Privileges[0].Attributes := Ord(Enable) * SE_PRIVILEGE_ENABLED;
      If AdjustTokenPrivileges(Token,False,@TokenPrivileges,0,nil,nil) then
        Result := GetLastError = ERROR_SUCCESS;
    end;
finally
  CloseHandle(Token);
end;
end;

end.

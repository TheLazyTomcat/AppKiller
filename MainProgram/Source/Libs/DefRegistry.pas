{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

DefRegistry

©František Milt 2015-02-20

Version 1.1

===============================================================================}
unit DefRegistry;

interface

uses
  Registry, DateUtils;

type
  TDefRegistry = class(TRegistry)
  public
    Function TryReadCurrency(const Name: String; out Value: Currency): Boolean; virtual;
    Function TryReadBinaryData(const Name: String; var Buffer; BuffSize: Integer; out BytesRead: Integer): Boolean; virtual;
    Function TryReadBool(const Name: String; out Value: Boolean): Boolean; virtual;
    Function TryReadDate(const Name: String; out Value: TDateTime): Boolean; virtual;
    Function TryReadDateTime(const Name: String; out Value: TDateTime): Boolean; virtual;
    Function TryReadFloat(const Name: String; out Value: Double): Boolean; virtual;
    Function TryReadInteger(const Name: String; out Value: Integer): Boolean; virtual;
    Function TryReadString(const Name: String; out Value: String): Boolean; virtual;
    Function TryReadTime(const Name: String; out Value: TDateTime): Boolean; virtual;
    //----------                                                    ----------//
    Function ReadCurrencyDef(const Name: String; const DefaultValue: Currency): Currency; virtual;
    Function ReadBinaryDataDef(const Name: String; var Buffer; BuffSize: Integer; const DefaultBuffer): Integer; virtual;
    Function ReadBoolDef(const Name: String; const DefaultValue: Boolean): Boolean; virtual;
    Function ReadDateDef(const Name: String; const DefaultValue: TDateTime): TDateTime; virtual;
    Function ReadDateTimeDef(const Name: String; const DefaultValue: TDateTime): TDateTime; virtual;
    Function ReadFloatDef(const Name: String; const DefaultValue: Double): Double; virtual;
    Function ReadIntegerDef(const Name: String; const DefaultValue: Integer): Integer; virtual;
    Function ReadStringDef(const Name: String; const DefaultValue: String): String; virtual;
    Function ReadTimeDef(const Name: String; const DefaultValue: TDateTime): TDateTime; virtual;
  end;

implementation

Function TDefRegistry.TryReadCurrency(const Name: String; out Value: Currency): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      Value := ReadCurrency(Name);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.TryReadBinaryData(const Name: String; var Buffer; BuffSize: Integer; out BytesRead: Integer): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      BytesRead := ReadBinaryData(Name,Buffer,BuffSize);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.TryReadBool(const Name: String; out Value: Boolean): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      Value := ReadBool(Name);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.TryReadDate(const Name: String; out Value: TDateTime): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      Value := ReadDate(Name);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.TryReadDateTime(const Name: String; out Value: TDateTime): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      Value := ReadDateTime(Name);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.TryReadFloat(const Name: String; out Value: Double): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      Value := ReadFloat(Name);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.TryReadInteger(const Name: String; out Value: Integer): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      Value := ReadInteger(Name);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.TryReadString(const Name: String; out Value: String): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      Value := ReadString(Name);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.TryReadTime(const Name: String; out Value: TDateTime): Boolean;
begin
try
  If ValueExists(Name) then
    begin
      Value := ReadTime(Name);
      Result := True;
    end
  else Result := False;
except
  Result := False;
end;
end;

//==============================================================================

Function TDefRegistry.ReadCurrencyDef(const Name: String; const DefaultValue: Currency): Currency;
begin
If not TryReadCurrency(Name,Result) then
  Result := DefaultValue;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.ReadBinaryDataDef(const Name: String; var Buffer; BuffSize: Integer; const DefaultBuffer): Integer;
begin
If not TryReadBinaryData(Name,Buffer,BuffSize,Result) then
  begin
    Move(DefaultBuffer,Buffer,BuffSize);
    Result := BuffSize
  end;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.ReadBoolDef(const Name: String; const DefaultValue: Boolean): Boolean;
begin
If not TryReadBool(Name,Result) then
  Result := DefaultValue;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.ReadDateDef(const Name: String; const DefaultValue: TDateTime): TDateTime;
begin
If not TryReadDate(Name,Result) then
  Result := DefaultValue;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.ReadDateTimeDef(const Name: String; const DefaultValue: TDateTime): TDateTime;
begin
If not TryReadDateTime(Name,Result) then
  Result := DefaultValue;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.ReadFloatDef(const Name: String; const DefaultValue: Double): Double;
begin
If not TryReadFloat(Name,Result) then
  Result := DefaultValue;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.ReadIntegerDef(const Name: String; const DefaultValue: Integer): Integer;
begin
If not TryReadInteger(Name,Result) then
  Result := DefaultValue;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.ReadStringDef(const Name: String; const DefaultValue: String): String;
begin
If not TryReadString(Name,Result) then
  Result := DefaultValue;
end;

//------------------------------------------------------------------------------

Function TDefRegistry.ReadTimeDef(const Name: String; const DefaultValue: TDateTime): TDateTime;
begin
If not TryReadTime(Name,Result) then
  Result := DefaultValue;
end;

end.

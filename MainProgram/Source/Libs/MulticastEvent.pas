{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Multicast event handling class

  ©František Milt 2016-03-01

  Version 1.0.3

  Dependencies:
    AuxTypes   - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses - github.com/ncs-sniper/Lib.AuxClasses

===============================================================================}
unit MulticastEvent;

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

{$TYPEINFO ON}

interface

uses
  AuxClasses;

{===============================================================================
--------------------------------------------------------------------------------
                                TMulticastEvent                                
--------------------------------------------------------------------------------
===============================================================================}

type
  TEvent = procedure of object;

  TMethods = array of TMethod;

{===============================================================================
    TMulticastEvent - class declaration
===============================================================================}

  TMulticastEvent = class(TCustomListObject)
  private
    fOwner:   TObject;
    fMethods: TMethods;
    fCount:   Integer;
    Function GetMethod(Index: Integer): TMethod;
  protected
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
  public
    constructor Create(Owner: TObject = nil);
    destructor Destroy; override;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function IndexOf(const Handler: TEvent): Integer; virtual;
    Function Add(const Handler: TEvent; AllowDuplicity: Boolean = False): Integer; virtual;
    Function Remove(const Handler: TEvent; RemoveAll: Boolean = True): Integer; virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Clear; virtual;
    procedure Call; virtual;
    property Methods[Index: Integer]: TMethod read GetMethod;
  published
    property Owner: TObject read fOwner;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                             TMulticastNotifyEvent                                                             
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TMulticastNotifyEvent - class declaration
===============================================================================}

  TMulticastNotifyEvent = class(TMulticastEvent)
  public
    Function IndexOf(const Handler: TNotifyEvent): Integer; reintroduce;
    Function Add(const Handler: TNotifyEvent; AllowDuplicity: Boolean = False): Integer; reintroduce;
    Function Remove(const Handler: TNotifyEvent; RemoveAll: Boolean = True): Integer; reintroduce;
    procedure Call(Sender: TObject); reintroduce;
  end;

implementation

uses
  SysUtils;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                TMulticastEvent                                
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TMulticastEvent - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TMulticastEvent - private methods
-------------------------------------------------------------------------------}

Function TMulticastEvent.GetMethod(Index: Integer): TMethod;
begin
If CheckIndex(Index) then
  Result := fMethods[Index]
else
  raise Exception.CreateFmt('TMulticastEvent.GetMethod: Index (%d) out of bounds.',[Index]);
end;

{-------------------------------------------------------------------------------
    TMulticastEvent - protected methods
-------------------------------------------------------------------------------}

Function TMulticastEvent.GetCapacity: Integer;
begin
Result := Length(fMethods);
end;

//------------------------------------------------------------------------------

procedure TMulticastEvent.SetCapacity(Value: Integer);
begin
If Value <> Length(fMethods) then
  begin
    If Value < Length(fMethods) then
      fCount := Value;
    SetLength(fMethods,Value);
  end;
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.GetCount: Integer;
begin
Result := fCount;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TMulticastEvent.SetCount(Value: Integer);
begin
// do nothing
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{-------------------------------------------------------------------------------
    TMulticastEvent - public methods
-------------------------------------------------------------------------------}

constructor TMulticastEvent.Create(Owner: TObject = nil);
begin
inherited Create;
fOwner := Owner;
SetLength(fMethods,0);
fCount := 0;
// adjust growing, no need for fast growth
GrowMode := gmLinear;
GrowFactor := 16;
end;

//------------------------------------------------------------------------------

destructor TMulticastEvent.Destroy;
begin
Clear;
inherited;
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.LowIndex: Integer;
begin
Result := Low(fMethods);
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.HighIndex: Integer;
begin
Result := Pred(fCount);
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.IndexOf(const Handler: TEvent): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := LowIndex to HighIndex do
  If (fMethods[i].Code = TMethod(Handler).Code) and
     (fMethods[i].Data = TMethod(Handler).Data) then
    begin
      Result := i;
      Break{For i};
    end
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.Add(const Handler: TEvent; AllowDuplicity: Boolean = False): Integer;
begin
If Assigned(TMethod(Handler).Code) and Assigned(TMethod(Handler).Data) then
  begin
    Result := IndexOf(Handler);
    If (Result < 0) or AllowDuplicity then
      begin
        Grow;
        Result := fCount;
        fMethods[Result] := TMethod(Handler);
        Inc(fCount);
      end;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.Remove(const Handler: TEvent; RemoveAll: Boolean = True): Integer;
begin
repeat
  Result := IndexOf(Handler);
  If Result >= 0 then
    Delete(Result);
until not RemoveAll or (Result < 0);
end;

//------------------------------------------------------------------------------

procedure TMulticastEvent.Delete(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    For i := Index to Pred(HighIndex) do
      fMethods[i] := fMethods[i + 1];
    Dec(fCount);
    Shrink;
  end
else raise Exception.CreateFmt('TMulticastEvent.Delete: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TMulticastEvent.Clear;
begin
fCount := 0;
Shrink;
end;

//------------------------------------------------------------------------------

procedure TMulticastEvent.Call;
var
  i:  Integer;
begin
For i := LowIndex to HighIndex do
  TEvent(fMethods[i]);
end;


{===============================================================================
--------------------------------------------------------------------------------
                             TMulticastNotifyEvent                                                             
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TMulticastNotifyEvent - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TMulticastNotifyEvent - public methods
-------------------------------------------------------------------------------}

Function TMulticastNotifyEvent.IndexOf(const Handler: TNotifyEvent): Integer;
begin
Result := inherited IndexOf(TEvent(Handler));
end;

//------------------------------------------------------------------------------

Function TMulticastNotifyEvent.Add(const Handler: TNotifyEvent; AllowDuplicity: Boolean = False): Integer;
begin
Result := inherited Add(TEvent(Handler),AllowDuplicity);
end;

//------------------------------------------------------------------------------

Function TMulticastNotifyEvent.Remove(const Handler: TNotifyEvent; RemoveAll: Boolean = True): Integer;
begin
Result := inherited Remove(TEvent(Handler),RemoveAll);
end;

//------------------------------------------------------------------------------

procedure TMulticastNotifyEvent.Call(Sender: TObject);
var
  i:  Integer;
begin
For i := LowIndex to HighIndex do
  TNotifyEvent(Methods[i])(Sender);
end;

end.

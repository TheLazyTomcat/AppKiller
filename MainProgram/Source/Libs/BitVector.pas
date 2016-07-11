{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  BitVector classes

  ©František Milt 2016-03-01

  Version 1.0.1 

===============================================================================}
unit BitVector;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  Classes, AuxTypes;

type
{==============================================================================}
{------------------------------------------------------------------------------}
{                           TBitVector - declaration                           }
{------------------------------------------------------------------------------}
{==============================================================================}
  TBitVector = class(TObject)
  private
    fOwnsMemory:  Boolean;
    fStatic:      Boolean;
    fMemSize:     TMemSize;
    fMemory:      Pointer;
    fCount:       Integer;
    fPopCount:    Integer;
    fChanging:    Integer;
    fChanged:     Boolean;
    fOnChange:    TNotifyEvent;
    Function GetBit_LL(Index: Integer): Boolean;
    Function SetBit_LL(Index: Integer; Value: Boolean): Boolean;
    Function GetBit(Index: Integer): Boolean;
    procedure SetBit(Index: Integer; Value: Boolean);
    Function GetCapacity: Integer;
    procedure SetCapacity(Value: Integer); virtual;
    procedure SetCount(Value: Integer); virtual;
  protected
    procedure ShiftDown(Idx1,Idx2: Integer); virtual;
    procedure ShiftUp(Idx1,Idx2: Integer); virtual;
    Function MemoryEditable(MethodName: String = 'MemoryEditable'; RaiseException: Boolean = True): Boolean; virtual;
    Function CheckIndex(Index: Integer; RaiseException: Boolean = False; MethodName: String = 'CheckIndex'): Boolean; virtual;
    procedure CommonInit; virtual;
    procedure ScanForPopCount; virtual;
    procedure DoOnChange; virtual;
  public
    constructor Create(Memory: Pointer; Count: Integer); overload; virtual;
    constructor Create(InitialCount: Integer = 0; InitialValue: Boolean = False); overload; virtual;
    destructor Destroy; override;
    procedure BeginChanging;
    Function EndChanging: Integer;
    Function LowIndex: Integer; virtual;
    Function HighIndex: Integer; virtual;    
    Function Firts: Boolean; virtual;
    Function Last: Boolean; virtual;
    Function Grow(Force: Boolean = False): Integer; virtual;
    Function Shrink: Integer; virtual;
    Function Add(Value: Boolean): Integer; virtual;
    procedure Insert(Index: Integer; Value: Boolean); virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Exchange(Index1, Index2: Integer); virtual;
    procedure Move(SrcIdx, DstIdx: Integer); virtual;
    procedure Fill(FromIdx, ToIdx: Integer; Value: Boolean); overload; virtual;
    procedure Fill(Value: Boolean); overload; virtual;
    procedure Complement(FromIdx, ToIdx: Integer); overload; virtual;    
    procedure Complement; overload; virtual;
    procedure Clear; virtual;
    procedure Reverse; virtual;
    Function IsEmpty: Boolean; virtual;
    Function IsFull: Boolean; virtual;
    Function FirstSet: Integer; virtual;
    Function FirstClean: Integer; virtual;
    Function LastSet: Integer; virtual;
    Function LastClean: Integer; virtual;
    procedure Append(Memory: Pointer; Count: Integer); overload; virtual;
    procedure Append(Vector: TBitVector); overload; virtual;
    procedure Assign(Memory: Pointer; Count: Integer); overload; virtual;
    procedure Assign(Vector: TBitVector); overload; virtual;
    procedure AssignOR(Memory: Pointer; Count: Integer); overload; virtual;
    procedure AssignOR(Vector: TBitVector); overload; virtual;
    procedure AssignAND(Memory: Pointer; Count: Integer); overload; virtual;
    procedure AssignAND(Vector: TBitVector); overload; virtual;
    procedure AssignXOR(Memory: Pointer; Count: Integer); overload; virtual;
    procedure AssignXOR(Vector: TBitVector); overload; virtual;
    Function Equals(Vector: TBitVector): Boolean; overload; virtual;
    procedure SaveToStream(Stream: TStream); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToFile(const FileName: String); virtual;
    procedure LoadFromFile(const FileName: String); virtual;
    property Bits[Index: Integer]: Boolean read GetBit write SetBit; default;
    property Memory: Pointer read fMemory;
  published
    property OwnsMemory: Boolean read fOwnsMemory;
    property Static: Boolean read fStatic;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read fCount write SetCount;
    property PopCount: Integer read fPopCount;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                        TBitVectorStatic - declaration                        }
{------------------------------------------------------------------------------}
{==============================================================================}
  TBitVectorStatic = class(TBitVector)
  protected
    procedure CommonInit; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                       TBitVectorStatic32 - declaration                       }
{------------------------------------------------------------------------------}
{==============================================================================}
  TBitVectorStatic32 = class(TBitVectorStatic)
  public
    constructor Create(Memory: Pointer; Count: Integer); overload; override;
    constructor Create(InitialCount: Integer = 0; InitialValue: Boolean = False); overload; override;
    Function FirstSet: Integer; override;
    Function FirstClean: Integer; override;
    Function LastSet: Integer; override;
    Function LastClean: Integer; override;
  end;

implementation

uses
  SysUtils, Math
  {$IF Defined(FPC) and not Defined(Unicode)}
  (*
    If compiler throws error that LazUTF8 unit cannot be found, you have to
    add LazUtils to required packages (Project > Project Inspector).
  *)
  , LazUTF8
  {$IFEND};

const
  AllocDeltaBits  = 32;
  AllocDeltaBytes = 4;

{$IFDEF ENDIAN_BIG}
Function SwapEndian(Value: UInt32): UInt32;
begin
Result := UInt32((Value and $000000FF shl 24) or (Value and $0000FF00 shl 8) or
                 (Value and $00FF0000 shr 8) or (Value and $FF000000 shr 24));
end;
{$ENDIF}

{==============================================================================}
{------------------------------------------------------------------------------}
{                         TBitVector - implementation                          }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TBitVector - private methods                                               }
{==============================================================================}

Function TBitVector.GetBit_LL(Index: Integer): Boolean;
begin
Result := ({%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(Index shr 3))^ shr (Index and 7)) and 1 <> 0;
end;

//------------------------------------------------------------------------------

Function TBitVector.SetBit_LL(Index: Integer; Value: Boolean): Boolean;
var
  OldByte:  Byte;
begin
OldByte := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(Index shr 3))^;
Result := (OldByte shr (Index and 7)) and 1 <> 0;
If Value then
  {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(Index shr 3))^ := OldByte or (1 shl (Index and 7))
else
  {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(Index shr 3))^ := OldByte and not (1 shl (Index and 7));
end;

//------------------------------------------------------------------------------

Function TBitVector.GetBit(Index: Integer): Boolean;
begin
If CheckIndex(Index) then
  Result := GetBit_LL(Index)
else
  raise Exception.CreateFmt('TBitVector.GetBit: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TBitVector.SetBit(Index: Integer; Value: Boolean);
var
  OldValue: Boolean;
begin
If CheckIndex(Index) then
  begin
    OldValue := SetBit_LL(Index,Value);
    If Value <> OldValue then
      begin
        If OldValue then Dec(fPopCount)
          else Inc(fPopCount);
        DoOnChange;
      end;
  end
else raise Exception.CreateFmt('TBitVector.SetBit: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TBitVector.GetCapacity: Integer;
begin
Result := fMemSize shl 3;
end;

//------------------------------------------------------------------------------

procedure TBitVector.SetCapacity(Value: Integer);
var
  NewMemSize: PtrUInt;
begin
If MemoryEditable('SetCapacity') then
  begin
    If Value >= 0 then
      begin
        NewMemSize := Ceil(Value / AllocDeltaBits) * AllocDeltaBytes;
        If fMemSize <> NewMemSize then
          begin
            fMemSize := NewMemSize;
            ReallocMem(fMemory,fMemSize);
            If Capacity < fCount then
              begin
                fCount := Capacity;
                ScanForPopCount;
                DoOnChange;
              end;
          end;
      end
    else raise Exception.Create('TBitVector.SetCapacity: Negative capacity not allowed.');
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.SetCount(Value: Integer);
var
  i:  Integer;
begin
If MemoryEditable('SetCount') then
  begin
    If Value >= 0 then
      begin
        If Value <> fCount then
          begin
            BeginChanging;
            try
              If Value > Capacity then Capacity := Value;
              If Value > fCount then
                begin
                  If (fCount and 7) <> 0 then
                    For i := fCount to Min(Pred(Value),fCount or 7) do
                      SetBit_LL(i,False);
                  For i := Ceil(fCount / 8) to Pred(Value shr 3) do
                    {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := 0;
                  If ((Value and 7) <> 0) and ((Value and not 7) >= fCount) then
                    For i := (Value and not 7) to Pred(Value) do
                      SetBit_LL(i,False);
                  fCount := Value;
                end
              else
                begin
                  fCount := Value;
                  ScanForPopCount;
                end;
              DoOnChange;
            finally
              EndChanging;
            end;
          end;
      end
    else raise Exception.Create('TBitVector.SetCount: Negative count not allowed.');
  end;
end;

{==============================================================================}
{   TBitVector - protected methods                                             }
{==============================================================================}

procedure TBitVector.ShiftDown(Idx1,Idx2: Integer);
var
  i:      Integer;
  Temp:   UInt16;
  Carry:  Boolean;
begin
If Idx2 > Idx1 then
  begin
    If (Idx2 shr 3) - (Idx1 shr 3) > 1 then
      begin
        // shift last byte and preserve shifted-out bit
        Carry := GetBit_LL(Idx2 and not 7);
        For i := (Idx2 and not 7) to Pred(Idx2) do
          SetBit_LL(i,GetBit_LL(i + 1));
        // shift whole bytes
        For i := Pred(Idx2 shr 3) downto Succ(Idx1 shr 3) do
          begin
            If Carry then
              Temp := UInt16({%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^) or $0100
            else
              Temp := UInt16({%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^) and $FEFF;
            Carry := (Temp and 1) <> 0;
            {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := Byte(Temp shr 1);
          end;
        // shift first byte and store carry
        For i := Idx1 to Pred(Idx1 or 7) do
          SetBit_LL(i,GetBit_LL(i + 1));
        SetBit_LL(Idx1 or 7,Carry);
      end
    else
      For i := Idx1 to Pred(Idx2) do
        SetBit_LL(i,GetBit_LL(i + 1));
  end
else raise Exception.CreateFmt('TBitVector.ShiftDown: First index (%d) must be smaller or equal to the second index (%d).',[Idx1,Idx2]);
end;

//------------------------------------------------------------------------------

procedure TBitVector.ShiftUp(Idx1,Idx2: Integer);
var
  i:      Integer;
  Temp:   UInt16;
  Carry:  Boolean;
begin
If Idx2 > Idx1 then
  begin
    If (Idx2 shr 3) - (Idx1 shr 3) > 1 then
      begin
        // shift first byte and preserve shifted-out bit
        Carry := GetBit_LL(Idx1 or 7);
        For i := (Idx1 or 7) downto Succ(Idx1) do
          SetBit_LL(i,GetBit_LL(i - 1));
        // shift whole bytes
        For i := Succ(Idx1 shr 3) to Pred(Idx2 shr 3) do
          begin
            If Carry then
              Temp := (UInt16({%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^) shl 1) or 1
            else
              Temp := (UInt16({%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^) shl 1) and not 1;
            Carry := (Temp and $100) <> 0;
            {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := Byte(Temp);
          end;
        // shift last byte and store carry
        For i := Idx2 downto Succ(Idx2 and not 7) do
          SetBit_LL(i,GetBit_LL(i - 1));
        SetBit_LL(Idx2 and not 7,Carry);
      end
    else
      For i := Idx2 downto Succ(Idx1) do
        SetBit_LL(i,GetBit_LL(i - 1));
  end
else raise Exception.CreateFmt('TBitVector.ShiftUp: First index (%d) must be smaller or equal to the second index (%d).',[Idx1,Idx2]);
end;

//------------------------------------------------------------------------------

Function TBitVector.MemoryEditable(MethodName: String = 'MemoryEditable'; RaiseException: Boolean = True): Boolean;
begin
Result := fOwnsMemory and not fStatic;
If RaiseException then
  begin
    If fStatic then
      raise Exception.CreateFmt('TBitVector.%s: Method not allowed for a static vector.',[MethodName]);  
    If not fOwnsMemory then
      raise Exception.CreateFmt('TBitVector.%s: Method not allowed for not owned memory.',[MethodName]);
  end;
end;

//------------------------------------------------------------------------------

Function TBitVector.CheckIndex(Index: Integer; RaiseException: Boolean = False; MethodName: String = 'CheckIndex'): Boolean;
begin
Result := (Index >= 0) and (Index < fCount);
If not Result and RaiseException then
  raise Exception.CreateFmt('TBitVector.%s: Index (%d) out of bounds.',[MethodName,Index]);
end;

//------------------------------------------------------------------------------

procedure TBitVector.CommonInit;
begin
fStatic := False;
fChanging := 0;
fChanged := False;
fOnChange := nil;
end;

//------------------------------------------------------------------------------

procedure TBitVector.ScanForPopCount;
var
  i:        Integer;
  WorkPtr:  PByte;

  Function CountBits(Buff: Byte; MaxBits: Byte = 8): Integer;
  var
    ii: Integer;
  begin
    Result := 0;
    If MaxBits >= 8 then
      case Buff of
          0:  Exit; // do nothing, result is already 0
        255:  Result := 8;
      else
        For ii := 0 to 7 do
          If ((Buff shr ii) and 1) <> 0 then Inc(Result);
      end
    else
      For ii := 0 to Pred(MaxBits) do
        If ((Buff shr ii) and 1) <> 0 then Inc(Result);
  end;

begin
fPopCount := 0;
If fCount > 0 then
  begin
    WorkPtr := PByte(fMemory);
    For i := 0 to Pred(fCount shr 3) do
      begin
        Inc(fPopCount,CountBits(WorkPtr^));
        Inc(WorkPtr);
      end;
    If (fCount and 7) > 0 then
      Inc(fPopCount,CountBits(WorkPtr^,fCount and 7));
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.DoOnChange;
begin
fChanged := True;
If (fChanging <= 0) and Assigned(fOnChange) then fOnChange(Self);
end;

{==============================================================================}
{   TBitVector - public methods                                                }
{==============================================================================}

constructor TBitVector.Create(Memory: Pointer; Count: Integer);
begin
inherited Create;
fOwnsMemory := False;
fMemSize := 0;
fMemory := Memory;
fCount := Count;
ScanForPopCount;
CommonInit;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

constructor TBitVector.Create(InitialCount: Integer = 0; InitialValue: Boolean = False);
begin
inherited Create;
fOwnsMemory := True;
Capacity := InitialCount;
fCount := InitialCount;
Fill(InitialValue);
CommonInit;
end;

//------------------------------------------------------------------------------

destructor TBitVector.Destroy;
begin
If fOwnsMemory then
  FreeMem(fMemory,fMemSize);
inherited;
end;

//------------------------------------------------------------------------------

procedure TBitVector.BeginChanging;
begin
If fChanging <= 0 then fChanged := False;
Inc(fChanging);
end;

//------------------------------------------------------------------------------

Function TBitVector.EndChanging: Integer;
begin
Dec(fChanging);
If fChanging <= 0 then
  begin
    fChanging := 0;
    If fChanged and Assigned(fOnChange) then fOnChange(Self);
  end;
Result := fChanging;  
end;

//------------------------------------------------------------------------------

Function TBitVector.LowIndex: Integer;
begin
Result := 0;
end;

//------------------------------------------------------------------------------

Function TBitVector.HighIndex: Integer;
begin
Result := fCount - 1;
end;

//------------------------------------------------------------------------------

Function TBitVector.Firts: Boolean;
begin
Result := GetBit(LowIndex);
end;

//------------------------------------------------------------------------------

Function TBitVector.Last: Boolean;
begin
Result := GetBit(HighIndex);
end;

//------------------------------------------------------------------------------

Function TBitVector.Grow(Force: Boolean = False): Integer;
begin
If Force then
  begin
    Capacity := Capacity + AllocDeltaBits;
    Result := Capacity;
  end
else
  begin
    If fCount >= Capacity then
      Result := Grow(True)
    else
      Result := Capacity;
  end;
end;

//------------------------------------------------------------------------------

Function TBitVector.Shrink: Integer;
begin
Capacity := fCount;
Result := Capacity;
end;

//------------------------------------------------------------------------------

Function TBitVector.Add(Value: Boolean): Integer;
begin
If MemoryEditable('Add') then
  begin
    Grow;
    Inc(fCount);
    SetBit_LL(HighIndex,Value);
    If Value then Inc(fPopCount);
    Result := HighIndex;
    DoOnChange;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Insert(Index: Integer; Value: Boolean);
begin
If MemoryEditable('Insert') then
  begin
    If Index >= fCount then
      Add(Value)
    else
      begin
        If CheckIndex(Index) then
          begin
            Grow;
            Inc(fCount);
            ShiftUp(Index,HighIndex);
            SetBit_LL(Index,Value);
            If Value then Inc(fPopCount);
            DoOnChange;
          end
        else raise Exception.CreateFmt('TBitVector.Insert: Index (%d) out of bounds.',[Index]);
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Delete(Index: Integer);
begin
If MemoryEditable('Delete') then
  begin
    If CheckIndex(Index) then
      begin
        If GetBit_LL(Index) then Dec(fPopCount);
        If Index < HighIndex then
          ShiftDown(Index,HighIndex);
        Dec(fCount);
        DoOnChange;
      end
    else raise Exception.CreateFmt('TBitVector.Delete: Index (%d) out of bounds.',[Index]);
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Exchange(Index1, Index2: Integer);
begin
If CheckIndex(Index1,True,'Exchange') and CheckIndex(Index2,True,'Exchange') then
  begin
    SetBit_LL(Index2,SetBit_LL(Index1,GetBit_LL(Index2)));
    DoOnChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Move(SrcIdx, DstIdx: Integer);
var
  Value:  Boolean;
begin
If CheckIndex(SrcIdx,True,'Move') and CheckIndex(DstIdx,True,'Move') then
  begin
    If SrcIdx <> DstIdx then
      begin
        Value := GetBit_LL(SrcIdx);
        If SrcIdx < DstIdx then
          ShiftDown(SrcIdx,DstIdx)
        else
          ShiftUp(DstIdx,SrcIdx);
        SetBit_LL(DstIdx,Value);
        DoOnChange;
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Fill(FromIdx, ToIdx: Integer; Value: Boolean);
var
  i:  Integer;
begin
If CheckIndex(FromIdx,True,'Fill') and CheckIndex(ToIdx,True,'Fill') then
  begin
    If FromIdx > ToIdx then
      begin
        i := FromIdx;
        FromIdx := ToIdx;
        ToIdx := i;
      end;
    If ((FromIdx and 7) <> 0) or ((ToIdx - FromIdx) < 7) then
      For i := FromIdx to Min(ToIdx,FromIdx or 7) do
        SetBit_LL(i,Value);
    For i := Ceil(FromIdx / 8) to Pred(Succ(ToIdx) shr 3) do
      {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := Ord(Value) * $FF;
    If ((ToIdx and 7) < 7) and ((ToIdx and not 7) > FromIdx) then
      For i := (ToIdx and not 7) to ToIdx do
        SetBit_LL(i,Value);
    ScanForPopCount;
    DoOnChange;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.Fill(Value: Boolean);
var
  i:  Integer;
begin
If fCount > 0 then
  begin
    For i := 0 to Pred(fCount shr 3) do
      {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := $FF * Ord(Value);
    For i := (fCount and not 7) to Pred(fCount) do
      SetBit_LL(i,Value);
    fPopCount := fCount * Ord(Value);      
    DoOnChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Complement(FromIdx, ToIdx: Integer);
var
  i:  Integer;
begin
If CheckIndex(FromIdx,True,'Complement') and CheckIndex(ToIdx,True,'Complement') then
  begin
    If FromIdx > ToIdx then
      begin
        i := FromIdx;
        FromIdx := ToIdx;
        ToIdx := i;
      end;
    If ((FromIdx and 7) <> 0) or ((ToIdx - FromIdx) < 7) then
      For i := FromIdx to Min(ToIdx,FromIdx or 7) do
        SetBit_LL(i,not GetBit_LL(i));
    For i := Ceil(FromIdx / 8) to Pred(Succ(ToIdx) shr 3) do
      {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := not {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^;
    If ((ToIdx and 7) < 7) and ((ToIdx and not 7) > FromIdx) then
      For i := (ToIdx and not 7) to ToIdx do
        SetBit_LL(i,not GetBit_LL(i));
    ScanForPopCount;
    DoOnChange;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.Complement;
var
  i:  Integer;
begin
If fCount > 0 then
  begin
    For i := 0 to Pred(fCount shr 3) do
      {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := not {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^;
    For i := (fCount and not 7) to Pred(fCount) do
      SetBit_LL(i,not GetBit_LL(i));
    fPopCount := fCount - fPopCount;
    DoOnChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Clear;
begin
If MemoryEditable('Clear') then
  begin
    fCount := 0;
    fPopCount := 0;
    DoOnChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Reverse;
var
  i:  Integer;
begin
If fCount > 1 then
  begin
    For i := 0 to Pred(fCount shr 1) do
      SetBit_LL(i,SetBit_LL(Pred(fCount) - i,GetBit_LL(i)));
    DoOnChange;  
  end;
end;

//------------------------------------------------------------------------------

Function TBitVector.IsEmpty: Boolean;
begin
Result := (fCount > 0) and (fPopCount = 0);
end;

//------------------------------------------------------------------------------

Function TBitVector.IsFull: Boolean;
begin
Result := (fCount > 0) and (fPopCount = fCount);
end;

//------------------------------------------------------------------------------

Function TBitVector.FirstSet: Integer;
var
  i:        Integer;
  WorkByte: Byte;

  Function ScanByte(Value: Byte): Integer;
  var
    ii: Integer;
  begin
    For ii := 0 to 7 do
      If (Value shr ii) and 1 <> 0 then
        begin
          Result := ii;
          Exit;
        end;
    raise Exception.Create('TBitVector.FirstSet.ScanByte: Operation not allowed.');
  end;

begin
If fCount > 0 then
  begin
    For i := 0 to Pred(fCount shr 3) do
      begin
        WorkByte := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^;
        If WorkByte <> 0 then
          begin
            Result := (i * 8) + ScanByte(WorkByte);
            Exit;
          end;
      end;
    For i := (fCount and not 7) to Pred(fCount) do
      If GetBit_LL(i) then
        begin
          Result := i;
          Exit;
        end;
    Result := -1;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TBitVector.FirstClean: Integer;
var
  i:        Integer;
  WorkByte: Byte;

  Function ScanByte(Value: Byte): Integer;
  var
    ii: Integer;
  begin
    For ii := 0 to 7 do
      If (Value shr ii) and 1 = 0 then
        begin
          Result := ii;
          Exit;
        end;
    raise Exception.Create('TBitVector.FirstClean.ScanByte: Operation not allowed.');
  end;

begin
If fCount > 0 then
  begin
    For i := 0 to Pred(fCount shr 3) do
      begin
        WorkByte := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^;
        If WorkByte <> $FF then
          begin
            Result := (i * 8) + ScanByte(WorkByte);
            Exit;
          end;
      end;
    For i := (fCount and not 7) to Pred(fCount) do
      If not GetBit_LL(i) then
        begin
          Result := i;
          Exit;
        end;
    Result := -1;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TBitVector.LastSet: Integer;
var
  i:        Integer;
  WorkByte: Byte;

  Function ScanByte(Value: Byte): Integer;
  var
    ii: Integer;
  begin
    For ii := 7 downto 0 do
      If (Value shr ii) and 1 <> 0 then
        begin
          Result := ii;
          Exit;
        end;
    raise Exception.Create('TBitVector.LastSet.ScanByte: Operation not allowed.');
  end;

begin
If fCount > 0 then
  begin
    For i := Pred(fCount) downto (fCount and not 7) do
      If GetBit_LL(i) then
        begin
          Result := i;
          Exit;
        end;
    For i := Pred(fCount shr 3) downto 0 do
      begin
        WorkByte := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^;
        If WorkByte <> 0 then
          begin
            Result := (i * 8) + ScanByte(WorkByte);
            Exit;
          end;
      end;
    Result := -1;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TBitVector.LastClean: Integer;
var
  i:        Integer;
  WorkByte: Byte;

  Function ScanByte(Value: Byte): Integer;
  var
    ii: Integer;
  begin
    For ii := 7 downto 0 do
      If (Value shr ii) and 1 = 0 then
        begin
          Result := ii;
          Exit;
        end;
    raise Exception.Create('TBitVector.LastSet.ScanByte: Operation not allowed.');
  end;

begin
If fCount > 0 then
  begin
    For i := Pred(fCount) downto (fCount and not 7) do
      If not GetBit_LL(i) then
        begin
          Result := i;
          Exit;
        end;
    For i := Pred(fCount shr 3) downto 0 do
      begin
        WorkByte := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^;
        If WorkByte <> $FF then
          begin
            Result := (i * 8) + ScanByte(WorkByte);
            Exit;
          end;
      end;
    Result := -1;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Append(Memory: Pointer; Count: Integer);
var
  i:          Integer;
  WorkByte:   Byte;
  TempVector: TBitVector;
begin
If MemoryEditable('Append') then
  begin
    If (fCount and 7) = 0 then
      begin
        Capacity := fCount + Count;
        System.Move(Memory^,{%H-}Pointer({%H-}PtrUInt(fMemory) + PtrUInt(fCount shr 3))^,Count shr 3);
        If (Count and 7) <> 0 then
          begin
            WorkByte := {%H-}PByte({%H-}PtrUInt(Memory) + PtrUInt(Count shr 3))^;
            For i := 0 to Pred(Count - (Count and not 7)) do
              SetBit_LL(fCount + (Count and not 7) + i,(WorkByte shr i) and 1 <> 0);
          end;    
        Inc(fCount,Count);
        ScanForPopCount;
        DoOnChange;
      end
    else
      begin
        TempVector := TBitVector.Create(Memory,Count);
        try
          Append(TempVector);
        finally
          TempVector.Free;
        end;
      end;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.Append(Vector: TBitVector);
var
  i:  Integer;
begin
If MemoryEditable('Append') then
  begin
    If (fCount and 7) <> 0 then
      begin
        Capacity := fCount + Vector.Count;
        For i := 0 to Vector.HighIndex do
          SetBit_LL(fCount + i,Vector.GetBit_LL(i));  
        Inc(fCount,Vector.Count);
        ScanForPopCount;
        DoOnChange;
      end
    else Append(Vector.Memory,Vector.Count);
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Assign(Memory: Pointer; Count: Integer);
var
  i:        Integer;
  WorkByte: Byte;
begin
If MemoryEditable('Assign') then
  begin
    BeginChanging;
    try
      Capacity := Count;
      System.Move(Memory^,fMemory^,Count shr 3);
      If (Count and 7) <> 0 then
        begin
          WorkByte := {%H-}PByte({%H-}PtrUInt(Memory) + PtrUInt(Count shr 3))^;
          For i := (Count and not 7) to Pred(Count) do
            SetBit_LL(i,(WorkByte shr (i and 7)) and 1 <> 0);
        end;
      fCount := Count;
      ScanForPopCount;
      DoOnChange;
    finally
      EndChanging;
    end;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.Assign(Vector: TBitVector);
begin
Assign(Vector.Memory,Vector.Count);
end;

//------------------------------------------------------------------------------

procedure TBitVector.AssignOR(Memory: Pointer; Count: Integer);
var
  i:        Integer;
  WorkByte: Byte;
begin
If MemoryEditable('AssignOR') then
  begin
    BeginChanging;
    try
      If Count > fCount then Self.Count := Count;
      For i := 0 to Pred(Count shr 3) do
        {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ or
                                                           {%H-}PByte({%H-}PtrUInt(Memory) + PtrUInt(i))^;
      If (Count and 7) <> 0 then
        begin
          WorkByte := {%H-}PByte({%H-}PtrUInt(Memory) + PtrUInt(Count shr 3))^;
          For i := (Count and not 7) to Pred(Count) do
            SetBit_LL(i,GetBit_LL(i) or ((WorkByte shr (i and 7)) and 1 <> 0));
        end;
      ScanForPopCount;
      DoOnChange;
    finally
      EndChanging;
    end;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.AssignOR(Vector: TBitVector);
begin
AssignOR(Vector.Memory,Vector.Count);
end;
 
//------------------------------------------------------------------------------

procedure TBitVector.AssignAND(Memory: Pointer; Count: Integer);
var
  i:        Integer;
  WorkByte: Byte;
begin
If MemoryEditable('AssignAND') then
  begin
    BeginChanging;
    try
      If Count > fCount then
        begin
          i := fCount;
          Self.Count := Count;
          Fill(i,Pred(fCount),True);
        end;
      For i := 0 to Pred(Count shr 3) do
        {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ and 
                                                           {%H-}PByte({%H-}PtrUInt(Memory) + PtrUInt(i))^;
      If (Count and 7) <> 0 then
        begin
          WorkByte := {%H-}PByte({%H-}PtrUInt(Memory) + PtrUInt(Count shr 3))^;
          For i := (Count and not 7) to Pred(Count) do
            SetBit_LL(i,GetBit_LL(i) and ((WorkByte shr (i and 7)) and 1 <> 0));
        end;
      ScanForPopCount;
      DoOnChange;
    finally
      EndChanging;
    end;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.AssignAND(Vector: TBitVector);
begin
AssignAND(Vector.Memory,Vector.Count);
end;

//------------------------------------------------------------------------------

procedure TBitVector.AssignXOR(Memory: Pointer; Count: Integer);
var
  i:        Integer;
  WorkByte: Byte;
begin
If MemoryEditable('AssignXOR') then
  begin
    BeginChanging;
    try
      If Count > fCount then Self.Count := Count;
      For i := 0 to Pred(Count shr 3) do
        {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ xor
                                                           {%H-}PByte({%H-}PtrUInt(Memory) + PtrUInt(i))^;
      If (Count and 7) <> 0 then
        begin
          WorkByte := {%H-}PByte({%H-}PtrUInt(Memory) + PtrUInt(Count shr 3))^;
          For i := (Count and not 7) to Pred(Count) do
            SetBit_LL(i,GetBit_LL(i) xor ((WorkByte shr (i and 7)) and 1 <> 0));
        end;
      ScanForPopCount;
      DoOnChange;
    finally
      EndChanging;
    end;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.AssignXOR(Vector: TBitVector);
begin
AssignXOR(Vector.Memory,Vector.Count);
end;

//------------------------------------------------------------------------------

Function TBitVector.Equals(Vector: TBitVector): Boolean;
var
  i:  Integer;
begin
Result := False;
If (fCount = Vector.Count) and (fPopCount = Vector.PopCount) then
  begin
    For i := 0 to Pred(fCount shr 3) do
      If {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(i))^ <> {%H-}PByte({%H-}PtrUInt(Vector.Memory) + PtrUInt(i))^ then Exit;
    If (fCount and 7) <> 0 then
      For i := (fCount and not 7) to Pred(fCount) do
        If GetBit_LL(i) <> Vector[i] then Exit;
    Result := True;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.SaveToStream(Stream: TStream);
var
  TempByte: Byte;
begin
Stream.WriteBuffer(fMemory^,fCount shr 3);
If (fCount and 7) <> 0 then
  begin
    TempByte := {%H-}PByte({%H-}PtrUInt(fMemory) + PtrUInt(fCount shr 3))^ and (Byte($FF) shr (8 - (fCount and 7)));
    Stream.WriteBuffer(TempByte,1);
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.LoadFromStream(Stream: TStream);
begin
If MemoryEditable('LoadFromStream') then
  begin
    Count := Integer((Stream.Size - Stream.Position) shl 3);
    Stream.ReadBuffer(fMemory,fCount shr 3);
    ScanForPopCount;
    DoOnChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.SaveToFile(const FileName: String);
var
  FileStream: TFileStream;
begin
{$IF Defined(FPC) and not Defined(Unicode)}
FileStream := TFileStream.Create(UTF8ToSys(FileName),fmCreate or fmShareExclusive);
{$ELSE}
FileStream := TFileStream.Create(FileName,fmCreate or fmShareExclusive);
{$IFEND}
try
  SaveToStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.LoadFromFile(const FileName: String);
var
  FileStream: TFileStream;
begin
{$IF Defined(FPC) and not Defined(Unicode)}
FileStream := TFileStream.Create(UTF8ToSys(FileName),fmOpenRead or fmShareDenyWrite);
{$ELSE}
FileStream := TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
{$IFEND}
try
  LoadFromStream(FileStream);
finally
  FileStream.Free;
end;
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                      TBitVectorStatic - implementation                       }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TBitVectorStatic - protected methods                                       }
{==============================================================================}

procedure TBitVectorStatic.CommonInit;
begin
inherited;
fStatic := True;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                     TBitVectorStatic32 - implementation                      }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TBitVectorStatic32 - public methods                                        }
{==============================================================================}

constructor TBitVectorStatic32.Create(Memory: Pointer; Count: Integer);
begin
If (Count and 31) = 0 then
  inherited Create(Memory,Count)
else
  raise Exception.Create('TBitVectorStatic32.Create: Count must be divisible by 32.');
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

constructor TBitVectorStatic32.Create(InitialCount: Integer = 0; InitialValue: Boolean = False);
begin
If (Count and 31) = 0 then
  inherited Create(InitialCount,InitialValue)
else
  raise Exception.Create('TBitVectorStatic32.Create: Count must be divisible by 32.');
end;

//------------------------------------------------------------------------------

Function TBitVectorStatic32.FirstSet: Integer;
var
  i:      Integer;
  Buffer: UInt32;

  Function ScanBuffer(Value: UInt32): Integer;
  var
    ii: Integer;
  begin
    For ii := 0 to 31 do
      If (Value shr ii) and 1 <> 0 then
        begin
          Result := ii;
          Exit;
        end;
    raise Exception.Create('TBitVectorStatic32.FirstSet.ScanBuffer: Operation not allowed.');
  end;

begin
Result := -1;
If fCount > 0 then
  For i := 0 to Pred(fCount shr 5) do
    begin
    {$IFDEF ENDIAN_BIG}
      Buffer := SwapEndian({%H-}PUInt32({%H-}PtrUInt(fMemory) + PtrUInt(i * SizeOf(UInt32)))^);
    {$ELSE}
      Buffer := {%H-}PUInt32({%H-}PtrUInt(fMemory) + PtrUInt(i * SizeOf(UInt32)))^;
    {$ENDIF}
      If Buffer <> 0 then
        begin
          Result := (i * 32) + ScanBuffer(Buffer);
          Break;
        end;
    end;
end;

//------------------------------------------------------------------------------

Function TBitVectorStatic32.FirstClean: Integer;
var
  i:      Integer;
  Buffer: UInt32;

  Function ScanBuffer(Value: UInt32): Integer;
  var
    ii: Integer;
  begin
    For ii := 0 to 31 do
      If (Value shr ii) and 1 = 0 then
        begin
          Result := ii;
          Exit;
        end;
    raise Exception.Create('TBitVectorStatic32.FirstClean.ScanBuffer: Operation not allowed.');
  end;

begin
Result := -1;
If fCount > 0 then
  For i := 0 to Pred(fCount shr 5) do
    begin
    {$IFDEF ENDIAN_BIG}
      Buffer := SwapEndian({%H-}PUInt32({%H-}PtrUInt(fMemory) + PtrUInt(i * SizeOf(UInt32)))^);
    {$ELSE}
      Buffer := {%H-}PUInt32({%H-}PtrUInt(fMemory) + PtrUInt(i * SizeOf(UInt32)))^;
    {$ENDIF}
      If Buffer <> $FFFFFFFF then
        begin
          Result := (i * 32) + ScanBuffer(Buffer);
          Break;
        end;
    end;
end;

//------------------------------------------------------------------------------

Function TBitVectorStatic32.LastSet: Integer;
var
  i:      Integer;
  Buffer: UInt32;

  Function ScanBuffer(Value: UInt32): Integer;
  var
    ii: Integer;
  begin
    For ii := 31 downto 0 do
      If (Value shr ii) and 1 <> 0 then
        begin
          Result := ii;
          Exit;
        end;
    raise Exception.Create('TBitVectorStatic32.LastSet.ScanBuffer: Operation not allowed.');
  end;

begin
Result := -1;
If fCount > 0 then
  For i := Pred(fCount shr 5) downto 0 do
    begin
    {$IFDEF ENDIAN_BIG}
      Buffer := SwapEndian({%H-}PUInt32({%H-}PtrUInt(fMemory) + PtrUInt(i * SizeOf(UInt32)))^);
    {$ELSE}
      Buffer := {%H-}PUInt32({%H-}PtrUInt(fMemory) + PtrUInt(i * SizeOf(UInt32)))^;
    {$ENDIF}
      If Buffer <> 0 then
        begin
          Result := (i * 32) + ScanBuffer(Buffer);
          Break;
        end;
    end;
end;

//------------------------------------------------------------------------------

Function TBitVectorStatic32.LastClean: Integer;
var
  i:      Integer;
  Buffer: UInt32;

  Function ScanBuffer(Value: UInt32): Integer;
  var
    ii: Integer;
  begin
    For ii := 31 downto 0 do
      If (Value shr ii) and 1 = 0 then
        begin
          Result := ii;
          Exit;
        end;
    raise Exception.Create('TBitVectorStatic32.LastClean.ScanBuffer: Operation not allowed.');
  end;

begin
Result := -1;
If fCount > 0 then
  For i := Pred(fCount shr 5) downto 0 do
    begin
    {$IFDEF ENDIAN_BIG}
      Buffer := SwapEndian({%H-}PUInt32({%H-}PtrUInt(fMemory) + PtrUInt(i * SizeOf(UInt32)))^);
    {$ELSE}
      Buffer := {%H-}PUInt32({%H-}PtrUInt(fMemory) + PtrUInt(i * SizeOf(UInt32)))^;
    {$ENDIF}
      If Buffer <> $FFFFFFFF then
        begin
          Result := (i * 32) + ScanBuffer(Buffer);
          Break;
        end;
    end;
end;

end.

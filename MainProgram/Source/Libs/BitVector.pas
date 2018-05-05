{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  BitVector classes

  ©František Milt 2018-05-02

  Version 1.3

  Dependencies:
    AuxTypes    - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses  - github.com/ncs-sniper/Lib.AuxClasses
    BitOps      - github.com/ncs-sniper/Lib.BitOps
    StrRect     - github.com/ncs-sniper/Lib.StrRect
  * SimpleCPUID - github.com/ncs-sniper/Lib.SimpleCPUID

  SimpleCPUID might not be needed, see BitOps library for details.

===============================================================================}
unit BitVector;

interface

{$IFDEF FPC}
  {$MODE Delphi}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

{$TYPEINFO ON}

uses
  Classes, AuxTypes, AuxClasses;

type
{===============================================================================
--------------------------------------------------------------------------------
                                   TBitVector                                   
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TBitVector - class declaration
===============================================================================}

  TBitVector = class(TCustomListObject)
  private
    fOwnsMemory:    Boolean;
    fStatic:        Boolean;
    fMemSize:       TMemSize;
    fMemory:        Pointer;
    fCount:         Integer;
    fPopCount:      Integer;
    fChangeCounter: Integer;
    fChanged:       Boolean;
    fOnChange:      TNotifyEvent;
    Function GetBytePtrBitIdx(BitIndex: Integer): PByte;
    Function GetBytePtrByteIdx(ByteIndex: Integer): PByte;
    Function GetBit_LL(Index: Integer): Boolean;
    Function SetBit_LL(Index: Integer; Value: Boolean): Boolean;
    Function GetBit(Index: Integer): Boolean;
    procedure SetBit(Index: Integer; Value: Boolean);
  protected
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
    procedure ShiftDown(Idx1,Idx2: Integer); virtual;
    procedure ShiftUp(Idx1,Idx2: Integer); virtual;
    procedure RaiseError(const ErrorMessage: String; Values: array of const); overload; virtual;
    procedure RaiseError(const ErrorMessage: String); overload; virtual;
    Function MemoryEditable(MethodName: String = 'MemoryEditable'; RaiseException: Boolean = True): Boolean; virtual;
    Function CheckIndexAndRaise(Index: Integer; MethodName: String = 'CheckIndex'): Boolean; virtual;
    procedure CommonInit; virtual;
    procedure ScanForPopCount; virtual;
    procedure DoOnChange; virtual;
  public
    constructor Create(Memory: Pointer; Count: Integer); overload; virtual;
    constructor Create(InitialCount: Integer = 0; InitialValue: Boolean = False); overload; virtual;
    destructor Destroy; override;
    procedure BeginChanging;
    Function EndChanging: Integer;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function First: Boolean; virtual;
    Function Last: Boolean; virtual;
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
    Function IsEqual(Vector: TBitVector): Boolean; virtual;
    procedure SaveToStream(Stream: TStream); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToFile(const FileName: String); virtual;
    procedure LoadFromFile(const FileName: String); virtual;
    property Bits[Index: Integer]: Boolean read GetBit write SetBit; default;
    property Memory: Pointer read fMemory;
  published
    property OwnsMemory: Boolean read fOwnsMemory;
    property Static: Boolean read fStatic;
    property PopCount: Integer read fPopCount;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                TBitVectorStatic
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TBitVectorStatic - class declaration
===============================================================================}

  TBitVectorStatic = class(TBitVector)
  protected
    procedure CommonInit; override;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                               TBitVectorStatic32                               
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TBitVectorStatic32 - class declaration
===============================================================================}

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
  SysUtils, Math, BitOps, StrRect;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W4055:={$WARN 4055 OFF}} // Conversion between ordinals and pointers is not portable
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                   TBitVector                                   
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TBitVector - auxiliaty constants and functions
===============================================================================}

const
  AllocDeltaBits  = 128;
  AllocDeltaBytes = AllocDeltaBits div 8;

Function BooleanOrd(Value: Boolean): Integer;
begin
If Value then Result := 1
  else Result := 0;
end;

{===============================================================================
    TBitVector - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TBitVector - private methods
-------------------------------------------------------------------------------}

Function TBitVector.GetBytePtrBitIdx(BitIndex: Integer): PByte;
begin
{$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
Result := PByte(PtrUInt(fMemory) + PtrUInt(BitIndex shr 3));
{$IFDEF FPCDWM}{$POP}{$ENDIF}
end;

//------------------------------------------------------------------------------

Function TBitVector.GetBytePtrByteIdx(ByteIndex: Integer): PByte;
begin
{$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
Result := PByte(PtrUInt(fMemory) + PtrUInt(ByteIndex));
{$IFDEF FPCDWM}{$POP}{$ENDIF}
end;

//------------------------------------------------------------------------------

Function TBitVector.GetBit_LL(Index: Integer): Boolean;
begin
Result := BT(GetBytePtrBitIdx(Index)^,Index and 7);
end;

//------------------------------------------------------------------------------

Function TBitVector.SetBit_LL(Index: Integer; Value: Boolean): Boolean;
begin
Result := BitSetTo(GetBytePtrBitIdx(Index)^,Index and 7,Value);
end;

//------------------------------------------------------------------------------

Function TBitVector.GetBit(Index: Integer): Boolean;
begin
Result := False;
If CheckIndexAndRaise(Index,'GetBit') then
  Result := GetBit_LL(Index);
end;

//------------------------------------------------------------------------------

procedure TBitVector.SetBit(Index: Integer; Value: Boolean);
begin
If CheckIndexAndRaise(Index,'SetBit') then
  begin
    If Value <> SetBit_LL(Index,Value) then
      begin
        If Value then Inc(fPopCount)
          else Dec(fPopCount);
        DoOnChange;
      end;
  end;
end;

{-------------------------------------------------------------------------------
    TBitVector - protected methods
-------------------------------------------------------------------------------}

Function TBitVector.GetCapacity: Integer;
begin
Result := Integer(fMemSize shl 3);
end;

//------------------------------------------------------------------------------

procedure TBitVector.SetCapacity(Value: Integer);
var
  NewMemSize: TMemSize;
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
    else RaiseError('SetCapacity: Negative capacity not allowed.');
  end;
end;

//------------------------------------------------------------------------------

Function TBitVector.GetCount: Integer;
begin
Result := fCount;
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
              If Value > Capacity then
                Capacity := Value;
              If Value > fCount then
                begin
                  // reset added bits
                  If (fCount and 7) <> 0 then
                    SetBitsValue(GetBytePtrBitIdx(Pred(fCount))^,0,fCount and 7,7);
                  For i := Ceil(fCount / 8) to (Pred(Value) shr 3) do
                    GetBytePtrByteIdx(i)^ := 0;
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
    else RaiseError('SetCount: Negative count not allowed.');
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.ShiftDown(Idx1,Idx2: Integer);
var
  Carry:  Boolean;
  i:      Integer;
  Buffer: UInt16;  
begin
If Idx2 > Idx1 then
  begin
    If (Idx1 shr 3) = (Idx2 shr 3)  then
      begin
        // shift is done inside of one byte
        SetBitsValue(GetBytePtrBitIdx(Idx1)^,GetBytePtrBitIdx(Idx1)^ shr 1,Idx1 and 7,Idx2 and 7);
      end
    else
      begin
        // shift is done across at least one byte boundary
        // shift last byte and preserve shifted-out bit
        Carry := GetBit_LL(Idx2 and not 7);
        SetBitsValue(GetBytePtrBitIdx(Idx2)^,GetBytePtrBitIdx(Idx2)^ shr 1,0,Idx2 and 7);
        // shift whole bytes
        For i := Pred(Idx2 shr 3) downto Succ(Idx1 shr 3) do
          begin
            Buffer := GetBytePtrByteIdx(i)^;
            BitSetTo(Buffer,8,Carry);
            Carry := (Buffer and 1) <> 0;
            GetBytePtrByteIdx(i)^ := Byte(Buffer shr 1);
          end;
        // shift first byte and store carry
        SetBitsValue(GetBytePtrBitIdx(Idx1)^,GetBytePtrBitIdx(Idx1)^ shr 1,Idx1 and 7,7);
        SetBit_LL(Idx1 or 7,Carry);
      end;
  end
else RaiseError('ShiftDown: First index (%d) must be smaller or equal to the second index (%d).',[Idx1,Idx2]);
end;

//------------------------------------------------------------------------------

procedure TBitVector.ShiftUp(Idx1,Idx2: Integer);
var
  Carry:  Boolean;
  i:      Integer;
  Buffer: UInt16;
begin
If Idx2 > Idx1 then
  begin
    If (Idx1 shr 3) = (Idx2 shr 3)  then
      begin
        // shift is done inside of one byte
        SetBitsValue(GetBytePtrBitIdx(Idx1)^,Byte(GetBytePtrBitIdx(Idx1)^ shl 1),Idx1 and 7,Idx2 and 7);
      end
    else
      begin
        // shift is done across at least one byte boundary
        // shift first byte and preserve shifted-out bit
        Carry := GetBit_LL(Idx1 or 7);
        SetBitsValue(GetBytePtrBitIdx(Idx1)^,Byte(GetBytePtrBitIdx(Idx1)^ shl 1),Idx1 and 7,7);
        // shift whole bytes
        For i := Succ(Idx1 shr 3) to Pred(Idx2 shr 3) do
          begin
            Buffer := UInt16(GetBytePtrByteIdx(i)^ shl 1);
            BitSetTo(Buffer,0,Carry);
            Carry := (Buffer and $100) <> 0;
            GetBytePtrByteIdx(i)^ := Byte(Buffer);
          end;
        // shift last byte and store carry
        SetBitsValue(GetBytePtrBitIdx(Idx2)^,Byte(GetBytePtrBitIdx(Idx2)^ shl 1),0,Idx2 and 7);
        SetBit_LL(Idx2 and not 7,Carry);
      end;
  end
else RaiseError('ShiftDown: First index (%d) must be smaller or equal to the second index (%d).',[Idx1,Idx2]);
end;

//------------------------------------------------------------------------------

procedure TBitVector.RaiseError(const ErrorMessage: String; Values: array of const);
begin
raise Exception.CreateFmt(Format('%s.%s',[Self.ClassName,ErrorMessage]),Values);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TBitVector.RaiseError(const ErrorMessage: String);
begin
RaiseError(ErrorMessage,[]);
end;

//------------------------------------------------------------------------------

Function TBitVector.MemoryEditable(MethodName: String = 'MemoryEditable'; RaiseException: Boolean = True): Boolean;
begin
Result := fOwnsMemory and not fStatic;
If RaiseException then
  begin
    If fStatic then
      RaiseError('%s: Method not allowed for a static vector.',[MethodName]);
    If not fOwnsMemory then
      RaiseError('%s: Method not allowed for not owned memory.',[MethodName]);
  end;
end;

//------------------------------------------------------------------------------

Function TBitVector.CheckIndexAndRaise(Index: Integer; MethodName: String = 'CheckIndex'): Boolean;
begin
Result := CheckIndex(Index);
If not Result then
  RaiseError('%s: Index (%d) out of bounds.',[MethodName,Index]);
end;

//------------------------------------------------------------------------------

procedure TBitVector.CommonInit;
begin
fStatic := False;
fChangeCounter := 0;
fChanged := False;
fOnChange := nil;
end;

//------------------------------------------------------------------------------

procedure TBitVector.ScanForPopCount;
var
  i:        Integer;
begin
fPopCount := 0;
If fCount > 0 then
  begin
    For i := 0 to Pred(fCount shr 3) do
      Inc(fPopCount,BitOps.PopCount(GetBytePtrByteIdx(i)^));
    If (fCount and 7) > 0 then
      Inc(fPopCount,BitOps.PopCount(Byte(GetBytePtrBitIdx(fCount)^ and ($FF shr (8 - (fCount and 7))))));
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.DoOnChange;
begin
fChanged := True;
If (fChangeCounter <= 0) and Assigned(fOnChange) then
  fOnChange(Self);
end;

{-------------------------------------------------------------------------------
    TBitVector - public methods
-------------------------------------------------------------------------------}

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
If fChangeCounter <= 0 then
  fChanged := False;
Inc(fChangeCounter);
end;

//------------------------------------------------------------------------------

Function TBitVector.EndChanging: Integer;
begin
Dec(fChangeCounter);
If fChangeCounter <= 0 then
  begin
    fChangeCounter := 0;
    If fChanged and Assigned(fOnChange) then
      fOnChange(Self);
  end;
Result := fChangeCounter;  
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

Function TBitVector.First: Boolean;
begin
Result := GetBit(LowIndex);
end;

//------------------------------------------------------------------------------

Function TBitVector.Last: Boolean;
begin
Result := GetBit(HighIndex);
end;

//------------------------------------------------------------------------------

Function TBitVector.Add(Value: Boolean): Integer;
begin
If MemoryEditable('Add') then
  begin
    Grow;
    Inc(fCount);
    SetBit_LL(HighIndex,Value);
    If Value then
      Inc(fPopCount);
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
    If Index < fCount then
      begin
        If CheckIndexAndRaise(Index,'Insert') then
          begin
            Grow;
            Inc(fCount);
            ShiftUp(Index,HighIndex);
            SetBit_LL(Index,Value);
            If Value then
              Inc(fPopCount);
            DoOnChange;
          end;
      end
    else Add(Value);
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Delete(Index: Integer);
begin
If MemoryEditable('Delete') then
  begin
    If CheckIndexAndRaise(Index,'Delete') then
      begin
        If GetBit_LL(Index) then
          Dec(fPopCount);
        If Index < HighIndex then
          ShiftDown(Index,HighIndex);
        Dec(fCount);
        Shrink;
        DoOnChange;
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Exchange(Index1, Index2: Integer);
begin
If Index1 <> Index2 then
  If CheckIndexAndRaise(Index1,'Exchange') and CheckIndexAndRaise(Index2,'Exchange') then
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
If SrcIdx <> DstIdx then
  If CheckIndexAndRaise(SrcIdx,'Move') and CheckIndexAndRaise(DstIdx,'Move') then
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

//------------------------------------------------------------------------------

procedure TBitVector.Fill(FromIdx, ToIdx: Integer; Value: Boolean);
var
  i:  Integer;
begin
If FromIdx <= ToIdx then
  If CheckIndexAndRaise(FromIdx,'Fill') and CheckIndexAndRaise(ToIdx,'Fill') then
    begin
      If FromIdx <> ToIdx then
        begin
          If ((FromIdx and 7) <> 0) or ((ToIdx - FromIdx) < 7) then
            SetBitsValue(GetBytePtrBitIdx(FromIdx)^,$FF * BooleanOrd(Value),FromIdx and 7,Min(ToIdx - (FromIdx and not 7),7));
          For i := Ceil(FromIdx / 8) to Pred(Succ(ToIdx) shr 3) do
            GetBytePtrByteIdx(i)^ := $FF * BooleanOrd(Value);
          If ((ToIdx and 7) < 7) and ((ToIdx and not 7) > FromIdx) then
            SetBitsValue(GetBytePtrBitIdx(ToIdx)^,$FF * BooleanOrd(Value),0,ToIdx and 7);
          ScanForPopCount;
          DoOnChange;
        end
      else SetBit(FromIdx,Value);
    end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.Fill(Value: Boolean);
var
  i:  Integer;
begin
If fCount > 0 then
  begin
    For i := 0 to (Pred(fCount) shr 3) do
      GetBytePtrByteIdx(i)^ := $FF * BooleanOrd(Value);
    fPopCount := fCount * BooleanOrd(Value);
    DoOnChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.Complement(FromIdx, ToIdx: Integer);
var
  i:  Integer;
begin
If FromIdx <= ToIdx then
  If CheckIndexAndRaise(FromIdx,'Complement') and CheckIndexAndRaise(ToIdx,'Complement') then
    begin
      If FromIdx <> ToIdx then
        begin
          If ((FromIdx and 7) <> 0) or ((ToIdx - FromIdx) < 7) then
            SetBitsValue(GetBytePtrBitIdx(FromIdx)^,not GetBytePtrBitIdx(FromIdx)^,FromIdx and 7,Min(ToIdx - (FromIdx and not 7),7));
          For i := Ceil(FromIdx / 8) to Pred(Succ(ToIdx) shr 3) do
            GetBytePtrByteIdx(i)^ := not GetBytePtrByteIdx(i)^;
          If ((ToIdx and 7) < 7) and ((ToIdx and not 7) > FromIdx) then
            SetBitsValue(GetBytePtrBitIdx(ToIdx)^,not GetBytePtrBitIdx(ToIdx)^,0,ToIdx and 7);
          ScanForPopCount;
          DoOnChange;
        end
      else SetBit(FromIdx,not GetBit_LL(FromIdx));
    end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.Complement;
var
  i:  Integer;
begin
If fCount > 0 then
  begin
    For i := 0 to (Pred(fCount) shr 3) do
      GetBytePtrByteIdx(i)^ := not GetBytePtrByteIdx(i)^;
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
    Shrink;
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
Result := (fCount > 0) and (fPopCount >= fCount);
end;

//------------------------------------------------------------------------------

Function TBitVector.FirstSet: Integer;
var
  i:        Integer;
  WorkByte: Byte;
begin
If fCount > 0 then
  begin
    For i := 0 to Pred(fCount shr 3) do
      begin
        WorkByte := GetBytePtrByteIdx(i)^;
        If WorkByte <> 0 then
          begin
            Result := (i * 8) + BSF(WorkByte);
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
begin
If fCount > 0 then
  begin
    For i := 0 to Pred(fCount shr 3) do
      begin
        WorkByte := GetBytePtrByteIdx(i)^;
        If WorkByte <> $FF then
          begin
            Result := (i * 8) + BSF(not WorkByte);
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
        WorkByte := GetBytePtrByteIdx(i)^;
        If WorkByte <> 0 then
          begin
            Result := (i * 8) + BSR(WorkByte);
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
        WorkByte := GetBytePtrByteIdx(i)^;
        If WorkByte <> $FF then
          begin
            Result := (i * 8) + BSR(not WorkByte);
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
  Shift:      Integer;
  i:          Integer;
  ByteBuff:   PByte;
begin
If MemoryEditable('Append') and (Count > 0) then
  begin
    If (fCount and 7) = 0 then
      begin
        Capacity := fCount + Count;
        System.Move(Memory^,GetBytePtrByteIdx(fCount shr 3)^,Ceil(Count / 8));
      end
    else
      begin
        Capacity := Succ(fCount or 7) + Count;
        System.Move(Memory^,GetBytePtrByteIdx(Succ(fCount shr 3))^,Ceil(Count / 8));
        Shift := 8 - (fCount and 7);
        For i := (fCount shr 3) to Pred((fCount shr 3) + Ceil(Count / 8)) do
          begin
            ByteBuff := GetBytePtrByteIdx(i + 1);
            SetBitsValue(GetBytePtrByteIdx(i)^,Byte(ByteBuff^ shl (8 - Shift)),8 - Shift,7);
            ByteBuff^ := ByteBuff^ shr Shift;
          end;
      end;
    Inc(fCount,Count);
    ScanForPopCount;
    DoOnChange;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBitVector.Append(Vector: TBitVector);
begin
Append(Vector.Memory,Vector.Count);
end;

//------------------------------------------------------------------------------

procedure TBitVector.Assign(Memory: Pointer; Count: Integer);
begin
If MemoryEditable('Assign') then
  begin
    If Count > Capacity then
      Capacity := Count;
    System.Move(Memory^,fMemory^,Ceil(Count / 8));
    fCount := Count;
    ScanForPopCount;
    DoOnChange;
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
  i:  Integer;
begin
If MemoryEditable('AssignOR') then
  begin
    BeginChanging;
    try
      If Count > fCount then Self.Count := Count;
    {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
      For i := 0 to Pred(Count shr 3) do
        GetBytePtrByteIdx(i)^ := GetBytePtrByteIdx(i)^ or PByte(PtrUInt(Memory) + PtrUInt(i))^;
      If (Count and 7) <> 0 then
        For i := (Count and not 7) to Pred(Count) do
          SetBit_LL(i,GetBit_LL(i) or ((PByte(PtrUInt(Memory) + PtrUInt(Count shr 3))^ shr (i and 7)) and 1 <> 0));
    {$IFDEF FPCDWM}{$POP}{$ENDIF}
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
  i:  Integer;
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
    {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
      For i := 0 to Pred(Count shr 3) do
        GetBytePtrByteIdx(i)^ := GetBytePtrByteIdx(i)^ and PByte(PtrUInt(Memory) + PtrUInt(i))^;
      If (Count and 7) <> 0 then
        For i := (Count and not 7) to Pred(Count) do
          SetBit_LL(i,GetBit_LL(i) and ((PByte(PtrUInt(Memory) + PtrUInt(Count shr 3))^ shr (i and 7)) and 1 <> 0));
    {$IFDEF FPCDWM}{$POP}{$ENDIF}
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
  i:  Integer;
begin
If MemoryEditable('AssignXOR') then
  begin
    BeginChanging;
    try
      If Count > fCount then Self.Count := Count;
    {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
      For i := 0 to Pred(Count shr 3) do
        GetBytePtrByteIdx(i)^ := GetBytePtrByteIdx(i)^ xor PByte(PtrUInt(Memory) + PtrUInt(i))^;
      If (Count and 7) <> 0 then
        For i := (Count and not 7) to Pred(Count) do
          SetBit_LL(i,GetBit_LL(i) xor ((PByte(PtrUInt(Memory) + PtrUInt(Count shr 3))^ shr (i and 7)) and 1 <> 0));
    {$IFDEF FPCDWM}{$POP}{$ENDIF}
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

Function TBitVector.IsEqual(Vector: TBitVector): Boolean;
var
  i:  Integer;
begin
Result := False;
If (fCount = Vector.Count) and (fPopCount = Vector.PopCount) then
  begin
  {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
    For i := 0 to Pred(fCount shr 3) do
      If GetBytePtrByteIdx(i)^ <> PByte(PtrUInt(Vector.Memory) + PtrUInt(i))^ then Exit;
  {$IFDEF FPCDWM}{$POP}{$ENDIF}
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
    TempByte := SetBits(0,GetBytePtrByteIdx(fCount shr 3)^,0,Pred(fCount and 7));
    Stream.WriteBuffer(TempByte,1);
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.LoadFromStream(Stream: TStream);
begin
If MemoryEditable('LoadFromStream') then
  begin
    Count := Integer((Stream.Size - Stream.Position) shl 3);
    Stream.ReadBuffer(fMemory^,fCount shr 3);
    ScanForPopCount;
    DoOnChange;
  end;
end;

//------------------------------------------------------------------------------

procedure TBitVector.SaveToFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareExclusive);
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
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  LoadFromStream(FileStream);
finally
  FileStream.Free;
end;
end;


{===============================================================================
--------------------------------------------------------------------------------
                                TBitVectorStatic
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TBitVectorStatic - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TBitVectorStatic - protected methods
-------------------------------------------------------------------------------}

procedure TBitVectorStatic.CommonInit;
begin
inherited;
fStatic := True;
end;

{===============================================================================
--------------------------------------------------------------------------------
                               TBitVectorStatic32
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TBitVectorStatic32 - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TBitVectorStatic32 - public methods
-------------------------------------------------------------------------------}

constructor TBitVectorStatic32.Create(Memory: Pointer; Count: Integer);
begin
If (Count and 31) = 0 then
  inherited Create(Memory,Count)
else
  RaiseError('Create: Count must be divisible by 32.');
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

constructor TBitVectorStatic32.Create(InitialCount: Integer = 0; InitialValue: Boolean = False);
begin
If (Count and 31) = 0 then
  inherited Create(InitialCount,InitialValue)
else
  RaiseError('Create: Count must be divisible by 32.');
end;

//------------------------------------------------------------------------------

Function TBitVectorStatic32.FirstSet: Integer;
var
  i:      Integer;
  Buffer: UInt32;
begin
Result := -1;
If fCount > 0 then
  For i := 0 to Pred(fCount shr 5) do
    begin
    {$IFDEF ENDIAN_BIG}
      Buffer := EndianSwap(PUInt32(GetBytePtrByteIdx(i * SizeOf(UInt32)))^);
    {$ELSE}
      Buffer := PUInt32(GetBytePtrByteIdx(i * SizeOf(UInt32)))^;
    {$ENDIF}
      If Buffer <> 0 then
        begin
          Result := (i * 32) + BSF(Buffer);
          Break;
        end;
    end;
end;

//------------------------------------------------------------------------------

Function TBitVectorStatic32.FirstClean: Integer;
var
  i:      Integer;
  Buffer: UInt32;
begin
Result := -1;
If fCount > 0 then
  For i := 0 to Pred(fCount shr 5) do
    begin
    {$IFDEF ENDIAN_BIG}
      Buffer := EndianSwap(PUInt32(GetBytePtrByteIdx(i * SizeOf(UInt32)))^);
    {$ELSE}
      Buffer := PUInt32(GetBytePtrByteIdx(i * SizeOf(UInt32)))^;
    {$ENDIF}
      If Buffer <> $FFFFFFFF then
        begin
          Result := (i * 32) + BSF(not Buffer);
          Break;
        end;
    end;
end;

//------------------------------------------------------------------------------

Function TBitVectorStatic32.LastSet: Integer;
var
  i:      Integer;
  Buffer: UInt32;
begin
Result := -1;
If fCount > 0 then
  For i := Pred(fCount shr 5) downto 0 do
    begin
    {$IFDEF ENDIAN_BIG}
      Buffer := EndianSwap(PUInt32(GetBytePtrByteIdx(i * SizeOf(UInt32)))^);
    {$ELSE}
      Buffer := PUInt32(GetBytePtrByteIdx(i * SizeOf(UInt32)))^;
    {$ENDIF}
      If Buffer <> 0 then
        begin
          Result := (i * 32) + BSR(Buffer);
          Break;
        end;
    end;
end;

//------------------------------------------------------------------------------

Function TBitVectorStatic32.LastClean: Integer;
var
  i:      Integer;
  Buffer: UInt32;
begin
Result := -1;
If fCount > 0 then
  For i := Pred(fCount shr 5) downto 0 do
    begin
    {$IFDEF ENDIAN_BIG}
      Buffer := EndianSwap(PUInt32(GetBytePtrByteIdx(i * SizeOf(UInt32)))^);
    {$ELSE}
      Buffer := PUInt32(GetBytePtrByteIdx(i * SizeOf(UInt32)))^;
    {$ENDIF}
      If Buffer <> $FFFFFFFF then
        begin
          Result := (i * 32) + BSR(not Buffer);
          Break;
        end;
    end;
end;

end.

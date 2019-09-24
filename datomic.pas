unit datomic;
//
//  Implements atomic versions for some primitive types as object wrappers.
//
//  All public methods and properties are atomic operations.
//

{$MODE FPC}
{$MODESWITCH RESULT}
{$MODESWITCH OUT}

interface

type
PAtomicInteger = ^TAtomicInteger;
TAtomicInteger = object
    // Atomic signed integer.

public type
  TInteger = PtrInt;
  TValue   = TInteger;
    // Actual primitive type. You can use the type as TAtomicInteger.TValue
    // to store non-atomic integers that exchange their values with atomic
    // integers.
    //
    // Example:
    //
    //      var
    //        A: TAtomicInteger;
    //        I: TAtomicInteger.TInteger;
    //
    //      I := 5;
    //      A.Init(I);
    //      I := A.Value + 10;
    //      A.Value := 13;
    //      A.CompareExchangeStrong(I, 13);
    //      A.Done;

public const
  SIZE      = SizeOf(TInteger);
    // Size in bytes.
  BITS      = 8 * SIZE;
    // Size in bits.

private
  FValue: TInteger;

public
  procedure Init(Value: TInteger);
    // Like SetValue, but assumes unitialized.
  procedure Done; inline;
    // Discards the value.
  function GetValue: TInteger; inline;
    // Atomicly reads the value.
  procedure SetValue(Value: TInteger); inline;
    // Atomicly writes the value.
  function CompareExchangeStrong(var Expected: TInteger;
                                 Desired: TInteger): Boolean; inline;
    // Does atomic compare-and-exchange operation.
    //
    // Compares the value and the Expected. If they are equal, sets the value
    // to the Desired and returns True. If they are not equal, sets the Expected
    // to the current value and returns False.
  procedure Inc; inline;
    // Increments the value by 1.
  procedure Dec; inline;
    // Decrements the value by 1.
  property Value: TInteger read GetValue write SetValue;
end;

PAtomicBoolean = ^TAtomicBoolean;
TAtomicBoolean = object
public type
  TValue = Boolean;

private
  FValue: TAtomicInteger.TInteger;

public
  procedure Init(Value: Boolean);
    // Like SetValue, but assumes unitialized.
  procedure Done; inline;
    // Discards the value.
  function GetValue: Boolean; inline;
    // Atomicly reads the value.
  procedure SetValue(Value: Boolean); inline;
    // Atomicly writes the value.
  function CompareExchangeStrong(var Expected: Boolean;
                                 Desired: Boolean): Boolean; inline;
    // Compares the value and the Expected. If they are equal, sets the value
    // to the Desired and returns True. If they are not equal, sets the Expected
    // to the current value and returns False.
    //
    // The whole operation is atomic.
  function Exchange(NewValue: Boolean): Boolean; inline;
    // Writes the NewValue. Returns the old value.
  property Value: Boolean read GetValue write SetValue;
end;

PAtomicPointer = ^TAtomicPointer;
TAtomicPointer = object
public type
  TValue = Pointer;

private
  FValue: Pointer;

public
  procedure Init(Value: Pointer);
    // Like SetValue, but assumes unitialized.
  procedure Done; inline;
    // Discards the value.
  function GetValue: Pointer; inline;
    // Atomicly reads the value.
  procedure SetValue(Value: Pointer); inline;
    // Atomicly writes the value.
  function CompareExchangeStrong(var Expected: Pointer;
                                 Desired: Pointer): Boolean; inline;
    // Compares the value and the Expected. If they are equal, sets the value
    // to the Desired and returns True. If they are not equal, sets the Expected
    // to the current value and returns False.
    //
    // The whole operation is atomic.
  property Value: Pointer read GetValue write SetValue;
end;

implementation

procedure TAtomicInteger.Init(Value: TInteger);
begin
  FValue := Value;
end;

procedure TAtomicInteger.Done;
begin
end;

function TAtomicInteger.GetValue: TInteger;
begin
  // Here and further we use Pointer version of InterlockedCompareExchange,
  // because only this version works with values of size of native integers.
  Result := TInteger(InterlockedCompareExchange(Pointer(FValue), nil, nil));
end;

procedure TAtomicInteger.SetValue(Value: TInteger);
begin
  InterlockedExchange(Pointer(FValue), Pointer(Value));
end;

function TAtomicInteger.CompareExchangeStrong(var Expected: TInteger;
                               Desired: TInteger): Boolean;
var
  Temp: TInteger;
begin
  Temp := TInteger(InterlockedCompareExchange(Pointer(FValue), Pointer(Desired), Pointer(Expected)));
  Result := Expected = Temp;
  Expected := Temp;
end;

procedure TAtomicInteger.Inc;
begin
  InterlockedIncrement(Pointer(FValue));
end;

procedure TAtomicInteger.Dec;
begin
  InterlockedDecrement(Pointer(FValue));
end;

procedure TAtomicBoolean.Init(Value: Boolean);
begin
  FValue := TAtomicInteger.TInteger(Value);
end;

procedure TAtomicBoolean.Done;
begin
end;

function TAtomicBoolean.GetValue: Boolean;
begin
  Exit(PtrUInt(InterlockedCompareExchange(Pointer(TAtomicInteger.TInteger(FValue)), nil, nil)) <> 0);
end;

procedure TAtomicBoolean.SetValue(Value: Boolean);
begin
  InterlockedExchange(Pointer(FValue), Pointer(TAtomicInteger.TInteger(Value)));
end;

function TAtomicBoolean.CompareExchangeStrong(var Expected: Boolean;
                               Desired: Boolean): Boolean;
var
  Temp: Boolean;
begin
  Temp := PtrUInt(InterlockedCompareExchange(Pointer(FValue), Pointer(TAtomicInteger.TInteger(Desired)), Pointer(TAtomicInteger.TInteger(Expected)))) <> 0;
  Result := Expected = Temp;
  Expected := Temp;
end;

function TAtomicBoolean.Exchange(NewValue: Boolean): Boolean;
begin
  Exit(PtrUInt(InterlockedExchange(Pointer(FValue), Pointer(TAtomicInteger.TInteger(NewValue)))) <> 0);
end;

procedure TAtomicPointer.Init(Value: Pointer);
begin
  FValue := Value;
end;

procedure TAtomicPointer.Done;
begin
end;

function TAtomicPointer.GetValue: Pointer;
begin
  Result := InterlockedCompareExchange(FValue, nil, nil);
end;

procedure TAtomicPointer.SetValue(Value: Pointer);
begin
  InterlockedExchange(FValue, Value);
end;

function TAtomicPointer.CompareExchangeStrong(var Expected: Pointer;
                               Desired: Pointer): Boolean;
var
  Temp: Pointer;
begin
  Temp := InterlockedCompareExchange(FValue, Desired, Expected);
  Result := Expected = Temp;
  Expected := Temp;
end;

end.

unit AllSerializablePrimitives;

interface

uses
  System.SysUtils, System.Classes, System.JSON, JSON2Obj;

type
  TObjectStatus = (osUnknown, osActive, osInactive);
  TObjectStatusSet = set of TObjectStatus;

  [MarshallOption( SerializeProperty )]
  TAllPrimitives = class
  private
    // --- Boolean ---
    FBoolValue: Boolean;

    // --- Integer family ---
    FByteValue: Byte;
    FShortIntValue: ShortInt;
    FSmallIntValue: SmallInt;
    FWordValue: Word;
    FIntegerValue: Integer;
    FCardinalValue: Cardinal;
    FInt64Value: Int64;
    FUInt64Value: UInt64;

    // --- Floating point ---
    FSingleValue: Single;
    FDoubleValue: Double;
    FExtendedValue: Extended;
    FCurrencyValue: Currency;
    FCompValue: Comp;

    // --- Characters ---
    FCharValue: Char;
    FWideCharValue: WideChar;
    FAnsiCharValue: AnsiChar;

    // --- Strings ---
    FStringValue: string;
    FAnsiStringValue: AnsiString;
    FWideStringValue: WideString;

    // --- Date / time ---
    FDateTimeValue: TDateTime;
    FDateValue: TDate;
    FTimeValue: TTime;

    // --- Special ---
    FGUIDValue: TGUID;
    FBytesValue: TBytes;

    // --- Enum + Set ---
    FStatus: TObjectStatus;
    FStatuses: TObjectStatusSet;

    // --- Arrays ---
    FIntArray: TArray<Integer>;
    FStrArray: TArray<string>;
    FBoolArray: TArray<Boolean>;
    FDoubleArray: TArray<Double>;

  public
    constructor Create;

    // --- Properties ---
    property BoolValue: Boolean read FBoolValue write FBoolValue;

    property ByteValue: Byte read FByteValue write FByteValue;
    property ShortIntValue: ShortInt read FShortIntValue write FShortIntValue;
    property SmallIntValue: SmallInt read FSmallIntValue write FSmallIntValue;
    property WordValue: Word read FWordValue write FWordValue;
    property IntegerValue: Integer read FIntegerValue write FIntegerValue;
    property CardinalValue: Cardinal read FCardinalValue write FCardinalValue;
    property Int64Value: Int64 read FInt64Value write FInt64Value;
    property UInt64Value: UInt64 read FUInt64Value write FUInt64Value;

    property SingleValue: Single read FSingleValue write FSingleValue;
    property DoubleValue: Double read FDoubleValue write FDoubleValue;
    property ExtendedValue: Extended read FExtendedValue write FExtendedValue;
    property CurrencyValue: Currency read FCurrencyValue write FCurrencyValue;
    property CompValue: Comp read FCompValue write FCompValue;

    property CharValue: Char read FCharValue write FCharValue;
    property WideCharValue: WideChar read FWideCharValue write FWideCharValue;
    property AnsiCharValue: AnsiChar read FAnsiCharValue write FAnsiCharValue;

    property StringValue: string read FStringValue write FStringValue;
    property AnsiStringValue: AnsiString read FAnsiStringValue write FAnsiStringValue;
    property WideStringValue: WideString read FWideStringValue write FWideStringValue;

    property DateTimeValue: TDateTime read FDateTimeValue write FDateTimeValue;
    property DateValue: TDate read FDateValue write FDateValue;
    property TimeValue: TTime read FTimeValue write FTimeValue;

    property GUIDValue: TGUID read FGUIDValue write FGUIDValue;
    property BytesValue: TBytes read FBytesValue write FBytesValue;

    property Status: TObjectStatus read FStatus write FStatus;
    property Statuses: TObjectStatusSet read FStatuses write FStatuses;

    property IntArray: TArray<Integer> read FIntArray write FIntArray;
    property StrArray: TArray<string> read FStrArray write FStrArray;
    property BoolArray: TArray<Boolean> read FBoolArray write FBoolArray;
    property DoubleArray: TArray<Double> read FDoubleArray write FDoubleArray;
  end;

implementation

{ TAllPrimitives }

constructor TAllPrimitives.Create;
begin
  inherited;

  // Booleans
  FBoolValue := True;

  // Integers
  FByteValue := 255;
  FShortIntValue := -100;
  FSmallIntValue := 32000;
  FWordValue := 65000;
  FIntegerValue := 123456;
  FCardinalValue := 987654;
  FInt64Value := 1234567890123;
  FUInt64Value := 9876543210987;

  // Floating
  FSingleValue := 3.14;
  FDoubleValue := 2.718281828;
  FExtendedValue := 1.6180339887;
  FCurrencyValue := 1234.56;
  FCompValue := 99999;

  // Characters
  FCharValue := 'A';
  FWideCharValue := 'Ω';
  FAnsiCharValue := 'Z';

  // Strings
  FStringValue := 'Hello World';
  FAnsiStringValue := 'Ansi Text';
  FWideStringValue := 'Wide Text ✓';

  // Date / time
  FDateTimeValue := Now;
  FDateValue := Date;
  FTimeValue := Time;

  // Special
  FGUIDValue := TGUID.NewGuid;
  FBytesValue := TEncoding.UTF8.GetBytes('binary-data');

  // Enum + set
  FStatus := osActive;
  FStatuses := [osActive, osInactive];

  // Arrays
  FIntArray := TArray<Integer>.Create(1, 2, 3, 4, 5);
  FStrArray := TArray<string>.Create('alpha', 'beta', 'gamma');
  FBoolArray := TArray<Boolean>.Create(True, False, True);
  FDoubleArray := TArray<Double>.Create(0.1, 0.2, 0.3, 0.4);
end;

end.


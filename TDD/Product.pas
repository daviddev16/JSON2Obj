unit Product;

interface

uses
  JSON2Obj,
  System.SysUtils;

type
  // Nested class for product dimensions
  TDimensions = class
  private
    FWidth: Double;
    FHeight: Double;
    FDepth: Double;
    FWeight: Double;
    FVolume: Double;
    FLength: Double;
  public
    property Width: Double read FWidth write FWidth;
    property Height: Double read FHeight write FHeight;
    property Depth: Double read FDepth write FDepth;
    property Weight: Double read FWeight write FWeight;
    property Volume: Double read FVolume write FVolume;
    property Length: Double read FLength write FLength;
  end;

  [MarshallOption( SerializeProperty )]
  [MarshallOption( SerializeEmptyAsNull )]
  TSupplier = class
  private
    FID: Integer;
    FName: string;
    FContactEmail: string;
    FPhone: string;
    FCity: string;
    FCountry: string;
    FIsActive: Boolean;
    FRating: Double;
  public
    property ID: Integer read FID write FID;
    property Name: string read FName write FName;
    property ContactEmail: string read FContactEmail write FContactEmail;
    property Phone: string read FPhone write FPhone;
    property City: string read FCity write FCity;
    property Country: string read FCountry write FCountry;
    property IsActive: Boolean read FIsActive write FIsActive;
    property Rating: Double read FRating write FRating;
  end;

  // Main Product class
  [ MarshallOption( SerializeProperty ) ]
  [ MarshallOption( SerializeEmptyAsNull ) ]
  TProduct = class
  private
    // Integer family
    FID: Integer;
    FCode: Int64;
    FSmallIntValue: SmallInt;
    FWordValue: Word;
    FCardinalValue: Cardinal;
    FShortIntValue: ShortInt;
    FUInt64Value: UInt64;

    // Floating point family
    FPrice: Double;
    FDiscount: Single;
    FExtendedValue: Extended;
    FFloatValue: Real;
    FCurrencyValue: Currency;

    // Boolean family
    FInStock: Boolean;
    FIsFeatured: Boolean;
    FIsDigital: Boolean;
    FIsReturnable: Boolean;

    // Char / string family
    FName: string;
    FDescription: string;
    FCategory: string;
    FCharCode: Char;
    FSKU: string;
    FBarcode: string;

    // Date/Time family
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
    FExpiresAt: TDateTime;
    FLastSoldAt: TDateTime;

    // Byte / raw types
    FByteValue: Byte;
    FByteFlag: Byte;
    FByteLevel: Byte;

    // Nested classes
    FDimensions: TDimensions;
    FSupplier: TSupplier;
  public
    constructor Create;
    destructor Destroy; override;

    // Integer family
    property ID: Integer read FID write FID;
    property Code: Int64 read FCode write FCode;
    property SmallIntValue: SmallInt read FSmallIntValue write FSmallIntValue;
    property WordValue: Word read FWordValue write FWordValue;
    property CardinalValue: Cardinal read FCardinalValue write FCardinalValue;
    property ShortIntValue: ShortInt read FShortIntValue write FShortIntValue;
    property UInt64Value: UInt64 read FUInt64Value write FUInt64Value;

    // Floating point family
    property Price: Double read FPrice write FPrice;
    property Discount: Single read FDiscount write FDiscount;
    property ExtendedValue: Extended read FExtendedValue write FExtendedValue;
    property FloatValue: Real read FFloatValue write FFloatValue;
    property CurrencyValue: Currency read FCurrencyValue write FCurrencyValue;

    // Boolean family
    property InStock: Boolean read FInStock write FInStock;
    property IsFeatured: Boolean read FIsFeatured write FIsFeatured;
    property IsDigital: Boolean read FIsDigital write FIsDigital;
    property IsReturnable: Boolean read FIsReturnable write FIsReturnable;

    // Char / string family
    property Name: string read FName write FName;
    property Description: string read FDescription write FDescription;
    property Category: string read FCategory write FCategory;
    property CharCode: Char read FCharCode write FCharCode;
    property SKU: string read FSKU write FSKU;
    property Barcode: string read FBarcode write FBarcode;

    // Date/Time family
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
    property ExpiresAt: TDateTime read FExpiresAt write FExpiresAt;
    property LastSoldAt: TDateTime read FLastSoldAt write FLastSoldAt;

    // Byte / raw types
    property ByteValue: Byte read FByteValue write FByteValue;
    property ByteFlag: Byte read FByteFlag write FByteFlag;
    property ByteLevel: Byte read FByteLevel write FByteLevel;

    // Nested classes
    property Dimensions: TDimensions read FDimensions write FDimensions;
    property Supplier: TSupplier read FSupplier write FSupplier;
  end;

implementation

{ TProduct }

constructor TProduct.Create;
begin
  inherited;
  FDimensions := TDimensions.Create();
  FSupplier := TSupplier.Create();
end;

destructor TProduct.Destroy;
begin
  FDimensions.Free();
  FSupplier.Free();
  inherited;
end;

end.

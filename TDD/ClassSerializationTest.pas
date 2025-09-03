unit ClassSerializationTest;

interface

uses
  JSON2Obj,
  MockUtils,
  IOUtils,
  System.SysUtils,
  System.Types,
  DUnitX.TestFramework;

type
  [TestFixture]
  TClassSerializationTest = class
  public
    [Test] procedure SimpleDeserializationTest();
    [Test] procedure BackAndForthSerializationTest();
    [Test] procedure SerializeEnumWithIntegerContractTest();
    [Test] procedure DeserializeEnumWithIntegerContractTest();
    [Test] procedure SerializeEnumWithStringContractTest();
    [Test] procedure DeserializeEnumWithStringContractTest();
    [Test] procedure SerializeWithEmptyAsNullTest();
    [Test] procedure SerializeWithEmptyAsEmptyTest();
    [Test] procedure SerializeWithPropertyTest();
    [Test] procedure SerializeWithFieldTest();
  end;

implementation

uses
  Product, Other;

{ TClassSerializationTest }

procedure TClassSerializationTest.SimpleDeserializationTest();
var
  LProduct: TProduct;
  LJSONContent: String;
begin
  LJSONContent := TMockUtils.ReadResource( 'MCK_001_Product' );
  LProduct := TJson2.JsonTextToObject<TProduct>( LJSONContent );
  try
    Assert.AreEqual(LProduct.Barcode, '1234567890123');
    Assert.AreEqual<Integer>(LProduct.ByteFlag, 1);
    Assert.AreEqual<Integer>(LProduct.ByteLevel, 5);
    Assert.AreEqual<Integer>(LProduct.ByteValue, 200);
    Assert.AreEqual<Cardinal>(LProduct.CardinalValue, 123456789);
    Assert.AreEqual(LProduct.Category, 'Electronics');
    Assert.AreEqual(LProduct.CharCode, 'A');
    Assert.AreEqual<Int64>(LProduct.Code, 9876543210);
    Assert.AreEqual(FormatDateTime('yyyy-mm-dd hh:nn:ss', LProduct.CreatedAt), '2025-08-17 19:36:10');
    Assert.AreEqual(LProduct.CurrencyValue, 49.95, 0.0001);
    Assert.AreEqual(LProduct.Description, 'High-performance gaming laptop with RGB keyboard.');
    Assert.AreEqual(LProduct.Discount, 0.150000005960464, 0.0000001);
    Assert.AreEqual(FormatDateTime('yyyy-mm-dd hh:nn:ss', LProduct.ExpiresAt), '2026-08-27 19:36:10');
    Assert.AreEqual(LProduct.ExtendedValue, 123456.789, 0.0001);
    Assert.AreEqual<Integer>(LProduct.ID, 1001);
    Assert.IsTrue(LProduct.InStock);
    Assert.IsFalse(LProduct.IsDigital);
    Assert.IsTrue(LProduct.IsFeatured);
    Assert.IsTrue(LProduct.IsReturnable);
    Assert.AreEqual(FormatDateTime('yyyy-mm-dd hh:nn:ss', LProduct.LastSoldAt), '2025-08-22 19:36:10');
    Assert.AreEqual(LProduct.FloatValue, 3.14159, 0.00001);
    Assert.AreEqual(LProduct.Name, 'Gaming Laptop');
    Assert.AreEqual(LProduct.Price, 249.99, 0.0001);
    Assert.AreEqual<ShortInt>(LProduct.ShortIntValue, 120);
    Assert.AreEqual(LProduct.SKU, 'LAP-2025-GAM');
    Assert.AreEqual<SmallInt>(LProduct.SmallIntValue, 12345);
    Assert.AreEqual<UInt64>(LProduct.UInt64Value, 9999999999);
    Assert.AreEqual(FormatDateTime('yyyy-mm-dd hh:nn:ss', LProduct.UpdatedAt), '2025-08-26 19:36:10');
    Assert.AreEqual<Word>(LProduct.WordValue, 54321);
    Assert.AreEqual(LProduct.Dimensions.Depth, 24.0, 0.0001);
    Assert.AreEqual(LProduct.Dimensions.Height, 2.5, 0.0001);
    Assert.AreEqual(LProduct.Dimensions.Length, 38.0, 0.0001);
    Assert.AreEqual(LProduct.Dimensions.Volume, 2130.5, 0.0001);
    Assert.AreEqual(LProduct.Dimensions.Weight, 2.2, 0.0001);
    Assert.AreEqual(LProduct.Dimensions.Width, 35.5, 0.0001);
    Assert.AreEqual(LProduct.Supplier.City, 'Rio de Janeiro');
    Assert.AreEqual(LProduct.Supplier.ContactEmail, 'support@techsupplies.com');
    Assert.AreEqual(LProduct.Supplier.Country, 'Brazil');
    Assert.AreEqual<Integer>(LProduct.Supplier.ID, 501);
    Assert.IsTrue(LProduct.Supplier.IsActive);
    Assert.AreEqual(LProduct.Supplier.Name, 'Tech Supplies Ltd.');
    Assert.AreEqual(LProduct.Supplier.Phone, '+55 21 99999-8888');
    Assert.AreEqual(LProduct.Supplier.Rating, 4.7, 0.0001);
  finally
    LProduct.Free;
  end;
end;

procedure TClassSerializationTest.BackAndForthSerializationTest();
var
  LProduct: TProduct;
  LJSONBaseContent: String;
  LJSONOut, LJSONIn: String;
begin
  LJSONBaseContent := TMockUtils.ReadResource( 'MCK_001_Product' );
  LProduct := TJson2.JsonTextToObject<TProduct>( LJSONBaseContent );
  try
    // Serialize
    LJSONOut := TJson2.ObjectToJsonText( LProduct );
  finally
    LProduct.Free();
  end;
  try
    // Deserialize
    LProduct := TJson2.JsonTextToObject<TProduct>( LJSONBaseContent );
    LJSONIn := TJson2.ObjectToJsonText( LProduct );
  finally
    LProduct.Free();
  end;
  Assert.AreEqual( LJSONOut, LJSONIn );
end;

procedure TClassSerializationTest.SerializeEnumWithIntegerContractTest();
var
  LObjWithEnum: TEnumRepresentation;
begin
  TJson2
    .Instance
    .Configure( [ SerializeField, SerializeEnumAsInteger ] );

  LObjWithEnum := TEnumRepresentation.Create();
  try
    LObjWithEnum.FStatus := osCreated;
    Assert.AreEqual( TJson2.ObjectToJsonText(LObjWithEnum),
                     '{"StatusObj":200}' );

    LObjWithEnum.FStatus := osLoaded;
    Assert.AreEqual( TJson2.ObjectToJsonText(LObjWithEnum),
                     '{"StatusObj":204}' );

    LObjWithEnum.FStatus := osUnload;
    Assert.AreEqual( TJson2.ObjectToJsonText(LObjWithEnum),
                     '{"StatusObj":214}' );

    LObjWithEnum.FStatus := osDestroyed;
    Assert.AreEqual( TJson2.ObjectToJsonText(LObjWithEnum),
                     '{"StatusObj":318}' );
  finally
    LObjWithEnum.Free();
  end;
end;

procedure TClassSerializationTest.DeserializeEnumWithIntegerContractTest();
var
  LObjWithEnum: TEnumRepresentation;
begin
  TJson2
    .Instance
    .Configure( [ SerializeField, SerializeEnumAsInteger ] );

  LObjWithEnum := TJson2.JsonTextToObject<TEnumRepresentation>('{"StatusObj":200}');
  Assert.AreEqual(LObjWithEnum.FStatus, osCreated);

  LObjWithEnum := TJson2.JsonTextToObject<TEnumRepresentation>('{"StatusObj":204}');
  Assert.AreEqual(LObjWithEnum.FStatus, osLoaded);

  LObjWithEnum := TJson2.JsonTextToObject<TEnumRepresentation>('{"StatusObj":214}');
  Assert.AreEqual(LObjWithEnum.FStatus, osUnload);

  LObjWithEnum := TJson2.JsonTextToObject<TEnumRepresentation>('{"StatusObj":318}');
  Assert.AreEqual(LObjWithEnum.FStatus, osDestroyed);
end;

procedure TClassSerializationTest.SerializeEnumWithStringContractTest();
var
  LObjWithEnum: TEnumRepresentation;
begin
  TJson2
    .Instance
    .Configure( [ SerializeField, SerializeEnumAsString ] );

  LObjWithEnum := TEnumRepresentation.Create();
  try
    LObjWithEnum.FStatus := osCreated;
    Assert.AreEqual( TJson2.ObjectToJsonText(LObjWithEnum),
                     '{"StatusObj":"CREATED"}' );

    LObjWithEnum.FStatus := osLoaded;
    Assert.AreEqual( TJson2.ObjectToJsonText(LObjWithEnum),
                     '{"StatusObj":"LOADED"}' );

    LObjWithEnum.FStatus := osUnload;
    Assert.AreEqual( TJson2.ObjectToJsonText(LObjWithEnum),
                     '{"StatusObj":"UNLOADED"}' );

    LObjWithEnum.FStatus := osDestroyed;
    Assert.AreEqual( TJson2.ObjectToJsonText(LObjWithEnum),
                     '{"StatusObj":"DESTROYED"}' );
  finally
    LObjWithEnum.Free();
  end;
end;

procedure TClassSerializationTest.SerializeWithEmptyAsEmptyTest();
var
  LWithStrObj: TWithStrObj;
begin
  TJson2
    .Instance
    .Configure( [ SerializeField ] );

  LWithStrObj := TWithStrObj.Create();
  try
    Assert.AreEqual(TJson2.ObjectToJsonText( LWithStrObj ), '{"logText":""}');
  finally
    LWithStrObj.Free();
  end;
end;

procedure TClassSerializationTest.SerializeWithEmptyAsNullTest();
var
  LWithStrObj: TWithStrObj;
begin
  TJson2
    .Instance
    .Configure( [ SerializeField, SerializeEmptyAsNull ] );

  LWithStrObj := TWithStrObj.Create();
  try
    Assert.AreEqual(TJson2.ObjectToJsonText( LWithStrObj ), '{"logText":null}');
  finally
    LWithStrObj.Free();
  end;
end;

procedure TClassSerializationTest.SerializeWithFieldTest();
var
  LObjWithField: TObjWithField;
begin
  LObjWithField := TObjWithField.Create();
  LObjWithField.FPrivateField := 'PropField1234';
  try
    Assert.AreEqual(TJson2.ObjectToJsonText( LObjWithField ), '{"FieldKey":"PropField1234"}');
  finally
    LObjWithField.Free();
  end;
end;

procedure TClassSerializationTest.SerializeWithPropertyTest();
var
  LObjWithProp: TObjWithProp;
begin
  LObjWithProp := TObjWithProp.Create();
  LObjWithProp.PropField := 'PropField1234';
  try
    Assert.AreEqual(TJson2.ObjectToJsonText( LObjWithProp ), '{"PropertyFieldKey":"PropField1234"}');
  finally
    LObjWithProp.Free();
  end;
end;

procedure TClassSerializationTest.DeserializeEnumWithStringContractTest();
var
  LObjWithEnum: TEnumRepresentation;
begin
  TJson2
    .Instance
    .Configure( [ SerializeField, SerializeEnumAsInteger ] );

  LObjWithEnum := TJson2.JsonTextToObject<TEnumRepresentation>('{"StatusObj":"CREATED"}');
  Assert.AreEqual(LObjWithEnum.FStatus, osCreated);

  LObjWithEnum := TJson2.JsonTextToObject<TEnumRepresentation>('{"StatusObj":"LOADED"}');
  Assert.AreEqual(LObjWithEnum.FStatus, osLoaded);

  LObjWithEnum := TJson2.JsonTextToObject<TEnumRepresentation>('{"StatusObj":"UNLOADED"}');
  Assert.AreEqual(LObjWithEnum.FStatus, osUnload);

  LObjWithEnum := TJson2.JsonTextToObject<TEnumRepresentation>('{"StatusObj":"DESTROYED"}');
  Assert.AreEqual(LObjWithEnum.FStatus, osDestroyed);
end;

initialization
  TDUnitX.RegisterTestFixture(TClassSerializationTest);

end.

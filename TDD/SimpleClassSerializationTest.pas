unit SimpleClassSerializationTest;

interface

uses
  JSON2Obj,
  IOUtils,
  System.SysUtils,
  AllSerializablePrimitives,
  DUnitX.TestFramework;

type
  [TestFixture]
  TSimpleClassSerializationTest = class
    public
      [Test] procedure SerializeTest;
      [Test] procedure DeserializeTest;
    end;

implementation

{ TSimpleClassSerializationTest }

procedure TSimpleClassSerializationTest.DeserializeTest;
begin

end;

procedure TSimpleClassSerializationTest.SerializeTest();
var
  LAllPrimitivesObj: TAllPrimitives;
begin
  LAllPrimitivesObj := TAllPrimitives.Create();

  TFile.WriteAllText(
  'C:\Users\David\delphi-workspace\Json2Obj\TDD\Mock\MCK_002_Primitives.json',
  TJson2.ObjectToJsonText( LAllPrimitivesObj ),
  TEncoding.UTF8 );
end;

initialization
  TDUnitX.RegisterTestFixture(TSimpleClassSerializationTest);

end.

## Serialização e Deserialização

```pascal
uses JSON2Obj;
```
```pascal
class function TJson2.JsonArrayToList<T>(AJSONArray: TJSONArray): TList<T>;
class function TJson2.JsonTextToObject<T>(AJSONText: String): T;
class function TJson2.ObjectToJsonText<T>(AObj: T): String; overload;
class function TJson2.ObjectToJsonText(AObj: TObject): String; overload;
class function TJson2.JsonToObject<T>(AJSONObject: TJSONObject): T;
class function TJson2.ObjectToJson<T>(AObj: T): TJSONObject;
```

## Configuração por Tipo
```pascal
  [MarshallOption( SerializeProperty )]
  [MarshallOption( SerializeEmptyAsNull )]
  TSupplier = class
  private
    FID: Integer;
    FName: string;
    FContactEmail: string;
  public
    property ID: Integer read FID write FID;
    property Name: string read FName write FName;
    property ContactEmail: string read FContactEmail write FContactEmail;
  end;
```

## Configuração Global

As configurações globais aplicação o estilo de serialização para todos os objetos que não estão marcados por [MarshallOption].  

```pascal
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
```

## Serialização de Enum

Atualmente JSON2Obj suporta 2 tipos de serialização de enum, String e Integer, podendo usar os 2 tipos em tipo de enum.

### Inteiro
```pascal
  [IntegerEnumRule( TypeInfo(TObjectStatus), Ord(osCreated),   200 )]
  [IntegerEnumRule( TypeInfo(TObjectStatus), Ord(osLoaded),    204 )]
  [IntegerEnumRule( TypeInfo(TObjectStatus), Ord(osUnload),    214 )]
  [IntegerEnumRule( TypeInfo(TObjectStatus), Ord(osDestroyed), 318 )]
  TEnumRepresentation = class
    public
      [Key('StatusObj')] FStatus: TObjectStatus;
    end;
```
#### Resultado ( Utilizando SerializeEnumAsInteger ) 
```json

{"StatusObj":200}
```

### String
```pascal
  [StringEnumRule( TypeInfo(TObjectStatus), Ord(osCreated),   'CREATED' )]
  [StringEnumRule( TypeInfo(TObjectStatus), Ord(osLoaded),    'LOADED' )]
  [StringEnumRule( TypeInfo(TObjectStatus), Ord(osUnload),    'UNLOADED' )]
  [StringEnumRule( TypeInfo(TObjectStatus), Ord(osDestroyed), 'DESTROYED' )]
  TEnumRepresentation = class
    public
      [Key('StatusObj')] FStatus: TObjectStatus;
    end;
```
#### Resultado ( Utilizando SerializeEnumAsString )
```json

{"StatusObj":"CREATED"}
```





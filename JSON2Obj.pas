unit JSON2Obj;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.TypInfo,
  System.JSON,
  System.Rtti,
  System.DateUtils,
  System.SyncObjs,
  System.Variants,
  System.Generics.Collections;

type

  TMarshallOptionKind = ( SerializeProperty      = 0,
                          SerializeField         = 1,
                          SerializeSetterGetter  = 2,
                          SerializeEmptyAsNull   = 3,
                          SerializeEnumAsInteger = 4,
                          SerializeEnumAsString  = 5 );

  TMarshallOptionKindArray = TArray<TMarshallOptionKind>;

  //
  // Representa as configurações de TMarshallOptionKind no escopo
  // de tipo e global.
  //
  TMarshallFlags = class( TBits )
    private
      procedure ToState(AKind: TMarshallOptionKind; AState: Boolean);
    public
      procedure Setup(AKinds: TMarshallOptionKindArray);
      procedure Up(AKind: TMarshallOptionKind);
      procedure Down(AKind: TMarshallOptionKind);
      function HasKind(AKind: TMarshallOptionKind): Boolean;
      procedure ResetAllBits();
    public
      constructor Create();
    end;

  //
  // Cria objetos TMarshallFlags conforme o objeto RTTI. Atualmente só
  // possui suporte para adquirir informações de atributos em TRttiType.
  //
  TMarshallFlagsFactory = class sealed
    public
      class function FromRttiObject(ARttiObject: TRttiObject): TMarshallFlags;
    end;

  TOwnedObjectDictionary<K; V> = class( TObjectDictionary<K,V> )
    public
      constructor Create();
    end;

  TTypeInfoIndexer<T: class> = class( TOwnedObjectDictionary<PTypeInfo, T> );

{$Region 'Attributes'}

  KeyAttribute = class( TCustomAttribute )
    private
      FName: String;
    public
      constructor Create(AName: String);
    public
      property Name: String read FName;
    end;

  TTypeInfoRequiredAttribute = class( TCustomAttribute )
    private
      Handle: PTypeInfo;
    end;

  TCustomEnumContractRuleAttribute<V> = class( TTypeInfoRequiredAttribute )
    strict private
      FOrdinal: Int64;
      FValue: V;
    public
      constructor Create(AEnumTypeInfo: PTypeInfo;
                         AOrdinal: Int64;
                         AValue: V);
    public
      property EnumTypeInfo: PTypeInfo read Handle;
      property Ordinal:      Int64     read FOrdinal;
      property Value:        V         read FValue;
    end;

  StringEnumRuleAttribute = class( TCustomEnumContractRuleAttribute<String> );
  IntegerEnumRuleAttribute = class( TCustomEnumContractRuleAttribute<Integer> );

  MarshallOptionAttribute = class ( TCustomAttribute )
    strict private
      FKind: TMarshallOptionKind;
    public
      constructor Create(AKind: TMarshallOptionKind);
    public
      property Kind: TMarshallOptionKind read FKind;
    end;

{$EndRegion 'Attributes'}

{$Region 'Rtti Accessors'}

  //
  // A classe que implementar um IRttiAccessor deve fornecer a habilidade
  // de injetar e recuperar valores de algum objeto RTTI.
  //
  IRttiAccessor = interface
    function Get(const [ref] AObj: TObject): TValue;
    procedure Fill(const [ref] AObj: TObject; AValue: TValue);
  end;

  TRttiPropertyAccessor = class( TInterfacedObject, IRttiAccessor )
    strict private
      FRttiProperty: TRttiProperty;
    public
      function Get(const [ref] AObj: TObject): TValue;
      procedure Fill(const [ref] AObj: TObject; AValue: TValue);
    protected
      constructor Create(ARttiProperty: TRttiProperty);
    end;

  TRttiFieldAccessor = class( TInterfacedObject, IRttiAccessor )
    strict private
      FRttiField: TRttiField;
    public
      function Get(const [ref] AObj: TObject): TValue;
      procedure Fill(const [ref] AObj: TObject; AValue: TValue);
    protected
      constructor Create(ARttiField: TRttiField);
    end;

  { TODO }
  TRttiGetterSetterAccessor = class( TInterfacedObject, IRttiAccessor )
    private
      FSetterRttiMethod: TRttiMethod;
      FGetterRttiMethod: TRttiMethod;
    public
      function Get(const [ref] AObj: TObject): TValue; virtual; abstract;
      procedure Fill(const [ref] AObj: TObject; AValue: TValue); virtual; abstract;
  end;

{$EndRegion 'Rtti Accessors'}

  TRttiTypeHandler = class;

  TRttiBucket = class sealed
    strict private
      FInnerRttiType: TRttiType;
      FOuterRttiType: TRttiType;
      FIsArray: Boolean;
      FIsEnum: Boolean;
      FRttiAccessor: IRttiAccessor;
    protected
      FParent: TRttiTypeHandler;
    private
      property IsArray:       Boolean       read FIsArray;
      property IsEnum:        Boolean       read FIsEnum;
      property RttiAccessor:  IRttiAccessor read FRttiAccessor;
      property InnerRttiType: TRttiType     read FInnerRttiType;
      property OuterRttiType: TRttiType     read FOuterRttiType;
    protected
      constructor Create(AInnerRttiType: TRttiType;
                         AOuterRttiType: TRttiType;
                         ARttiAccessor: IRttiAccessor;
                         AIsArray: Boolean; AIsEnum: Boolean);
    end;

  TRttiBucketDictionary = TOwnedObjectDictionary<String, TArray<TRttiBucket>>;

  IMarshallFlagsConfigurer = interface
    procedure Configure(AKinds: TMarshallOptionKindArray); overload;
  end;

  TRttiTypeHandler = class sealed
    strict private
      FRttiType: TRttiType;
      FBucketMap: TRttiBucketDictionary;
      FConstructorMethod: TRttiMethod;
      FMarshallFlags: TMarshallFlags;
    protected
      property MarshallFlags: TMarshallFlags read FMarshallFlags;
    private
      function ExtractConstructor(ARttiType: TRttiType): TRttiMethod;
      function CreateNewObject(): TObject;
    private
      function ContainsBucket(ABucketName: String): Boolean;
      procedure AddRttiBucket(ABucketName: String; ARttiBucket: TRttiBucket);
    public
      procedure Configure(AKinds: TMarshallOptionKind);
    private
      property RttiBuckets: TRttiBucketDictionary read FBucketMap;
    public
      constructor Create(ARttiType: TRttiType);
      destructor Destroy(); override;
    end;

  TContractTypeMapper<T> = class
    private
      FValueToOrdinalMap: TDictionary<T, Int64>;
      FOrdinalToValueMap: TDictionary<Int64, T>;
    private
      function TryResolveOrdinal(AValue: T; out AOrdinal: Int64): Boolean;
      function TryResolveValue(AOrdinal: Int64; out AValue: T): Boolean;
      procedure AddEnumContract(AValue: T; AOrdinal: Int64);
    public
      constructor Create();
      destructor Destroy(); override;
    end;

  TStringMapper = TContractTypeMapper<String>;
  TIntegerMapper = TContractTypeMapper<Integer>;

  TEnumTypeContract = class sealed
    strict private
      FStringMapper: TStringMapper;
      FIntegerMapper: TIntegerMapper;
    private
      function GetStringMapper(): TStringMapper;
      function GetIntegerMapper(): TIntegerMapper;
    public
      property StringMapper: TStringMapper read GetStringMapper;
      property IntegerMapper: TIntegerMapper read GetIntegerMapper;
    public
      constructor Create();
      destructor Destroy(); override;
    end;

  TJson2 = class( TInterfacedObject, IMarshallFlagsConfigurer )
    strict private
      FRWSync: IReadWriteSync;
      FRttiContext: TRttiContext;
      FGlobalMarhsallFlags: TMarshallFlags;
      FRttiTypeHandlerMap: TTypeInfoIndexer<TRttiTypeHandler>;
      FEnumTypeContractMap: TTypeInfoIndexer<TEnumTypeContract>;
      FDefaultOptions: TArray<TMarshallOptionKind>;
    protected
      property GlobalMarhsallFlags: TMarshallFlags read FGlobalMarhsallFlags;
    private
      class var FSingleton: TJson2;
    private
      class procedure FreeAssigned(const [ref] AObj: TObject);
      class procedure FreeArray<T: class>(var Arr: TArray<T>);
    public
      class constructor Create();
      class destructor Destroy();
    public
      class function JsonArrayToList<T: class>(AJSONArray: TJSONArray): TList<T>;
      class function JsonTextToObject<T: class>(AJSONText: String): T;
      class function ObjectToJsonText<T: class>(AObj: T): String; overload;
      class function ObjectToJsonText(AObj: TObject): String; overload;
      class function JsonToObject<T: class>(AJSONObject: TJSONObject): T;
      class function ObjectToJson<T: class>(AObj: T): TJSONObject;
      class procedure SetDefaultKinds(AKinds: TArray<TMarshallOptionKind>);
    private
      function StringToDateTime(AText: String): TDateTime;
      function DateTimeToString(ADateTime: TDateTime): String;
      function NewJSONNull(): TJSONValue;
    private
      function EnumToJSONValue(const [ref] AValue: TValue;
                               AMarshallFlags: TMarshallFlags): TJSONValue;
      function ArrayToJSONValue(const [ref] AValue: TValue;
                                ARttiTypeHandler: TRttiTypeHandler): TJSONValue;
      function ToJSONValue(const [ref] AValue: TValue;
                           ARttiTypeHandler: TRttiTypeHandler): TJSONValue;
    private
      function ToEnumOrdValue(ATypeInfo: PTypeInfo;
                              AJSONValue: TJSONValue): TValue;
      function ToRTTIValue(ARttiBucket: TRttiBucket;
                           AJSONValue: TJSONValue): TValue;
      function JSONStringToRTTIValue(AJSONString: TJSONString;
                                     ATypeInfo: PTypeInfo): TValue;
      function JSONNumberToRTTIValue(AJSONNumber: TJSONNumber;
                                     ATypeInfo: PTypeInfo): TValue;
      function JSONObjectToRTTIValue(AJSONObject: TJSONObject;
                                     ATypeInfo: PTypeInfo): TValue;
      function JSONArrayToRTTIValue(AJSONArray: TJSONArray;
                                    ARttiBucket: TRttiBucket): TValue;
    private
      function GetRttiTypeOfMember(ARttiMember: TRttiMember): TRttiType;
      procedure RegisterEnumTypeContract(ARttiType: TRttiType);
      procedure RegisterRttiBucket(ARttiTypeHandler: TRttiTypeHandler;
                                   ARttiDataMember: TRttiMember);
      function CanHandleBucket(ABucketName: String): Boolean;
      function AsRttiType(ATypeInfo: PTypeInfo): TRttiType;
      function GetEnumTypeContract(ATypInfo: PTypeInfo): TEnumTypeContract;
      function GetRttiTypeHandler(ATypInfo: PTypeInfo): TRttiTypeHandler;
      function GetOptions(ARttiType: TRttiType): TArray<TMarshallOptionKind>;
      function ExtractJSOName(ARttiDataMember: TRttiMember): String;
      procedure ExtractRttiProperties(ARttiType: TRttiType;
                                      ARttiTypeHandler: TRttiTypeHandler);
      procedure ExtractRttiFields(ARttiType: TRttiType;
                                  ARttiTypeHandler: TRttiTypeHandler);
    public
      procedure Configure(AKinds: TMarshallOptionKindArray); overload;
    public
      function SerializeObject(AObject: TObject): TJSONValue;
      function Serialize<T: class>(AObject: T): TJSONObject;
      function DeserializeObject(AJSONObject: TJSONObject;
                                 ATypeInfo: PTypeInfo): TObject;
      function Deserialize<T: class>(AJSONObject: TJSONObject): T;
    public
      class property Instance: TJson2 read FSingleton;
    public
      constructor Create();
      destructor Destroy(); override;
    end;

implementation

{$Region 'TOwnedObjectDictionary<K,V>'}

constructor TOwnedObjectDictionary<K,V>.Create();
begin
  if PTypeInfo( TypeInfo( V ) ).Kind = tkClass then
    inherited Create( [ doOwnsValues ] )
  else
    inherited Create();
end;

{$EndRegion 'TOwnedObjectDictionary<K,V>'}

{$Region 'Attributes'}

constructor TCustomEnumContractRuleAttribute<V>.Create(AEnumTypeInfo: PTypeInfo;
                                                       AOrdinal: Int64;
                                                       AValue: V);
begin
  Handle   := AEnumTypeInfo;
  FOrdinal := AOrdinal;
  FValue   := AValue;
end;

constructor MarshallOptionAttribute.Create(AKind: TMarshallOptionKind);
begin
  FKind := AKind;
end;

constructor KeyAttribute.Create(AName: String);
begin
  FName := AName;
end;

{$EndRegion 'Attributes'}

{$Region 'TJson2'}

constructor TJson2.Create();
begin
  TRttiContext.KeepContext();
  FRttiContext := TRttiContext.Create();
  FRWSync := TMultiReadExclusiveWriteSynchronizer.Create();
  FRttiTypeHandlerMap := TTypeInfoIndexer<TRttiTypeHandler>.Create();
  FEnumTypeContractMap := TTypeInfoIndexer<TEnumTypeContract>.Create();
  FGlobalMarhsallFlags := TMarshallFlags.Create();
  FGlobalMarhsallFlags.Up( SerializeProperty );
  FGlobalMarhsallFlags.Up( SerializeEmptyAsNull );
  FGlobalMarhsallFlags.Up( SerializeEnumAsString );
end;

function TJson2.DeserializeObject(AJSONObject: TJSONObject;
                                  ATypeInfo: PTypeInfo): TObject;
var
  LInstance: TObject;
  LRttiTypeHandler: TRttiTypeHandler;
var
  LJSONValue: TJSONValue;
  LRttiBuckets: TArray<TRttiBucket>;
  LBucketName: String;
begin
  LInstance := nil;

  LRttiTypeHandler := GetRttiTypeHandler( ATypeInfo );
  LInstance := LRttiTypeHandler.CreateNewObject();
  
  for var LRttiBucketEntry in LRttiTypeHandler.RttiBuckets do
  begin
    LBucketName := LRttiBucketEntry.Key;
    LJSONValue := AJSONObject.GetValue( LBucketName );

    if not Assigned( LJSONValue ) then
      Continue;

    LRttiBuckets := LRttiBucketEntry.Value;

    for var LRttiBucket in LRttiBuckets do
    begin
      try
        LRttiBucket.RttiAccessor.Fill( LInstance, ToRTTIValue( LRttiBucket,
                                                               LJSONValue ) );
      except
        on Ex: EInvalidCast do
          raise Exception.CreateFmt('Bucket "%s" expected type "%s" but found "%s". ',
                                    [ LBucketName,
                                      LRttiBucket.OuterRttiType.Name,
                                      LJSONValue.ClassName ] );
      end;
    end;
  end;

  Result := LInstance;
end;

function TJson2.Deserialize<T>(AJSONObject: TJSONObject): T;
begin
  Result := ( DeserializeObject( AJSONObject, TypeInfo( T ) ) as T );
end;

function TJson2.SerializeObject(AObject: TObject): TJSONValue;
var
  LRttiTypeHandler: TRttiTypeHandler;
  LJSONObject: TJSONObject;
var
  LRttiBuckets: TArray<TRttiBucket>;
  LBucketName: String;
  LValue: TValue;
begin
  if not Assigned( AObject ) then
    Exit( TJSONNull.Create() );

  LRttiTypeHandler := GetRttiTypeHandler( AObject.ClassInfo );
  LJSONObject := TJSONObject.Create();

  for var LRttiBucketEntry in LRttiTypeHandler.RttiBuckets do
  begin
    LBucketName := LRttiBucketEntry.Key;
    LRttiBuckets := LRttiBucketEntry.Value;

    for var LRttiBucket in LRttiBuckets do
    begin
      LValue := LRttiBucket.RttiAccessor.Get( AObject );
      LJSONObject.AddPair( LBucketName, ToJSONValue( LValue,
                                                     LRttiTypeHandler ) );
    end;    
  end;

  Result := LJSONObject;
end;

function TJson2.Serialize<T>(AObject: T): TJSONObject;
begin
  Result := ( SerializeObject( AObject ) as TJSONObject );
end;

procedure TJson2.RegisterEnumTypeContract(ARttiType: TRttiType);
var
  LEnumTypeInfo: PTypeInfo;
  LContract: TEnumTypeContract;
var
  LStringEnumRuleAttr: StringEnumRuleAttribute;
  LIntegerEnumRuleAttr: IntegerEnumRuleAttribute;
begin
  for var LAttribute in ARttiType.GetAttributes() do
  begin
    if not LAttribute.InheritsFrom( TTypeInfoRequiredAttribute ) then
      Continue;

    LEnumTypeInfo := TTypeInfoRequiredAttribute( LAttribute ).Handle;
    LContract := GetEnumTypeContract( LEnumTypeInfo );

    if LAttribute is StringEnumRuleAttribute then
    begin
      LStringEnumRuleAttr := StringEnumRuleAttribute( LAttribute );

      LContract
          .StringMapper
          .AddEnumContract( LStringEnumRuleAttr.Value,
                            LStringEnumRuleAttr.Ordinal );
    end

    else if LAttribute is IntegerEnumRuleAttribute then
    begin
      LIntegerEnumRuleAttr := IntegerEnumRuleAttribute( LAttribute );

      LContract
          .IntegerMapper
          .AddEnumContract( LIntegerEnumRuleAttr.Value,
                            LIntegerEnumRuleAttr.Ordinal );
    end;
  end;
end;

function TJson2.ToRTTIValue(ARttiBucket: TRttiBucket;
                            AJSONValue: TJSONValue): TValue;
var
  AInnerTypeInfo: PTypeInfo;
begin
  if AJSONValue is TJSONNull then
    Exit( TValue.Empty );

  AInnerTypeInfo := ARttiBucket.InnerRttiType.Handle;

  if ( ARttiBucket.IsEnum ) and
     ( not ARttiBucket.InnerRttiType.HasName('Boolean') ) then
  begin
    Exit( ToEnumOrdValue( AInnerTypeInfo, AJSONValue  ) );
  end;

  if AJSONValue is TJSONNumber then
    Exit( JSONNumberToRTTIValue( ( AJSONValue as TJSONNumber ),
                                 AInnerTypeInfo ) );

  if AJSONValue is TJSONBool then
    Exit( TValue.From<Boolean>( (AJSONValue as TJSONBool).AsBoolean ) );

  if AJSONValue is TJSONString then
    Exit( JSONStringToRTTIValue( ( AJSONValue as TJSONString ),
                                 AInnerTypeInfo ) );

  if AJSONValue is TJSONObject then
    Exit( JSONObjectToRTTIValue( ( AJSONValue as TJSONObject ),
                                 AInnerTypeInfo ) );

  if AJSONValue is TJSONArray then
    Exit( JSONArrayToRTTIValue( ( AJSONValue as TJSONArray ),
                                ARttiBucket ) );

  raise Exception.CreateFmt( 'Could found a type for value "%s".',
                             [AJSONValue.Value] );
end;

function TJson2.JSONStringToRTTIValue(AJSONString: TJSONString;
                                      ATypeInfo: PTypeInfo): TValue;
begin
  if ATypeInfo.Name = 'TDateTime' then
    Exit( TValue.From<TDateTime>( StringToDateTime( AJSONString.Value ) ) )

  else if ATypeInfo.Name = 'TDate' then
    Exit( TValue.From<TDate>( Trunc( StringToDateTime( AJSONString.Value ) ) ) );

  Result := TValue.From<String>( AJSONString.Value );
end;

function TJson2.JSONArrayToRTTIValue(AJSONArray: TJSONArray;
                                     ARttiBucket: TRttiBucket): TValue;
var
  LArray: Array Of TValue;
  LCount: Integer;
begin
  LCount := AJSONArray.Count;

  SetLength( LArray, LCount );
  Dec( LCount, 1 );

  for var I := 0 to LCount do
    LArray[I] := ToRTTIValue( ARttiBucket, AJSONArray.Items[I] );

  Result := TValue.FromArray( ARttiBucket.OuterRttiType.Handle,
                              LArray );
end;

function TJson2.JSONObjectToRTTIValue(AJSONObject: TJSONObject;
                                      ATypeInfo: PTypeInfo): TValue;
begin
  Result := TValue.From<TObject>( DeserializeObject( AJSONObject, ATypeInfo ) );
end;

function TJson2.JSONNumberToRTTIValue(AJSONNumber: TJSONNumber;
                                      ATypeInfo: PTypeInfo): TValue;
begin
  Result := TValue.Empty;

  case ATypeInfo.Kind of
    tkInteger, tkInt64:
      Exit( AJSONNumber.AsInt64 );

    tkFloat:
      Exit(  AJSONNumber.AsDouble );
  end;
end;

function TJson2.ToEnumOrdValue(ATypeInfo: PTypeInfo;
                               AJSONValue: TJSONValue): TValue;
var
  LOrdinal: Int64;
var
  LJSONString: TJSONString;
  LJSONNumber: TJSONNumber;
begin
  with GetEnumTypeContract( ATypeInfo ) do
  begin
    if AJSONValue is TJSONNumber then
    begin
      LJSONNumber := TJSONNumber( AJSONValue );

      if IntegerMapper.TryResolveOrdinal( LJSONNumber.AsInt, LOrdinal ) then
        Exit ( TValue.FromOrdinal( ATypeInfo, LOrdinal ) );
    end

    else if AJSONValue is TJSONString then
    begin
      LJSONString := TJSONString( AJSONValue );

      if StringMapper.TryResolveOrdinal( LJSONString.Value, LOrdinal ) then
        Exit ( TValue.FromOrdinal( ATypeInfo, LOrdinal ) )
    end
  end;

  raise Exception.CreateFmt('"%s" is not a valid value for "%s".',
                            [ AJSONValue.Value, ATypeInfo^.Name ]);
end;

function TJson2.ToJSONValue(const [ref] AValue: TValue;
                            ARttiTypeHandler: TRttiTypeHandler): TJSONValue;
var
  LMarshallFlags: TMarshallFlags;
begin
  if AValue.IsEmpty then
    Exit( NewJSONNull() );

  LMarshallFlags := ARttiTypeHandler.MarshallFlags;

  case AValue.Kind of
    tkInteger, tkInt64:
      Exit( TJSONNumber.Create( AValue.AsInt64() ) );

    tkFloat:
      if AValue.TypeInfo = TypeInfo( TDateTime ) then
      begin
        var LContentDateTime := TDateTime( AValue.AsExtended() );

        if ( LContentDateTime <= 0 ) then
          Exit( TJSONNull.Create() );

        Exit( TJSONString.Create( DateTimeToString( LContentDateTime ) ) )
      end
      else if AValue.TypeInfo = TypeInfo( TDate ) then
      begin
        var LContentDate := TDate( Trunc( AValue.AsExtended() ) );

        if ( LContentDate <= 0 ) then
          Exit( TJSONNull.Create() );

        Exit( TJSONString.Create( DateTimeToString( LContentDate ) ) )
      end
      else
        Exit( TJSONNumber.Create( AValue.AsExtended() ) );

    tkChar, tkString, tkUString, tkWChar, tkLString, tkWString:
    begin
      var LContentStr := AValue.AsString();

      if ( Trim(LContentStr) = EmptyStr ) and
         ( LMarshallFlags.HasKind( SerializeEmptyAsNull ) ) then
      begin
        Exit( TJSONNull.Create() );
      end;

      Exit( TJSONString.Create( AValue.AsString() ) );
    end;

    tkEnumeration:
      Exit( EnumToJSONValue( AValue, LMarshallFlags ) );

    tkDynArray:
      Exit( ArrayToJSONValue( AValue, ARttiTypeHandler ) );

    tkClass:
      Exit( SerializeObject( AValue.AsObject() ) );

    else
      Result := TJSONString.Create( AValue.ToString() );
  end;
end;

function TJson2.ArrayToJSONValue(const [ref] AValue: TValue;
                                 ARttiTypeHandler: TRttiTypeHandler): TJSONValue;
var
  LCount: Integer;
  LElement: TValue;
  LJSONArray: TJSONArray;
begin
  LJSONArray := TJSONArray.Create();
  try
    LCount := AValue.GetArrayLength - 1;
    for var I := 0 to LCount do
    begin
      LElement := AValue.GetArrayElement( I );
      LJSONArray.AddElement( ToJSONValue( LElement, ARttiTypeHandler ) );
    end;
    Result := LJSONArray;
  except
    LJSONArray.Free();
    raise;
  end;
end;

function TJson2.EnumToJSONValue(const [ref] AValue: TValue;
                                AMarshallFlags: TMarshallFlags): TJSONValue;
var
  LOrdinal: Int64;
var
  LEnumString: String;
  LEnumInteger: Integer;
begin
  if AValue.TypeInfo = TypeInfo( Boolean ) then
    Exit( TJSONBool.Create( AValue.AsBoolean() ) );

  if not AValue.IsOrdinal then
    Exit( TJSONString.Create( AValue.ToString() ) );

  LOrdinal := AValue.AsOrdinal();

  with GetEnumTypeContract( AValue.TypeInfo ) do
  begin
    if AMarshallFlags.HasKind( SerializeEnumAsString ) then
    begin
      if StringMapper.TryResolveValue( LOrdinal, LEnumString ) then
        Exit( TJSONString.Create( LEnumString ) )
      else
        Exit( TJSONString.Create( AValue.ToString() ) );
    end
    else if AMarshallFlags.HasKind( SerializeEnumAsInteger ) then
    begin
      if IntegerMapper.TryResolveValue( LOrdinal, LEnumInteger ) then
        Exit( TJSONNumber.Create( LEnumInteger ) )
      else
        Exit( TJSONNumber.Create( LOrdinal ) );
    end;
  end;

  Result := NewJSONNull();
end;

function TJson2.GetRttiTypeHandler(ATypInfo: PTypeInfo): TRttiTypeHandler;
var
  LTypeRttiHandler: TRttiTypeHandler;
  LRttiType: TRttiType;
begin
  LTypeRttiHandler := nil;

  FRWSync.BeginRead();
  try
    FRttiTypeHandlerMap.TryGetValue( ATypInfo,
                                     LTypeRttiHandler );
  finally
    FRWSync.EndRead();
  end;

  if Assigned( LTypeRttiHandler ) then
    Exit( LTypeRttiHandler );

  LRttiType := AsRttiType( ATypInfo );

  LTypeRttiHandler := TRttiTypeHandler.Create( LRttiType );

  FRWSync.BeginWrite();
  try
    try
      if LTypeRttiHandler.MarshallFlags.HasKind( SerializeProperty ) then
        ExtractRttiProperties( LRttiType, LTypeRttiHandler )

      else if LTypeRttiHandler.MarshallFlags.HasKind( SerializeField ) then
        ExtractRttiFields( LRttiType, LTypeRttiHandler );

      RegisterEnumTypeContract( LRttiType );
    except
      LTypeRttiHandler.Free();
      raise;
    end;
    FRttiTypeHandlerMap.Add( ATypInfo, LTypeRttiHandler );
  finally
    FRWSync.EndWrite();
  end;

  Result := LTypeRttiHandler;
end;

function TJson2.GetEnumTypeContract(ATypInfo: PTypeInfo): TEnumTypeContract;
var
  LEnumTypeContract: TEnumTypeContract;
begin
  if FEnumTypeContractMap.TryGetValue( ATypInfo,
                                       LEnumTypeContract ) then
    Exit( LEnumTypeContract );

  LEnumTypeContract := TEnumTypeContract.Create();
  FEnumTypeContractMap.Add( ATypInfo, LEnumTypeContract );

  Result := LEnumTypeContract;
end;

procedure TJson2.ExtractRttiProperties(ARttiType: TRttiType;
                                       ARttiTypeHandler: TRttiTypeHandler);
begin
  for var LRttiProperty in ARttiType.GetProperties() do
    RegisterRttiBucket( ARttiTypeHandler, LRttiProperty );
end;

procedure TJson2.ExtractRttiFields(ARttiType: TRttiType;
                                   ARttiTypeHandler: TRttiTypeHandler);
begin
  for var LRttiProperty in ARttiType.GetFields() do
    RegisterRttiBucket( ARttiTypeHandler, LRttiProperty );
end;

procedure TJson2.RegisterRttiBucket(ARttiTypeHandler: TRttiTypeHandler;
                                    ARttiDataMember: TRttiMember);
var
  LDataType: TRttiType;
  LIsArray, LIsEnum: Boolean;
  LInnerRttiType: TRttiType;
  LRttiBucket: TRttiBucket;
  LBucketName: String;
  LRttiAccessor: IRttiAccessor;
begin
  LDataType := GetRttiTypeOfMember( ARttiDataMember );

  // non-contiguous enum não possui TypeInfo.
  // Apenas mantenho o comportamento de REST.Json.
  if ( LDataType = nil ) or ( LDataType.Handle = nil ) then
    Exit;

  LBucketName := ExtractJSOName( ARttiDataMember );

  if not CanHandleBucket( LBucketName ) then
    Exit;

  LIsArray := False;
  LIsArray := LIsArray or ( LDataType.TypeKind = tkArray );
  LIsArray := LIsArray or ( LDataType.TypeKind = tkDynArray );

  LIsEnum := ( LDataType.TypeKind = tkEnumeration );

  if LDataType.TypeKind = tkArray then
    LInnerRttiType := ( LDataType as TRttiArrayType ).ElementType

  else if LDataType.TypeKind = tkDynArray then
    LInnerRttiType := ( LDataType as TRttiDynamicArrayType ).ElementType

  else
    LInnerRttiType := LDataType;

  if ARttiDataMember is TRttiProperty then
    LRttiAccessor := TRttiPropertyAccessor
                        .Create( TRttiProperty( ARttiDataMember ) )

  else if ARttiDataMember is TRttiField then
    LRttiAccessor := TRttiFieldAccessor
                        .Create( TRttiField( ARttiDataMember ) );


  LRttiBucket := TRttiBucket.Create( LInnerRttiType,
                                     LDataType,
                                     LRttiAccessor,
                                     LIsArray,
                                     LIsEnum );

  ARttiTypeHandler.AddRttiBucket( LBucketName, LRttiBucket );
end;

function TJson2.GetRttiTypeOfMember(ARttiMember: TRttiMember): TRttiType;
begin
  if not Assigned( ARttiMember )  then
    Exit( nil );

  if ARttiMember is TRttiProperty then
    Exit( TRttiProperty( ARttiMember ).PropertyType );

  if ARttiMember is TRttiField then
    Exit( TRttiField( ARttiMember ).FieldType );

  raise Exception.CreateFmt('"%s" does not provide TRttiType.',
                            [ ARttiMember.Name ]);
end;

function TJson2.GetOptions(ARttiType: TRttiType): TArray<TMarshallOptionKind>;
var
  LKindList: TList<TMarshallOptionKind>;
begin
  LKindList := TList<TMarshallOptionKind>.Create();
  try
    for var LAttribute in ARttiType.GetAttributes() do
      if LAttribute is MarshallOptionAttribute then
        LKindList.Add( ( LAttribute as MarshallOptionAttribute ).Kind );

    Result := LKindList.ToArray;
  finally
    LKindList.Free();
  end;
end;

function TJson2.StringToDateTime(AText: String): TDateTime;
var
  LFormatSettings: TFormatSettings;
begin
  LFormatSettings := TFormatSettings.Create();
  LFormatSettings.DateSeparator := '-';
  LFormatSettings.TimeSeparator := ':';
  LFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  LFormatSettings.ShortTimeFormat := 'hh:nn:ss';
  Result := StrToDateTime( StringReplace( AText, 'T', ' ', [] ), 
                           LFormatSettings );
end;

function TJson2.DateTimeToString(ADateTime: TDateTime): String;
begin
  Result := FormatDateTime( 'yyyy"-"mm"-"dd"T"hh":"nn":"ss', ADateTime );
end;

function TJson2.CanHandleBucket(ABucketName: String): Boolean;
begin
  Result := ( ABucketName <> 'RefCount' );
end;

procedure TJson2.Configure(AKinds: TMarshallOptionKindArray);
begin
  if Assigned( FGlobalMarhsallFlags ) then
    FGlobalMarhsallFlags.Setup( AKinds );
end;

function TJson2.ExtractJSOName(ARttiDataMember: TRttiMember): String;
var
  LJSONMemberName: String;
  LKeyAttribute: KeyAttribute;
  LSkipIndex: Integer;
begin
  LKeyAttribute := ARttiDataMember.GetAttribute<KeyAttribute>();

  if not Assigned( LKeyAttribute ) then
  begin
    LJSONMemberName := ARttiDataMember.Name;
    if LJSONMemberName.StartsWith( 'F', True ) then
    begin
      if UpperCase( LJSONMemberName.Chars[1] ) = 'F'  then
        LSkipIndex := 2
      else
        LSkipIndex := 1;

      LJSONMemberName := LJSONMemberName.Substring( LSkipIndex,
                                                    LJSONMemberName.Length );
    end;
  end
  else
    LJSONMemberName := LKeyAttribute.Name;

  Result := LJSONMemberName;
end;

function TJson2.AsRttiType(ATypeInfo: PTypeInfo): TRttiType;
begin
  Result := FRttiContext.GetType( ATypeInfo );
end;

function TJson2.NewJSONNull(): TJSONValue;
begin
  Result := TJSONNull.Create();
end;

destructor TJson2.Destroy();
begin
  FreeAssigned( FRttiTypeHandlerMap );
  FreeAssigned( FEnumTypeContractMap );
  FRttiContext.Free();
  FRWSync := nil;
  inherited;
end;

class procedure TJson2.FreeAssigned(const [ref] AObj: TObject);
var
  LTemp: TObject;
begin
  if Assigned( AObj ) then
  begin
    LTemp := AObj;
    TObject( Pointer( @AObj )^ ) := nil;
    LTemp.Free();
  end;
end;

class procedure TJson2.FreeArray<T>(var Arr: TArray<T>);
begin
  if Assigned( Arr ) then
  begin
    for var LElemento in Arr do
      FreeAssigned( LElemento );
    SetLength( Arr, 0 );
  end;
end;

{$EndRegion 'TJson2'}

{$Region 'Rtti Accessors'}

constructor TRttiPropertyAccessor.Create(ARttiProperty: TRttiProperty);
begin
  FRttiProperty := ARttiProperty;
end;

procedure TRttiPropertyAccessor.Fill(const [ref] AObj: TObject; AValue: TValue);
begin
  FRttiProperty.SetValue( PByte( AObj ), AValue );
end;

function TRttiPropertyAccessor.Get(const [ref] AObj: TObject): TValue;
begin
  Result := FRttiProperty.GetValue( PByte( AObj ) );
end;

constructor TRttiFieldAccessor.Create(ARttiField: TRttiField);
begin
  FRttiField := ARttiField;
end;

procedure TRttiFieldAccessor.Fill(const [ref] AObj: TObject; AValue: TValue);
begin
  FRttiField.SetValue( PByte( AObj ), AValue );
end;

function TRttiFieldAccessor.Get(const [ref] AObj: TObject): TValue;
begin
  Result := FRttiField.GetValue( PByte( AObj ) );
end;

{$EndRegion 'Rtti Accessors'}

{$Region 'TRttiTypeHandler'}

constructor TRttiTypeHandler.Create(ARttiType: TRttiType);
begin
  FRttiType := ARttiType;
  FBucketMap := TRttiBucketDictionary.Create();
  FMarshallFlags := TMarshallFlagsFactory.FromRttiObject( ARttiType );
  FConstructorMethod := ExtractConstructor( ARttiType );
end;

procedure TRttiTypeHandler.AddRttiBucket(ABucketName: String;
                                         ARttiBucket: TRttiBucket);
var
  LOldSize: Integer;
  LNewBucketArray, LBucketArray: TArray<TRttiBucket>;
begin
  if FBucketMap.TryGetValue( ABucketName, LBucketArray ) then
  begin
    LOldSize := Length( LBucketArray );
    SetLength( LNewBucketArray, LOldSize + 1 );
    TArray.Copy<TRttiBucket>( LBucketArray,  LNewBucketArray, LOldSize );
    LNewBucketArray[ LOldSize ] := ARttiBucket;
    FBucketMap.AddOrSetValue( ABucketName, LNewBucketArray );
    Exit;
  end;
  SetLength( LNewBucketArray, 1 );
  LNewBucketArray[0] := ARttiBucket;
  LNewBucketArray[0].FParent := Self;
  FBucketMap.Add( ABucketName, LNewBucketArray );
end;

procedure TRttiTypeHandler.Configure(AKinds: TMarshallOptionKind);
begin
  FMarshallFlags.ResetAllBits();
end;

function TRttiTypeHandler.ContainsBucket(ABucketName: String): Boolean;
begin
  Result := FBucketMap.ContainsKey( ABucketName );
end;

function TRttiTypeHandler.CreateNewObject(): TObject;
var
  LValue: TValue;
  LInstance: TObject;
begin
  LInstance := nil;

  LValue := FConstructorMethod
              .Invoke( FRttiType.AsInstance.MetaclassType, [] );

  if not LValue.IsEmpty then
    LInstance := LValue.AsObject();

  Result := LInstance;
end;

function TRttiTypeHandler.ExtractConstructor(ARttiType: TRttiType): TRttiMethod;
var
  LConstructorMethod: TRttiMethod;
begin
  for var LRttiMethod in ARttiType.GetMethods() do
  begin
    if not LRttiMethod.IsConstructor then
      Continue;

    if Length( LRttiMethod.GetParameters() ) <> 0 then
      Continue;

    LConstructorMethod := LRttiMethod;
    Break;
  end;

  if not Assigned( LConstructorMethod ) then
    raise Exception.CreateFmt('Não foi possível localizar um constructor '+
                              'sem parâmetro para "%s".', [ ARttiType.Name ]);

  Result := LConstructorMethod;
end;


destructor TRttiTypeHandler.Destroy();
var
  LRttiBucketArray: TArray<TRttiBucket>;
begin
  for var LRttiBucket in FBucketMap do
  begin
    LRttiBucketArray := LRttiBucket.Value;
    TJson2.FreeArray<TRttiBucket>( LRttiBucketArray );
    FBucketMap.AddOrSetValue( LRttiBucket.Key, [] );
  end;
  FBucketMap.Free();
  inherited;
end;

{$EndRegion 'TRttiTypeHandler'}

{$Region 'TContractTypeMapper<T>'}

constructor TContractTypeMapper<T>.Create();
begin
  FValueToOrdinalMap := TDictionary<T, Int64>.Create();
  FOrdinalToValueMap := TDictionary<Int64, T>.Create();
end;

procedure TContractTypeMapper<T>.AddEnumContract(AValue: T; AOrdinal: Int64);
begin
  FValueToOrdinalMap.AddOrSetValue( AValue, AOrdinal );
  FOrdinalToValueMap.AddOrSetValue( AOrdinal, AValue );
end;

function TContractTypeMapper<T>.TryResolveOrdinal(AValue: T; out AOrdinal: Int64): Boolean;
begin
  Result := FValueToOrdinalMap.TryGetValue( AValue, AOrdinal );
end;

function TContractTypeMapper<T>.TryResolveValue(AOrdinal: Int64; out AValue: T): Boolean;
begin
  Result := FOrdinalToValueMap.TryGetValue( AOrdinal, AValue );
end;

destructor TContractTypeMapper<T>.Destroy();
begin
  FValueToOrdinalMap.Free();
  FOrdinalToValueMap.Free();
end;

{$EndRegion 'TContractTypeMapper<T>'}

{$Region 'TEnumTypeContract'}

constructor TEnumTypeContract.Create();
begin
  FStringMapper := nil;
  FIntegerMapper := nil;
end;

destructor TEnumTypeContract.Destroy();
begin
  TJson2.FreeAssigned( FStringMapper );
  TJson2.FreeAssigned( FIntegerMapper );
  inherited;
end;

function TEnumTypeContract.GetIntegerMapper(): TIntegerMapper;
begin
  if Assigned( FIntegerMapper ) then
    Exit( FIntegerMapper );

  FIntegerMapper := TIntegerMapper.Create();
  Result := FIntegerMapper;
end;

function TEnumTypeContract.GetStringMapper(): TStringMapper;
begin
  if Assigned( FStringMapper ) then
    Exit( FStringMapper );

  FStringMapper := TStringMapper.Create();
  Result := FStringMapper;
end;

{$EndRegion 'TEnumTypeContract'}

{$Region 'TRttiBucket'}

constructor TRttiBucket.Create(AInnerRttiType: TRttiType;
                               AOuterRttiType: TRttiType;
                               ARttiAccessor: IRttiAccessor;
                               AIsArray: Boolean; AIsEnum: Boolean);
begin
  FInnerRttiType := AInnerRttiType;
  FOuterRttiType := AOuterRttiType;
  FRttiAccessor  := ARttiAccessor;
  FIsArray       := AIsArray;
  FIsEnum        := AIsEnum;
end;

{$EndRegion 'TRttiBucket'}

{$Region 'TMarshallFlags'}

constructor TMarshallFlags.Create();
begin
  Size := 16;
  inherited;
end;

procedure TMarshallFlags.Down(AKind: TMarshallOptionKind);
begin
  ToState( AKind, False );
end;

procedure TMarshallFlags.Setup(AKinds: TMarshallOptionKindArray);
begin
  ResetAllBits();
  for var LKind in AKinds do Up( LKind );
end;

function TMarshallFlags.HasKind(AKind: TMarshallOptionKind): Boolean;
begin
  Result := Bits[ Ord( AKind ) ];
end;

procedure TMarshallFlags.Up(AKind: TMarshallOptionKind);
begin
  ToState( AKind, True );
end;

procedure TMarshallFlags.ToState(AKind: TMarshallOptionKind; AState: Boolean);
begin
  Bits[ Ord( AKind ) ] := AState;
end;

procedure TMarshallFlags.ResetAllBits();
begin
  for var I := 0 to Size - 1 do
    Bits[I] := False;
end;

{$EndRegion 'TMarshallFlags'}

{$Region 'TTypeFlagsFactory'}

class function TMarshallFlagsFactory.FromRttiObject(
  ARttiObject: TRttiObject): TMarshallFlags;
var
  LKindOrdinal: Int64;
  LLocalMarshallFlags: TMarshallFlags;
  LMarshallOptionAttribute: MarshallOptionAttribute;
begin
  LLocalMarshallFlags := nil;

  for var LTypeAttribute in ARttiObject.GetAttributes do
  begin
    if not ( LTypeAttribute is MarshallOptionAttribute ) then
      Continue;

    LMarshallOptionAttribute := MarshallOptionAttribute( LTypeAttribute );

    if not Assigned( LLocalMarshallFlags ) then
      LLocalMarshallFlags := TMarshallFlags.Create();

    LKindOrdinal := Ord( LMarshallOptionAttribute.Kind );
    LLocalMarshallFlags[ LKindOrdinal ] := True;
  end;

  if Assigned( LLocalMarshallFlags ) then
    Exit( LLocalMarshallFlags );

  Result := ( TJson2.FSingleton.GlobalMarhsallFlags );
end;

{$EndRegion 'TTypeFlagsFactory'}

{$Region 'Exposed static functions' }

class function TJson2.JsonArrayToList<T>(AJSONArray: TJSONArray): TList<T>;
var
  LCurrJSONObject: TJSONObject;
  LObjList: TList<T>;
begin
  LObjList := TObjectList<T>.Create( True );
  try
    for var I := 0 to AJSONArray.Count - 1 do
    begin
      if not ( AJSONArray[I] is TJSONObject ) then
        raise Exception.CreateFmt('Item "%d" is not a JSONObject.',[I]);

      LCurrJSONObject := ( AJSONArray[I] as TJSONObject );

      var LNewObj := JsonToObject<T>( LCurrJSONObject );

      if LNewObj <> nil then
        LObjList.Add( LNewObj );
    end;

    Result := LObjList;
  except
    FreeAssigned( LObjList );
    raise;
  end;
end;

class function TJson2.JsonTextToObject<T>(AJSONText: String): T;
var
  LJSONValue: TJSONValue;
  LJSONObject: TJSONObject;
begin
  LJSONValue := TJSONValue.ParseJSONValue( AJSONText );
  try
    if not ( LJSONValue is TJSONObject ) then
      raise Exception.CreateFmt( '(%s) is not a JSON object.',
                                 [ AJSONText ] );

    LJSONObject := TJSONObject( LJSONValue );
    Result := FSingleton.DeserializeObject( LJSONObject,
                                            TypeInfo( T ) ) as T;
  finally
    FreeAssigned( LJSONValue );
  end;
end;

class function TJson2.ObjectToJsonText<T>(AObj: T): String;
var
  LJSONObject: TJSONObject;
begin
  try
    LJSONObject := ObjectToJson<T>( AObj );
    Result := LJSONObject.ToString();
  finally
    if Assigned( LJSONObject ) then
      LJSONObject.Free();
  end;
end;

class function TJson2.ObjectToJsonText(AObj: TObject): String;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJSONObject( FSingleton.SerializeObject( AObj ) );
  try
    Result := LJSONObject.ToString();
  finally
    FreeAssigned( LJSONObject );
  end;
end;

class function TJson2.JsonToObject<T>(AJSONObject: TJSONObject): T;
begin
  Result := ( FSingleton.Deserialize<T>( AJSONObject ) );
end;

class function TJson2.ObjectToJson<T>(AObj: T): TJSONObject;
begin
  Result := ( FSingleton.Serialize<T>( AObj ) );
end;

class procedure TJson2.SetDefaultKinds(AKinds: TArray<TMarshallOptionKind>);
begin
  if AKinds <> nil then
    FSingleton.FDefaultOptions := AKinds;
end;

class constructor TJson2.Create();
begin
  FSingleton := TJson2.Create();
end;

class destructor TJson2.Destroy();
begin
end;

{$EndRegion 'Exposed static functions' }


end.

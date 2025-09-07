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
  System.Generics.Collections;

type

  TMarshallOptionKind = ( SerializeProperty      = 0,
                          SerializeField         = 1,
                          SerializeSetterGetter  = 2,
                          SerializeEmptyAsNull   = 3,
                          SerializeEnumAsInteger = 4,
                          SerializeEnumAsString  = 5 );

{$Region 'Forward Declarations'}

  TRttiBucket = class;

  TRttiTypeHandler = class;

  TEnumTypeContract = class;

  TJsonMarhshaller = class;

  TContractTypeMapper<T> = class;

  TAbstractRttiBucket = class;
  
  TStringMapper = TContractTypeMapper<String>;

  TIntegerMapper = TContractTypeMapper<Integer>;

  TMarshallOptionKindArray = TArray<TMarshallOptionKind>;
  
  TOwnedObjectDictionary<K; V> = class;

  TRttiBucketDictionary = TOwnedObjectDictionary<String, TArray<TAbstractRttiBucket>>;

{$EndRegion 'Forward Declarations'}

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

  TransientAttribute = class( TCustomAttribute )
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

  MarshallOptionAttribute = class ( TCustomAttribute )
    strict private
      FKind: TMarshallOptionKind;
    public
      constructor Create(AKind: TMarshallOptionKind);
    public
      property Kind: TMarshallOptionKind read FKind;
    end;

  StringEnumRuleAttribute = class( TCustomEnumContractRuleAttribute<String> );
  
  IntegerEnumRuleAttribute = class( TCustomEnumContractRuleAttribute<Integer> );

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

{$Region 'Utilities'}

  TGuard = class sealed
    public
      class procedure State(ACondition: Boolean; AMessage: String; Args: Array Of Const);
      class procedure Fail(AMessage: String; Args: Array Of Const);
    end;

  TInfoUtil = class sealed
    public
      class function IsClass(ATypeInfo: PTypeInfo; AName: String): Boolean;
    end;

{$EndRegion 'Utilities'}

  //
  // Representa as configurações de TMarshallOptionKind no escopo
  // de tipo e global.
  //
  TMarshallFlags = class( TBits )
    private
      procedure ToState(AKind: TMarshallOptionKind; AState: Boolean);
    public
      procedure CloneFrom(AOtherMarshallFlags: TMarshallFlags);
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


  //
  //
  //
  IMarshallFlagsConfigurer = interface
    procedure Configure(AKinds: TMarshallOptionKindArray); overload;
  end;

  //
  //
  //
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
    
  //
  //
  //
  //
  TAbstractRttiBucket = class abstract( TInterfacedObject, IRttiAccessor )
    private
      FInnerRttiType: TRttiType;
      FOuterRttiType: TRttiType;
      FIsArray: Boolean;
      FIsEnum: Boolean;
      FRttiAccessor: IRttiAccessor;
      FMarshallFlags: TMarshallFlags;
    protected
      FParent: TRttiTypeHandler;
    protected { Rtti mapping }
      function ToJSONValue(const [ref] AValue: TValue): TJSONValue; virtual; abstract;
      function ToRTTIValue(AJSONValue: TJSONValue): TValue; virtual; abstract;
    public { proxy para IRttiAccessor }
      function Get(const [ref] AObj: TObject): TValue;  virtual; abstract;
      procedure Fill(const [ref] AObj: TObject; AValue: TValue); virtual; abstract;
    public { JSON adapters }
      function GetAsJSONValue(const [ref] AObj: TObject): TJSONValue; virtual; abstract;
      procedure FillWithJSONValue(const [ref] AObj: TObject; AJSONValue: TJSONValue); virtual; abstract;
    private
      property IsArray:       Boolean        read FIsArray;
      property IsEnum:        Boolean        read FIsEnum;
      property RttiAccessor:  IRttiAccessor  read FRttiAccessor;
      property InnerRttiType: TRttiType      read FInnerRttiType;
      property OuterRttiType: TRttiType      read FOuterRttiType;
      property MarshallFlags: TMarshallFlags read FMarshallFlags;
    public
      constructor Create(AInnerRttiType: TRttiType;
                         AOuterRttiType: TRttiType;
                         ARttiAccessor: IRttiAccessor;
                         AIsArray: Boolean; AIsEnum: Boolean;
                         AMarshallFlags: TMarshallFlags);
    end;
    
  //
  //
  //
  //
  TRttiBucket = class( TAbstractRttiBucket )
    protected { Rtti mapping }
      function ToJSONValue(const [ref] AValue: TValue): TJSONValue; override;
      function ToRTTIValue(AJSONValue: TJSONValue): TValue; override;
    public { proxy para IRttiAccessor }
      function Get(const [ref] AObj: TObject): TValue; override;
      procedure Fill(const [ref] AObj: TObject; AValue: TValue); override;
    public { JSON adapters }
      function GetAsJSONValue(const [ref] AObj: TObject): TJSONValue; override;
      procedure FillWithJSONValue(const [ref] AObj: TObject; AJSONValue: TJSONValue); override;
    private
      function StringToDateTime(AText: String): TDateTime;
      function DateTimeToString(ADateTime: TDateTime): String;
      function NewJSONNull(): TJSONValue;
    private
      function ObjectToJSONValue(const [ref] AValue: TValue): TJSONValue;
      function EnumToJSONValue(const [ref] AValue: TValue): TJSONValue;
      function ArrayToJSONValue(const [ref] AValue: TValue): TJSONValue;
    private
      function ToEnumOrdValue(ATypeInfo: PTypeInfo;
                              AJSONValue: TJSONValue): TValue;
      function JSONStringToRTTIValue(AJSONString: TJSONString;
                                     ATypeInfo: PTypeInfo): TValue;
      function JSONNumberToRTTIValue(AJSONNumber: TJSONNumber;
                                     ATypeInfo: PTypeInfo): TValue;
      function JSONObjectToRTTIValue(AJSONObject: TJSONObject;
                                     ATypeInfo: PTypeInfo): TValue;
      function JSONArrayToRTTIValue(AJSONArray: TJSONArray): TValue;
    private
      function GetEnumTypeContract(ATypeInfo: PTypeInfo): TEnumTypeContract;
    end;

  //
  // Representa um TRttiBucket que retém informação para serialização e
  // deserialização do tipo : TList<T>.
  //
  TGenericListRttiBucket = class( TRttiBucket )
    strict private
      FConstructorMethod: TRttiMethod;
      FCountRttiProperty: TRttiProperty;
      FItemRttiProperty: TRttiIndexedProperty;
      FAddRttiMethod: TRttiMethod;
    protected { Rtti mapping }
      function ToJSONValue(const [ref] AValue: TValue): TJSONValue; override;
      function ToRTTIValue(AJSONValue: TJSONValue): TValue; override;
    private
      function CreateNewList(): TObject;
      procedure AddItemFor(const [ref] AObj: TObject; AValue: TValue);
      function GetItemCountOf(AInstance: Pointer): Integer;
      function GetItemValueOf(AInstance: Pointer; AIndex: Integer): TValue;
      function ExtractConstructor(): TRttiMethod;
      function ExtractInnerType(): TRttiType;
    protected
      constructor Create(AOuterRttiType: TRttiType;
                         ARttiAccessor: IRttiAccessor;
                         AMarshallFlags: TMarshallFlags);
    end;
  
  //
  //
  //
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
      procedure AddRttiBucket(ABucketName: String; ARttiBucket: TAbstractRttiBucket);
    private
      property RttiBuckets: TRttiBucketDictionary read FBucketMap;
    public
      constructor Create(ARttiType: TRttiType);
      destructor Destroy(); override;
    end;

  //
  //
  //
  TJsonMarhshaller = class sealed
    strict private
      FRWSync: IReadWriteSync;
      FRttiContext: TRttiContext;
      FGlobalMarhsallFlags: TMarshallFlags;
      FRttiTypeHandlerMap: TTypeInfoIndexer<TRttiTypeHandler>;
      FEnumTypeContractMap: TTypeInfoIndexer<TEnumTypeContract>;
    protected
      property GlobalMarhsallFlags: TMarshallFlags read FGlobalMarhsallFlags;
    private
      class var FMarshaller: TJsonMarhshaller;
      class property Marshaller: TJsonMarhshaller read FMarshaller;
    private
      class procedure FreeAssigned(const [ref] AObj: TObject);
      class procedure FreeArray<T: class>(var Arr: TArray<T>);
    public
      class constructor Create();
      class destructor Destroy();
    private
      function GetRttiTypeOfMember(ARttiMember: TRttiMember): TRttiType;
      procedure RegisterEnumTypeContract(ARttiType: TRttiType);
      procedure RegisterRttiBucket(ARttiTypeHandler: TRttiTypeHandler;
                                   ARttiDataMember: TRttiMember);
      function CanHandleBucket(ABucketName: String): Boolean;
      function AsRttiType(ATypeInfo: PTypeInfo): TRttiType;
      function GetEnumTypeContract(ATypeInfo: PTypeInfo): TEnumTypeContract;
      function GetRttiTypeHandler(ATypInfo: PTypeInfo): TRttiTypeHandler;
      function ExtractJSOName(ARttiDataMember: TRttiMember): String;
      procedure ExtractRttiProperties(ARttiType: TRttiType;
                                      ARttiTypeHandler: TRttiTypeHandler);
      procedure ExtractRttiFields(ARttiType: TRttiType;
                                  ARttiTypeHandler: TRttiTypeHandler);
    public
      procedure Configure(AKinds: TMarshallOptionKindArray);
    public
      procedure InvalidateCache();
      function SerializeObject(AObject: TObject): TJSONValue;
      function Serialize<T: class>(AObject: T): TJSONObject;
      function DeserializeObject(AJSONObject: TJSONObject;
                                 ATypeInfo: PTypeInfo): TObject;
      function Deserialize<T: class>(AJSONObject: TJSONObject): T;
    public
      constructor Create();
      destructor Destroy(); override;
    end;
    
  //
  //
  //
  TJson2 = class sealed( TInterfacedObject )
    public
      class procedure Invalidate();
    public
      class procedure ConfigureGlobal(AKinds: TMarshallOptionKindArray);
      class procedure ConfigureType(AKinds: TMarshallOptionKindArray);
      class procedure ConfigureBucket(AKinds: TMarshallOptionKindArray);    
    public
      class function JsonArrayToList<T: class>(AJSONArray: TJSONArray): TList<T>;
      class function JsonTextToObject<T: class>(AJSONText: String): T;
      class function ObjectToJsonText<T: class>(AObj: T): String; overload;
      class function ObjectToJsonText(AObj: TObject): String; overload;
      class function JsonToObject<T: class>(AJSONObject: TJSONObject): T;
      class function ObjectToJson<T: class>(AObj: T): TJSONObject;
    end;

const
  JSON2OBJ_VERSION = '1.0.1';

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

{$Region 'TJsonMarhshaller'}

constructor TJsonMarhshaller.Create();
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

function TJsonMarhshaller.DeserializeObject(AJSONObject: TJSONObject;
                                            ATypeInfo: PTypeInfo): TObject;
var          
  LInstance: TObject;
  LRttiTypeHandler: TRttiTypeHandler;
var
  LJSONValue: TJSONValue;
  LRttiBuckets: TArray<TAbstractRttiBucket>;
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
        LRttiBucket.FillWithJSONValue( LInstance, LJSONValue );
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

function TJsonMarhshaller.Deserialize<T>(AJSONObject: TJSONObject): T;
begin
  Result := ( DeserializeObject( AJSONObject, TypeInfo( T ) ) as T );
end;

function TJsonMarhshaller.SerializeObject(AObject: TObject): TJSONValue;
var
  LRttiTypeHandler: TRttiTypeHandler;
  LJSONObject: TJSONObject;
var
  LRttiBuckets: TArray<TAbstractRttiBucket>;
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
      LJSONObject.AddPair( LBucketName, 
                           LRttiBucket.GetAsJSONValue( AObject ) );
  end;

  Result := LJSONObject;
end;

function TJsonMarhshaller.Serialize<T>(AObject: T): TJSONObject;
begin
  Result := ( SerializeObject( AObject ) as TJSONObject );
end;

procedure TJsonMarhshaller.RegisterEnumTypeContract(ARttiType: TRttiType);
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


function TJsonMarhshaller.GetRttiTypeHandler(ATypInfo: PTypeInfo): TRttiTypeHandler;
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

function TJsonMarhshaller.GetEnumTypeContract(ATypeInfo: PTypeInfo): TEnumTypeContract;
var
  LEnumTypeContract: TEnumTypeContract;
  LOrdinal: Int64;
  LRttiEnumType: TRttiEnumerationType;
  LDefaultEnumName: String;
begin
  if FEnumTypeContractMap.TryGetValue( ATypeInfo,
                                       LEnumTypeContract ) then
    Exit( LEnumTypeContract );

  LEnumTypeContract := TEnumTypeContract.Create();
  LRttiEnumType := TRttiEnumerationType( FRttiContext.GetType( ATypeInfo ) );

  for LOrdinal := LRttiEnumType.MinValue to LRttiEnumType.MaxValue do
  begin
    LDefaultEnumName := GetEnumName( ATypeInfo, LOrdinal );
    LEnumTypeContract.StringMapper.AddEnumContract( LDefaultEnumName, LOrdinal );
    LEnumTypeContract.IntegerMapper.AddEnumContract( LOrdinal, LOrdinal );
  end;

  FEnumTypeContractMap.Add( ATypeInfo, LEnumTypeContract );

  Result := LEnumTypeContract;
end;

procedure TJsonMarhshaller.ExtractRttiProperties(ARttiType: TRttiType;
                                                 ARttiTypeHandler: TRttiTypeHandler);
begin
  for var LRttiProperty in ARttiType.GetProperties() do
    RegisterRttiBucket( ARttiTypeHandler, LRttiProperty );
end;

procedure TJsonMarhshaller.ExtractRttiFields(ARttiType: TRttiType;
                                             ARttiTypeHandler: TRttiTypeHandler);
begin
  for var LRttiProperty in ARttiType.GetFields() do
    RegisterRttiBucket( ARttiTypeHandler, LRttiProperty );
end;

procedure TJsonMarhshaller.RegisterRttiBucket(ARttiTypeHandler: TRttiTypeHandler;
                                              ARttiDataMember: TRttiMember);
var
  LDataType: TRttiType;
  LIsArray, LIsEnum: Boolean;
  LInnerRttiType: TRttiType;
  LRttiBucket: TRttiBucket;
  LBucketName: String;
  LRttiAccessor: IRttiAccessor;
  LMarshallFlags: TMarshallFlags;
begin
  // LDataType == OuterRttiType
  LDataType := GetRttiTypeOfMember( ARttiDataMember );

  // non-contiguous enum não possui TypeInfo.
  // Apenas mantenho o comportamento de REST.Json.
  if ( LDataType = nil ) or ( LDataType.Handle = nil ) then
    Exit;

  LBucketName := ExtractJSOName( ARttiDataMember );

  if not CanHandleBucket( LBucketName ) then
    Exit;

  if ARttiDataMember.HasAttribute<TransientAttribute> then
    Exit;

  // Atualmente as MarshallFlags de Buckets herdam de TRttiTypeHandler.
  LMarshallFlags := ARttiTypeHandler.MarshallFlags;
    
  LIsArray := False;
  LIsArray := LIsArray or ( LDataType.TypeKind = tkArray );
  LIsArray := LIsArray or ( LDataType.TypeKind = tkDynArray );

  LIsEnum := ( LDataType.TypeKind = tkEnumeration );

  LInnerRttiType := nil;

  if ARttiDataMember is TRttiProperty then
    LRttiAccessor := TRttiPropertyAccessor
                        .Create( TRttiProperty( ARttiDataMember ) )

  else if ARttiDataMember is TRttiField then
    LRttiAccessor := TRttiFieldAccessor
                        .Create( TRttiField( ARttiDataMember ) );

  LRttiBucket := nil;

  // Arrays //
  if LDataType.TypeKind = tkArray then
    LInnerRttiType := TRttiArrayType( LDataType ).ElementType

  else if LDataType.TypeKind = tkDynArray then
    LInnerRttiType := TRttiDynamicArrayType( LDataType ).ElementType

  // Special types handling //
  else if LDataType.TypeKind = tkClass then
  begin

    if TInfoUtil.IsClass( LDataType.Handle, 'TList' ) or
       TInfoUtil.IsClass( LDataType.Handle, 'TObjectList' ) then
    begin
      LRttiBucket := TGenericListRttiBucket.Create( LDataType,
                                                    LRttiAccessor,
                                                    LMarshallFlags );
    end;

  end;

  // Fallback //
  if LInnerRttiType = nil then
    LInnerRttiType := LDataType;

  if LRttiBucket = nil then
  begin
    LRttiBucket := TRttiBucket.Create( LInnerRttiType,
                                       LDataType,
                                       LRttiAccessor,
                                       LIsArray,
                                       LIsEnum,
                                       LMarshallFlags );
  end;

  ARttiTypeHandler.AddRttiBucket( LBucketName, LRttiBucket );
end;

function TJsonMarhshaller.GetRttiTypeOfMember(ARttiMember: TRttiMember): TRttiType;
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

function TRttiBucket.StringToDateTime(AText: String): TDateTime;
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

function TRttiBucket.DateTimeToString(ADateTime: TDateTime): String;
begin
  Result := FormatDateTime( 'yyyy"-"mm"-"dd"T"hh":"nn":"ss', ADateTime );
end;

function TJsonMarhshaller.CanHandleBucket(ABucketName: String): Boolean;
begin
  Result := ( ABucketName <> 'RefCount' );
end;

procedure TJsonMarhshaller.Configure(AKinds: TMarshallOptionKindArray);
begin
  try
    if Assigned( FGlobalMarhsallFlags ) then
      FGlobalMarhsallFlags.Setup( AKinds );
  finally
    TJsonMarhshaller.Marshaller.InvalidateCache();
  end;
end;

function TJsonMarhshaller.ExtractJSOName(ARttiDataMember: TRttiMember): String;
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

function TJsonMarhshaller.AsRttiType(ATypeInfo: PTypeInfo): TRttiType;
begin
  Result := FRttiContext.GetType( ATypeInfo );
end;

procedure TJsonMarhshaller.InvalidateCache();
begin
  FRWSync.BeginWrite();
  try
    FRttiTypeHandlerMap.Clear();
    FEnumTypeContractMap.Clear();
  finally
    FRWSync.EndWrite();
  end;
end;

destructor TJsonMarhshaller.Destroy();
begin
  FreeAssigned( FRttiTypeHandlerMap );
  FreeAssigned( FEnumTypeContractMap );
  FRttiContext.Free();
  FGlobalMarhsallFlags.Free();
  FRWSync := nil;
  inherited;
end;

class procedure TJsonMarhshaller.FreeAssigned(const [ref] AObj: TObject);
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

class procedure TJsonMarhshaller.FreeArray<T>(var Arr: TArray<T>);
begin
  if Assigned( Arr ) then
  begin
    for var LElemento in Arr do
      FreeAssigned( LElemento );
    SetLength( Arr, 0 );
  end;
end;

class constructor TJsonMarhshaller.Create();
begin
  FMarshaller := TJsonMarhshaller.Create();
end;

class destructor TJsonMarhshaller.Destroy();
begin
  FMarshaller.Free();
end;

{$EndRegion 'TJsonMarhshaller'}

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
                                         ARttiBucket: TAbstractRttiBucket);
var
  LOldSize: Integer;
  LNewBucketArray, LBucketArray: TArray<TAbstractRttiBucket>;
begin
  if FBucketMap.TryGetValue( ABucketName, LBucketArray ) then
  begin
    LOldSize := Length( LBucketArray );
    SetLength( LNewBucketArray, LOldSize + 1 );
    TArray.Copy<TAbstractRttiBucket>( LBucketArray,  LNewBucketArray, LOldSize );
    LNewBucketArray[ LOldSize ] := ARttiBucket;
    FBucketMap.AddOrSetValue( ABucketName, LNewBucketArray );
    Exit;
  end;
  SetLength( LNewBucketArray, 1 );
  LNewBucketArray[0] := ARttiBucket;
  LNewBucketArray[0].FParent := Self;
  FBucketMap.Add( ABucketName, LNewBucketArray );
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
  LRttiBucketArray: TArray<TAbstractRttiBucket>;
begin
  for var LRttiBucket in FBucketMap do
  begin
    LRttiBucketArray := LRttiBucket.Value;
    TJsonMarhshaller.FreeArray<TAbstractRttiBucket>( LRttiBucketArray );
    FBucketMap.AddOrSetValue( LRttiBucket.Key, [] );
  end;
  FBucketMap.Free();
  FMarshallFlags.Free();
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
  TJsonMarhshaller.FreeAssigned( FStringMapper );
  TJsonMarhshaller.FreeAssigned( FIntegerMapper );
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

constructor TAbstractRttiBucket.Create(AInnerRttiType: TRttiType;
                                       AOuterRttiType: TRttiType;
                                       ARttiAccessor: IRttiAccessor;
                                       AIsArray: Boolean; AIsEnum: Boolean;
                                       AMarshallFlags: TMarshallFlags);
begin
  FInnerRttiType := AInnerRttiType;
  FOuterRttiType := AOuterRttiType;
  FRttiAccessor  := ARttiAccessor;
  FIsArray       := AIsArray;
  FIsEnum        := AIsEnum;
  FMarshallFlags := AMarshallFlags;
end;

procedure TRttiBucket.Fill(const [ref] AObj: TObject; AValue: TValue);
begin
  RttiAccessor.Fill( AObj, AValue );
end;

procedure TRttiBucket.FillWithJSONValue(const [ref] AObj: TObject; AJSONValue: TJSONValue);
begin
  Fill( AObj, ToRTTIValue( AJSONValue ) );
end;

function TRttiBucket.Get(const [ref] AObj: TObject): TValue;
begin
  Result := RttiAccessor.Get( AObj );
end;

function TRttiBucket.GetAsJSONValue(const [ref] AObj: TObject): TJSONValue;
begin
  Result := ToJSONValue( Get( AObj ) );
end;

function TRttiBucket.GetEnumTypeContract(ATypeInfo: PTypeInfo): TEnumTypeContract;
begin
  Result := ( TJsonMarhshaller.Marshaller.GetEnumTypeContract( ATypeInfo ) );
end;

function TRttiBucket.ToRTTIValue(AJSONValue: TJSONValue): TValue;
var
  LInnerTypeInfo: PTypeInfo;
begin
  if AJSONValue is TJSONNull then
    Exit( TValue.Empty );

  LInnerTypeInfo := InnerRttiType.Handle;

  if ( IsEnum ) and 
     ( not TInfoUtil.IsClass( LInnerTypeInfo, 'Boolean' ) ) then
  begin
    Exit( ToEnumOrdValue( LInnerTypeInfo, AJSONValue  ) );
  end;

  if AJSONValue is TJSONNumber then
    Exit( JSONNumberToRTTIValue( ( AJSONValue as TJSONNumber ),
                                 LInnerTypeInfo ) );

  if AJSONValue is TJSONBool then
    Exit( TValue.From<Boolean>( (AJSONValue as TJSONBool).AsBoolean ) );

  if AJSONValue is TJSONString then
    Exit( JSONStringToRTTIValue( ( AJSONValue as TJSONString ),
                                 LInnerTypeInfo ) );

  if AJSONValue is TJSONObject then
    Exit( JSONObjectToRTTIValue( ( AJSONValue as TJSONObject ),
                                 LInnerTypeInfo ) );

  if AJSONValue is TJSONArray then
    Exit( JSONArrayToRTTIValue( ( AJSONValue as TJSONArray ) ) );

  raise Exception.CreateFmt( 'Could found a type for value "%s".',
                             [AJSONValue.Value] );
end;

function TRttiBucket.JSONStringToRTTIValue(AJSONString: TJSONString;
                                           ATypeInfo: PTypeInfo): TValue;
var
  LValue: String;
  LOrdinal: Int64;
begin
  LValue := AJSONString.Value;

  if TInfoUtil.IsClass( ATypeInfo, 'TDateTime' ) then
    Exit( TValue.From<TDateTime>( StringToDateTime( LValue ) ) )

  else if TInfoUtil.IsClass( ATypeInfo, 'TDate' ) then
    Exit( TValue.From<TDate>( Trunc( StringToDateTime( LValue ) ) ) )

  else if ATypeInfo.Kind = tkEnumeration then
  begin
    with GetEnumTypeContract( ATypeInfo ) do
    begin
      if StringMapper.TryResolveOrdinal( LValue, LOrdinal  ) then
        Exit( TValue.FromOrdinal( ATypeInfo, LOrdinal ) );

      TGuard.Fail( 'Failed to map string "%" to ordinal of "%s".',
                   [ LValue, ATypeInfo^.Name ] );
    end;
  end;

  Result := TValue.From<String>( AJSONString.Value );
end;

function TRttiBucket.JSONArrayToRTTIValue(AJSONArray: TJSONArray): TValue;
var
  LArray: Array Of TValue;
  LCount: Integer;
begin
  LCount := AJSONArray.Count;

  SetLength( LArray, LCount );
  Dec( LCount, 1 );

  for var I := 0 to LCount do
    LArray[I] := ToRTTIValue( AJSONArray.Items[I] );

  Result := TValue.FromArray( OuterRttiType.Handle, LArray );
end;

function TRttiBucket.JSONObjectToRTTIValue(AJSONObject: TJSONObject;
                                           ATypeInfo: PTypeInfo): TValue;
var
  LObj: TObject;
begin
  LObj := TJsonMarhshaller.Marshaller.DeserializeObject( AJSONObject,
                                                         ATypeInfo );
  Result := TValue.From<TObject>( LObj );
end;

function TRttiBucket.JSONNumberToRTTIValue(AJSONNumber: TJSONNumber;
                                           ATypeInfo: PTypeInfo): TValue;
var
  LOrdinal: Int64;
  LValue: Integer;
begin
  Result := TValue.Empty;

  if ATypeInfo.Kind = tkEnumeration then
  begin
    with GetEnumTypeContract( ATypeInfo ) do
    begin
      if IntegerMapper.TryResolveOrdinal( LValue, LOrdinal  ) then
        Exit( TValue.FromOrdinal( ATypeInfo, LOrdinal ) );

      TGuard.Fail( 'Failed to map integer "%" to ordinal of "%s".',
                   [ LValue, ATypeInfo^.Name ] );
    end;
  end;

  case ATypeInfo.Kind of
    tkInteger, tkInt64:
      Exit( AJSONNumber.AsInt64 );

    tkFloat:
      Exit(  AJSONNumber.AsDouble );
  end;
end;

function TRttiBucket.ToEnumOrdValue(ATypeInfo: PTypeInfo;
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

function TRttiBucket.ToJSONValue(const [ref] AValue: TValue): TJSONValue;
begin
  if AValue.IsEmpty then
    Exit( NewJSONNull() );

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
         ( FMarshallFlags.HasKind( SerializeEmptyAsNull ) ) then
      begin
        Exit( TJSONNull.Create() );
      end;

      Exit( TJSONString.Create( AValue.AsString() ) );
    end;

    tkEnumeration:
      Exit( EnumToJSONValue( AValue ) );

    tkDynArray:
      Exit( ArrayToJSONValue( AValue ) );

    tkClass:
      Exit( ObjectToJSONValue( AValue ) );

    else
      Result := TJSONString.Create( AValue.ToString() );
  end;
end;

function TRttiBucket.ArrayToJSONValue(const [ref] AValue: TValue): TJSONValue;
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
      LJSONArray.AddElement( ToJSONValue( LElement ) );
    end;
    Result := LJSONArray;
  except
    LJSONArray.Free();
    raise;
  end;
end;

function TRttiBucket.EnumToJSONValue(const [ref] AValue: TValue): TJSONValue;
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
    if FMarshallFlags.HasKind( SerializeEnumAsString ) then
    begin
      if StringMapper.TryResolveValue( LOrdinal, LEnumString ) then
        Exit( TJSONString.Create( LEnumString ) )
      else
        Exit( TJSONString.Create( AValue.ToString() ) );
    end
    else if FMarshallFlags.HasKind( SerializeEnumAsInteger ) then
    begin
      if IntegerMapper.TryResolveValue( LOrdinal, LEnumInteger ) then
        Exit( TJSONNumber.Create( LEnumInteger ) )
      else
        Exit( TJSONNumber.Create( LOrdinal ) );
    end;
  end;

  Result := NewJSONNull();
end;

function TRttiBucket.ObjectToJSONValue(const [ref] AValue: TValue): TJSONValue;
begin
  Result := ( TJsonMarhshaller.Marshaller.SerializeObject( AValue.AsObject() ) );
end;

function TRttiBucket.NewJSONNull(): TJSONValue;
begin
  Result := TJSONNull.Create();
end;


{$EndRegion 'TRttiBucket'}

{$Region 'TGenericListRttiBucket'}

constructor TGenericListRttiBucket.Create(AOuterRttiType: TRttiType;
                                          ARttiAccessor: IRttiAccessor;
                                          AMarshallFlags: TMarshallFlags);
var
  LOuterTypeName: String;
begin
  LOuterTypeName := AOuterRttiType.Handle^.Name;

  FOuterRttiType := AOuterRttiType;
  FMarshallFlags := AMarshallFlags;
  FRttiAccessor  := ARttiAccessor;

  FInnerRttiType     := ExtractInnerType();
  FCountRttiProperty := AOuterRttiType.GetProperty( 'Count' );
  FItemRttiProperty  := AOuterRttiType.GetIndexedProperty( 'Items' );
  FConstructorMethod := ExtractConstructor();

  TGuard.State( ( FInnerRttiType <> nil ),
                'Could not define the Inner type for "%s".',
                [ LOuterTypeName ] );

  TGuard.State( ( FCountRttiProperty <> nil ),
                'Failed to find the Count property of "%s".',
                  [ LOuterTypeName ] );

  TGuard.State( ( FItemRttiProperty <> nil ),
                'Failed to find the Item property of "%s".',
                [ LOuterTypeName ] );

  TGuard.State( ( FConstructorMethod <> nil ),
                'Failed to find a valid constructor for "%s".',
                [ LOuterTypeName ] );
end;

function TGenericListRttiBucket.ToJSONValue(const [ref] AValue: TValue): TJSONValue;
var
  LJSONArray: TJSONArray;
var
  LGenListInstance: TObject;
  LItemCount: Integer;
  LItemValue: TValue;
  LJSONValue: TJSONValue;
begin
  LGenListInstance := AValue.AsObject();

  if not Assigned( LGenListInstance ) then
  begin
    if MarshallFlags.HasKind( SerializeEmptyAsNull ) then
      Exit( NewJSONNull() )
    else
      Exit( TJSONArray.Create() );
  end;

  LJSONArray := TJSONArray.Create();
  try
    LItemCount := GetItemCountOf( PByte( LGenListInstance ) );

    for var I := 0 to LItemCount - 1 do
    begin
      LItemValue := GetItemValueOf( PByte( LGenListInstance ), I );

      if LItemValue.IsEmpty then
        Continue;

      LJSONValue := ( inherited ToJSONValue( LItemValue ) );
      LJSONArray.AddElement( LJSONValue );
    end;

    Result := LJSONArray;
  except
    TJsonMarhshaller.FreeAssigned( LJSONValue );
    LJSONArray.Free();
    raise;
  end;
end;

function TGenericListRttiBucket.ToRTTIValue(AJSONValue: TJSONValue): TValue;
var
  LJSONArray: TJSONArray;
  LGenListInstance: TObject;
  LItemValue: TValue;
begin
  TGuard.State( ( AJSONValue is TJSONArray ),
                '"%s" expected to be an array.', [ AJSONValue.ToJSON() ] );

  LJSONArray := TJSONArray( AJSONValue );

  LGenListInstance := CreateNewList();

  for var LJSONValue in LJSONArray do
  begin
    LItemValue := ( inherited ToRTTIValue( LJSONValue ) );
    AddItemFor( LGenListInstance, LItemValue );
  end;

  Result := TValue.From<TObject>( LGenListInstance );
end;

function TGenericListRttiBucket.ExtractConstructor(): TRttiMethod;
var
  LParameters: TArray<TRttiParameter>;
  LCreateRttiMethods: TArray<TRttiMethod>;
  LRttiMethod: TRttiMethod;
begin
  LCreateRttiMethods := OuterRttiType.GetMethods( 'Create' );
  Assert( LCreateRttiMethods <> nil );
  Assert( Length( LCreateRttiMethods ) > 0 );

  for LRttiMethod in LCreateRttiMethods do
  begin
    if not LRttiMethod.IsConstructor then
      Continue;

    LParameters := LRttiMethod.GetParameters();

    if ( TInfoUtil.IsClass( OuterRttiType.Handle, 'TList' ) ) and
       ( Length( LParameters ) = 0 ) then
    begin
      Exit( LRttiMethod );
    end;

    if ( Length( LParameters ) = 1 ) and 
       ( TInfoUtil.IsClass( OuterRttiType.Handle, 'TObjectList' ) ) and
       ( TInfoUtil.IsClass( LParameters[0].ParamType.Handle, 'Boolean' ) ) then
    begin
      Exit( LRttiMethod );
    end;
  end;

  Result := LCreateRttiMethods[0];
end;

function TGenericListRttiBucket.ExtractInnerType(): TRttiType;
var
  LAddRttiMethod: TRttiMethod;
  LItemParameter: TRttiParameter;
begin
  LAddRttiMethod := OuterRttiType.GetMethod( 'Add' );

  TGuard.State( ( LAddRttiMethod <> nil ),
                  'Failed to find Add(...) function for "%s".',
                  [ OuterRttiType.Name ] );

  Result := LAddRttiMethod.GetParameters()[0].ParamType;
  FAddRttiMethod := LAddRttiMethod;
end;

function TGenericListRttiBucket.CreateNewList(): TObject;
var
  LValue: TValue;
  LInstance: TObject;
  LParameters: Array Of TValue;
begin
  LInstance := nil;

  if TInfoUtil.IsClass( OuterRttiType.Handle, 'TList' ) then
    LParameters := []

  // Permitir quando for TObjectList<T>, que a lista seja dona dos
  // objetos adicionados.
  else if TInfoUtil.IsClass( OuterRttiType.Handle, 'TObjectList' ) then
    LParameters := [ TValue.From<Boolean>( True ) ];
  
  LValue := FConstructorMethod.Invoke( OuterRttiType.AsInstance.MetaclassType, 
                                       LParameters );

  if not LValue.IsEmpty then
    LInstance := LValue.AsObject();
 
  Result := LInstance;
end;

function TGenericListRttiBucket.GetItemCountOf(AInstance: Pointer): Integer;
begin
  Result := ( FCountRttiProperty.GetValue( AInstance ).AsInteger );
end;

function TGenericListRttiBucket.GetItemValueOf(AInstance: Pointer;
                                               AIndex: Integer): TValue;
begin
  Result := ( FItemRttiProperty.GetValue( AInstance,
                                          [ TValue.From<Integer>( AIndex )  ] ) );
end;

procedure TGenericListRttiBucket.AddItemFor(const [ref] AObj: TObject;
                                            AValue: TValue);
begin
  FAddRttiMethod.Invoke( AObj, [ AValue ] );
end;

{$EndRegion 'TGenericListRttiBucket'}

{$Region 'TMarshallFlags'}

constructor TMarshallFlags.Create();
begin
  Size := 16;
  inherited;
end;

procedure TMarshallFlags.CloneFrom(AOtherMarshallFlags: TMarshallFlags);
begin
  ResetAllBits();
  Size := AOtherMarshallFlags.Size;
  for var LBit := 0 to Size - 1 do
    Bits[ LBit ] := AOtherMarshallFlags[ LBit ];
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

  LLocalMarshallFlags := TMarshallFlags.Create();
  LLocalMarshallFlags.CloneFrom( TJsonMarhshaller.Marshaller.GlobalMarhsallFlags );
  Result := LLocalMarshallFlags;
end;

{$EndRegion 'TTypeFlagsFactory'}

{$Region 'TJson2' }

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
    TJsonMarhshaller.FreeAssigned( LObjList );
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

    Result := TJsonMarhshaller.Marshaller.DeserializeObject( LJSONObject, 
                                                             TypeInfo( T ) ) as T;
  finally
    TJsonMarhshaller.FreeAssigned( LJSONValue );
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
  LJSONValue: TJSONValue;
begin
  LJSONValue := TJsonMarhshaller.Marshaller.SerializeObject( AObj );
  try
    Result := LJSONValue.ToString();
  finally
    TJsonMarhshaller.FreeAssigned( LJSONValue );
  end;
end;

class function TJson2.JsonToObject<T>(AJSONObject: TJSONObject): T;
begin
  Result := ( TJsonMarhshaller.Marshaller.Deserialize<T>( AJSONObject ) );
end;

class function TJson2.ObjectToJson<T>(AObj: T): TJSONObject;
begin
  Result := ( TJsonMarhshaller.Marshaller.Serialize<T>( AObj ) );
end;

class procedure TJson2.ConfigureBucket(AKinds: TMarshallOptionKindArray);
begin
  raise Exception.CreateFmt('JSON2Obj "%s" does not yet support dynamic configuration of MarshallFlags in Bucket.', [ JSON2OBJ_VERSION ] );
end;

class procedure TJson2.ConfigureType(AKinds: TMarshallOptionKindArray);
begin
  raise Exception.CreateFmt('JSON2Obj "%s" does not yet support dynamic configuration of MarshallFlags in Types.', [ JSON2OBJ_VERSION ] );
end;

class procedure TJson2.ConfigureGlobal(AKinds: TMarshallOptionKindArray);
begin
  TJsonMarhshaller.Marshaller.Configure( AKinds );
end;

class procedure TJson2.Invalidate();
begin
  TJsonMarhshaller.Marshaller.InvalidateCache();
end;

{$EndRegion 'TJson2' }

{$Region 'TInfoUtil'}

class function TInfoUtil.IsClass(ATypeInfo: PTypeInfo; AName: String): Boolean;
begin
  if ATypeInfo = nil then
    Exit( False );

  Result := String( ATypeInfo.Name ).StartsWith( AName, True );
end;

{$EndRegion 'TInfoUtil'}

{$Region 'TGuard'}

class procedure TGuard.Fail(AMessage: String;
                            Args: array of Const);
begin
  State( False, AMessage, Args );
end;

class procedure TGuard.State(ACondition: Boolean;
                             AMessage: String;
                             Args: array of Const);
begin
  Assert( ACondition, Format( AMessage, Args ) );
end;

{$EndRegion 'TGuard'}

end.

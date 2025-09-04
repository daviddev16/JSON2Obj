unit Other;

interface

uses
  JSON2Obj,
  DUnitX.TestFramework;

type
  TObjectStatus = (osCreated, osLoaded, osUnload, osDestroyed);

  [IntegerEnumRule( TypeInfo(TObjectStatus), Ord(osCreated),   200 )]
  [IntegerEnumRule( TypeInfo(TObjectStatus), Ord(osLoaded),    204 )]
  [IntegerEnumRule( TypeInfo(TObjectStatus), Ord(osUnload),    214 )]
  [IntegerEnumRule( TypeInfo(TObjectStatus), Ord(osDestroyed), 318 )]
  [StringEnumRule( TypeInfo(TObjectStatus), Ord(osCreated),   'CREATED' )]
  [StringEnumRule( TypeInfo(TObjectStatus), Ord(osLoaded),    'LOADED' )]
  [StringEnumRule( TypeInfo(TObjectStatus), Ord(osUnload),    'UNLOADED' )]
  [StringEnumRule( TypeInfo(TObjectStatus), Ord(osDestroyed), 'DESTROYED' )]
  TEnumRepresentation = class
    public
      [Key('StatusObj')] FStatus: TObjectStatus;
    end;

  TEnumNoContractRepresentation = class
    public
      [Key('StatusObj')] FStatus: TObjectStatus;
    end;

  TWithStrObj = class
    public
      [Key('logText')] FLog: String;
    end;

  [MarshallOption( SerializeProperty )]
  TObjWithProp = class
    public
      FPrivateField: String;
    public
      [Key('PropertyFieldKey')]
      property PropField: String read FPrivateField write FPrivateField;
    end;

  [MarshallOption( SerializeField )]
  TObjWithField = class
    public
      [Key('FieldKey')]
      FPrivateField: String;
    end;

  [MarshallOption( SerializeField )]
  TObjWithTransient = class
    public
      [Key('accessKey')] FAccessKey: String;
      [Transient] FAccessAuthToken: String;
      [Transient] FAccessRefreshToken: String;
    end;

implementation

end.

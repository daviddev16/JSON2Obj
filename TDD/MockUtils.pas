unit MockUtils;

interface

uses
  Windows,
  System.JSON,
  System.SysUtils,
  System.Classes;

type
  TMockUtils = class
    public
      class function ReadAsJSONObject(ResName: String): TJSONObject;
      class function ReadResource(ResName: String): String;
    end;

implementation

{ TMockUtils }

class function TMockUtils.ReadAsJSONObject(ResName: String): TJSONObject;
begin
  Result := TJSONValue.ParseJSONValue( ReadResource( ResName ) ) as TJSONObject;
end;

class function TMockUtils.ReadResource(ResName: String): String;
var
  LResStream: TResourceStream;
  LBytes: TBytes;
begin
  LResStream := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
  try
    SetLength( LBytes, LResStream.Size );
    LResStream.ReadBuffer( LBytes[0], Length( LBytes ) );
    Result := TEncoding.UTF8.GetString( LBytes );
  finally
    LResStream.Free();
  end;
end;

end.

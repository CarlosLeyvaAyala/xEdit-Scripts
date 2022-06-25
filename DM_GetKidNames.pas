unit GetKidNames;
{
  Hotkey: Ctrl+K

  Gets editor IDs separated by comma for adding to a KID list.
}
interface

uses xEditApi;

implementation

var
  output: TStringList;

function Initialize: Integer;
begin
  output := TStringList.Create;
end;

function Process(e: IInterface): Integer;
begin
  output.Add(EditorID(e));
end;

function Finalize: Integer;
var
  i: Integer;
begin
  AddMessage(output.commaText);
  output.Free;
end;

end.

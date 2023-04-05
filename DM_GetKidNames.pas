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

function IsESL(f: IInterface): Boolean;
begin
  Result := GetElementEditValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL') = 1;
end;

function ActualFixedFormId(e: IInterface): string;
var
  fID, ffID: Cardinal;
begin
  fID := FormID(e);
  if(IsESL(GetFile(e))) then ffID := fID and $FFF
  else ffID := fID and $FFFFFF;
  Result := Lowercase(IntToHex(ffID, 1));
end;

function RecordToStr(e: IInterface): string;
begin
  e := MasterOrSelf(e);
  Result := Format('%s|%s', [
    GetFileName(GetFile(e)),
    ActualFixedFormId(e)
  ]);
end;

function Initialize: Integer;
begin
  output := TStringList.Create;
  AddMessage(#13#10#13#10);
end;

function Process(e: IInterface): Integer;
var
  ed, f, n, s, kidLine: string;
begin
  s := Signature(e);
  if (not ((s = 'ARMO') or (s = 'WEAP') or (s = 'AMMO'))) then Exit;

  ed := EditorID(e);
  f := RecordToStr(e);
  n := DisplayName(e);
  kidLine := Format('%s|%s|%s|%s', [ed, f, s, n]);
  AddMessage(kidLine);
  output.Add(kidLine);
end;

function Finalize: Integer;
begin
  AddMessage(#13#10#13#10);
  output.SaveToFile('Edit Scripts\DM_Items.kid');
  output.Free;
end;

end.

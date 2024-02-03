unit DM_AddEnchantments;
{
    Hotkey: F3
}
interface

uses xEditApi;

implementation

var
    recCount: Integer;
    output: TStringList;
    gFileTo: IInterface;
    rx: TPerlRegex;

function Initialize: Integer;
var 
  i: integer;
  f: IInterface;
begin
  rx := TPerlRegex.Create;
  output := TStringList.Create;
  gFileTo := FileByName('Vokriinator as Enchantments.esp');
end;

// Separates a string by capitals.  
// Example:
//  'BDO BMSNecklaceBlack' => 'BDO BMS Necklace Black' 
function SeparateCapitals(aStr: string): string;
var
  r: TPerlRegex;
begin
  r := TPerlRegex.Create;
  try
    r.RegEx := '((?<=[a-z])[A-Z]|[A-Z](?=[a-z]))';
    r.Subject := aStr;
    r.Replacement := ' \1';
    r.ReplaceAll;
    Result := Trim(r.Subject);
  finally
    r.Free;
  end;
end;

function FileByName(s: string): IInterface;
var
    i: integer;
begin
    Result := nil;

    for i := 0 to FileCount - 1 do 
        if GetFileName(FileByIndex(i)) = s then begin
            Result := FileByIndex(i);
            Exit;
        end;
end;

function FindRecordByEdid(signature, edid, fileName: string): IInterface;
var
    keys: IwbGroupRecord;
    key, k, esp, f: IInterface;
    i: Integer;
begin
    Result := nil;
    esp := FileByName(fileName);

    if not Assigned(esp) then begin 
        AddMessage(Format('Can not find "%s" because "%s" does not exist.', [edid, fileName]));
        Exit;
    end;

    Result := MainRecordByEditorID(GroupBySignature(esp, signature), edid);
    if not Assigned(Result) then 
        AddMessage(Format('"%s" was not found in "%s".', [edid, fileName]));
end;

function Process(e: IInterface): Integer;
var
    v: variant;
//     s: TStringList;
    s, s2, basePath: string;
    isUnique, o, g, parentPerk: IInterface;
    i, j, n, m: Integer;
    r: Real;
    elem, elem2: IwbGroupRecord;
begin
    o := FindRecordByEdid('ARMO', '0AllisGoldBody', '[Melodic] All is Gold.esp');
    AddMessage(Name(o));  
end;

function Finalize: Integer;
var
  i: Integer;
begin
  // AddMessage(output.commaText);
  // for i := 0 to output.Count - 1 do
  //   AddMessage(output[i]);
  output.Free;
  rx.Free
end;
end.

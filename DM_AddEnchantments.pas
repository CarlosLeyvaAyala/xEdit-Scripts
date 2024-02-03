unit DM_AddEnchantments;
{
    Hotkey: F3
}
interface

uses xEditApi;

implementation

var
    recCount: Integer;
    input: TStringList;
    gFileTo: IInterface;
    rx: TPerlRegex;

function Initialize: Integer;
var 
    i: integer;
    f: IInterface;
begin
    rx := TPerlRegex.Create;
    input := TStringList.Create;
    input.LoadFromFile('Edit scripts\input.txt');
    for i := 0 to input.Count - 1 do 
        CreateEnchantment(input[i]);
    // gFileTo := FileByName('Vokriinator as Enchantments.esp');
end;

procedure CreateEnchantment(line: string);
var 
    armor, mgef: IInterface;
begin
    armor := ElementFromLine(line, 'ARMO', 2, 1);
    mgef := ElementFromLine(line, 'MGEF', 4, 3);
    AddMessage(Name(armor));
    AddMessage(Name(mgef));
end;

function ElementFromLine(line, signature: string; rxGroupEdid, rxGroupEsp: integer): IInterface;
const 
    dataRx = '(.*?),(.*?),(.*?),(.*)';
begin
    Result := nil;
    rx.Subject := line;
    rx.RegEx := dataRx;
    rx.Match;
    Result := FindRecordByEdid(signature, rx.Groups[rxGroupEdid], rx.Groups[rxGroupEsp]);
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

// function Process(e: IInterface): Integer;
// var
//     v: variant;
//     s: TStringList;
//     s, s2, basePath: string;
//     isUnique, o, g, parentPerk: IInterface;
//     i, j, n, m: Integer;
//     r: Real;
//     elem, elem2: IwbGroupRecord;
// begin
//     o := FindRecordByEdid('ARMO', '0AllisGoldBody', '[Melodic] All is Gold.esp');
//     AddMessage(Name(o));  
// end;

function Finalize: Integer;
var
  i: Integer;
begin
  // AddMessage(input.commaText);
  // for i := 0 to input.Count - 1 do
  //   AddMessage(input[i]);
  input.Free;
  rx.Free
end;
end.

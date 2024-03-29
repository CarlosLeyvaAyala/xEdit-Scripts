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

const 
    dataRx = '(.*?),(.*?),(.*?),(.*),(\d+),(\d+),(\d+)';

function Initialize: Integer;
var 
    i: integer;
    f: IInterface;
begin
    rx := TPerlRegex.Create;
    input := TStringList.Create;
    input.LoadFromFile('Edit scripts\input.txt');
    
    // Create or clean enchantments first
    for i := 0 to input.Count - 1 do 
        CreateEnchantment(input[i]);

    // Add effects, one by one
    for i := 0 to input.Count - 1 do 
        AddEffects(input[i]);
end;

function NormalizeName(n: string): string;
begin
    Result := StringReplace(n, ' ', '', [rfReplaceAll]);
    Result := StringReplace(Result, '[', '', [rfReplaceAll]);
    Result := StringReplace(Result, ']', '', [rfReplaceAll]);
end;

function GetArmorEnchantmentEdid(e: IInterface): string;
const 
    fmt = 'Ench_%s';
begin
    Result :=  Format(fmt, [EditorID(e)]);
end;

procedure RemoveEffects(e: IInterface); 
var
  o: IInterface;
  i, n: Integer;
begin
  o := ElementByPath(e, 'Effects');
  n := ElementCount(o);

  i := 0;
  repeat 
      RemoveByIndex(o, 0, true);
      Inc(i);
  until (i >= n);
end;

function EnchantmentFromTemplate(newEdid: string): IInterface;
var
  base: IInterface;
begin
  // Copy EnchArmorMuffle "Muffle" [ENCH:00092A77] from Skyrim.esm.
  base := RecordByFormID(FileByIndex(0), $92A77, true);

  Result := wbCopyElementToFile(base, gFileTo, true, false);
  Add(Result, 'ENCH', true);

  // Clean copied template
  SetEditorID(Result, newEdid);
  SetElementEditValues(Result, 'ENIT\Enchant Type', 'Enchantment');
  RemoveEffects(Result);
end;

procedure CreateEnchantment(line: string);
var 
    armor, ench: IInterface;
    enchEdid: string;
begin
    armor := ArmorFromLine(line);
    gFileTo := GetFile(armor);
    
    enchEdid :=  GetArmorEnchantmentEdid(armor);
    ench := FindRecordByEdid('ENCH', enchEdid, GetFileName(gFileTo));
    
    if not Assigned(ench) then begin
        AddMessage('Create ' + enchEdid);
        EnchantmentFromTemplate(enchEdid);
    end
    else begin
        AddMessage('Clean ' + enchEdid);
        RemoveEffects(ench);
    end;
end;

procedure AddEffects(line: string);
var 
    armor, mgef, ench, effects, newEffect: IInterface;
    enchEdid: string;
begin
    armor := ArmorFromLine(line);
    mgef := EffectFromLine(line);
    gFileTo := GetFile(armor);
    enchEdid :=  GetArmorEnchantmentEdid(armor);
    ench := FindRecordByEdid('ENCH', enchEdid, GetFileName(gFileTo));

    SetElementEditValues(armor, 'EITM', Name(ench));

    if GetFile(mgef) <> gFileTo then
        AddMasterIfMissing(
        gFileTo,
        GetFileName( GetFile(mgef) )
    );

    // Create effect
    effects := ElementByPath(ench, 'Effects');
    newEffect := ElementAssign(effects, HighInteger, nil, False);

    // Edit effect
    SetElementEditValues(newEffect, 'EFID', Name(mgef));
    SetElementEditValues(newEffect, 'EFIT\Magnitude', ValueFromLine(line, 5));
    SetElementEditValues(newEffect, 'EFIT\Area', ValueFromLine(line, 6));
    SetElementEditValues(newEffect, 'EFIT\Duration', ValueFromLine(line, 7));
end;

function ArmorFromLine(line: string): IInterface;
begin
    Result := ElementFromLine(line, 'ARMO', 2, 1);
end;

function EffectFromLine(line: string): IInterface;
begin
    Result := ElementFromLine(line, 'MGEF', 4, 3);
end;

function ElementFromLine(line, signature: string; rxGroupEdid, rxGroupEsp: integer): IInterface;
begin
    Result := nil;
    rx.Subject := line;
    rx.RegEx := dataRx;
    rx.Match;
    Result := FindRecordByEdid(signature, rx.Groups[rxGroupEdid], rx.Groups[rxGroupEsp]);
end;

function ValueFromLine(line: string; rxGroupValue: integer): IInterface;
begin
    rx.Subject := line;
    rx.RegEx := dataRx;
    rx.Match;
    Result := rx.Groups[rxGroupValue];
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

function Finalize: Integer;
var
  i: Integer;
begin
  input.Free;
  rx.Free
end;
end.

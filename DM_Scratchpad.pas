unit DM_Scratchpad;
{
    Hotkey: F4
}
interface

// uses xEditApi, 'DM_RenameUtils\Auto', 'DM_RenameUtils\Globals', DM_SelectPlugin;
uses xEditApi;

implementation

var
    recCount: Integer;
    output: TStringList;

function Initialize: Integer;
var 
  i: integer;
  f: IInterface;
begin
  output := TStringList.Create;
  // iterate over loaded plugins
  // for i := 0 to Pred(FileCount) do begin
  //   f := FileByIndex(i);
  //   if HasHeavyArmor(f) then begin
  //     AddMessage(IntToHex(GetLoadOrder(f), 2) + ' ' + GetFileName(f));
  //   end;
  // end;
end;

function IsESL(f: IInterface): Boolean;
begin
  Result := GetElementEditValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL') = 1;
end;
  
function ActualFixedFormId(e: IInterface; toLower, padZeros, padXs: Boolean): string;
var
  fID, ffID: Cardinal;
  num0: Integer;
  xx: string;
begin
  
  fID := FormID(e);
  if(IsESL(GetFile(e))) then begin
    ffID := fID and $FFF;
    xx := 'xxxxx';
    num0 := 3;
  end
  else begin
    ffID := fID and $FFFFFF; 
    xx := 'xx';
    num0 := 6;
  end;

  if not padZeros then num0 := 1;
  if not padXs then xx := '';

  Result := Lowercase(xx + IntToHex(ffID, num0));
end;

function KeywordIndex(e: IInterface; edid: string): Integer;
var
  kwda: IInterface;
  n: integer;
begin
  Result := -1;
  kwda := ElementByPath(e, 'KWDA');
  for n := 0 to ElementCount(kwda) - 1 do
    if GetElementEditValues(LinksTo(ElementByIndex(kwda, n)), 'EDID') = edid then begin
      Result := n;
      Exit;
    end;
end;

procedure RemoveKeyword(e: IInterface; edid: string);
var
    idx: Integer;
begin
    idx := KeywordIndex(e, edid);
    if idx <> -1 then
        RemoveElement(ElementByPath(e, 'KWDA'), idx);
end;

function HasKeyword(e: IInterface; edid: string): boolean;
begin
  Result := KeywordIndex(e, edid) <> -1;
end;

procedure AddKeyword(e: IInterface; edid, fileName: string);
var
    keys: IwbGroupRecord;
    key, k: IInterface;
begin
    if KeywordIndex(e, edid) <> -1 then Exit;

    // Find in Skyrim.esm
    key := MainRecordByEditorID(GroupBySignature(FileByIndex(0), 'KYWD'), edid);
    if Assigned(key) then begin
        k := ElementAssign(ElementByPath(e, 'KWDA'), HighInteger, nil, false);
        SetEditValue(k, Name(key));
    end;
end;

procedure SwapKeyword(e: IInterface; fromKey, toKey: string);
var
    idx: Integer;
    key: IInterface;
begin
    idx := KeywordIndex(e, fromKey);
    if idx <> -1 then begin
        key := ElementByIndex(ElementByPath(e, 'KWDA'), idx);
        AddMessage(toKey);
        SetEditValue(key, toKey);
    end;
end;

procedure ProcessFormlist(e: IInterface);
var
    items, entry: IInterface;
    i: Integer;
begin
    items := ElementByName(e, 'FormIDs');
    for i := 0 to ElementCount(items) - 1 do begin
        entry := ElementByIndex(items, i);
        AddMessage( IntToStr(i) );
        AddMessage( Path(entry) );
        AddMessage(
            GetElementEditValues(LinksTo(entry), 'EDID')
        );
    end;
end;

procedure ConvertToArmorType(e: IInterface; aType: string);
begin
    SetElementEditValues(e, 'BOD2\Armor Type', aType);
end;

procedure ConvertToArmorClothes(e: IInterface);
begin
    SwapKeyword(e, 'ArmorHeavy', 'ArmorClothing [KYWD:0006BBE8]');
    SwapKeyword(e, 'ArmorLight', 'ArmorClothing [KYWD:0006BBE8]');
    ConvertToArmorType(e, 'Clothing');
end;

procedure ConvertToArmorHeavy(e: IInterface);
begin
    SwapKeyword(e, 'ArmorClothing', 'ArmorHeavy [KYWD:0006BBD2]');
    SwapKeyword(e, 'ArmorLight', 'ArmorHeavy [KYWD:0006BBD2]');
    ConvertToArmorType(e, 'Heavy Armor');
end;

procedure ConvertToArmorLight(e: IInterface);
begin
    SwapKeyword(e, 'ArmorClothing', 'ArmorLight [KYWD:0006BBD3]');
    SwapKeyword(e, 'ArmorHeavy', 'ArmorLight [KYWD:0006BBD3]');
    ConvertToArmorType(e, 'Light Armor');
end;

procedure RemoveNonPlayable(e: IInterface);
var
    original, override: variant;
begin
  original := GetElementEditValues(Master(e), 'Record Header\Record Flags\Non-Playable');
  override := GetElementEditValues(HighestOverrideOrSelf(e, $FFFF), 'Record Header\Record Flags\Non-Playable');
  if original = 1 and override = 0 then begin
    AddMessage(GetElementEditValues(e, 'EDID') + ' changed');
    Remove(e);
  end;
end;

procedure AddEmptyKeyword(e: IInterface);
var
    i: Integer;
    n: string;
    l: TStringList;
begin
    l := TStringList.Create;
    try
        l.Add('underwear');
        l.Add('skirt');
        l.Add('shorts');
        l.Add('shoes');
        l.Add('panti');
        l.Add('panty');
        l.Add('top');
        l.Add('dress');
        l.Add('corset');
        l.Add('boot');
        n := GetElementEditValues(e, 'FULL');
        for i := 0 to l.Count - 1 do begin
            if ContainsText(n, l[i]) then begin
                ElementAssign(ElementByPath(e, 'KWDA'), HighInteger, nil, false);   // Empty keyword
                Exit;
            end;
        end;
    finally
        l.Free;
    end;

end;

procedure ExportArmorInfo(e: IInterface);
var 
    edid, full, esp: string;
begin
    edid := GetElementEditValues(e, 'EDID');
    full := GetElementEditValues(e, 'FULL');
    esp := GetFileName(GetFile(Master(e)));
    AddMessage(Format('%s|%s|%s', [full, edid, esp]));
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

procedure MakeIsLocation(e: IInterface);
var
  f, k, s, c: string;
const 
  kFmt = 'Keyword.from(Game.getFormFromFile(0x%s, "Skyrim.esm"))';
  fFmt = 'export const is%s = (l: Location) => l.hasKeyword(%s)';
  cFmt = '/** Checks if a location is of type "%s". */';
begin
  k := Format(kFmt, [ActualFixedFormId(e)]);
  s := StringReplace(EditorID(e), 'LocType', '', [rfReplaceAll]);
  s := StringReplace(EditorID(e), 'LocSet', 'Set', [rfReplaceAll]);
  f := Format(fFmt, [s, k]);
  c := Format(cFmt, [Lowercase(SeparateCapitals(s))]);
  AddMessage(c);
  AddMessage(f);
  AddMessage(' ')
end;

function Process(e: IInterface): Integer;
var
    v: variant;
//     s: TStringList;
    s, s2, basePath: string;
    isUnique, o: IInterface;
    i: Integer;
    r: Real;
const
    race = 'Arg';
    sex = 'Man';
    fitness = 'Fat';
begin
  // Add(e, 'Armature', false);
  // MakeIsLocation(e);
  AddMessage(ActualFixedFormId(e, false, true, true));
  // AddMessage('player.removeitem 6f0' + ActualFixedFormId(e) + ' 1');
    // Inc(recCount);
    // ExportArmorInfo(e);
    // AddMessage(IntToHex(FormID(e), 2));
    // if GetElementNativeValues(e, 'DATA\Float') = 70 then
    // AddMessage(GetElementEditValues(e, 'EDID'));

    // If GetElementNativeValues(e, 'ACBS\Flags\Female') then begin
    //   // SetElementEditValues(e, 'NAM6', RandomRange(92, 96) / 100.0);
    //   // r := GetElementNativeValues(e, 'NAM6');
    //   // SetElementNativeValues(WinningOverride(e),'NAM6', r);
    //   RemoveElement(e, ElementBySignature(e, 'WNAM')) ;
    //   RemoveElement(WinningOverride(e), ElementBySignature(WinningOverride(e), 'WNAM')) ;
    // end;

    // o := WinningOverride(e);
    // if GetFileName(GetFile(o)) = 'Bashed Patch, 0.esp' then
    // Remove(o);

    // AddMessage(IntToStr(recCount));
    // =====================================
    // Rename Maxick textures
    // =====================================
    // if Signature(e) = 'TXST' then begin
    //     Inc(recCount);
    //     // Normal map
    //     s := Format('%s%s_%.2d', [sex, fitness, recCount]);
    //     // s2 := Format('actors\character\Maxick\%s\%s.dds', [race, s]);
    //     basePath := Format('actors\character\Maxick\%s\', [race]);
    //     SetElementEditValues(e, 'Textures (RGB/A)\TX01', basePath + s + '.dds');
    //     SetElementEditValues(e, 'EDID', race + s);

    //     // SetElementEditValues(e, 'Textures (RGB/A)\TX00', 'Actors\Character\Male\MaleBody_1.dds');
    //     // SetElementEditValues(e, 'Textures (RGB/A)\TX03', 'Actors\Character\Male\MaleBody_1_sk.dds');
    //     // SetElementEditValues(e, 'Textures (RGB/A)\TX07', 'Actors\Character\Male\MaleBody_1_S.dds');
    // end
    // else if Signature(e) = 'FLST' then begin
    //     ProcessFormlist(e)
    // end;

    // ============================================================
    // SetElementNativeValues(e, 'DATA\Weight', 5);
    // AddMessage({GetElementEditValues(e, 'FULL') + ' ' + }GetElementEditValues(e, 'DATA\Weight'));

    // ConvertToArmorClothes(e);
    // ConvertToArmorLight(e);
    // ConvertToArmorHeavy(e);
    // AddKeyword(e, 'MagicDisallowEnchanting', 'Skyrim.esm');
    // Add(e, 'EITM', true);
    // AddEmptyKeyword(e);
    // ============================================================

    // InsertElement(ElementByPath(e, 'KWDA'), 0, nil);

    // AddMessage(GetElementEditValues(e, 'BOD2\Armor Type'));

    // v := GetElementNativeValues(e, 'DATA\Value');
    // e := HighestOverrideOrSelf(e, $FFFF);
    // SetElementNativeValues(e, 'DATA\Value', v);

    // SetElementNativeValues(e, 'DATA\Weight', 0);
    // SetElementNativeValues(e, 'DATA - Weight', 0.1);

    // esm, id, nombre, clase, sexo
        // AddMessage(Format('%s|0x%s', [GetFileName(GetFile(e)), Lowercase(IntToHex(FormId(e), 1))]));
        // AddMessage(GetElementEditValues(e, 'ACBS\Flags\Female'));

        // AddMessage(
        //     GetElementEditValues(
        //         LinksTo(ElementByPath(e, 'CNAM')),
        //         'FULL'
        //     )
        // );
        // AddMessage(
        //     GetElementEditValues(                e,                'FULL'            )
        // );

    // AddMessage(GetElementEditValues(e, 'EDID'));

    // AddMessage();
    // AddMessage(GetAutoName(e));
    // RemoveNonPlayable(e);
end;

function Finalize: Integer;
var
  i: Integer;
begin
  // AddMessage(output.commaText);
  // for i := 0 to output.Count - 1 do
  //   AddMessage(output[i]);
  output.Free;
end;

end.

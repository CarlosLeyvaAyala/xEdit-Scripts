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

function Initialize: Integer;
begin
    // Auto_LoadConfig;
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

function Process(e: IInterface): Integer;
var
    v: variant;
//     s: TStringList;
    s, s2, basePath: string;
    isUnique: IInterface;
    i: Integer;
const
    race = 'Arg';
    sex = 'Man';
    fitness = 'Fat';
begin
    Inc(recCount);
    AddMessage(GetElementEditValues(e, 'FULL'));
    AddMessage(GetElementEditValues(e, 'DOFT'));
    AddMessage('=====================');
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

    // ConvertToArmorClothes(e);
    // ConvertToArmorHeavy(e);
    AddKeyword(e, 'MagicDisallowEnchanting', 'Skyrim.esm');
    Add(e, 'EITM', true);
    AddEmptyKeyword(e);

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
begin
    // Auto_UnloadConfig;
end;

end.

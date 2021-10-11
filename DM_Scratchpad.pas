unit DM_Scratchpad;
{
    Hotkey: F4
}

uses xEditApi, 'DM_RenameUtils\Auto', 'DM_RenameUtils\Globals', DM_SelectPlugin;

var
    recCount: Integer;

function Initialize: Integer;
begin
    Auto_LoadConfig;
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
    key: IInterface;
begin
    // Find in Skyrim.esm
    key := MainRecordByEditorID(GroupBySignature(FileByIndex(0), 'KYWD'), edid);
    if Assigned(key) then
    // AddMessage(GetElementEditValues(key, 'EDID'));
        AddElement(ElementByPath(e, 'KWDA'), key);
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
    RemoveKeyword(e, 'ArmorHeavy');
    RemoveKeyword(e, 'ArmorLight');
    // AddKeyword(e, 'ArmorClothing', 'Skyrim.esm');
    ConvertToArmorType(e, 'Clothing');
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
    // AddMessage(original);
    // AddMessage(override);
    // AddMessage(GetElementEditValues(e, 'Record Header\Signature'));
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
    RemoveNonPlayable(e);
end;

function Finalize: Integer;
begin
    Auto_UnloadConfig;
end;

end.

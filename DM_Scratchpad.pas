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

function Process(e: IInterface): Integer;
var
    v: variant;
//     s: TStringList;
    s, s2, basePath: string;
    isUnique: IInterface;
const
    race = 'Hum';
    sex = 'Man';
    fitness = 'Fat';
begin
    // =====================================
    // Rename Maxick textures
    // =====================================
    Inc(recCount);
    // Normal map
    s := Format('%s%s_%.2d', [sex, fitness, recCount]);
    // s2 := Format('actors\character\Maxick\%s\%s.dds', [race, s]);
    basePath := Format('actors\character\Maxick\%s\', [race]);
    SetElementEditValues(e, 'Textures (RGB/A)\TX01', basePath + s + '.dds');
    SetElementEditValues(e, 'EDID', race + s);
    // AddMessage(s2);
    // SetElementEditValues(e, 'Textures (RGB/A)\TX00', 'Actors\Character\Male\MaleBody_1.dds');
    // SetElementEditValues(e, 'Textures (RGB/A)\TX03', 'Actors\Character\Male\MaleBody_1_sk.dds');
    // SetElementEditValues(e, 'Textures (RGB/A)\TX07', 'Actors\Character\Male\MaleBody_1_S.dds');

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
end;

function Finalize: Integer;
begin
    Auto_UnloadConfig;
end;

end.

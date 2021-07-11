unit DM_Scratchpad;
{
    Hotkey: F4
}

uses xEditApi, 'DM_RenameUtils\Auto', 'DM_RenameUtils\Globals', DM_SelectPlugin;


function Initialize: Integer;
begin
    Auto_LoadConfig;
end;

function Process(e: IInterface): Integer;
var
    v: variant;
//     s: TStringList;
begin
    // v := GetElementNativeValues(e, 'DATA\Value');
    // e := HighestOverrideOrSelf(e, $FFFF);
    // SetElementNativeValues(e, 'DATA\Value', v);

    SetElementNativeValues(e, 'DATA\Weight', 0);
    // SetElementNativeValues(e, 'DATA - Weight', 0.1);

    // SelectDirectory('asPromptStringOfSomeKind', '', '', nil);

    // AddMessage();
    // AddMessage(GetAutoName(e));
end;

function Finalize: Integer;
begin
    Auto_UnloadConfig;
end;

end.

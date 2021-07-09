unit DM_Scratchpad;
{
    Hotkey: F4
}

uses xEditApi, 'DM_RenameUtils\Auto', 'DM_RenameUtils\Globals';


function Initialize: Integer;
begin
    Auto_LoadConfig;
end;

function Process(e: IInterface): Integer;
var
    v: variant;
//     s: TStringList;
begin
    v := GetElementNativeValues(e, 'DATA\Value');
    e := HighestOverrideOrSelf(e, $FFFF);
    SetElementNativeValues(e, 'DATA\Value', v);
    // AddMessage();
    // AddMessage(GetAutoName(e));
end;

function Finalize: Integer;
begin
    Auto_UnloadConfig;
end;

end.

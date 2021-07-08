unit DM_Scratchpad;
{
    Hotkey: F4
}

interface
uses xEditApi, 'DM_RenameUtils\Auto', 'DM_RenameUtils\Globals';

implementation

function Initialize: Integer;
begin
    Auto_LoadConfig;
end;

function Process(e: IInterface): Integer;
var
    s: TStringList;
begin
    AddMessage(GetAutoName(e));
end;

function Finalize: Integer;
begin
    Auto_UnloadConfig;
end;

end.

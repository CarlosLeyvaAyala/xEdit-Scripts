unit DM_RemoveCustomBodies;
{
    This script removes records
    Hotkey: F8
}
interface
uses xEditApi;

implementation

// Ignore. This was written to find which record entries use enforced face textures,
// but it couldn't find anything. Left for reference purposes.
// procedure Find(e: IInterface; s: string);
// var
//     i: Integer;
//     elem: IInterface;
// begin
//     if ContainsText(GetEditValue(e), s) then begin
//         AddMessage(
//             Format(
//                 '%s    -    %s',
//                 [
//                     Path(e),
//                     GetEditValue(e)
//                 ]
//             )
//         );
//     end;

//     for i := 0 to ElementCount(e) - 1 do begin
//         Find(ElementByIndex(e, i), s);
//     end;
// end;

// Gets NPC name for logging purposes
function GetName(e: IInterface): string;
begin
    Result := GetEditValue(ElementBySignature(e, 'FULL'));
    if Result = '' then
        Result := GetEditValue(ElementBySignature(e, 'EDID'));
end;

// Sets your default body by removing those enforced by mod authors
procedure SetDefaultBody(e: IInterface);
var
    WNAM, winWNAM, override: IInterface;
begin
    if (Signature(e) <> 'NPC_') then
        Exit;

    WNAM := ElementBySignature(e, 'WNAM');
    override := WinningOverride(e);
    winWNAM := ElementBySignature(override, 'WNAM');
    RemoveElement(e, WNAM);                 // Remove custom body enforced by mod author.
    RemoveElement(override, winWNAM);       // Remove custom body also from the winning esp

    if (WNAM <> nil) or (winWNAM <> nil) then begin
        AddMessage(
            Format( '%s will now use your default body.', [GetName(e)] )
        );
    end;
end;

function Process(e: IInterface): Integer;
var
    s: string;
begin
    // Find(e, 'serana\femalehead');
    SetDefaultBody(e);
end;

end.

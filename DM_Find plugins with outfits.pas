unit DM_FindOutfitPlugins;
{
	Finds all plugins that contain outfits.
}

uses xEditApi;

function Initialize: integer;
var
    i: integer;
    f: IInterface;
begin
    AddMessage(#13#10);
    AddMessage(#13#10);

    // iterate over loaded plugins
    for i := 0 to Pred(FileCount) do begin
        f := FileByIndex(i);
        if Assigned(GroupBySignature(f, 'OTFT')) then
            AddMessage(GetFileName(f));
    end;
    
    AddMessage(#13#10);
    AddMessage(#13#10);
end;

end.

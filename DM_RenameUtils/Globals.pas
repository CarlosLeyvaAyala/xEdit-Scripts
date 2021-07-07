unit Globals;

var
    cfgNames: TStringList;
    cfgFormats: TStringList;

implementation

procedure Auto_LoadConfig;
begin
    cfgNames := TStringList.Create;
    cfgNames.LoadFromFile(ScriptsPath + 'DM_RenameUtils\_Names.ini');
    cfgFormats := TStringList.Create;
    cfgFormats.LoadFromFile(ScriptsPath + 'DM_RenameUtils\_Formats.ini');
end;

procedure Auto_UnloadConfig;
begin
    cfgNames.Free;
    cfgFormats.Free;
end;

end.

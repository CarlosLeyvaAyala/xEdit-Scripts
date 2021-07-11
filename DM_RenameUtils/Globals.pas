unit Globals;

var
    cfgNames: TStringList;
    cfgFormats: TStringList;
const
    gExtDebugInfo = false;

    // Logging strings
    lBigSeparator = '################';
    nl = #13#10;
    lHeadFoot = lBigSeparator + ' %s %s(%s) ' + lBigSeparator;
    lHeadder = nl + lHeadFoot;
    lFooter = nl + lHeadFoot + nl;

procedure LogExtDebug(aMsg: string);
begin
    if gExtDebugInfo then AddMessage(aMsg);
end;

function HasKeywordContaining(e: IInterface; edid: string): string;
var
  kwda: IInterface;
  n: integer;
  kw: string;
begin
  Result := '';
  kwda := ElementByPath(e, 'KWDA');
  for n := 0 to ElementCount(kwda) - 1 do begin
    kw := GetElementEditValues(LinksTo(ElementByIndex(kwda, n)), 'EDID');
    if ContainsStr(kw, edid) then begin
      Result := kw;
      Exit;
    end;
  end;
end;

// Create a sorted list. Mostly used for tags when Auto mode is used
function CreateSortedList: TStringList;
begin
    Result := TStringList.Create;
    Result.Sorted := true;
    Result.NameValueSeparator := sNameValSep;
end;

// Load configuration files
procedure Auto_LoadConfig;
begin
    cfgNames := TStringList.Create;
    cfgNames.LoadFromFile(ScriptsPath + 'DM_RenameUtils\_Names.ini');
    cfgFormats := TStringList.Create;
    cfgFormats.LoadFromFile(ScriptsPath + 'DM_RenameUtils\_Formats.ini');
end;

// Unload configuration files
procedure Auto_UnloadConfig;
begin
    cfgNames.Free;
    cfgFormats.Free;
end;

// Had to do this because aList.Values[index] doesn't work for some reason.
function Value(aList: TStringList; index: Integer): string;
var
    del: string;
begin
    del := aList.Names[index] + sNameValSep;
    Result := StringReplace(aList[index], del, '', [rfReplaceAll])
end;

// A function that Stringlist has always been lacking.
function ValueFromName(aList: TStringList; aName: string): string;
var
    i: Integer;
begin
    i := aList.IndexOfName(aName);
    if i < 0 then
        Result := ''
    else
        Result := Value(aList, i);
end;

end.

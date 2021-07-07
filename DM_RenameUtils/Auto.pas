unit Auto;
interface
uses xEditApi;

implementation

const
    iHOverride = $FFFF;     // Maximum record override to search for. This is way bigger than the maximum SSE supports.
    sNameValSep = '=';

// Had to do this because aList.Values[index] doesn't work for some reason.
function Value(aList: TStringList; index: Integer): string;
var
    del: string;
begin
    del := aList.Names[index] + sNameValSep;
    Result := StringReplace(aList[index], del, '', [rfReplaceAll])
end;

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

function FmtNameValue(aName, aValue: string): string;
begin
    Result := AName + sNameValSep + aValue;
end;

function CreateSortedList: TStringList;
begin
    Result := TStringList.Create;
    Result.Sorted := true;
    Result.NameValueSeparator := sNameValSep;
end;

function GetOriginalName(e: IInterface): string;
begin
    e := MasterOrSelf(e);
    Result := GetElementEditValues(e, 'FULL');
end;

procedure AddOriginalName(e: IInterface; aList: TStringList);
begin
    aList.Add( FmtNameValue('[OriginalName]', GetOriginalName(e)) );
end;

function GenerateName(recType: string; aData: TStringList): string;
var
    i: Integer;
    fmt: string;
begin
    if ValueFromName(aData, '[OriginalName]') = '' then begin
        AddMessage('Unnamed record found. Skipping renaming.');
    end;

    // cfgFormats is defined in Globals
    fmt := ValueFromName(cfgFormats, recType);
    if fmt = '' then begin
        Result := '*** PROGRAMMER''s ERROR ***';
        Exit;
    end;

    Result := fmt;
    for i := 0 to aData.Count - 1 do begin
        Result := StringReplace(
            Result,
            aData.Names[i],
            Value(aData, i),
            [rfReplaceAll]
        );
    end;
end;

// Substitutes tags found for some record to the names the user actually wants.
function ReplaceTags(aList: TStringList): TStringList;
var
    i: Integer;
    s, name, val: string;
    cfg: TStringList;
begin
    // aList.NameValueSeparator := sNameValSep;
    cfg := cfgNames;
    Result := CreateSortedList;

    try
        for i := 0 to aList.Count - 1 do begin
            name := Value(aList, i);
            val := ValueFromName(cfg, Value(aList, i));
            // Had to do this because this stupid bullshit can't directly assign values to aList[i]
            if val <> '' then
                Result.Add(aList.Names[i] + sNameValSep + val)
            else
                Result.Add(aList[i]);
        end;
    finally
        aList.Free;
    end;
end;

// function SpellLevel(aMinSkill: Integer): Integer;
// begin
//     if aMinSkill < 25 then
//         Result := 1
//     else if aMinSkill < 50 then
//         Result := 2
//     else if aMinSkill < 75 then
//         Result := 3
//     else if aMinSkill < 100 then
//         Result := 4
//     else
//         Result := 5
// end;

// function GetSpellData(aSpell: IInterface): TStringList;
// var
//     lvl: Integer;
//     school, minLvl: string;
//     i, mgFx: IInterface;
// begin
//     Result := CreateSortedList;
//     try
//         // Find raw values
//         AddOriginalName(aSpell, Result);

//         // Find data from the Magic Effect
//         aSpell := HighestOverrideOrSelf(aSpell, iHOverride);
//         mgFx :=LinksTo(ElementByPath(aSpell, 'Effects\Effect #0\EFID'));

//         school := Format(
//             '[SpellSchool%s]',
//             [GetElementEditValues(mgFx, 'Magic Effect Data\DATA\Magic Skill')]
//             );
//         lvl := SpellLevel(GetElementEditValues(mgFx, 'Magic Effect Data\DATA\Minimum Skill Level'));

//         Result.Add(FmtNameValue('[SpellSchool]', school));
//         Result.Add(FmtNameValue('[SpellLvlNum]', Format('[SpellLvlNum%d]', [lvl])));
//         Result.Add(FmtNameValue('[SpellLvlName]', Format('[SpellLvlName%d]', [lvl])));

//         Result := ReplaceTags(Result);
//     except
//         on E: Exception do begin
//             Result.Free;
//             raise e;
//         end;
//     end;
// end;

// function GetSpellName(aSpell: IInterface): string;
// begin
//     Result := GenerateName('Spell', GetSpellData(aSpell) );
//     // AddMessage(cfgFormats.Text)
// end;

end.

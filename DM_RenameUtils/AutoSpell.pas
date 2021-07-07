unit AutoSpell;
interface
uses xEditApi;

// function GetSpellName(aSpell: IInterface): TStringList;
implementation

function _SpellLevel(aMinSkill: Integer): Integer;
begin
    if aMinSkill < 25 then
        Result := 1
    else if aMinSkill < 50 then
        Result := 2
    else if aMinSkill < 75 then
        Result := 3
    else if aMinSkill < 100 then
        Result := 4
    else
        Result := 5
end;

function _GetSpellData(aSpell: IInterface): TStringList;
var
    lvl: Integer;
    school, minLvl: string;
    i, mgFx: IInterface;
begin
    Result := CreateSortedList;
    try
        // Find raw values
        AddOriginalName(aSpell, Result);

        // Find data from the Magic Effect
        aSpell := HighestOverrideOrSelf(aSpell, iHOverride);
        mgFx :=LinksTo(ElementByPath(aSpell, 'Effects\Effect #0\EFID'));

        school := Format(
            '[SpellSchool%s]',
            [GetElementEditValues(mgFx, 'Magic Effect Data\DATA\Magic Skill')]
            );
        lvl := _SpellLevel(GetElementEditValues(mgFx, 'Magic Effect Data\DATA\Minimum Skill Level'));

        Result.Add(FmtNameValue('[SpellSchool]', school));
        Result.Add(FmtNameValue('[SpellLvlNum]', Format('[SpellLvlNum%d]', [lvl])));
        Result.Add(FmtNameValue('[SpellLvlName]', Format('[SpellLvlName%d]', [lvl])));

        Result := ReplaceTags(Result);
    except
        on E: Exception do begin
            Result.Free;
            raise e;
        end;
    end;
end;

function GetSpellName(aSpell: IInterface): string;
begin
    Result := GenerateName('Spell', _GetSpellData(aSpell) );
end;

end.

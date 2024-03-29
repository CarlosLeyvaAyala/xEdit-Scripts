unit AutoSpell;
uses xEditApi;

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

// Find data from some Magic Effect
procedure GetMgFxData(mgFx: IInterface; aData: TStringList);
var
    rawLvl, lvl: Integer;
    school, minLvl: string;
begin
    mgFx := HighestOverrideOrSelf(mgFx, iHOverride);
    school := Format(
        '[SpellSchool%s]',
        [GetElementEditValues(mgFx, 'Magic Effect Data\DATA\Magic Skill')]
        );
    rawLvl := GetElementEditValues(mgFx, 'Magic Effect Data\DATA\Minimum Skill Level');
    lvl := _SpellLevel(rawLvl);

    AddTag(aData, '[MagicFxName]', GetElementEditValues(mgFx, 'FULL'));
    AddTag(aData, '[SpellSchool]', school);
    AddTag(aData, '[SpellLvl]', IntToStr(rawLvl));
    AddTag(aData, '[SpellLvlNum]', Format('[SpellLvlNum%d]', [lvl]));
    AddTag(aData, '[SpellLvlName]', Format('[SpellLvlName%d]', [lvl]));
end;

// Find data from the Magic Effect for this spell
procedure _GetSpellMgFxData(aSpell: IInterface; aData: TStringList);
var
    mgFx: IInterface;
begin
    aSpell := HighestOverrideOrSelf(aSpell, iHOverride);
    mgFx :=LinksTo(ElementByPath(aSpell, 'Effects\Effect #0\EFID'));
    GetMgFxData(mgFx, aData);
end;

// Get all spell data. This is the heart of this functionality.
function _GetSpellData(aSpell: IInterface): TStringList;
var
    lvl: Integer;
    school, minLvl: string;
    mgFx: IInterface;
begin
    Result := CreateSortedList;
    try
        // Find raw values
        AddName(Result, aSpell);
        AddEdid(Result, aSpell);
        _GetSpellMgFxData(aSpell, Result);
    except
        on E: Exception do begin
            Result.Free;
            raise e;
        end;
    end;
end;

// Gets data with tags replaced. Used by spellbooks
function GetSpellDataForParent(aSpell: IInterface): TStringList;
begin
    Result := _GetSpellData(aSpell);
    ReplaceTagName(Result, tagName, tagSpellName);
    ReplaceTagName(Result, tagOriginalName, tagSpellOriginalName);
end;

// This is the function the clients will be using
function GetSpellName(aSpell: IInterface): string;
begin
    if Signature(aSpell) <> 'SPEL' then Exit;       // Safeguard
    Result := GenerateName('Spell', _GetSpellData(aSpell) );
end;

end.

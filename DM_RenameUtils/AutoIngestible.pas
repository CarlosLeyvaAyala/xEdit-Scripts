unit AutoIngestible;
uses xEditApi, 'AutoSpell';

procedure _AddIngestibleCommonTags(aList: TStringList; aAlch: IInterface);
begin
    AddName(aList, aAlch);
    AddEdid(aList, aAlch);
    AddEdidLvl(aList, aAlch);
    AddTag(aList, '[IngestibleUniqueName]', _GetUniqueName(aAlch));
end;

procedure _AddIngestibleType(aList: TStringList; iType: string);
begin
    AddTag(aList, '[IngestibleType]', iType);
end;

function _GetPotionData(aAlch: IInterface): TStringList;
var
    spell: IInterface;
begin
    Result := CreateSortedList;

    try
        spell := LinksTo(ElementByPath(aAlch, 'DATA\Spell'));
        // Get inherited spell tags
        Result := GetSpellDataForParent(spell); // Doesn't work because paths are not compatible
        // Generated spell name
        // AddTag(Result, tagSpell, GenerateName('Spell', _GetSpellData(spell) ));

        _AddIngestibleCommonTags(Result, aAlch);
        _AddIngestibleType(Result, '[Potion]')

    except
        on E: Exception do begin
            Result.Free;
            raise e;
        end;
    end;
end;

function _IsFood(aAlch: IInterface): Boolean;
begin
    Result := GetElementNativeValues(aAlch, 'ENIT\Flags\Food Item');
end;

function _IsPoison(aAlch: IInterface): Boolean;
begin
    Result := GetElementNativeValues(aAlch, 'ENIT\Flags\Poison');
end;

// This is the function the clients will be using
function GetIngestibleName(aAlch: IInterface): string;
begin
    if Signature(aAlch) <> 'ALCH' then Exit;       // Safeguard
    
    if _IsFood(aAlch) then begin
        Result := GetElementEditValues(aAlch, 'FULL');
        AddMessage('Food items auto renaming still not supported');
    end
    else if _IsPoison(aAlch) then begin
        Result := GetElementEditValues(aAlch, 'FULL');
        AddMessage('Poison auto renaming still not supported');
    end
    else
        // Result := GetElementEditValues(aAlch, 'FULL');
        Result := GenerateName('Potion', _GetPotionData(aAlch));
end;

end.

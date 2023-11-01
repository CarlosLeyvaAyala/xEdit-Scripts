unit AutoBook;
uses xEditApi, 'AutoSpell';

// Get all spell data. This is the heart of this functionality.
function _GetSpellbookData(aBook: IInterface): TStringList;
var
    spell: IInterface;
begin
    Result := CreateSortedList;
    try
        spell := LinksTo(ElementByPath(aBook, 'DATA\Spell'));
        // Get inherited spell tags
        Result := GetSpellDataForParent(spell);
        // Generated spell name
        AddTag(Result, tagSpell, GenerateName('Spell', _GetSpellData(spell) ));
        AddName(Result, aBook);
        AddEdid(Result, aBook);
    except
        on E: Exception do begin
            Result.Free;
            raise e;
        end;
    end;
end;

function _IsSpellBook(aBook: IInterface): Boolean;
begin
    Result := GetElementNativeValues(aBook, 'DATA\Flags\Teaches Spell');
end;

// This is the function the clients will be using
function GetBookName(aBook: IInterface): string;
begin
    if Signature(aBook) <> 'BOOK' then Exit;       // Safeguard
    if _IsSpellBook(aBook) then
        Result := GenerateName('Spellbook', _GetSpellbookData(aBook))
    else
        Result := GetElementEditValues(aBook, 'FULL');
end;

end.

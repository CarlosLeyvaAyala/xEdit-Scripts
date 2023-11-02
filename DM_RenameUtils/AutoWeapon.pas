unit AutoWeapon;

// Removes certain words from the name
function _GetSimpleName(weaponName: string): string;
var
  i: Integer;
begin
    Result := weaponName;

    for i := 0 to cleanWeapon.Count - 1 do 
        Result := StringReplace(Result, cleanWeapon[i], '', [rfReplaceAll]);

    Result := Trim(Result);
end;

function _GetWeapSimpleName(aWeap: IInterface): string;
begin
    aWeap := MasterOrSelf(aWeap);
    Result := _GetSimpleName( GetElementEditValues(aWeap, 'FULL') );
end;

procedure GetEnchantmentData(aEnchant: IInterface; aData: TStringList);
begin
  AddTag(aData, '[EnchantName]', GetElementEditValues(aEnchant, 'FULL'));
  GetMgFxData(LinksTo(ElementByPath(aEnchant, 'Effects\Effect #0\EFID')), aData);
end;

function _GetMagicWeaponLvl(aWeap: IInterface): Integer;
var
  r: TPerlRegex;
begin
  r := TPerlRegex.Create;
  try
    r.RegEx := '(\d+$)';
    r.Subject := EditorID(aWeap);
    if r.Match then 
        Result := StrToInt(r.Groups[1])
    else
        Result := 0;
  finally
    r.Free;
  end;
end;

function _GetMagicWeaponSimpleName(aWeap: IInterface): string;
var 
  weapName: string;
begin
  weapName := GetElementEditValues(MasterOrSelf(aWeap), 'FULL');
  Result := RegexReplace(weapName, ' of .*$', ''); // Clean enchantment name
  Result := _GetSimpleName(Result);
end;

function _GetMagicWeaponData(aWeap: IInterface): TStringList;
var
  enchant: IInterface;
begin
  Result := CreateSortedList;
  try
    // Find raw values
    AddName(Result, aWeap);
    AddEdid(Result, aWeap);
    // Cleans everything after 'Sword of', 'Staff of'...
    AddTag(Result, '[WeapSimpleName]', _GetMagicWeaponSimpleName(aWeap));
    AddTag(Result, '[WeaponType]', HasKeywordContaining(aWeap, 'WeapType'));
    AddTag(Result, '[WeaponLvlNum]', Format('[WeaponLvlNum%d]', [_GetMagicWeaponLvl(aWeap)]));
    GetEnchantmentData(LinksTo(ElementBySignature(aWeap, 'EITM')), Result);
    Result := ReplaceTags(Result);
  except
    on E: Exception do begin
      Result.Free;
      raise e;
    end;
  end;
end;

function _GetWeaponData(aWeap: IInterface): TStringList;
begin
  Result := CreateSortedList;
  try
    // Find raw values
    AddName(Result, aWeap);
    AddEdid(Result, aWeap);
    AddTag(Result, '[WeapSimpleName]', _GetWeapSimpleName(aWeap));
    AddTag(Result, '[WeaponType]', HasKeywordContaining(aWeap, 'WeapType'));
    Result := ReplaceTags(Result);
  except
    on E: Exception do begin
      Result.Free;
      raise e;
    end;
  end;
end;

function GetWeaponName(aWeap: IInterface): string;
var
  mgFx: IInterface;
begin
  if Assigned(ElementBySignature(aWeap, 'EITM')) then
    Result := GenerateName('WeaponMagical', _GetMagicWeaponData(aWeap) )
  else
    Result := GenerateName('Weapon', _GetWeaponData(aWeap));
    // Result := GetElementEditValues(aWeap, 'FULL');
end;

end.

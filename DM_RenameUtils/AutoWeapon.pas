unit AutoWeapon;

function _GetCleanableWeapWords: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('Sword');
  Result.Add('Staff');
  Result.Add('Dagger');
  Result.Add('War Axe');
  Result.Add('Waraxe');
  Result.Add('Warhammer');
  Result.Add('Mace');
  Result.Add('Greatsword');
  Result.Add('Battleaxe');
  Result.Add('Bow');
  Result.Add('Axe');
end;

// Removes certain words from the name
function _GetSimpleName(weaponName, cleaningFmt: string): string;
var
  i: Integer;
  toClean: TStringList;
  r: TPerlRegex;
begin
  Result := weaponName;
  r := TPerlRegex.Create;
  try
    toClean := _GetCleanableWeapWords;
    for i := 0 to toClean.Count -1 do begin
      // Cleans everything after the found word
      r.RegEx := Format(cleaningFmt, [ toClean[i] ]);
      r.Subject := Result;
      r.Replacement := '';
      r.ReplaceAll;
      Result := Trim(r.Subject);
    end;
  finally
    r.Free;
    toClean.Free;
  end;
end;

function _GetWeapSimpleName(aWeap: IInterface; cleaningFmt: string): string;
begin
  Result := _GetSimpleName(GetElementEditValues(MasterOrSelf(aWeap), 'FULL'), cleaningFmt);
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
  Result := _GetSimpleName(Result, '(%s)');
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
    AddTag(Result, '[WeapSimpleName]', _GetWeapSimpleName(aWeap, '(%s)'));
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

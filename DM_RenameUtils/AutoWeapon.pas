unit AutoWeapon;

function _GetCleanableWeapWords: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('Sword');
  Result.Add('Staff');
  Result.Add('War Axe');
  Result.Add('Waraxe');
  Result.Add('Greatsword');
  Result.Add('Battleaxe');
  Result.Add('Bow');
end;

// Cleans everything after 'Sword of', 'Staff of'...
function _GetMagWeapSimpleName(aWeap: IInterface): string;
var
  i: Integer;
  toClean: TStringList;
  r: TPerlRegex;
begin
  aWeap := MasterOrSelf(aWeap);
  Result := GetElementEditValues(aWeap, 'FULL');
  r := TPerlRegex.Create;
  try
    toClean := _GetCleanableWeapWords;
    for i := 0 to toClean.Count -1 do begin
      // Cleans everything after the found word
      r.RegEx := Format('(%s of.*)', [ toClean[i] ]);
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

procedure GetEnchantmentData(aEnchant: IInterface; aData: TStringList);
begin
  AddTag(aData, '[EnchantName]', GetElementEditValues(aEnchant, 'FULL'));
  GetMgFxData(LinksTo(ElementByPath(aEnchant, 'Effects\Effect #0\EFID')), aData);
end;

function _GetMagicWeaponData(aWeap: IInterface): TStringList;
var
//   lvl: Integer;
//   school, minLvl: string;
  enchant: IInterface;
begin
  Result := CreateSortedList;
  try
    // Find raw values
    AddName(Result, aWeap);
    AddEdid(Result, aWeap);
    AddTag(Result, '[WeapSimpleName]', _GetMagWeapSimpleName(aWeap));
    AddTag(Result, '[WeaponType]', HasKeywordContaining(aWeap, 'WeapType'));
    GetEnchantmentData(LinksTo(ElementBySignature(aWeap, 'EITM')), Result);
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
    Result := GetElementEditValues(aWeap, 'FULL');
end;

end.

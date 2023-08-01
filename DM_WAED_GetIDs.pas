unit DM_EC_GetIDs;
{
  Hotkey: Ctrl+Shift+F5
}

uses xEditApi, SysUtils, StrUtils;

var
  output, output2: TStringList;

const
  enchFmt =
'  "%s": {'#13#10
'    "enchantName": "%s",'#13#10
'    "enchantId": "%s"'#13#10
'  },';

  fullFmt =
'  {'#13#10
'    "newItemName": "%s",'#13#10
'    "itemName": "%s",'#13#10
'    "itemId": "%s",'#13#10 +
'    "enchantName": "%s",'#13#10
'    "enchantId": "%s"'#13#10
'  },';

function IsESL(f: IInterface): Boolean;
begin
  Result := GetElementEditValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL') = 1;
end;

function ActualFixedFormId(e: IInterface): string;
var
  fID, ffID: Cardinal;
begin
  fID := FormID(e);
  if(IsESL(GetFile(e))) then ffID := fID and $FFF
  else ffID := fID and $FFFFFF;
  Result := Lowercase(IntToHex(ffID, 1));
end;

function RecordToStr(e: IInterface): string;
begin
  Result := Format('%s|0x%s', [
    GetFileName(GetFile(e)),
    ActualFixedFormId(e)
  ]);
end;

// TODO: DELETE
function GetId(e: IInterface): string;
begin
  Result := '';
  if Assigned(e) then
    Result := RecordToStr(MasterOrSelf(e));
end;

function GetUniqueId(e: IInterface): string;
begin
  Result := '';
  if Assigned(e) then
    Result := RecordToStr(MasterOrSelf(e));
end;

function GetName(e: IInterface): string;
begin
  Result := '';
  if Assigned(e) then
    Result := GetElementEditValues(e, 'FULL');
end;

// TODO: DELETE
function GetWeaponArmor(e: IInterface): string;
var
  rName: string;
  ench: Variant;
begin
  ench := LinksTo(ElementByPath(e, 'EITM'));
  rName := GetName(e);
  Result := Format(fullFmt, [rName, rName, GetId(e), GetName(ench), GetId(ench)]);

  if Assigned(ench) then
    output2.Add(GetEnchant(ench));
end;

// TODO: DELETE
function GetEnchantMagnitude(e: IInterface): string;
var
  i, n: Integer;
  fxs, fx, ench: IInterface;
  mag: Real;
  mags: TStringList;
  eName: string;
const
  fmt = '%s (%g)';
begin
  mags := TStringList.Create;

  try
    fxs := ElementByPath(e, 'Effects');
    n := ElementCount(fxs);
    for i := 0 to n - 1 do begin
      fx := ElementByIndex(fxs, i);
      ench := LinksTo(ElementByPath(fx, 'EFID'));
      eName := GetElementEditValues(ench, 'FULL');
      mag := GetElementNativeValues(fx, 'EFIT\Magnitude');
      mags.Add(Format(fmt, [eName, mag]));
    end;
    Result := StringReplace(mags.CommaText, ',', ', ', [rfReplaceAll]);
    Result := StringReplace(Result, '"', '', [rfReplaceAll]);
  finally
    mags.Free;
  end;
end;

// TODO: DELETE
function GetEnchantName(e: IInterface): string;
var
  r, edid: string;
begin
  r := GetName(e);
  edid := EditorID(e);

  if ContainsText(edid, '01') then r := r + ' I'
  else if ContainsText(edid, '02') then r := r + ' II'
  else if ContainsText(edid, '03') then r := r + ' III'
  else if ContainsText(edid, '04') then r := r + ' IV'
  else if ContainsText(edid, '05') then r := r + ' V'
  else if ContainsText(edid, '06') then r := r + ' VI';
  
  Result := r;
end;

// TODO: DELETE
function GetEnchant(e: IInterface): string;
const
  nameFmt = '%s (%s)';
var
  nm: string;
begin
  nm := GetEnchantMagnitude(e);
  // nm := Format(nameFmt, [GetName(e), GetEnchantMagnitude(e)]);
  Result := Format(enchFmt, [GetEnchantName(e), nm, GetId(e)]);
end;

function GetObjectFxData(e: IInterface): string;
var
    i, n: Integer;
    fxs, fx, ench: IInterface;
    uid, eName, edid, a, d ,m: string;
const
    fmt = '%s;;%s;;%s;;%s;;%s;;%s;;;';
begin
    Result := '';

    fxs := ElementByPath(e, 'Effects');
    n := ElementCount(fxs);
    for i := 0 to n - 1 do begin
        fx := ElementByIndex(fxs, i);
        ench := LinksTo(ElementByPath(fx, 'EFID'));
        
        uid := GetUniqueId(ench);
        edid := EditorID(ench);
        eName := GetElementEditValues(ench, 'FULL');
        a := GetElementEditValues(fx, 'EFIT\Area');
        d := GetElementEditValues(fx, 'EFIT\Duration');
        m := GetElementEditValues(fx, 'EFIT\Magnitude');

        Result := Result + Format(fmt, [uid, edid, eName, a, d, m]);
    end;

    Result := DeleteByRegex(Result, ';;;$');
end;

// Gets enchantment data used by the Skyrim Item Manager
function GetEnchantSIM(e: IInterface): string;
const
  fmt = '%s;;;%s;;;%s;;;%s';
var
  nm: string;
begin
  Result := Format(fmt, [GetId(e), EditorID(e), GetName(e), GetObjectFxData(e)]);
end;

function Process(e: IInterface): Integer;
var
  s: string;
begin
  s := '';
  if Signature(e) = 'ARMO' then s := GetWeaponArmor(e)
  else if Signature(e) = 'ENCH' then s := GetEnchant(e) + #13#10#13#10 + GetEnchantSIM(e);

  if s <> '' then output.Add(s)
end;

function DeleteLastComma(s: string): string;
var
  l: Integer;
begin
  Result := s;

  l := Length(s) - 1;
  if RightStr(s, 1) = ',' then Result := LeftStr(s, l);
end;

procedure PrintOutput(l: TStringList);
var
  s: string;
begin
  s := DeleteLastComma(TrimRight(l.Text));
  AddMessage(s);
end;

function Initialize: Integer;
begin
  output := TStringList.Create;
  output2 := TStringList.Create;
end;

function Finalize: Integer;
begin
  PrintOutput(output);
  if output2.Text <> '' then begin
    AddMessage(#13#10#13#10);
    PrintOutput(output2);
  end;

  output.Free;
  output2.Free;
end;

function DeleteByRegex(subject, regex: string): string;
var
    r: TPerlRegex;
begin
    r := TPerlRegex.Create;
    try
        r.Subject := subject;
        r.RegEx := regex;
        r.Replacement := '\1';
        r.ReplaceAll;
        Result := r.Subject;
    finally
        r.Free;
    end;
end;

end.

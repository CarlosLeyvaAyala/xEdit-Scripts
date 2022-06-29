unit DM_EC_GetIDs;
{
    Hotkey: Ctrl+Shift+F5
	
	****************************************************
	*** THIS IS AN SSEDIT SCRIPT, NOT A DELPHI FILE! ***
	****************************************************
	
	Gets a list of NPCs in a format usable for Max Sick
	Gains NPC database. 
	Outputs an *.sql file to "SSEdit\Edit Scripts\".
	
	Change the hotkey to your preference.
}

uses xEditApi, SysUtils, StrUtils;

var
  output: TStringList;

const 
  enchFmt = 
'    "enchantName": "%s",'#13#10
'    "enchantId": "%s"'#13#10;

  fullFmt = 
'  {'#13#10
'    "newItemName": "%s",'#13#10
'    "itemName": "%s",'#13#10
'    "itemId": "%s",'#13#10 +
'    "enchantName": "",'#13#10
'    "enchantId": ""'#13#10
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

function GetWeaponArmor(e: IInterface): string;
var
  id, rName: string;
begin
  id := RecordToStr(MasterOrSelf(e));
  rName := GetElementEditValues(e, 'FULL');
  Result := Format(fullFmt, [rName, rName, id]);
end;

function GetEnchant(e: IInterface): string;
var
  id, rName: string;
begin
  id := RecordToStr(MasterOrSelf(e));
  rName := GetElementEditValues(e, 'FULL');
  Result := Format(enchFmt, [rName, id]);
end;

function Process(e: IInterface): Integer;
var 
  s: string;
begin
  s := '';
  if Signature(e) = 'ARMO' then s := GetWeaponArmor(e)
  else if Signature(e) = 'ENCH' then s := GetEnchant(e);

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

function Initialize: Integer;
begin
  output := TStringList.Create;
end;

function Finalize: Integer;
var
  s: string;
begin
  s := DeleteLastComma(TrimRight(output.Text));
  AddMessage(s);
  output.Free;
end;

end.

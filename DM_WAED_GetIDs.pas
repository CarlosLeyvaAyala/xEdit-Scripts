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

const 
  enchFmt = 
'    "enchantName": "%s",'#13#10
'    "enchantId": "%s"'#13#10;

  fullFmt = 
'  {'#13#10
'    "itemName": "%s",'#13#10
'    "itemId": "%s",'#13#10 +
'    "enchantName": "",'#13#10
'    "enchantId": ""'#13#10
'  }';

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

function GetWeaponArmor(e: IInterface): Integer;
var
  id, rName: string;
begin
  rName := RecordToStr(MasterOrSelf(e));
  id := GetElementEditValues(e, 'FULL');
  AddMessage(Format(fullFmt, [id, rName]));
end;

function GetEnchant(e: IInterface): Integer;
var
  id, rName: string;
begin
  rName := RecordToStr(MasterOrSelf(e));
  id := GetElementEditValues(e, 'FULL');
  AddMessage(Format(enchFmt, [id, rName]));
end;

function Process(e: IInterface): Integer;
begin
  if Signature(e) = 'ARMO' then GetWeaponArmor(e)
  else if Signature(e) = 'ENCH' then GetEnchant(e);
end;

end.

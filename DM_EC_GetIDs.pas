unit DM_EC_GetIDs;
{
    Hotkey: Ctrl+F5
	
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
  outputs: TStringList;

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

function Initialize: integer;
begin
  outputs := TStringList.Create;
end;

function Finalize: Integer;
var 
  i: Integer;
begin
  AddMessage(Format(
    '%s',
    [StringReplace(outputs.DelimitedText, '"""', '"', [rfReplaceAll])]
  ));

  outputs.Free;
end;

function RecordToStr(e: IInterface): string;
begin
  Result := Format('"%s|0x%s"', [
    GetFileName(GetFile(e)),
    ActualFixedFormId(e)
  ]);
end;

function Process(e: IInterface): Integer;
begin
  outputs.Add(RecordToStr(MasterOrSelf(e)));
end;

end.

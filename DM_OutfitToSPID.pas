unit DM_OutfitToSPID;
{
  Converts selected outfits to SPID records.

    Hotkey: Ctrl+F4
}

uses xEditApi;

procedure Separate;
begin
  AddMessage(#13#10#13#10);
end;

function Initialize: Integer;
begin
  Separate;
end;

function Finalize: Integer;
begin
  Separate;
end;

function OutfitFmt(e: IInterface): string;
var
  iFile: IInterface;
  fName: string;
begin
  iFile := GetFile(e);
  fName := GetFileName(iFile);
  Result := Format('Outfit = 0x%s~%s|', [ActualFixedFormId(e), fName]);
end;

function NpcFmt(e: IInterface): string;
var
  otft: IInterface;
begin
  otft := LinksTo(ElementBySignature(e, 'DOFT')); 
  Result := OutfitFmt(otft) + GetElementEditValues(e, 'FULL');
end;

function Process(e: IInterface): Integer;
var
  s: string;
begin
  if Signature(e) = 'OTFT' then AddMessage(OutfitFmt(e))
  else if Signature(e) = 'NPC_' then AddMessage(NpcFmt(e));
end;

function ActualFixedFormId(e: IInterface): string;
var
  fileOrder: Integer;
  sFormId, sFile: string;
begin
  fileOrder := GetLoadOrder(GetFile(e));
  sFormId := IntToHex(FormID(e), 1);
  if fileOrder > 0 then begin
    sFile := IntToHex(fileOrder, 1);
    sFormId := RightStr(sFormId, Length(sFormId) - Length(sFile));
  end;
  Result := Uppercase(IntToHex(StrToInt('$' + sFormId), 1));
end;

end.

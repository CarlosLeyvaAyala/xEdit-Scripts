unit DM_GetFemForms_Botox;
{
Hotkey: F6
}

interface
uses xEditApi;

implementation

// Performs tests so the record can be considered valid.
// MODIFY THIS
function Tests(e: IInterface): Boolean;
begin
  Result := true;
  Result := Result and ContainsText(GetEditValue(ElementBySignature(e, 'RNAM')), 'vampire')
end;

function Initialize: integer;
begin
end;

function GetFormId(e: IInterface): string;
begin
  Result := RightStr(IntToHex(FixedFormID(e), 1), 4)
end;

function IsFem(e: IInterface): Boolean;
begin
  Result := GetElementEditValues(e, 'ACBS\Flags\Female') = '1';
end;

function GenBatchMove(e: IInterface): string;
begin
  Result := Format('robocopy "%%s%%" "%%d%%" *%s.* /S', [GetFormId(e)])
end;

function Process(e: IInterface): Integer;
var
  sig: string;
  i: Integer;
begin
  sig := Signature(e);

  if sig = 'NPC_' then begin
    if IsFem(e) and Tests(e) then begin
      AddMessage( ':: ' + GetEditValue(ElementBySignature(e, 'FULL')) );
      // AddMessage( ':: ' + GetEditValue(ElementBySignature(e, 'RNAM')) );
      AddMessage( GenBatchMove(e) );
    end;
  end;
end;

function Finalize: Integer;
begin
end;

end.

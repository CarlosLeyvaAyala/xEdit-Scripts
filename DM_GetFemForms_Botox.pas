unit DM_GetFemForms_Botox;
{
Hotkey: F6
}

interface
uses xEditApi;

implementation

var
  addedRecs: Integer;

// Performs tests so the record can be considered valid.
// MODIFY THIS to suit your needs.
function Tests(e: IInterface): Boolean;
begin
  Result := true;
  Result := Result and ContainsText(GetEditValue(ElementBySignature(e, 'RNAM')), 'vampire')
end;

function GetFormId(e: IInterface): string;
begin
  Result := RightStr(IntToHex(FixedFormID(e), 1), 4)
end;

function IsFem(e: IInterface): Boolean;
begin
  Result := GetElementEditValues(e, 'ACBS\Flags\Female') = '1';
end;

procedure LogName(e: IInterface);
var
  n: string;
begin
  n := GetEditValue(ElementBySignature(e, 'FULL'));
  if n = '' then
    n := Format('Unnamed NPC [%s]', [GetFormId(e)]);
  AddMessage(
    Format('%s was added to patch', [n])
  );
end;

function Initialize: integer;
begin
  addedRecs := 0;
  // Crear archivo esl AddNewFileName('Botox SE - ', true)
  // Agregar records
end;

function ReplacePath(e: IInterface; aPath: string): string;
var
  fn: string;
begin
  fn := GetElementEditValues(e, aPath);
  fn := StringReplace(
    fn,
    'actors\character\character assets\Botox\Hair\',
    'KS Hairdo''s\',
    [rfReplaceAll, rfIgnoreCase]
  );
  Result := StringReplace(fn, 'Human\', '', [rfReplaceAll, rfIgnoreCase]);
  SetElementEditValues(e, aPath, Result)
end;

procedure RenamePath(e: IInterface);
begin
  AddMessage(GetEditValue(ElementBySignature(e, 'FULL')));
  AddMessage(ReplacePath(e, 'Model\MODL'));
  // RemoveElement(e, 'Parts')      // Process hairlines
  // AddMessage(ReplacePath(e, 'Parts\Part #0\NAM1'));    // Process hairs
end;

function Process(e: IInterface): Integer;
begin
  if (Signature(e) = 'NPC_') and IsFem(e) and Tests(e) then begin
    addedRecs := addedRecs + 1;
    LogName(e);
    // Agregar HighestOverrideOrSelf al archivo
  end;

  if (Signature(e) = 'HDPT') then begin
    RenamePath(e);
  end;
end;

function Finalize: Integer;
begin
  AddMessage(Format('Finished. %d records added.', [addedRecs]));
end;

// function GenBatchMove(e: IInterface): string;
// begin
//   Result := Format('robocopy "%%s%%" "%%d%%" *%s.* /S', [GetFormId(e)])
// end;

// Old method. Don't use this anymore.
// function GenRobocopy(e: IInterface): string;
// begin
//   AddMessage( ':: ' + GetEditValue(ElementBySignature(e, 'FULL')) );
//   AddMessage( GenBatchMove(e) );
// end;

end.

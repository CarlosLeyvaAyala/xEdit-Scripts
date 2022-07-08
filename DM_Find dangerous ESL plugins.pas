{
  Find ESL plugins that can corrupt save games and cause crashes.
}
unit FindDangerousESL;

const
  // Change to <false> to display only errors.
  displayNoErrorsFound = true;

  // ************************************************
  // * Don't edit values below here
  // ************************************************
  iESLMaxRecords = $800;  // max possible new records in ESL

  AnalysisSuccess = 0;
  HasTooManyRecords = 2;
  HasOtherError = 3;

var 
  errors: TStringList;

function CheckRecords(f: IInterface): Integer;
var
  i: Integer;
  e: IInterface;
  RecCount, RecMaxFormID, fid: Cardinal;
  msg: string;
const 
  overflowFmt = '%s > "%s": %s';
  manyRecsFmt = 'Plugin has too many records and can not ever be turned into an ESL.';
begin
  Result := AnalysisSuccess;

  for i := 0 to Pred(RecordCount(f)) do begin
    e := RecordByIndex(f, i);
    
    // override doesn't affect ESL
    if not IsMaster(e) then Continue;
    
    Inc(RecCount);    
    if RecCount > iESLMaxRecords then begin
      errors.Add(manyRecsFmt);
      Result := HasTooManyRecords;
      Exit;
    end;
    
    msg := Check(e);
    if msg <> '' then begin
      errors.Add(Format(overflowFmt, [Signature(e), EditorID(e), msg]));
      Result := HasOtherError;
    end;     
  end;
end;

procedure AddSeparator;
const
  sep = '**********************************************';
begin
  if displayNoErrorsFound then AddMessage(sep)
  else AddMessage(' ');
end;

procedure DisplayAnalysisMessage(espName: string; RecordAnalysis: Integer);
var
  msg: string;
  i: Integer;
  ctdFriendly: Boolean;
const 
  corruption = #13#10'If you continue to use this plugin, it will surely lead to CTDs.';
  successFmt = '%s has no errors.';
  errorsFmt = '%s has errors:';
  errorFmt = '    %s';
begin
  if RecordAnalysis = AnalysisSuccess then begin
    if displayNoErrorsFound then 
      AddMessage(Format(successFmt, [espName]));
    Exit;
  end;

  ctdFriendly := false;

  AddSeparator;
  AddMessage(Format(errorsFmt, [espName]));

  for i := 0 to errors.Count - 1 do begin
    msg := errors[i];
    ctdFriendly := ctdFriendly or 
      ContainsText(msg, 'invalid for a light module') or 
      ContainsText(msg, 'too many records');

    AddMessage(Format(errorFmt, [msg]));
  end;

  if ctdFriendly then AddMessage(corruption);

  AddSeparator;
end;

procedure CheckForESL(f: IInterface);
var 
  msg: string;
begin
  errors.Clear;

  msg := Check(f);
  if msg <> '' then
    errors.Add(msg);

  DisplayAnalysisMessage(Name(f), CheckRecords(f));
end;

function IsESL(f: IInterface): Boolean;
begin
  Result := GetElementEditValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL') = 1;
end;
  
function Initialize: integer;
var
  i: integer;
  f: IInterface;
begin
  errors := TStringList.Create;

  // iterate over loaded plugins
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if (IsESL(f)) then CheckForESL(f);
  end;
end;

function Finalize: Integer;
begin
  errors.Free;
end;

end.

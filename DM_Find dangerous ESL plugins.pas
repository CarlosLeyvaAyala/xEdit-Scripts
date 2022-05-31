{
  Find ESL plugins that can corrupt save games and cause crashes.
}
unit FindDangerousESL;

const
  iESLMaxRecords = $800;  // max possible new records in ESL
  iESLMaxFormID = $fff;   // max allowed FormID number in ESL

  AnalysisSuccess = 0;
  HasCell = 1;
  HasTooManyRecords = 2;
  HasIdOverflow = 3;

function CheckRecords(f: IInterface): Integer;
var
  i: Integer;
  e: IInterface;
  RecCount, RecMaxFormID, fid: Cardinal;
begin
  Result := AnalysisSuccess;

  for i := 0 to Pred(RecordCount(f)) do begin
    e := RecordByIndex(f, i);
    
    // override doesn't affect ESL
    if not IsMaster(e) then Continue;
    
    if Signature(e) = 'CELL' then begin
      Result := HasCell;
      Exit;
    end;
    
    Inc(RecCount);    
    if RecCount > iESLMaxRecords then begin
      Result := HasTooManyRecords;
      Exit;
    end;
    
    fid := FormID(e) and $FFF;
    if fid > iESLMaxFormID then begin
      AddMessage(IntToHex(fid, 4));
      Result := HasIdOverflow;
      Exit;
    end;
  end;
end;

procedure DisplayAnalysisMessage(espName: string; RecordAnalysis: Integer);
var
  msg: string;
const 
  corruption = ' If you continue to use this plugin, it will surely lead to CTDs.';
begin
  case RecordAnalysis of
    HasCell: 
      msg := 'Warning: Plugin has new CELL(s) which won''t work when turned into ESL and overridden by other mods due to the game bug';
    HasTooManyRecords:
      msg := '***ERROR***: Plugin has too many records and can''t ever be turned into an ESL.' + corruption;
    HasIdOverflow:
      msg := '***ERROR***: Plugin has a record out of bounds. Contact the author so they can remove the ESL flag, compact FormIDs and then turn on the ESL flag again.' + corruption;
    else 
      msg := '';
  end;
  
  if msg = '' then Exit;
  AddMessage(espName);
  AddMessage(#9 + msg);
end;

procedure CheckForESL(f: IInterface);
begin
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
  // iterate over loaded plugins
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if (IsESL(f)) then CheckForESL(f);
  end;
end;

end.

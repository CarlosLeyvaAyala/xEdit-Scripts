unit DM_GetRefIds;
{
  Gets the RefIDs of an esp/esl file, so you can know where to prid in the console.
  Hotkey: Ctrl+R
}

uses xEditApi;

var
  rx, eslRx: TPerlRegex;
  outList: TStringList;
  msgFmt, fileFmt: string;

function MakeRelativeFormId(formId: string): string;
begin
  eslRx.Subject := formId;
  eslRx.RegEx := 'FE.{3}(.*)';  

  if eslRx.Match then begin
    eslRx.Replacement := 'FExxx\1';
    eslRx.ReplaceAll;
    Result := eslRx.Subject;
  end
  else begin
    eslRx.RegEx := '^\d{2}(.*)';
    eslRx.Replacement := 'xx\1';
    eslRx.ReplaceAll;
    Result := eslRx.Subject;
  end;
end;

function ProcessMatch(e: IInterface; fmt: string): string;
var
  refId, baseEdid, baseName, baseId, location: string;
const 
  locFmt = '%s (%s)';
begin
  // RefId: $2 
  // BaseEDID: $3 
  // BaseName: $5 
  // BaseID: $6 
  // CellEdid: $7 
  // Cell Name: $9 
  // CellID: $10 
  // World EDID: $12 
  // WorldName: $13
  refId := MakeRelativeFormId(rx.Groups[2]);
  baseEdid := rx.Groups[3];
  baseName := rx.Groups[5];
  baseId := MakeRelativeFormId(rx.Groups[6]);
  if rx.Groups[7] = '' then
    location := Format(locFmt, [Trim(rx.Groups[13]), Trim(rx.Groups[12])])
  else
    location := Format(locFmt, [Trim(rx.Groups[9]), Trim(rx.Groups[7])]);

  Result := Format(fmt, [refId, baseId, baseName, baseEdid, Trim(location)]);
end;

procedure SetupMessages;
const
  fmtId = '%-8.8s   ';
  fmtEdid = '%-30.30s   ';
  fmtName = '%-20.20s   ';
  fmtLoc = '%-50.50s   ';
begin
  msgFmt := fmtId  + fmtId + fmtName + fmtEdid + fmtLoc;
  fileFmt := '%s,%s,%s,%s,%s';

  AddMessage(#13#10);
  AddMessage('*** NAMES IN THIS TABLE MAY BE CUT FOR MAKING THE TABLE ALIGN PROPERLY ***');
  AddMessage('Exported data will be fine, though.');
  AddMessage(#13#10);
  outList.Add(Format(fileFmt, ['RefID', 'BaseID', 'Name', 'Editor ID', 'Location']));
  AddMessage(Format(msgFmt, ['RefID', 'BaseID', 'Name', 'Editor ID', 'Location']));
  AddMessage('================================================================================================================================================');
end;

procedure GetNpcData(e: IInterface);
begin
  rx.Subject := GetElementEditValues(e, 'Record Header\FormID');
  rx.RegEx := '^(\w+ )?\[ACHR:([0-9a-fA-F]+)\] \(places (\w+) ("(.*)" )?\[NPC_:([0-9a-fA-F]+)\].*Children of (\w+ )?("(.*)" )?\[CELL:([0-9a-fA-F]+)\]( \(in (\w+) "(.*)")?';  
  rx.Replacement := '';

  if rx.Match then begin
    AddMessage(ProcessMatch(e, msgFmt));
    outList.Add(ProcessMatch(e, fileFmt));
  end
  else begin 
    AddMessage(#13#10);
    AddMessage('**************************************************************');
    AddMessage('*** Not recognized. Please report to this script developer *** ');
    AddMessage(rx.Subject);
    AddMessage('**************************************************************');
    AddMessage(#13#10);
  end;
end;

function Process(e: IInterface): Integer;
var
  master: IInterface;
begin
  if Signature(e) <> 'ACHR' then Exit;
  master := MasterOrSelf(e);
  if IntToStr(OverrideCount(master)) <> 0 then Exit;
  GetNpcData(e);
end;

function Initialize: Integer;
begin
  outList := TStringList.Create;
  rx := TPerlRegex.Create;
  // -- RefId: $2 \tBaseEDID: $3 \tBaseName: $5 \tBaseID: $6 \tCellEdid: $7 \tCell Name: $9 \tCellID: $10 \tWorld EDID: $12 \tWorldName: $13\n
  rx.RegEx := '^(\w+ )?\[ACHR:([0-9a-fA-F]+)\] \(places (\w+) ("(.*)" )?\[NPC_:([0-9a-fA-F]+)\].*Children of (\w+ )?("(.*)" )?\[CELL:([0-9a-fA-F]+)\]( \(in (\w+) "(.*)")?';
  eslRx := TPerlRegex.Create;
  SetupMessages;
end;

function Finalize: Integer;
begin 
  outList.SaveToFile('Edit Scripts\RefIds.csv');
  AddMessage(#13#10);
  AddMessage('NPCs were saved to "Edit Scripts\RefIds.csv"');
  AddMessage(#13#10);

  rx.Free;
  eslRx.Free;
  outList.Free;
end;

end.

unit DM_GetRefIds;
{
  Hotkey: Ctrl+R
}

uses xEditApi;

var
  rx, eslRx, espRx: TPerlRegex;
  ref, base, cell, outList: TStringList;
  refNPCs: TList;
  msgFmt, fileFmt: string;

function HexToInt(const str: string): Integer;
begin
  Result := StrToInt('$' + str);
end;

function IsESL(f: IInterface): Boolean;
begin
  Result := GetElementEditValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL') = 1;
end;
  
function ActualFixedFormId(e: IInterface; toLower, padZeros, padXs: Boolean): string;
var
  fID, ffID: Cardinal;
  num0: Integer;
  xx: string;
begin
  
  fID := FormID(e);
  if(IsESL(GetFile(e))) then begin
    ffID := fID and $FFF;
    xx := 'FExxx';
    num0 := 3;
  end
  else begin
    ffID := fID and $FFFFFF; 
    xx := 'xx';
    num0 := 6;
  end;

  if not padZeros then num0 := 1;
  if not padXs then xx := '';

  Result := xx + IntToHex(ffID, num0);
  if toLower then Result := Lowercase(Result);
end;

procedure AddMatch;
var
  baseName: string;
begin
  if rx.Groups[5] <> '' then baseName := '(' + rx.Groups[5] + ')';
  ref.Add(Format('RefID: %s', [rx.Groups[2]]));
  base.Add(Format('BaseID: %s %s %s', [rx.Groups[6], rx.Groups[3], baseName]));
  cell.Add(Format('Cell: %s %s (%s)', [rx.Groups[9], rx.Groups[8], rx.Groups[7]]));
end;

function MaxLen(l: TStringList): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to l.Count - 1 do begin
    Result := Max(Result, Length(l[i]));
  end;  
end;

function GetLine(r, b, c: string; bL: Integer; toFile: Boolean): string;
var
  sep: string;
begin
  if toFile then sep := #9
  else sep := #9#9;
  Result := Format('%s' + sep + '%-*s' + sep + '%s', [r, bL, b, c]);
end;

procedure PrintResults;
var
  i, baseL: Integer;
  s: string;
  outFile: TStringList;
begin
  baseL := MaxLen(base);
  outFile := TStringList.Create;

  try
    for i := 0 to ref.Count - 1 do begin
      // s := Format('%s' #9#9 '%-*s' #9#9 '%s', [ref[i], baseL, base[i], cell[i]]);
      AddMessage(GetLine(ref[i], base[i], cell[i], baseL, false));
      outFile.Add(GetLine(ref[i], base[i], cell[i], baseL, true));
    end;  
    outFile.SaveToFile('Edit Scripts\RefIds.txt');
  finally
    outFile.Free;
  end;
end;

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
  // RecordByFormID(aFile, formId, false);
  rx.Subject := GetElementEditValues(e, 'Record Header\FormID');
  rx.RegEx := '^(\w+ )?\[ACHR:([0-9a-fA-F]+)\] \(places (\w+) ("(.*)" )?\[NPC_:([0-9a-fA-F]+)\].*Children of (\w+ )?("(.*)" )?\[CELL:([0-9a-fA-F]+)\]( \(in (\w+) "(.*)")?';  
  rx.Replacement := '';

  if rx.Match then begin
    AddMessage(ProcessMatch(e, msgFmt));
    outList.Add(ProcessMatch(e, fileFmt));
  end
  else AddMessage('*** not recognized *** ' + rx.Subject);
end;

procedure ProcessNpcs;
var
  i: Integer;
  e: IInterface;
  data: TData;
begin
  for i := 0 to refNPCs.Count - 1 do begin
    e := ObjectToElement(refNPCs[i]);
    // AddMessage(GetElementEditValues(e, 'Record Header\FormID'));
    GetNpcData(e);
  end;
end;

function Process(e: IInterface): Integer;
begin
  // RefID: $2 \t BaseID: $6 $3 ($5) \t Cell: $9 $8 $7
  if Signature(e) <> 'ACHR' then Exit;
  GetNpcData(e);
  // refNPCs.Add(e);
  // AddMessage(s);

  // rx.Subject := s;
  // rx.Replacement := 'RefID: \2 \t BaseID: \6 \3 (\5) \t Cell: \9 \8 \7';
  // if rx.Match then AddMatch
  // else AddMessage('---- ' + s);
end;

function Initialize: Integer;
begin
  outList := TStringList.Create;
  rx := TPerlRegex.Create;
  eslRx := TPerlRegex.Create;
  // -- RefId: $2 \tBaseEDID: $3 \tBaseName: $5 \tBaseID: $6 \tCellEdid: $7 \tCell Name: $9 \tCellID: $10 \tWorld EDID: $12 \tWorldName: $13\n
  rx.RegEx := '^(\w+ )?\[ACHR:([0-9a-fA-F]+)\] \(places (\w+) ("(.*)" )?\[NPC_:([0-9a-fA-F]+)\].*Children of (\w+ )?("(.*)" )?\[CELL:([0-9a-fA-F]+)\]( \(in (\w+) "(.*)")?';
  ref := TStringList.Create;
  base := TStringList.Create;
  cell := TStringList.Create;
  refNPCs := TList.Create;
  SetupMessages;
end;

function Finalize: Integer;
begin 
  outList.SaveToFile('Edit Scripts\RefIds.csv');
  AddMessage(#13#10);
  AddMessage('NPCs were saved to "Edit Scripts\RefIds.csv"');
  AddMessage(#13#10);
  
  ProcessNpcs;
  PrintResults;
  rx.Free;
  eslRx.Free;
  outList.Free;
  ref.Free;
  base.Free;
  cell.Free;
  refNPCs.Free;
end;

end.

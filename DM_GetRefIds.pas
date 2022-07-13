unit DM_GetRefIds;
{
  Hotkey: Ctrl+R
}

uses xEditApi;

var
  rx: TPerlRegex;
  ref, base, cell: TStringList;

procedure AddMatch;
var
  baseName: string;
begin
  if rx.Groups[5] <> '' then baseName := '(' + rx.Groups[5] + ')';
  ref.Add(Format('RefID: %s', [rx.Groups[2]]));
  base.Add(Format('BaseID: %s %s %s', [rx.Groups[6], rx.Groups[3], baseName]));
  cell.Add(Format('Cell: %s %s (%s)', [rx.Groups[9], rx.Groups[8], rx.Groups[7]]));
end;

function Process(e: IInterface): Integer;
var
  s: string;
begin
  // RefID: $2 \t BaseID: $6 $3 ($5) \t Cell: $9 $8 $7
  if Signature(e) <> 'ACHR' then Exit;
  s := GetElementEditValues(e, 'Record Header\FormID');

  rx.Subject := s;
  rx.Replacement := 'RefID: \2 \t BaseID: \6 \3 (\5) \t Cell: \9 \8 \7';
  if rx.Match then AddMatch
  else AddMessage(s);
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

function Initialize: Integer;
begin
  rx := TPerlRegex.Create;
  rx.RegEx := '(?U)^(\w+ )?\[ACHR:([0-9a-fA-F]+)\].*places (\w+) ("(.*)" )?\[NPC_:([0-9a-fA-F]+)\].*Children of (\w+) "(.*)" \[CELL:([0-9a-fA-F]+)\]';
  ref := TStringList.Create;
  base := TStringList.Create;
  cell := TStringList.Create;
end;

function Finalize: Integer;
begin
  PrintResults;
  rx.Free;
  ref.Free;
  base.Free;
  cell.Free;
end;

end.

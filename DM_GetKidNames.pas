unit GetKidNames;
{
  Hotkey: Ctrl+K

  Gets editor IDs separated by comma for adding to a KID list.
}
interface

uses xEditApi;

implementation

var
  items, outfits: TStringList;

procedure CreateObjects;
begin
    items := TStringList.Create;
    outfits := TStringList.Create;
end;

procedure FreeObjects;
begin
    items.Free;
    outfits.Free;
end;

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
  e := MasterOrSelf(e);
  Result := Format('%s|%s', [
    GetFileName(GetFile(e)),
    ActualFixedFormId(e)
  ]);
end;

procedure AddSeparator;
begin
    AddMessage(#13#10);
end;

function Initialize: Integer;
begin
    CreateObjects;
    AddSeparator;
    AddSeparator;
end;

procedure AddItem(e: IInterface);
var
    ed, f, n, kidLine, s: string;
begin
    ed := EditorID(e);
    f := RecordToStr(e);
    s := Signature(e);
    n := DisplayName(e);
    kidLine := Format('%s|%s|%s|%s', [ed, f, s, n]);
    AddMessage(kidLine);
    items.Add(kidLine);
end;

function GetOutfitItems(e: IInterface): string;
var
    i: Integer;
    lst: TStringList;
    items, li, piece: IInterface;
begin
    items := ElementBySignature(e, 'INAM');
    if not Assigned(items) then Exit;
    Result := '***Error***';

    lst := TStringList.Create;
    try
        for i := 0 to ElementCount(items) - 1 do begin
            li := ElementByIndex(items, i);
            piece := LinksTo(li);
            lst.add(RecordToStr(piece));
        end;
        Result := lst.commaText;
    finally
        lst.Free;
    end;

    Result := StringReplace(Result, '"', '', [rfReplaceAll]);
    Result := StringReplace(Result, '|', '~', [rfReplaceAll]);
end;

procedure AddOutfit(e: IInterface);
var
    ed, f, kidLine: string;
begin
    ed := EditorID(e);
    f := RecordToStr(e);
    kidLine := Format('%s|%s|OTFT|%s', [ed, f, GetOutfitItems(e)]);
    AddMessage(kidLine);
    outfits.Add(kidLine);
end;

function Process(e: IInterface): Integer;
var
    s: string;
begin
    s := Signature(e);
    if ((s = 'ARMO') or (s = 'WEAP') or (s = 'AMMO')) then AddItem(e)
    else if s= 'OTFT' then AddOutfit(e);
end;

procedure SaveFile(const contents: TStringList; filename: string);
begin
    if contents.Count > 0 then contents.SaveToFile('Edit Scripts\' + filename);
end;

function Finalize: Integer;
begin
    AddSeparator;
    AddSeparator;
    SaveFile(items, '___.items');
    SaveFile(outfits, '___.outfits');
    // if items.Count > 0 then items.SaveToFile('Edit Scripts\___.items');
    // if outfits.Count > 0 then outfits.SaveToFile('Edit Scripts\___.outfits');
    FreeObjects;
end;

end.

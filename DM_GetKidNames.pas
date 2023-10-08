unit GetKidNames;
{
  Hotkey: Ctrl+K

  Gets editor IDs separated by comma for adding to a KID list.
}
interface

uses xEditApi;

implementation

var
    items, outfits, keywords, spidStrings, spidForms: TStringList;

procedure CreateObjects;
begin
    items := TStringList.Create;
    outfits := TStringList.Create;
    keywords := TStringList.Create;
    spidStrings := TStringList.Create;
    spidForms := TStringList.Create;
end;

procedure FreeObjects;
begin
    items.Free;
    outfits.Free;
    keywords.Free;
    spidStrings.Free;
    spidForms.Free;
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

function KeywordIndex(e: IInterface; edid: string): Integer;
var
  kwda: IInterface;
  n: integer;
begin
  Result := -1;
  kwda := ElementByPath(e, 'KWDA');
  for n := 0 to ElementCount(kwda) - 1 do
    if GetElementEditValues(LinksTo(ElementByIndex(kwda, n)), 'EDID') = edid then begin
      Result := n;
      Exit;
    end;
end;

function HasKeyword(e: IInterface; edid: string): boolean;
begin
  Result := KeywordIndex(e, edid) <> -1;
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

///////////////////////////////////////////////////////////////////////
// Item
///////////////////////////////////////////////////////////////////////
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

///////////////////////////////////////////////////////////////////////
// Outfit
///////////////////////////////////////////////////////////////////////
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

///////////////////////////////////////////////////////////////////////
// Keyword
///////////////////////////////////////////////////////////////////////
procedure AddKeyword(e: IInterface);
var 
    output: string;
begin
    output := EditorID(e);
    AddMessage(output);
    keywords.Add(output);
end;

///////////////////////////////////////////////////////////////////////
// SPID Functions
///////////////////////////////////////////////////////////////////////
function SpidElement(e: IInterface; path, category: string): string;
var
    v: string;
const
    spidAcFmt = '%s|%s'; // SPID Autcomcomplete Format -> Value|Category
begin
    v := GetElementEditValues(e, path);
    if v <> '' then Result := Format(spidAcFmt, [v, category])
    else Result := '';
end;

procedure SpidString(e: IInterface; path, category: string);
var
    v: string;
begin
    v := SpidElement(e, path, category);
    if v <> '' then spidStrings.Add(v);
end;

procedure SpidForm(e: IInterface; category: string);
begin
    spidForms.Add(SpidElement(e, 'EDID', category));
end;

procedure AddSpidForm(e: IInterface; category: string);
begin
    AddMessage(EditorID(e));
    SpidForm(e, category);
end;

///////////////////////////////////////////////////////////////////////
// NPC
///////////////////////////////////////////////////////////////////////
// A valid NPC must be a humanoid race.
function IsValidNPC(e: IInterface): boolean;
var 
    iRace: IInterface;
begin
    iRace := LinksTo(ElementByPath(e, 'RNAM'));
    Result := 
        HasKeyword(iRace, 'ActorTypeNPC') and 
        (not ElementExists(e, 'ACBS - Configuration\Flags\Is CharGen Face Preset')) and
        (not HasKeyword(iRace, 'ActorTypeCreature')) and 
        (not HasKeyword(iRace, 'ActorTypeAnimal'));
end;

procedure AddSpidNPC(e: IInterface);
var 
    i: Integer;
    factions, faction: IInterface;
begin
    if not IsValidNPC(e) then Exit;

    AddMessage('--------------------------------');
    AddMessage(EditorID(e));
    SpidString(e, 'EDID', 'EDID');
    SpidString(e, 'FULL', 'Full name');
    AddMessage(GetElementEditValues(e, 'FULL'));
    //// Not exported anymore because it generates too mutch duplicated entries
    // SpidString(e, 'SHRT', 'Short name');  NOT

    AddSpidForm(LinksTo(ElementByPath(e, 'RNAM')), 'Race');
    AddSpidForm(LinksTo(ElementByPath(e, 'CNAM')), 'Class');
    AddSpidForm(LinksTo(ElementByPath(e, 'CRIF')), 'Faction');
    AddSpidForm(LinksTo(ElementByPath(e, 'ZNAM')), 'Combat style');
    AddSpidForm(LinksTo(ElementByPath(e, 'VTCK')), 'Voice type');
    
    factions := ElementByPath(e, 'Factions');

    for i := 0 to ElementCount(factions) - 1 do begin
        faction := ElementByIndex(factions, i);
        faction := ElementByIndex(faction, 0); // Factions have a weird structure
        AddSpidForm(LinksTo(faction), 'Faction');
    end;
end;

///////////////////////////////////////////////////////////////////////
// Race
///////////////////////////////////////////////////////////////////////
procedure AddSpidRace(e: IInterface);
begin
    if not HasKeyword(e, 'ActorTypeNPC') then Exit;
    AddSpidForm(e, 'Race');
end;

///////////////////////////////////////////////////////////////////////
// FormList
///////////////////////////////////////////////////////////////////////
procedure AddSpidFormList(e: IInterface);
var
  item, items: IInterface;
begin
  items := ElementByPath(e, 'FormIDs');
  item := LinksTo(ElementByIndex(items, 0));
  if((Signature(item) <> 'NPC_') or (not IsValidNPC(item))) then Exit;
  AddSpidForm(e, 'FormID list');
end;

///////////////////////////////////////////////////////////////////////
// FormList
///////////////////////////////////////////////////////////////////////
procedure AddSpidCellNPC(e: IInterface);
var
    npc: IInterface;
begin
    npc := LinksTo(ElementByPath(e, 'NAME'));
    if not IsValidNPC(npc) then Exit;
    AddSpidForm(e, 'NPC ref');
    AddSpidNPC(npc);
end;

///////////////////////////////////////////////////////////////////////
// Base processing
///////////////////////////////////////////////////////////////////////

function Process(e: IInterface): Integer;
var
    s: string;
begin
    s := Signature(e);
    if ((s = 'ARMO') or (s = 'WEAP') or (s = 'AMMO')) then AddItem(e)
    else if s= 'OTFT' then AddOutfit(e)
    else if s= 'KYWD' then AddKeyword(e)
    else if s= 'NPC_' then AddSpidNPC(e)
    else if s= 'RACE' then AddSpidRace(e)
    else if s= 'CLAS' then AddSpidForm(e, 'Class')
    else if s= 'FACT' then AddSpidForm(e, 'Faction')
    else if s= 'CSTY' then AddSpidForm(e, 'Combat style')
    else if s= 'VTYP' then AddSpidForm(e, 'Voice type')
    else if s= 'LCTN' then AddSpidForm(e, 'Location')
    else if s= 'FLST' then AddSpidFormList(e)
    else if s= 'ACHR' then AddSpidCellNPC(e);
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
    SaveFile(keywords, '___.keywords');
    SaveFile(spidStrings, '___.spidstrs');
    SaveFile(spidForms, '___.spidfrms');
    FreeObjects;
end;

end.

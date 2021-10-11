unit DM_OutfitFromSelected;
{
    Hotkey: Shift+F4
}

uses xEditApi, DM_SelectPlugin;

var
  gFileTo, gOft: IInterface;
  gCount: Integer;

// Create an empty outfit and return it's handle.
function _OutfitFromTemplate(aOName: string): IInterface;
var
  base: IInterface;
const
  eSleepOftNotFound = 'How did you manage to delete DefaultSleepOutfit [OTFT:0001697D] from Skyrim.esm? I need it as a template to create a new outfit.';
  eCantCreate = 'I couldn''t create a new outfit for some unknown reason. Please, manually create a new one by copying any existng OTFT record to %s.';
begin
  // Copy DefaultSleepOutfit [OTFT:0001697D] from Skyrim.esm.
  base := RecordByFormID(FileByIndex(0), $0001697D, True);
  if not Assigned(base) then raise Exception.Create(eSleepOftNotFound);
  Result := wbCopyElementToFile(base, gFileTo, True, True);
  if not Assigned(Result) then raise Exception.Create(Format(eCantCreate, [GetFileName(gFileTo)]));

  // Clean copied template
  SetElementEditValues(Result, 'EDID', aOName);
end;

// Get the outfit record in which we we'll add selected armors.
function _GetOutfit: IInterface;
var
  oName: string;
const
  eOftNotFound = '"%s" hasn''t an OTFT group. Create one by right clicking that file here in xEdit > Add > OTFT.';
begin
  Result := nil;
  if not InputQuery('Name your new outfit', 'Name', oName) then Exit;
  if not HasGroup(gFileTo, 'OTFT') then raise Exception.Create(Format(eOftNotFound, [GetFileName(gFileTo)]));

  // If outfit already exists, use that one. Create a new one if it doesn't.
  Result := MainRecordByEditorID(GroupBySignature(gFileTo, 'OTFT'), oName);
  if Assigned(Result) then AddMessage(Format('Adding more items to "%s".', [oName]))
  else Result := _OutfitFromTemplate(oName);
end;

// Remove farm clothes from cloned list.
// Had to this because it seems completely emptying a list makes xEdit hang.
procedure _CleanTemplatePijamas;
var
  items: IInterface;
  iName: string;
begin
  items := ElementByPath(gOft, 'INAM');
  iName := GetElementEditValues(
      LinksTo( ElementByIndex(items, 0) ),
      'EDID'
  );
  if iName = 'ClothesFarmClothes01' then RemoveElement(items, 0);
end;



function Initialize: Integer;
begin
  gCount := 0;

  gFileTo := GetPlugin('Where do you want to create the new outfit?');
  if not Assigned(gFileTo) then begin
    Result := -1;
    Exit;
  end;

  gOft := _GetOutfit;
  if not Assigned(gOft) then begin
    Result := -1;
    Exit;
  end;
end;

function Process(e: IInterface): Integer;
var
  items, newItem: IInterface;
begin
  // This record isn't an armor. Try next.
  if Signature(e) <> 'ARMO' then Exit;

  AddMasterIfMissing(
    gFileTo,
    GetFileName( GetFile(e) )
  );
  CleanMasters(gFileTo);   // Removes self as master.

  // Add this armor to outfit
  items := ElementByPath(gOft, 'INAM');
  newItem := ElementAssign(items, HighInteger, nil, False);
  SetEditValue(newItem, Name(e));
  Inc(gCount);
end;

function Finalize: Integer;
begin
  if gCount = 0 then
    AddMessage('No armors added to outfit. Did you select valid armors when running this script?')
  else begin
    _CleanTemplatePijamas;
    AddMessage(
      Format(
        '%d records added to %s in %s',
        [
          gCount,
          GetElementEditValues(gOft, 'EDID'),
          GetFileName(gFileTo)
        ]
      )
    );
  end;
end;

end.

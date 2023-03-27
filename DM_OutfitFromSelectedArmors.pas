unit DM_OutfitFromSelectedArmors;

{
  Creates a new outfit from selected armors.

    Hotkey: Shift+F4
}

uses xEditApi;

const
  fileName = '<Change this>.esp';

var
  gFileTo, gOft: IInterface;
  gCount: Integer;

// Gets a file handle by its name.
function FileByName(s: string): IInterface;
var
  i: integer;
begin
  Result := nil;

  for i := 0 to FileCount - 1 do 
    if GetFileName(FileByIndex(i)) = s then begin
      Result := FileByIndex(i);
      Exit;
    end;
end;

// Create an empty outfit and return it's handle.
function _OutfitFromTemplate(aOName: string): IInterface;
var
  base: IInterface;
const
  eSleepOftNotFound = 'How did you manage to delete DefaultSleepOutfit [OTFT:0001697D] from Skyrim.esm? I need it as a template to create a new outfit.';
  eCantCreate = 'I couldn''t create a new outfit for some unknown reason. Please, manually create a new one by copying any existng OTFT record to %s.';
begin
  AddMessage('Copying outfit from template');
  // Copy DefaultSleepOutfit [OTFT:0001697D] from Skyrim.esm.
  base := RecordByFormID(FileByIndex(0), $1697D, true);
  if not Assigned(base) then raise Exception.Create(eSleepOftNotFound);

  Result := wbCopyElementToFile(base, gFileTo, true, false);
  Add(Result, 'INAM', true);

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

procedure _CreateGroup;
var
  OTFT: IInterface;
begin
  // Make sure OTFT exists
  OTFT := GroupBySignature(FileByLoadOrder(0), 'OTFT');
  wbCopyElementToFile(OTFT, gFileTo, true, false);
end;

function _GetCurrFile(params):integer;
var
  oName: string;
begin
  if not InputQuery('Name your new outfit', 'Name', oName) then Exit;
end;

function Initialize: Integer;
begin
  gCount := 0;

  if fileName = '<Change this>.esp' then begin
    AddMessage(#13#10);
    AddMessage(#13#10);
    AddMessage('********************************************************************');
    AddMessage('Please change the target plugin by modifing this script''s "fileName"');
    AddMessage('variable (see bundled images for instructions).');
    AddMessage(#13#10);
    AddMessage('Options:');
    AddMessage(#9'- Leave empty to add outfits to the armors'' plugin file.');
    AddMessage(#9'- Rename it as MyFile.esp to add them to a file.');
    AddMessage(#9'  If file does not exist, it is created with esl flags.');
    AddMessage('********************************************************************');
    AddMessage(#13#10);
    AddMessage(#13#10);
    Result := -1;
    Exit;
  end
  else if fileName = '' then begin
    AddMessage('Target plugin is empty. Outfit will be added to the file where your armors are.');
  end
  else begin
    gFileTo := FileByName(fileName);
    if(not Assigned(gFileTo)) then begin
      gFileTo := AddNewFileName(fileName, true);
      AddMessage('File ' + fileName + ' was created with esl flags.');
    end
    AddMessage('Adding outfit to ' + GetFileName(gFileTo));
  end;

  if Assigned(gFileTo) then begin
    _CreateGroup;

    gOft := _GetOutfit;
    if not Assigned(gOft) then begin
      Result := -1;
      Exit;
    end;
  end;
end;

function Process(e: IInterface): Integer;
var
  items, newItem: IInterface;
begin
  if not Assigned(gFileTo) then begin
    gFileTo := GetFile(e);
    _CreateGroup;
    gOft := _GetOutfit;
  end;

  if not Assigned(gOft) then begin
    Result := -1;
    Exit;
  end;

  // This record isn't an armor. Try next.
  if Signature(e) <> 'ARMO' then Exit;

  if GetFile(e) <> gFileTo then
    AddMasterIfMissing(
      gFileTo,
      GetFileName( GetFile(e) )
    );

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

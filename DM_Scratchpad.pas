unit DM_Scratchpad;
{
    Hotkey: F4
}
interface

// uses xEditApi, 'DM_RenameUtils\Auto', 'DM_RenameUtils\Globals', DM_SelectPlugin;
uses xEditApi;

implementation

var
    recCount: Integer;
    output: TStringList;
    gFileTo: IInterface;
    rx: TPerlRegex;

function Initialize: Integer;
var 
  i: integer;
  f: IInterface;
begin
  rx := TPerlRegex.Create;
  output := TStringList.Create;
  gFileTo := FileByName('Vokriinator as Enchantments.esp');
  // f := FileByName('[NINI] Karlstein.esp');
  // AddMasterIfMissing(f, 'Vokriinator as Enchantments.esp');

  // iterate over loaded plugins
  // for i := 0 to Pred(FileCount) do begin
  //   f := FileByIndex(i);
  //   if HasHeavyArmor(f) then begin
  //     AddMessage(IntToHex(GetLoadOrder(f), 2) + ' ' + GetFileName(f));
  //   end;
  // end;
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
    xx := 'xxxxx';
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

procedure RemoveKeyword(e: IInterface; edid: string);
var
    idx: Integer;
begin
    idx := KeywordIndex(e, edid);
    if idx <> -1 then
        RemoveElement(ElementByPath(e, 'KWDA'), idx);
end;

function HasKeyword(e: IInterface; edid: string): boolean;
begin
  Result := KeywordIndex(e, edid) <> -1;
end;

procedure AddKeyword(e: IInterface; edid, fileName: string);
var
    keys: IwbGroupRecord;
    key, k, esp, f: IInterface;
    i: Integer;
begin
    esp := nil;
    for i := 0 to FileCount - 1 do begin
      f := FileByIndex(i);
      if GetFileName(f) = fileName then begin
        esp := f;
        Break;
      end;
    end;

    //   Keyword already added or esp not exists
    if (KeywordIndex(e, edid) <> -1) or (not Assigned(esp)) then Exit;

    AddMasterIfMissing(GetFile(e), GetFileName(esp));

    // Find in Skyrim.esm
    key := MainRecordByEditorID(GroupBySignature(esp, 'KYWD'), edid);
    if Assigned(key) then begin
        k := ElementAssign(ElementByPath(e, 'KWDA'), HighInteger, nil, false);
        SetEditValue(k, Name(key));
    end;
end;

procedure ProcessFormlist(e: IInterface);
var
    items, entry: IInterface;
    i: Integer;
begin
    items := ElementByName(e, 'FormIDs');
    for i := 0 to ElementCount(items) - 1 do begin
        entry := ElementByIndex(items, i);
        AddMessage( IntToStr(i) );
        AddMessage( Path(entry) );
        AddMessage(
            GetElementEditValues(LinksTo(entry), 'EDID')
        );
    end;
end;

procedure RemoveNonPlayable(e: IInterface);
var
    original, override: variant;
begin
  original := GetElementEditValues(Master(e), 'Record Header\Record Flags\Non-Playable');
  override := GetElementEditValues(HighestOverrideOrSelf(e, $FFFF), 'Record Header\Record Flags\Non-Playable');
  if original = 1 and override = 0 then begin
    AddMessage(GetElementEditValues(e, 'EDID') + ' changed');
    Remove(e);
  end;
end;

procedure AddEmptyKeyword(e: IInterface);
var
    i: Integer;
    n: string;
    l: TStringList;
begin
    l := TStringList.Create;
    try
        l.Add('underwear');
        l.Add('skirt');
        l.Add('shorts');
        l.Add('shoes');
        l.Add('panti');
        l.Add('panty');
        l.Add('top');
        l.Add('dress');
        l.Add('corset');
        l.Add('boot');
        n := GetElementEditValues(e, 'FULL');
        for i := 0 to l.Count - 1 do begin
            if ContainsText(n, l[i]) then begin
                ElementAssign(ElementByPath(e, 'KWDA'), HighInteger, nil, false);   // Empty keyword
                Exit;
            end;
        end;
    finally
        l.Free;
    end;

end;

procedure ExportArmorInfo(e: IInterface);
var 
    edid, full, esp: string;
begin
    edid := GetElementEditValues(e, 'EDID');
    full := GetElementEditValues(e, 'FULL');
    esp := GetFileName(GetFile(Master(e)));
    AddMessage(Format('%s|%s|%s', [full, edid, esp]));
end;

// Separates a string by capitals.  
// Example:
//  'BDO BMSNecklaceBlack' => 'BDO BMS Necklace Black' 
function SeparateCapitals(aStr: string): string;
var
  r: TPerlRegex;
begin
  r := TPerlRegex.Create;
  try
    r.RegEx := '((?<=[a-z])[A-Z]|[A-Z](?=[a-z]))';
    r.Subject := aStr;
    r.Replacement := ' \1';
    r.ReplaceAll;
    Result := Trim(r.Subject);
  finally
    r.Free;
  end;
end;

procedure MakeIsLocation(e: IInterface);
var
  f, k, s, c: string;
const 
  kFmt = 'Keyword.from(Game.getFormFromFile(0x%s, "Skyrim.esm"))';
  fFmt = 'export const is%s = (l: Location) => l.hasKeyword(%s)';
  cFmt = '/** Checks if a location is of type "%s". */';
begin
  k := Format(kFmt, [ActualFixedFormId(e)]);
  s := StringReplace(EditorID(e), 'LocType', '', [rfReplaceAll]);
  s := StringReplace(EditorID(e), 'LocSet', 'Set', [rfReplaceAll]);
  f := Format(fFmt, [s, k]);
  c := Format(cFmt, [Lowercase(SeparateCapitals(s))]);
  AddMessage(c);
  AddMessage(f);
  AddMessage(' ')
end;

procedure RemoveOverrides(e: IInterface);
var
  n: Integer;
  d: IInterface;
begin
  n := OverrideCount(e);
  while n > 0 do begin
    d := OverrideByIndex(e, n - 1);
    Remove(d);
    n := OverrideCount(e);
  end;
end;

procedure GetEnchantEffects(e: IInterface);
var
  i, n: Integer;
  fxs, fx, ench: IInterface;
  mag: Real;
  mags: TStringList;
  eName: string;
const
  fmt = '%s (%g)';
begin
    fxs := ElementByPath(e, 'Effects');
    n := ElementCount(fxs);
    AddMessage(#13#10);
    for i := 0 to n - 1 do begin
        AddMessage('***S');
      fx := ElementByIndex(fxs, i);
      ench := ElementByPath(fx, 'EFID');
      AddMessage(GetEditValue(ench));
      AddMessage(Format(#9'Magnitude: %f', [GetElementNativeValues(fx, 'EFIT\Magnitude')]));
      AddMessage(Format(#9'Area: %s', [GetElementNativeValues(fx, 'EFIT\Area')]));
      AddMessage(Format(#9'Duration: %s', [GetElementNativeValues(fx, 'EFIT\Duration')]));
        AddMessage('***E');
    end;
    AddMessage(#13#10);
end;

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

procedure PrintMgEffectData(e: IInterface; path: string);
var 
  s: string;
const 
  p = 'Magic Effect Data\DATA\';
begin
  s := Format('%-30s %s', [path, GetElementEditValues(e, p + path)]);
  AddMessage(s);
end;

procedure EditMgEffectData(e: IInterface; path, value: string);
const 
  p = 'Magic Effect Data\DATA\';
begin
  SetElementEditValues(e, p + path, value);
end;

procedure VokriiRemoveConditions(e: IInterface); 
var
  o: IInterface;
  i, n: Integer;
begin
  o := ElementByPath(e, 'Conditions');
  n := ElementCount(o);

  i := 0;
  repeat 
      RemoveByIndex(o, 0, true);
      Inc(i);
  until (i >= n);
end;

function VokriiGetPerkName(e: IInterface): string; 
var
  s: string;
//   o: IInterface;
//   i, n: Integer;
const 
  // Ordinator
  ofmtXX =  'A_DM_%s_0%s_OrdPerk_%s';
  ofmt100 = 'A_DM_%s_100_OrdPerk_%s';
  // Vokrii
  vfmtXX =  'A_DM_%s_0%s_VokPerk_%s';
  vfmt100 = 'A_DM_%s_100_VokPerk_%s';
  // Vokriinator
  rfmtXXX =  'A_DM_%s_%s_VtrPerk_%s';
  // rfmt100 = 'A_DM_VtrPerk_%s_100_%s';
begin
  s := StringReplace(GetElementEditValues(e, 'FULL'), ' ', '', [rfReplaceAll]);
  Result := 'ERROR';
  rx.Subject := EditorID(e);

  rx.RegEx := 'ORD_(\w{3})(\d{2})';
  if rx.Match then begin
    Result := Format(ofmtXX, [UpperCase(rx.Groups[1]), rx.Groups[2], s]);
    Exit;
  end;

  rx.RegEx := 'DMVTR_(\w{3}).*?(\d{3})';
  if rx.Match then begin
    Result := Format(rfmtXXX, [UpperCase(rx.Groups[1]), rx.Groups[2], s]);
    Exit;
  end;
end;

procedure VokriiProcessPerk(e: IInterface);
var
  s, full, desc: string;
  o, mgef: IInterface;
begin
  VokriiRemoveConditions(e);

  s := VokriiGetPerkName(e);
  full := GetElementEditValues(e, 'FULL');
  desc := GetElementEditValues(e, 'DESC');
  SetEditorID(e, s);
  
  o := MainRecordByEditorID(GroupBySignature(gFileTo, 'MGEF'), 'A_DM_PIC_100_VokEnch_PerfectTouch');
  mgef := wbCopyElementToFile(o, gFileTo, true, true);
  SetEditorID(mgef, StringReplace(s, 'Perk', 'Ench', [rfReplaceAll]));
  SetElementEditValues(mgef, 'FULL', full);
  SetElementEditValues(mgef, 'DNAM', desc);
  SetEditValue(ElementByPath(mgef, 'Magic Effect Data\DATA\Perk to Apply'), Name(e));
end;

function FindRecordByEdid(signature, edid, fileName: string): IInterface;
var
    keys: IwbGroupRecord;
    key, k, esp, f: IInterface;
    i: Integer;
begin
    Result := nil;
    esp := FileByName(fileName);

    if not Assigned(esp) then begin 
        AddMessage(Format('Can not find "%s" because "%s" does not exist.', [edid, fileName]));
        Exit;
    end;

    Result := MainRecordByEditorID(GroupBySignature(esp, signature), edid);
    if not Assigned(Result) then 
        AddMessage(Format('"%s" was not found in "%s".', [edid, fileName]));
end;

function Process(e: IInterface): Integer;
var
    v: variant;
//     s: TStringList;
    s, s2, basePath: string;
    isUnique, o, g, parentPerk: IInterface;
    i, j, n, m: Integer;
    r: Real;
    elem, elem2: IwbGroupRecord;
const
    race = 'Arg';
    sex = 'Man';
    fitness = 'Fat';
    fmtSkmp = '{k: "%s", id: getFormFromUniqueId("Skimpify Enchantments.esp|0x%s")?.getFormID()},';
begin
  o := FindRecordByEdid('ARMO', '0AllisGoldBody', '[Melodic] All is Gold.esp');
  AddMessage(Name(o));
  
// AddNewFileName('Vokriinator as Enchantments.esp', true)
// if(OverrideCount(MasterOrSelf(e)) = 0)then
//   wbCopyElementToFile(WinningOverride(e), gFileTo, true, true);
//  SetEditorID(e, 'Karlstein');
// SetEditorID(e, 'DM_' + EditorID(e));
// AddMessage(IntToStr(OverrideCount(MasterOrSelf(e))));

// SetElementNativeValues(e, 'EITM', nil);
  // VokriiProcessPerk(e);
  // rx.Subject := EditorID(e);
  // rx.RegEx := 'A_DM_(\w+)_(\w{3}_\d{3})_(.*)';
  // rx.Replacement := 'A_DM_\2_\1_\3';
  // rx.ReplaceAll;
  // SetEditorID(e, rx.Subject);
  // if ContainsText(EditorID(e), 'NPC_') then begin 
  //   AddMessage(EditorID(e));
  //   Remove(e);
  // end;
  // AddMessage(EditorID(e));

  // EditMgEffectData(e, 'Casting Light', 'NULL - Null Reference [00000000]');
  // EditMgEffectData(e, 'Spellmaking\Area', '0');
  // EditMgEffectData(e, 'Spellmaking\Casting Time', '0');
  // EditMgEffectData(e, 'Explosion', 'NULL - Null Reference [00000000]');
  // EditMgEffectData(e, 'Delivery', 'Touch');
  // EditMgEffectData(e, 'Casting Art', 'NULL - Null Reference [00000000]');
  // EditMgEffectData(e, 'Equip Ability', 'NULL - Null Reference [00000000]');
  // Exit;

  // AddMessage(#13#10#13#10);
  // AddMessage(EditorID(e));
  // PrintMgEffectData(e, 'Base Cost');
  // PrintMgEffectData(e, 'Magic Skill');
  // PrintMgEffectData(e, 'Resist Value');
  // PrintMgEffectData(e, 'Counter Effect count');
  // PrintMgEffectData(e, 'Casting Light');
  // PrintMgEffectData(e, 'Taper Weight');
  // PrintMgEffectData(e, 'Hit Shader');
  // PrintMgEffectData(e, 'Enchant Shader');
  // PrintMgEffectData(e, 'Minimum Skill Level');
  // PrintMgEffectData(e, 'Spellmaking\Area');
  // PrintMgEffectData(e, 'Spellmaking\Casting Time');
  // PrintMgEffectData(e, 'Taper Curve');
  // PrintMgEffectData(e, 'Taper Duration');
  // PrintMgEffectData(e, 'Second AV Weight');
  // PrintMgEffectData(e, 'Archtype');
  // PrintMgEffectData(e, 'Actor Value');
  // PrintMgEffectData(e, 'Projectile');
  // PrintMgEffectData(e, 'Explosion');
  // PrintMgEffectData(e, 'Casting Type');
  // PrintMgEffectData(e, 'Delivery');
  // PrintMgEffectData(e, 'Second Actor Value');
  // PrintMgEffectData(e, 'Casting Art');
  // PrintMgEffectData(e, 'Hit Effect Art');
  // PrintMgEffectData(e, 'Impact Data');
  // PrintMgEffectData(e, 'Skill Usage Multiplier');
  // PrintMgEffectData(e, 'Dual Casting\Art');
  // PrintMgEffectData(e, 'Dual Casting\Scale');
  // PrintMgEffectData(e, 'Enchant Art');
  // PrintMgEffectData(e, 'Equip Ability');
  // PrintMgEffectData(e, 'Perk to Apply');
  // PrintMgEffectData(e, 'Casting Sound Level');
  // PrintMgEffectData(e, 'Script Effect AI\Score');
  // PrintMgEffectData(e, 'Script Effect AI\Delay Time');
  // AddMessage(#13#10);

  // PrintMgEffectData(e, '');
  // PrintMgEffectData(e, '');
  // PrintMgEffectData(e, '');
  // PrintMgEffectData(e, '');
  // PrintMgEffectData(e, '');
  // AddMessage(GetElementEditValues(e, 'ACBS\Flags\Opposite Gender Anims'));
  // SetElementNativeValues(e, 'ACBS\Flags\Opposite Gender Anims', 0)
    // o := ElementByPath(e, 'Conditions');
    // n := ElementCount(o);

    // i := 0;
    // repeat 
    //     parentPerk := EditorID(LinksTo(ElementByPath(ElementByIndex(o, i), 'CTDA\Perk')));
    //     Inc(i);
    // until (i >= n) or (parentPerk <> '');

    // i := 0;
    // repeat 
    //     s2 := GetElementEditValues(ElementByIndex(o, i), 'CTDA\Actor Value');
    //     Inc(i);
    // until (i >= n) or (s2 <> '');

    // parentPerk := EditorID(LinksTo(ElementByPath(ElementByIndex(o, 1), 'CTDA\Perk')));
    // if parentPerk = '' then 
    //     parentPerk := EditorID(LinksTo(ElementByPath(ElementByIndex(o, 0), 'CTDA\Perk')));
    
    // s2 := GetElementEditValues(ElementByIndex(o, 0), 'CTDA\Actor Value');
    // if s2 = '' then 
    //     s2 := GetElementEditValues(ElementByIndex(o, 1), 'CTDA\Actor Value');
    
    // AddMessage(Format('%s|%s|%s|%s|%s', [
    //     EditorID(e), 
    //     parentPerk,
    //     GetElementEditValues(e, 'FULL'),
    //     GetElementEditValues(e, 'DESC'),
    //     GetElementEditValues(ElementByIndex(o, 0), 'CTDA\Actor Value')
    //     ]));

    // AddMessage(EditorID(parentPerk));
    // g := GroupBySignature(FileByName('SexLabAroused.esm'), 'KYWD');
    // o := MainRecordByEditorID(g, 'EroticArmor');
    // AddMessage(IntToHex(FormID(o), 1));

    ////////////////////////////////////////////////////////
    // AddMessage(Format(fmtSkmp, [EditorID(e), ActualFixedFormId(e, false, false, false)]));
    // AddMessage(Format('|"%s"', [EditorID(e)]));
    // SetEditorID(e, StringReplace(EditorID(e), 'Spell', 'SpellNC', [rfReplaceAll]));
    // SetEditorID(e, StringReplace(EditorID(e), '___', '', [rfReplaceAll]));
    
    //////////////////////////////////////////////////////// 
    // if Signature(e) = 'ENCH' then GetEnchantEffects(e);
  // if (Signature(e) = 'RACE') and HasKeyword(e, 'ActorTypeNPC') then 
//   e := HighestOverrideOrSelf(e, 9999);
//   if Signature(e) = 'CELL' then begin
//       elem := ChildGroup(e);
//       n := ElementCount(elem);
//         AddMessage(IntToStr(n));
//       for i := 0 to n do begin
//         elem2 := ChildGroup(elem);
//         m := ElementCount(elem2);
//         AddMessage(IntToStr(m));
//         for j := 0 to m do begin
//           AddMessage(Name(ElementByIndex(elem2, j)));
//         end;
//       end;      
//   end;
    // for i := 0 to ElementCount(e) - 1 do begin
    //   elem := ElementByIndex(e, i);
    //   AddMessage(Name(elem));
    //   ChildrenOf(e);
    // end;

    // AddMessage(EditorID(e) + '  ' + IntToStr(ElementCount(e)));
  // AddMessage('"' + EditorID(e) + '",');
  // RemoveOverrides(e);
  // SetElementEditValues(e, 'Magic Effect Data\DATA\Hit Shader', 'MuffleFXShader [EFSH:000BCF25]');
  // Add(e, 'Armature', false);
  // MakeIsLocation(e);
//   AddMessage(ActualFixedFormId(e, false, false, false));
  // AddMessage('player.removeitem 6f0' + ActualFixedFormId(e) + ' 1');
    // Inc(recCount);
    // ExportArmorInfo(e);
    // AddMessage(IntToHex(FormID(e), 2));
    // if GetElementNativeValues(e, 'DATA\Float') = 70 then
    // AddMessage(GetElementEditValues(e, 'EDID'));

    // If GetElementNativeValues(e, 'ACBS\Flags\Female') then begin
    //   // SetElementEditValues(e, 'NAM6', RandomRange(92, 96) / 100.0);
    //   // r := GetElementNativeValues(e, 'NAM6');
    //   // SetElementNativeValues(WinningOverride(e),'NAM6', r);
    //   RemoveElement(e, ElementBySignature(e, 'WNAM')) ;
    //   RemoveElement(WinningOverride(e), ElementBySignature(WinningOverride(e), 'WNAM')) ;
    // end;

    // o := WinningOverride(e);
    // if GetFileName(GetFile(o)) = 'Bashed Patch, 0.esp' then
    // Remove(o);

    // AddMessage(IntToStr(recCount));
    // =====================================
    // Rename Maxick textures
    // =====================================
    // if Signature(e) = 'TXST' then begin
    //     Inc(recCount);
    //     // Normal map
    //     s := Format('%s%s_%.2d', [sex, fitness, recCount]);
    //     // s2 := Format('actors\character\Maxick\%s\%s.dds', [race, s]);
    //     basePath := Format('actors\character\Maxick\%s\', [race]);
    //     SetElementEditValues(e, 'Textures (RGB/A)\TX01', basePath + s + '.dds');
    //     SetElementEditValues(e, 'EDID', race + s);

    //     // SetElementEditValues(e, 'Textures (RGB/A)\TX00', 'Actors\Character\Male\MaleBody_1.dds');
    //     // SetElementEditValues(e, 'Textures (RGB/A)\TX03', 'Actors\Character\Male\MaleBody_1_sk.dds');
    //     // SetElementEditValues(e, 'Textures (RGB/A)\TX07', 'Actors\Character\Male\MaleBody_1_S.dds');
    // end
    // else if Signature(e) = 'FLST' then begin
    //     ProcessFormlist(e)
    // end;

    // ============================================================
    // SetElementNativeValues(e, 'DATA\Weight', 5);
    // AddMessage({GetElementEditValues(e, 'FULL') + ' ' + }GetElementEditValues(e, 'DATA\Weight'));

    // AddKeyword(e, 'MagicDisallowEnchanting', 'Skyrim.esm');
    // AddKeyword(e, 'SLA_BootsHeels', 'SexLabAroused.esm');
    // AddKeyword(e, 'SLA_ArmorHalfNaked', 'SexLabAroused.esm');
    // AddKeyword(e, 'SLA_ThongGString', 'SexLabAroused.esm');
    // AddKeyword(e, 'SLA_ArmorPartTop', 'SexLabAroused.esm');
    // AddKeyword(e, 'SLA_Brabikini', 'SexLabAroused.esm');
    // RemoveKeyword(e, 'SLA_Brabikini');
    // AddKeyword(e, 'SLA_ArmorHalfNakedBikini', 'SexLabAroused.esm');
    // AddKeyword(e, 'SLA_ArmorHalfNaked', 'SexLabAroused.esm');
    // Add(e, 'EITM', true);
    // AddEmptyKeyword(e);
    // ============================================================

    // InsertElement(ElementByPath(e, 'KWDA'), 0, nil);

    // AddMessage(GetElementEditValues(e, 'BOD2\Armor Type'));

    // v := GetElementNativeValues(e, 'DATA\Value');
    // e := HighestOverrideOrSelf(e, $FFFF);
    // SetElementNativeValues(e, 'DATA\Value', v);

    // SetElementNativeValues(e, 'DATA\Weight', 0);
    // SetElementNativeValues(e, 'DATA - Weight', 0.1);

    // esm, id, nombre, clase, sexo
        // AddMessage(Format('%s|0x%s', [GetFileName(GetFile(e)), Lowercase(IntToHex(FormId(e), 1))]));
        // AddMessage(GetElementEditValues(e, 'ACBS\Flags\Female'));

        // AddMessage(
        //     GetElementEditValues(
        //         LinksTo(ElementByPath(e, 'CNAM')),
        //         'FULL'
        //     )
        // );
        // AddMessage(
        //     GetElementEditValues(                e,                'FULL'            )
        // );

    // AddMessage(GetElementEditValues(e, 'EDID'));

    // AddMessage();
    // AddMessage(GetAutoName(e));
    // RemoveNonPlayable(e);
end;

function Finalize: Integer;
var
  i: Integer;
begin
  // AddMessage(output.commaText);
  // for i := 0 to output.Count - 1 do
  //   AddMessage(output[i]);
  output.Free;
  rx.Free
end;
end.

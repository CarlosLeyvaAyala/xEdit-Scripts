{
  Hotkey: F9
  
	Name: xEdit - FULL Batch Renamer
	Author: Carlos Leyva Ayala

	This is an xEdit script that modifies the FULL part of a record. 
	In short: it will help you renaming items, weapons, magic, etc.
	
	This software is provided as is. It should be quite harmless 
	because it only modifies names and doesn't give you the chance 
	to modify anything else (which could actually be game breaking).
	Even so, since We Live in a Society (heh...) that loves to sue for 
	any stupid reason, so I must warn you I can not be held responsible 
	if you somehow screw up something using this, trigger all those 
	world ending nukes, or whatever.
	If you are using xEdit scripts, at least you are aware of the 
	consecuences of touching things you shouldn't.
	
	By the way, since I'm making this source code public, it would be 
	quite innocent from my part to ask you not to copy it.
	Hopefully you won't take it and make it look like you wrote it 
	yorself, you would only be fooling yourself and not anyone else, 
	anyway.
	But if you find it useful for a commercial project or such, please
	consider donating whatever you like. That way, we all win :)

	After all, my knowledge on Delphi didn't come free :P 
	
	By the way, this script was inspired on this:
	https://www.nexusmods.com/fallout4/mods/5092
	I used the same concepts there because it seems to be somewhat 
	popular and it would help ease the use of my script to people
	who is already acquainted with that script. 
	But the implementation of mine is quite different, since I wrote 
	it from scratch.
}

unit DM_RenameUtils;

interface

function Initialize: integer;
function Process(ARecord: IInterface): Integer;
function Finalize: Integer;


implementation
uses xEditApi
,StrUtils, SysUtils, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Dialogs, 
System.Classes, 'DM_RenameUtils\Auto', 'DM_RenameUtils\Globals', 'DM_RenameUtils\gui'
;

const
  // ;>========================================================
  // ;>===        CHANGE THESE TO SUIT YOUR NEEDS         ===<;
  // ;>========================================================
  defaultDebugMode = false;         // Set to true if you wish
  defaultGetAllArmorTags = false;   // Set to true if you wish
  gExt = '.csv';                    // Extension of the import/export file

  // ;>========================================================
  // ;>===          DON'T CHANGE ANYTHING BELOW           ===<;
  // ;>========================================================
  chSig = 'FULL';       // Signature to change

  // All processing modes this script is capable of
  ptUndefined = 0;

  ptReplace = 100;
  ptPrepend = 200;
  ptPrependIf = 250;
  ptAppend = 300;

  ptMoveToFront = 400;
  ptMoveToTail = 500;

  ptTrimFront = 600;
  ptTrimAll = 700;
  ptTrimTail = 800;

  ptGetType = 900;

  ptFileExport = 1000;
  ptFileImport = 1100;

  ptAuto = 1200;
  ptRestore = 1300;
  ptOverride = 1400;
  ptFromEdid = 1500;
  ptDiagnose = 1600;

  pt = 00;

  // Warning strings
  wUserCancel = ' Ending script. Process cancelled by user. ';

  // Error strings
  eNoNameAssigned = '___ Record [%s] has no name. Skipping item.';
  eNoProcessSelected = 'No process has been selected. Shouldn''t have gotten here. Please contact this file''s author.';
  eNoProcessSelected2 = 'No process has been seleced. This is definitely a programming error. Please contact this file''s author.';
  eNoProcessToLog = 'No process to log. This file''s author forgot to add one.';

var
  // Global variables
  gRecordData: IInterface;     // Record to change
  gRecordName: IInterface;     // Record name to change
  gSignature: string;          // Record signature
  gProcessingType: Integer;    // What does the user want to do?
  gDebugMode: Boolean;         // Log changes, but not apply them. Use for debugging purposes.
  gGetAllArmoType: Boolean;    // Get all tags for armors?
  gCaseSensitive: Boolean;     // Unused for the moment
  gTextFile: TStringList;      // File contents for Export/Import
  gWarningAll: TStringList;    // All warnings found for selected records.
  gWarningCurr: TStringList;   // Warnings for currently processed record.

  // This variable is the most used to make changes on names. The user is prompted
  // to set its value via InputQuery.
  gsFrom: string;

  // This variable is used as a helper to make changes on names. The user is prompted
  // to set its value via InputQuery.
  // As of now, it's only used for replacing strings and "prepend if...".
  gsTo: string;
var
  lDebugIntroOutro: string;     // It says "test" when debugging


{$REGION 'Logging functions'}
// Logs when some name has changed
procedure LogNameChange(AOldName, ANewName: string);
begin
  AddMessage(Format('%-50.50s ->' + #9#9'%s', [AOldName, ANewName]));
end;

// Logs what the user wanted to do
procedure LogParameters;
var
  s, aux1: string;
begin
  if gGetAllArmoType then
    aux1 := 'ALL weapon/armor tags'
  else
    aux1 := 'a single weapon/armor tag';

  case gProcessingType of
    ptReplace: s := Format('Replacing "%s" with "%s"', [gsFrom, gsTo]);
    ptAppend: s := Format('Adding "%s" at the end of the names.', [gsFrom]);
    ptPrepend: s := Format('Adding "%s" at the start of the names.', [gsFrom]);
    ptPrependIf: s := Format('Adding "%s" at the start of the names if they contain "%s"', [gsFrom, gsTo]); //'Adding "' + gsFrom + '" at the start of the names if they contain "' + gsTo + '".';
    ptMoveToTail: s := 'Moving "' + gsFrom + '" to the end.';
    ptMoveToFront: s := 'Moving "' + gsFrom + '" to the beginning.';  
    ptTrimFront: s := 'Removing leading blanks.';  
    ptTrimAll: s := 'Removing leading and trailing blanks.';  
    ptTrimTail: s := 'Removing trailing blanks.';
    ptFileExport: s := Format('Exporting names to "%s.csv".', [gsFrom]);
    ptFileImport: s := Format('Importing names from "%s.csv".', [gsFrom]);
    ptAuto: s := 'Auto mode selected.' + nl + 
      'Remember it will never be 100% perfect because of the way some records are setup and your own defined formats' + nl + 
      '(not this script''s fault, really), but it should be at least 95% reliable.';
    ptGetType: s :=  Format('Getting %s.', [aux1]);
    ptRestore: s :=  'Restoring names from master esp file.';
    ptOverride: s :=  'Writing names to overriding esp plugins.';
    ptFromEdid: s :=  'Getting names from Editor ID (EDID).';
    ptDiagnose: s :=  'Diagnosing potential problems.';
  else
    s := eNoProcessToLog;
  end;
  
  AddMessage(s + nl);
end;

{$ENDREGION}

function HasKeyword(e: IInterface; edid: string): boolean;
var
  kwda: IInterface;
  n: integer;
begin
  Result := false;
  kwda := ElementByPath(e, 'KWDA');
  for n := 0 to ElementCount(kwda) - 1 do
    if GetElementEditValues(LinksTo(ElementByIndex(kwda, n)), 'EDID') = edid then begin
      Result := true;
      Exit;
    end;
end;

{$REGION 'String processing functions'}
procedure PCommit(AOldName, ANewName: string);
begin
  if AOldName = ANewName then Exit;
  if not gDebugMode then SetEditValue(gRecordName, ANewName);
  LogNameChange(AOldName, ANewName);
  // PDiagnose(ANewName);
end;

// Trims leading and trailing blanks from a name.
procedure PTrimAll(AOldItemName: string);
var
  r: string;
begin
  r := Trim(AOldItemName);
  PCommit(AOldItemName, r);
end;

// Trims leading blanks from a name.
procedure PTrimFront(AOldItemName: string);
var
  r: string;
begin
  r := TrimLeft(AOldItemName);
  PCommit(AOldItemName, r);
end;

// Trims trailing blanks from a name.
procedure PTrimTail(AOldItemName: string);
var
  r: string;
begin
  r := TrimRight(AOldItemName);
  PCommit(AOldItemName, r);
end;

// Replaces all ocurrences of AFrom to ATo in AOldItemName. Case sensitive.
procedure PReplace(AOldItemName, AFrom, ATo: string);
var
  r: string;
begin
  if not ContainsStr(AOldItemName, AFrom) then Exit;
  r := StringReplace(AOldItemName, AFrom, ATo, [rfReplaceAll]);
  PCommit(AOldItemName, r);
end;

// Adds a prefix to AOldItemName.
// This function is smart enough to not add the prefix if it's already there,
// but will add it anyway if the user wants to add space characters.
procedure PPrepend(AOldItemName, APrefix: string);
var
  r: string;
begin
  if StartsStr(APrefix, AOldItemName) and (Trim(APrefix) <> '') then Exit;
  r := APrefix + AOldItemName;
  PCommit(AOldItemName, r);
end;

// Adds a prefix to AOldItemName only if certain word is present in the name.
procedure PPrependIf(AOldItemName, APrefix, ACondition: string);
begin
  if ContainsStr(AOldItemName, ACondition) then PPrepend(AOldItemName, APrefix);
end;

// Appends a suffix to AOldItemName.
procedure PAppend(AOldItemName, ASuffix: string);
var
  r: string;
begin
  r := AOldItemName + ASuffix;
  PCommit(AOldItemName, r);
end;

// Finds any ocurrence of AFrom in AOldItemName and moves it to the string start.
// It does nothing if the name already starts with AFrom.
procedure PMoveToFront(AOldItemName, AFrom: string);
var
  r: string;
begin
  if not ContainsStr(AOldItemName, AFrom) or StartsStr(AFrom, AOldItemName) then Exit;
  r := AFrom + ' ' + StringReplace(AOldItemName, AFrom, '', [rfReplaceAll]);
  PCommit(AOldItemName, r);
end;

// Finds any ocurrence of AFrom in AOldItemName and moves it to the string ending.
procedure PMoveToTail(AOldItemName, AFrom: string);
var
  r: string;
begin
  if not ContainsStr(AOldItemName, AFrom) or EndsStr(AFrom, AOldItemName) then Exit;
  r := StringReplace(AOldItemName, AFrom, '', [rfReplaceAll]) + ' ' + AFrom;
  PCommit(AOldItemName, r);
end;

function PGetWAType_WeapKeywords: TStringList;
begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';
  
  Result.Append('WeapTypeBattleaxe=Bx');
  Result.Append('WeapTypeBoundArrow=Br');
  Result.Append('WeapTypeBow=Bw');
  Result.Append('WeapTypeDagger=Dg');
  Result.Append('WeapTypeGreatsword=Gs');
  Result.Append('WeapTypeMace=Mc');
  Result.Append('WeapTypeStaff=St');
  Result.Append('WeapTypeSword=Sw');
  Result.Append('WeapTypeWarAxe=Wx');
  Result.Append('WeapTypeWarhammer=Wh');
end;

function PGetWAType_ArmoKeywords: TStringList;
begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';
  
  // Main tags. These are the first to be searched for when not using the
  // Get All (Types) option.
  Result.Append('ArmorLight=Lt');
  Result.Append('ArmorHeavy=Hv');
  Result.Append('ArmorClothing=Cl');
  Result.Append('ClothingCirclet=Cir');
  Result.Append('ClothingNecklace=Nck');
  Result.Append('ClothingRing=Rng');
  Result.Append('ArmorShield=Sh');
  Result.Append('ArmorJewelry=Jwl');

  // Secondary tags. (Hopefully) Only gotten when used Get All (Types).
  Result.Append('ArmorHelmet=Hlm');
  Result.Append('ArmorCuirass=Cui');
  Result.Append('ArmorGauntlets=Gau');
  Result.Append('ArmorBoots=Boo');

  Result.Append('ClothingHead=Hat');
  Result.Append('ClothingBody=Rob');
  Result.Append('ClothingFeet=Sho');
  Result.Append('ClothingHands=Glo');

  Result.Append('MaterialShieldHeavy=Hvs');
  Result.Append('MaterialShieldLight=Lts');
end;

function PGetWAType_AttrFromKeywords(aKeywordList: TStringList): TStringList;
var 
  i: Integer;
begin
  Result := TStringList.Create;
  
  try
    for i := 0 to aKeywordList.Count - 1 do begin
      if HasKeyword(gRecordData, aKeywordList.Names[i]) then begin
        Result.Add(aKeywordList.ValueFromIndex[i]);
        // r := r + Format(outS, [keys.ValueFromIndex[i]]);
        if not gGetAllArmoType then
          Break;
      end;
    end;
  finally
    aKeywordList.Free;
  end;
end;

// Formats types. 
// From a string list containing
//        'Type1'
//        'Type2'
//        'TypeN'
// to a string in the form 
//        '[Type1][Type2][TypeN]'
function PGetWAType_FmtTypes(aTypeList: TStringList): string;
const
  outS = '[%s]';
var
  i: Integer;
begin
  for i := 0 to aTypeList.Count - 1 do begin
    aTypeList[i] := Format( outS, [aTypeList[i]] );
  end;
  Result := aTypeList.Text;
  Result := Trim(StringReplace(Result, #13, '', [rfReplaceAll, rfIgnoreCase]));
  Result := StringReplace(Result, #10, '', [rfReplaceAll, rfIgnoreCase]);
end;

// Returns name without old types
function PGetWAType_BaseName(aOldName: string; aTypes: TStringList): string;
var
  i: Integer;
begin
  Result := aOldName;
  for i := 0 to aTypes.Count - 1 do begin 
    Result := StringReplace(Result, aTypes[i], '', [rfReplaceAll]);
  end;
end;

function PGetWAType_TypesBySignature: TStringList;
begin
  if (gSignature = 'WEAP') then
    Result := PGetWAType_AttrFromKeywords(PGetWAType_WeapKeywords)
  else if (gSignature = 'ARMO') then
    Result := PGetWAType_AttrFromKeywords(PGetWAType_ArmoKeywords)
  else
    Result := nil
end;

// Prepends weapon/armor type.
procedure PGetWAType(AOldItemName: string);
const
  rtUnkn = 0;
  rtWeap = 10;
  rtArmo = 20;
  outS = '[%s]';
var
  types: TStringList;
  r: string;
begin
  types := PGetWAType_TypesBySignature;
  if types = nil then 
    Exit;     // Signature not supported

  try
    r := PGetWAType_FmtTypes(types) + PGetWAType_BaseName(AOldItemName, types);
    PCommit(AOldItemName, r);
  finally
    types.Free;
  end;
end;

procedure PFileExport;
var
  s, edid, name: string;
begin
  edid := GetEditValue(ElementBySignature(gRecordData, 'EDID'));
  name := GetEditValue(gRecordName);
  s := Format('%s=%s', [edid, name]);

  if not gDebugMode then
    gTextFile.Add(s);
  AddMessage(Format('Exporting "%s" with name "%s"', [edid, name]));
end;

procedure PFileImport;
var
  edid, name, r: string;
  pos: Integer;
begin
  edid := GetEditValue(ElementBySignature(gRecordData, 'EDID'));
  pos := IntToStr(gTextFile.IndexOfName(edid));

  if pos < 0 then
    Exit;
  r := gTextFile.ValueFromIndex[pos];
  name := GetEditValue(gRecordName);
  PCommit(name, r);
end;

procedure PAuto(aOldName: string);
begin
  PCommit(aOldName, GetAutoName(gRecordData));
end;

// Restores a name from master
procedure PRestore(aOldName: string);
var
  e: IInterface;
begin
  e := MasterOrSelf(gRecordData);
  PCommit(aOldName, GetElementEditValues(e, chSig));
end;

// Propagates name to overrides
procedure POverride(aNewName: string);
var
  old: IInterface;
begin
  gRecordData := HighestOverrideOrSelf(gRecordData, iHOverride);
  gRecordName := ElementBySignature(gRecordData, chSig);
  old := GetElementEditValues(gRecordData, chSig);
  PCommit(old, aNewName);
end;

// Separates a string by capitals.  
// Example:
//  'BDO BMSNecklaceBlack' => 'BDO BMS Necklace Black' 
function _SeparateCapitals(aStr: string): string;
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

// Gets a clean name from EDID.  
// Example:
//  '_BDO_BMSNecklaceBlack' => 'BDO BMS Necklace Black' 
procedure PFromEdid(aOldName: string);
var
  s: string;
begin
  s := GetElementEditValues(gRecordData, 'EDID');
  s := StringReplace(s, '_', ' ', [rfReplaceAll]);
  PCommit(aOldName, _SeparateCapitals(s));
end;

// Finds if a name has some repeated word anywhere
function _DiagRepeatedWord(r: TPerlRegex): Boolean;
begin
  r.RegEx := '(\b\w+\b).*\b\1\b';
  Result := r.Match;
end;

procedure _WarningLogCurrent(aMsg: string);
begin 
  gWarningCurr.Add(#9'* ' + aMsg);
end;

procedure _WarningDumpCurrent;
begin
  if gWarningCurr.Count > 0 then
    gWarningAll.Text := gWarningAll.Text + GetEditValue(gRecordName) + nl + gWarningCurr.Text + nl;
end;

procedure _WarningShowAll;
begin
  if gWarningAll.Count > 0 then begin
    AddMessage(nl + nl + lBigSeparator + ' WARNING ' + lBigSeparator + nl);
    AddMessage(gWarningAll.Text + nl + 'REMEMBER ALL THESE WARNINGS NEED TO BE MANUALLY FIXED.');
  end
  else AddMessage(nl + 'No warnings were found.');
end;

// Diagnoses an already processed name to find possible warnings.
procedure PDiagnose(aName: string);
var
  r: TPerlRegex;
begin
  r := TPerlRegex.Create;
  try
    r.Subject := aName;
    if _DiagRepeatedWord(r) then _WarningLogCurrent('Seems to have repeated words.');
  finally
    r.Free;
  end;
end;

// Assigns the method that should be used to process a string, according
// to user input.
// At this point, <gsFrom>, <gsTo>... and all other global variables
// should've been set by the user while using a Delphi Form.
procedure ProcessItemName;
var
  currentName: string;
begin
  currentName := GetEditValue(gRecordName);

  case gProcessingType of
    ptReplace: PReplace(currentName, gsFrom, gsTo);
    ptPrepend: PPrepend(currentName, gsFrom);
    ptPrependIf: PPrependIf(currentName, gsFrom, gsTo);
    ptAppend: PAppend(currentName, gsFrom);

    ptMoveToFront: PMoveToFront(currentName, gsFrom);
    ptMoveToTail: PMoveToTail(currentName, gsFrom);

    ptTrimFront: PTrimFront(currentName);
    ptTrimAll: PTrimAll(currentName);
    ptTrimTail: PTrimTail(currentName);

    ptFileExport: PFileExport;
    ptFileImport: PFileImport;

    ptAuto: PAuto(currentName);

    ptRestore: PRestore(currentName);
    ptOverride: POverride(currentName);
    ptFromEdid: PFromEdid(currentName);
    ptGetType: PGetWAType(currentName);
    
    ptDiagnose: PDiagnose(currentName);
  else
    AddMessage(eNoProcessSelected2);
  end;
end;
{$ENDREGION}

// Shows form and gets all data from it.
function _SetupAndShowForm: Integer;
begin
  Result := 0;
  gDebugMode := defaultDebugMode;
  gGetAllArmoType := defaultGetAllArmorTags;
  gCaseSensitive := false;
  gProcessingType := ptUndefined;
  
  if ShowForm <> mrOk then begin
    AddMessage(Format(lFooter, [wUserCancel, '', TimeToStr(Time)]));
    Result := 1;
  end;

  // No process selected. Abort script.
  if gProcessingType = ptUndefined then begin
    AddMessage(eNoProcessSelected);
    Result := 1;
  end;
end;

procedure _InitLists;
begin
  Auto_LoadConfig;
  gWarningAll := TStringList.Create;
  gWarningCurr := TStringList.Create;
end;

{$REGION 'xEdit processing functions'}
function Initialize: Integer;
var
  t: TStringlist;
begin
  _InitLists;

  Result := _SetupAndShowForm;
  if Result <> 0 then Exit;
  
  // Create file only if it was asked to
  case gProcessingType of
    ptFileExport: gTextFile := TStringlist.Create;
    ptFileImport: begin
      gTextFile := TStringlist.Create;
      gTextFile.LoadFromFile(gsFrom + gExt);
      gTextFile.Sort;
    end;
  end;

  // Logging info
  if gDebugMode then lDebugIntroOutro := 'TEST '
  else lDebugIntroOutro := '';
  AddMessage(Format(lHeadder, ['STARTING BATCH RENAMING', lDebugIntroOutro, TimeToStr(Time)]));
  if gProcessingType <> ptDiagnose then
    AddMessage(nl + 'Only changed names will be shown here.' + nl);
  LogParameters;

  Result := 0;
end;

function Process(ARecord: IInterface): Integer;
begin
  gWarningCurr.Clear;
  
//  gRecordName := ElementByName(ARecord, 'FULL - Name'); // Enable this line in the unlikely case this script process more kind of elements, so the input names would be user friendly.
  gRecordData := ARecord;
  gRecordName := ElementBySignature(ARecord, chSig);     // Disable this line in the unlikely case this script process more kind of elements, so the input names would be user friendly.
  gSignature := Signature(ARecord);

  // No record assigned. Try next record.
  if not Assigned(gRecordName) then begin
    AddMessage(
      Format(eNoNameAssigned, [GetElementEditValues(ARecord, 'EDID')])
    );
    Result := 0;
    Exit;
  end;
  
  // Everything's OK. Continue processing.
  ProcessItemName;
  PDiagnose( GetEditValue(gRecordName) );
  _WarningDumpCurrent;
  Result := 0;
end;

procedure _DestroyLists;
begin
  Auto_UnloadConfig;
  gWarningAll.Free;
  gWarningCurr.Free;
end;

function Finalize: Integer;
begin
  _WarningShowAll;

  if (gProcessingType = ptFileExport) and (not gDebugMode) then begin
    gTextFile.Sort;
    gTextFile.SaveToFile(gsFrom + gExt);
  end;

  AddMessage(Format(lFooter, ['ENDING BATCH RENAMING', lDebugIntroOutro, TimeToStr(Time)]));

  case gProcessingType of
    ptFileExport, ptFileImport: gTextFile.Free;
  end;

  _DestroyLists;

  Result := 0;
end;
{$ENDREGION}

{$REGION '--RegionTemplate--'}
{$ENDREGION}

end.

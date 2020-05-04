{
	Name: xEdit - FULL Batch Renamer
	Author: Carlos Leyva Ayala

    The GetWAType function requires Mathor's MXPF library!
    https://github.com/matortheeternal/mxpf

	This is an xEdit script that modifies the FULL part of a record. 
	In short: it will help you renaming items, weapons, magic, etc.
	
	This software is provided as is. It should be quite harmless 
	because it only modifies names and doesn't give you the chance 
	to modify anything else (which could actually be game breaking).
	Even so, since we live in a society (heh�) that loves to sue for 
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
//,'lib\mteFunctions'
,StrUtils, SysUtils, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Dialogs, System.Classes
;

const
  defaultDebugMode = true;          // Set to false if you wish
  defaultGetAllArmorTags = false;   // Set to true if you wish
  gExt = '.csv';

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

  pt = 00;

  // Logging strings
  lBigSeparator = '################';
  nl = #13#10;
  lHeadFoot = lBigSeparator + ' %s %s(%s) ' + lBigSeparator;
  lHeadder = nl + lHeadFoot;
  lFooter = nl + lHeadFoot + nl;

  // Warning strings
  wUserCancel = ' Ending script. Process cancelled by user. ';

  // Error strings
  eNoNameAssigned = 'Nothing to rename. Skipping item.';
  eNoProcessSelected = 'No process has been selected. Shouldn''t have gotten here. Please contact this file''s author.';
  eNoProcessSelected2 = 'No process has been seleced. This is definitely a programming error. Please contact this file''s author.';
  eNoProcessToLog = 'No process to log. This file''s author forgot to add one.';

  // UI constants
  btnW = 119;
  btnH = 25;

var
  // Global variables
  gRecordData: IInterface;     // Record to change
  gRecordName: IInterface;     // Record name to change
  gSignature: string;          // Record signature
  gProcessingType: Integer;    // What does the user want to do?
  gDebugMode: Boolean;         // Log changes, but not apply them. Use for debugging purposes.
  gGetAllArmoType: Boolean;    // Get all tags for armors?
  gCaseSensitive: Boolean;     // Unused for the moment
  gTextFile: TStringList;        // File contents for Export/Import

  // This variable is the most used to make changes on names. The user is prompted
  // to set its value via InputQuery.
  gsFrom: string;

  // This variable is used as a helper to make changes on names. The user is prompted
  // to set its value via InputQuery.
  // As of now, it's only used for replacing strings and "prepend if�".
  gsTo: string;
var
  frm: TForm;                   // User input form
  chkDebug: TCheckBox;          // Don't write changes if this is checked
  chkGetAllArmoType: TCheckBox; // Get all tags for armors

  lDebugIntroOutro: string;     // It says "test" when debugging


{$REGION 'Logging functions'}
procedure LogNameChange(AOldName, ANewName: string);
begin
{
  Logs when some name has changed
}
  AddMessage(Format('"%s" renamed as "%s"', [AOldName, ANewName]));
end;

procedure LogParameters;
var
  s, aux1: string;
begin
{
  Logs what the user wanted to do
}
  if gGetAllArmoType then
    aux1 := 'ALL weapon/armor tags'
  else
    aux1 := 'a single weapon/armor tag';

  case gProcessingType of
    ptReplace: s := Format('Replacing "%s" with "%s"', [gsFrom, gsTo]);
    ptAppend: s := Format('Adding "%s" at the end of the names.', [gsFrom]);
    ptPrepend: s := Format('Adding "%s" at the start of the names.', [gsFrom]);
    ptPrependIf: s := Format('Adding "%s" at the start of the names if they contain "%s"', [gsFrom, gsTo]); //'Adding "' + gsFrom + '" at the start of the names if they contain "' + gsTo + '".';
    ptGetType:
      s :=  Format('Getting %s.', [aux1]) + nl + nl +
            'IF THIS FUNCTION FAILS, REMEMBER TO DOWNLOAD MXPF LIBRARY AT:' + nl +
            'https://github.com/matortheeternal/mxpf';
    ptMoveToTail: s := 'Moving "' + gsFrom + '" to the end.';
    ptMoveToFront: s := 'Moving "' + gsFrom + '" to the beginning.';  
    ptTrimFront: s := 'Removing leading blanks.';  
    ptTrimAll: s := 'Removing leading and trailing blanks.';  
    ptTrimTail: s := 'Removing trailing blanks.';
    ptFileExport: s := Format('Exporting names to "%s.csv".', [gsFrom]);
    ptFileImport: s := Format('Importing names from "%s.csv".', [gsFrom]);
  else
    s := eNoProcessToLog;
  end;
  
  AddMessage(s + nl);
end;

procedure LogInputqueryFault;
const 
  s = 'Sorry. HAD TO CLOSE, otherwise InputQuery acts weird and won''t get your input. Someday I''ll find a workaround to this problem, just not today.';
  sp = '****************************************************';
begin
{
  Sadly, DelphiScript is not full fledged Delphi. Even though DelphiScript supports
  "out" variables, they seem to act somewhat weird under certain conditions.
  
  It was my desire not to close the Form when user cancels an input, so to give
  them a chance to try again, but InputQuery just starts acting weird when doing
  so; it opens the message prompt with some Chinese characters in the edit box
  and once it does that, I get blank values instead of what the user wrote.
  
  It may be a problem on DelphiScript or it may be the way xEdit calls DelphiScript,
  I don't know. Maybe some day I'll get to find a workaround for that problem.
  In the meantime, this message tells the user I'm aware of this behavior and I 
  also think it's annoying.
}
  AddMessage(sp);
  AddMessage(s);
  AddMessage(sp);
end;
{$ENDREGION}

{$REGION 'String processing functions'}
procedure PCommit(AOldName, ANewName: string);
begin
  if not gDebugMode then
    SetEditValue(gRecordName, ANewName);
  LogNameChange(AOldName, ANewName);
end;

procedure PTrimAll(AOldItemName: string);
var
  r: string;
begin
{
Trims leading and trailing blanks from a name.
}
  r := Trim(AOldItemName);
  if r = AOldItemName then
    Exit;
  PCommit(AOldItemName, r);
end;

procedure PTrimFront(AOldItemName: string);
var
  r: string;
begin
{
Trims leading blanks from a name.
}
  r := TrimLeft(AOldItemName);
  if r = AOldItemName then
    Exit;
  PCommit(AOldItemName, r);
end;

procedure PTrimTail(AOldItemName: string);
var
  r: string;
begin
{
Trims trailing blanks from a name.
}
  r := TrimRight(AOldItemName);
  if r = AOldItemName then
    Exit;
  PCommit(AOldItemName, r);
end;

procedure PReplace(AOldItemName, AFrom, ATo: string);
var
  r: string;
begin
{
  Replaces all ocurrences of AFrom to ATo in AOldItemName.
}
  if not ContainsStr(AOldItemName, AFrom) then
    Exit;
  r := StringReplace(AOldItemName, AFrom, ATo, [rfReplaceAll]);
  PCommit(AOldItemName, r);
end;

procedure PPrepend(AOldItemName, APrefix: string);
var
  r: string;
begin
{
Adds a prefix to AOldItemName.
This function is smart enough to not add the prefix if it's already there,
but will add it anyway if the user wants to add space characters.
}
  if StartsStr(APrefix, AOldItemName) and (Trim(APrefix) <> '') then
    Exit;

  r := APrefix + AOldItemName;
  PCommit(AOldItemName, r);
end;

procedure PPrependIf(AOldItemName, APrefix, ACondition: string);
begin
{
Adds a prefix to AOldItemName only if certain word is present in the name.
}
  if ContainsStr(AOldItemName, ACondition) then begin
    PPrepend(AOldItemName, APrefix);
  end;
end;

procedure PAppend(AOldItemName, ASuffix: string);
var
  r: string;
begin
{
Appends a suffix to AOldItemName.
}
  r := AOldItemName + ASuffix;
  PCommit(AOldItemName, r);
end;

procedure PMoveToFront(AOldItemName, AFrom: string);
var
  r: string;
begin
{
  Finds any ocurrence of AFrom in AOldItemName and moves it to the string start.
  It does nothing if the name already starts with AFrom.
}
  if not ContainsStr(AOldItemName, AFrom) or StartsStr(AFrom, AOldItemName) then
    Exit;

  r := AFrom + ' ' + StringReplace(AOldItemName, AFrom, '', [rfReplaceAll]);
  PCommit(AOldItemName, r);
end;

procedure PMoveToTail(AOldItemName, AFrom: string);
var
  r: string;
begin
{
  Finds any ocurrence of AFrom in AOldItemName and moves it to the string ending.
}
  if not ContainsStr(AOldItemName, AFrom) or EndsStr(AFrom, AOldItemName) then
    Exit;

  r := StringReplace(AOldItemName, AFrom, '', [rfReplaceAll]) + ' ' + AFrom;
  PCommit(AOldItemName, r);
end;

procedure PGetWAType_InitWeap(AList: TStringList);
begin
  AList.Append('WeapTypeBattleaxe=Bx');
  AList.Append('WeapTypeBoundArrow=Br');
  AList.Append('WeapTypeBow=Bw');
  AList.Append('WeapTypeDagger=Dg');
  AList.Append('WeapTypeGreatsword=Gs');
  AList.Append('WeapTypeMace=Mc');
  AList.Append('WeapTypeStaff=St');
  AList.Append('WeapTypeSword=Sw');
  AList.Append('WeapTypeWarAxe=Wx');
  AList.Append('WeapTypeWarhammer=Wh');
end;

procedure PGetWAType_InitArmo(AList: TStringList);
begin
  // PGetWAType: Possible armor tags
  AList.Append('ArmorLight=Lt');
  AList.Append('ArmorHeavy=Hv');
  AList.Append('ArmorClothing=Cl');
  AList.Append('ClothingCirclet=Cir');
  AList.Append('ClothingNecklace=Nck');
  AList.Append('ClothingRing=Rng');
  AList.Append('ArmorShield=Sh');
  AList.Append('ArmorJewelry=Jwl');

  AList.Append('ArmorHelmet=Hlm');
  AList.Append('ArmorCuirass=Cui');
  AList.Append('ArmorGauntlets=Gau');
  AList.Append('ArmorBoots=Boo');

  AList.Append('ClothingHead=Hat');
  AList.Append('ClothingBody=Rob');
  AList.Append('ClothingFeet=Sho');
  AList.Append('ClothingHands=Glo');

  AList.Append('MaterialShieldHeavy=Hvs');
  AList.Append('MaterialShieldLight=Lts');
end;

procedure PGetWAType(AOldItemName: string);
const
  rtUnkn = 0;
  rtWeap = 10;
  rtArmo = 20;
  outS = '[%s]';
var
  keys: TStringList;
  rType: Integer;
  i: Integer;
  r: string;
begin
{
  Prepends weapon/armor type.

  This function requires Mathor's MXPF library!
  https://github.com/matortheeternal/mxpf

}
  if (gSignature = 'WEAP') then
    rType := rtWeap
  else if (gSignature = 'ARMO') then
    rType := rtArmo
  else
    Exit;

  keys := TStringList.Create;
  try
    keys.NameValueSeparator := '=';
    case rType of
      rtWeap: PGetWAType_InitWeap(keys);
      rtArmo: PGetWAType_InitArmo(keys);
    end;

    // Prepend tags
    r := '';
    for i := 0 to keys.Count - 1 do begin
      if HasKeyword(gRecordData, keys.Names[i]) then begin
        r := r + Format(outS, [keys.ValueFromIndex[i]]);
        if not gGetAllArmoType then
          Break;
      end;
    end;

    r := r + AOldItemName;
    if r = AOldItemName then
      Exit;
    PCommit(AOldItemName, r);
  finally
    keys.Free;
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

procedure ProcessItemName;
var
  currentName: string;
begin
{
  Assigns the method that should be used to process a string, according
  to the user input.
  At this point, <gsFrom>, <gsTo>... and all other global variables
  should've been set by the user while using a Delphi Form.
}
  currentName := GetEditValue(gRecordName);

  case gProcessingType of
    ptReplace: PReplace(currentName, gsFrom, gsTo);
    ptPrepend: PPrepend(currentName, gsFrom);
    ptPrependIf: PPrependIf(currentName, gsFrom, gsTo);
    ptAppend: PAppend(currentName, gsFrom);

    ptGetType: PGetWAType(currentName);

    ptMoveToFront: PMoveToFront(currentName, gsFrom);
    ptMoveToTail: PMoveToTail(currentName, gsFrom);

    ptTrimFront: PTrimFront(currentName);
    ptTrimAll: PTrimAll(currentName);
    ptTrimTail: PTrimTail(currentName);

    ptFileExport: PFileExport;
    ptFileImport: PFileImport;
  else
    AddMessage(eNoProcessSelected2);
  end;
end;
{$ENDREGION}

{$REGION 'Form functions'}

procedure CloseInputqueryFault;
begin
{
See the description of LogInputqueryFault() to more info.
}
  LogInputqueryFault; 

  gProcessingType := ptUndefined;
  frm.Close;
  frm.ModalResult := mrCancel;
end;

function PromptGsFrom(ACaption, APrompt: string): Boolean;
begin
{
Asks the user to set the global variable <gsFrom>. This should be the 
only place where that variable is changed.
}
  Result := InputQuery(ACaption, APrompt, gsFrom);
end;

function PromptGsTo(ACaption, APrompt: string): Boolean;
begin
{
Asks the user to set the global variable <gsTo>. This should be the 
only place where that variable is changed. 
}
  Result := InputQuery(ACaption, APrompt, gsTo);
end;

procedure OnBtnReplaceClick(Sender: TObject);
begin
  if not PromptGsFrom('Replace word', 'From: ') then begin
    CloseInputqueryFault;
    Exit;
  end;

  if not PromptGsTo('Replace word', 'To: ') then begin
    CloseInputqueryFault;
    Exit;
  end;
    
  gProcessingType := ptReplace;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnPrependIfClick(Sender: TObject);
begin
  if not PromptGsFrom('Prepend word if', 'Prepend this: ') then begin
    CloseInputqueryFault;
    Exit;
  end;

  if not PromptGsTo('Prepend word if', 'If this word exists: ') then begin
    CloseInputqueryFault;
    Exit;
  end;
    
  gProcessingType := ptPrependIf;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnPrependClick(Sender: TObject);
begin
  if not PromptGsFrom('Prepend word', 'Prepend this: ') then begin
    CloseInputqueryFault;
    Exit;
  end;
    
  gProcessingType := ptPrepend;
  frm.Close;
  frm.ModalResult := mrOk;
end;

 procedure OnBtnAppendClick(Sender: TObject);
begin
  if not PromptGsFrom('Append word', 'Append this: ') then begin
    CloseInputqueryFault;
    Exit;
  end;
    
  gProcessingType := ptAppend;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnMoveFrontClick(Sender: TObject);
begin
  if not PromptGsFrom('Move to front', 'Move this: ') then begin
    CloseInputqueryFault;
    Exit;
  end;
    
  gProcessingType := ptMoveToFront;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnMoveTailClick(Sender: TObject);
begin
  if not PromptGsFrom('Move to tail', 'Move this: ') then begin
    CloseInputqueryFault;
    Exit;
  end;
    
  gProcessingType := ptMoveToTail;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnFileExportClick(Sender: TObject);
begin
  if not PromptGsFrom('Export to file', 'File name (without extension): ') then begin
    CloseInputqueryFault;
    Exit;
  end;

  gProcessingType := ptFileExport;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnFileImportClick(Sender: TObject);
begin
  if not PromptGsFrom('Import from file', 'File name (without extension): ') then begin
    CloseInputqueryFault;
    Exit;
  end;

  gProcessingType := ptFileImport;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnTrimFrontClick;
begin
  gProcessingType := ptTrimFront;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnTrimAllClick;
begin
  gProcessingType := ptTrimAll;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnTrimTailClick;
begin
  gProcessingType := ptTrimTail;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnGetTypeClick;
begin
  gProcessingType := ptGetType;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnChkDebugClick(Sender: TObject);
begin
  gDebugMode := chkDebug.Checked;
end;

procedure OnChkGetAllArmoTypeClick(Sender: TObject);
begin
  gGetAllArmoType := chkGetAllArmoType.Checked;
end;


function CreateButton(x, y: Integer; AFrm: TForm; AParent: TControl): TButton;
begin
  Result := TButton.Create(AFrm);
  Result.Parent := AParent;
  Result.Left := x;
  Result.Top := y;
  Result.Width := btnW;
  Result.Height := btnH;
end;

function CreateGroupbx(x, y, dx, nButtons: Integer; AFrm: TForm; AParent: TControl): TGroupBox;
const
  grpH = 65;
begin
    Result := TGroupBox.Create(AFrm);
    Result.Parent := AParent;
    Result.Left := x;
    Result.Top := y;
    Result.Width := (dx * (nButtons + 1)) + (btnW * nButtons);
    Result.Height := grpH;
end;

function ShowForm: Integer;
var
  btnExit, btnReplace, btnMoveFront, btnMoveTail, btnAppend, btnPrepend,
  btnPrependIf, btnTrimFront, btnTrimAll, btnTrimTail, btnGetType,
  btnFExport, btnFImport: TButton;
  grpMove, grpTrim, grpFile: TGroupBox;
const
  bigDY = 24;

  btnL = 24;
  btnT = 30;
  btnDY = 6;

  grpL = 200;
  grpH = 65;
  grpDY = 12;
  grpBtnT = 24;
  grpBtnDX = 19;
  grpBtnL = grpBtnDX;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := 'xEdit - FULL Batch Renamer';
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;
    frm.ShowHint := true;
    frm.Height := 370;
    frm.Width := 630;

    btnReplace := CreateButton(btnL, btnT, frm, frm);
    btnReplace.Caption := '&Replace';
    btnReplace.Hint := 'Replaces a part of the name with other';

    btnPrepend := CreateButton(btnL, btnT + btnH + bigDY, frm, frm);
    btnPrepend.Caption := '&Prepend';
    btnPrepend.Hint := 'Adds some word at the start of the name';

    btnPrependIf := CreateButton(btnL, btnPrepend.Top + btnH + btnDY, frm, frm);
    btnPrependIf.Caption := 'Prepend &if…';
    btnPrependIf.Hint := 'Adds some word at the start of the name if it contains some word';

    btnAppend := CreateButton(btnL, btnPrepend.Top + (btnH + btnDY) * 2, frm, frm);
    btnAppend.Caption := '&Append';
    btnAppend.Hint := 'Adds some word at the end of the name';

    /////////////////////////////////////////
    grpMove := CreateGroupbx(grpL, bigDY, grpBtnDX, 2, frm, frm);
    grpMove.Caption := 'Move to';

    btnMoveFront := CreateButton(grpBtnL, grpBtnT, frm, grpMove);
    btnMoveFront.Caption := '&Front';
    btnMoveFront.Hint := 'Moves some word to the beginning of the name';
    
    btnMoveTail := CreateButton(grpBtnL + btnW + grpBtnDX, grpBtnT, frm, grpMove);
    btnMoveTail.Caption := '&Tail';
    btnMoveTail.Hint := 'Moves some word to the end of the name';
    
    /////////////////////////////////////////    
    grpTrim := CreateGroupbx(grpL, grpMove.Top + grpH + grpDY, grpBtnDX, 3, frm, frm);
    grpTrim.Caption := 'Trim';

    btnTrimFront := CreateButton(grpBtnL, grpBtnT, frm, grpTrim);
    btnTrimFront.Caption := 'Front';
    btnTrimFront.Hint := 'Deletes leading blank spaces';
    
    btnTrimAll := CreateButton(grpBtnL + btnW + grpBtnDX, grpBtnT, frm, grpTrim);
    btnTrimAll.Caption := 'All';
    btnTrimAll.Hint := 'Deletes leading and trailing blank spaces';

    btnTrimTail := CreateButton(grpBtnL + (btnW + grpBtnDX) * 2, grpBtnT, frm, grpTrim);
    btnTrimTail.Caption := 'Tail';
    btnTrimTail.Hint := 'Deletes trailing blank spaces';

    /////////////////////////////////////////
    grpFile := CreateGroupbx(grpL, grpTrim.Top + grpH + grpDY, grpBtnDX, 2, frm, frm);
    grpFile.Caption := 'File operations';

    btnFExport := CreateButton(grpBtnL, grpBtnT, frm, grpFile);
    btnFExport.Caption := 'Export';
    btnFExport.Hint := 'Writes record name(s) to a file';

    btnFImport := CreateButton(grpBtnL + btnW + grpBtnDX, grpBtnT, frm, grpFile);
    btnFImport.Caption := 'Import';
    btnFImport.Hint := 'Reads record name(s) from a file';

    /////////////////////////////////////////
    btnGetType := CreateButton(grpL, grpFile.Top + (btnH + btnDY) * 3, frm, frm);
    btnGetType.Caption := 'Get t&ype';
    btnGetType.Hint := 'Prepends weapon/armor type. Needs Mathor''s mxpf!';

    chkGetAllArmoType := TCheckBox.Create(frm);
    chkGetAllArmoType.Parent := frm;
    chkGetAllArmoType.Caption := '&Get all';
    chkGetAllArmoType.Checked := gGetAllArmoType;
    chkGetAllArmoType.Width := btnW;
    chkGetAllArmoType.Left := btnGetType.Left + btnW + grpBtnDX;
    chkGetAllArmoType.Top := btnGetType.Top + (btnGetType.Height div 2)
      - (chkGetAllArmoType.Height div 2);
    chkGetAllArmoType.Hint := 'When checked, gets all tags an armor has';

    /////////////////////////////////////////
    chkDebug := TCheckBox.Create(frm);
    chkDebug.Parent := frm;
    chkDebug.Caption := '&Don'#39't apply changes';
    chkDebug.Checked := gDebugMode;
    chkDebug.Width := btnW;
    chkDebug.Left := btnL;
    chkDebug.Top := btnGetType.Top + btnH +  bigDY;
    chkDebug.Hint := 'Shows you the output of your operation, but doesn'#39't actually make changes on your file. Useful for testing purposes.';

    btnExit := TButton.Create(frm);
    btnExit.Parent := frm;
    btnExit.Caption := 'Exit';
    btnExit.Top := chkDebug.Top + bigDY;
    btnExit.Width := 225;
    btnExit.Left := (frm.Width div 2) - (btnExit.Width div 2);
    btnExit.Cancel := true;
    btnExit.ModalResult := mrCancel;

    /////////////////////////////////////////    
    // OnClick events
    btnReplace.OnClick := OnBtnReplaceClick;
    btnPrepend.OnClick := OnBtnPrependClick;
    btnPrependIf.OnClick := OnBtnPrependIfClick;
    btnAppend.OnClick := OnBtnAppendClick;
    btnGetType.OnClick := OnBtnGetTypeClick;
    btnMoveFront.OnClick := OnBtnMoveFrontClick;
    btnMoveTail.OnClick := OnBtnMoveTailClick;
    btnTrimFront.OnClick := OnBtnTrimFrontClick;
    btnTrimAll.OnClick := OnBtnTrimAllClick;
    btnTrimTail.OnClick := OnBtnTrimTailClick;
    btnFExport.OnClick := OnBtnFileExportClick;
    btnFImport.OnClick := OnBtnFileImportClick;
    chkDebug.OnClick := OnChkDebugClick;
    chkGetAllArmoType.OnClick := OnChkGetAllArmoTypeClick;

    /////////////////////////////////////////    
    // Procedurally adjust form
    frm.ClientWidth := grpTrim.Left + grpTrim.Width + btnL;
    frm.ClientHeight := btnExit.Top + btnH + bigDY;
    
    Result := frm.ShowModal;
  finally
    frm.Release;
  end;
end;
{$ENDREGION}

{$REGION 'xEdit processing functions'}
function Initialize: Integer;
var
  t: TStringlist;
begin
  gDebugMode := defaultDebugMode;
  gGetAllArmoType := defaultGetAllArmorTags;
  gCaseSensitive := false;
  gProcessingType := ptUndefined;

  if ShowForm <> mrOk then begin
    AddMessage(Format(lFooter, [wUserCancel, '', TimeToStr(Time)]));
    Result := 1;
    Exit;
  end;

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
  if gDebugMode then
    lDebugIntroOutro := 'TEST '
  else
    lDebugIntroOutro := '';
  AddMessage(Format(lHeadder, ['STARTING BATCH RENAMING', lDebugIntroOutro, TimeToStr(Time)]));
  LogParameters;

  Result := 0;
end;

function Process(ARecord: IInterface): Integer;
begin
//  gRecordName := ElementByName(ARecord, 'FULL - Name'); // Enable this line in the unlikely case this script process more kind of elements, so the input names would be user friendly.
  gRecordData := ARecord;
  gRecordName := ElementBySignature(ARecord, 'FULL');     // Disable this line in the unlikely case this script process more kind of elements, so the input names would be user friendly.
  //gRecordName := ElementBySignature(ARecord, 'DESC');
  gSignature := Signature(ARecord);

  // No record assigned. Try next record.
  if not Assigned(gRecordName) then begin
    AddMessage(eNoNameAssigned);
    Result := 0;
    Exit;
  end;

  // No process selected. Abort script.
  if gProcessingType = ptUndefined then begin
    AddMessage(eNoProcessSelected);
    Result := 1;
    Exit;
  end;

  // Everything's OK. Continue processing.
  ProcessItemName;
  Result := 0;
end;

function Finalize: Integer;
begin
  if (gProcessingType = ptFileExport) and (not gDebugMode) then begin
    gTextFile.Sort;
    gTextFile.SaveToFile(gsFrom + gExt);
  end;

  AddMessage(Format(lFooter, ['ENDING BATCH RENAMING', lDebugIntroOutro, TimeToStr(Time)]));

  case gProcessingType of
    ptFileExport, ptFileImport: gTextFile.Free;
  end;

  Result := 0;
end;
{$ENDREGION}

{$REGION '--RegionTemplate--'}
{$ENDREGION}

end.

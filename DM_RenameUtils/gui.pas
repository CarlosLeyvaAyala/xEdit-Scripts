unit gui;

var
  frm: TForm;                   // User input form

const
  cancelStr = '***ThIsF0rMw4SCaNcEL1eD!!111***';  // Made to deal with strange InputQuery behavior

  // UI constants
  btnW = 160;
  btnH = 42;
  ctrlDX = 24;
  ctrlDY = 10;
  bigDY = 24;

var
    guiFrom: string;

// Asks the user to input a value. Made to deal with InputQuery bullshit behavior.
function _PromptQuery(ACaption, APrompt: string): string;
var
  accept: Boolean;
begin
  accept := InputQuery(ACaption, APrompt, Result);
  if not accept then Result := cancelStr;
end;

// Sets the value of <gsFrom> based on user input. Returns to form if promt was cancelled.
// This should be the only place this variable is changed.
function _SetGsFrom(ACaption, APrompt: string): Boolean;
var
  s: string;
begin
  s := _PromptQuery(ACaption, APrompt);
  if s = cancelStr then
    Result := false
  else begin
    gsFrom := s;
    Result := true;
  end;
end;

// Sets the value of <gsTo> based on user input. Returns to form if promt was cancelled.
// This should be the only place this variable is changed.
function _SetGsTo(ACaption, APrompt: string): Boolean;
var
  s: string;
begin
  s := _PromptQuery(ACaption, APrompt);
  if s = cancelStr then
    Result := false
  else begin
    gsTo := s;
    Result := true;
  end;
end;

// Closes form and sets what kind of processing will be done.
procedure _ContinueProcessing(aProcessingType: Integer);
begin
  gProcessingType := aProcessingType;
  frm.Close;
  frm.ModalResult := mrOk;
end;

procedure OnBtnReplaceClick(Sender: TObject);
const
  p = 'Replace word';
begin
  if _SetGsFrom(p, 'From: ') then
    if _SetGsTo(p, 'To: ') then
      _ContinueProcessing(ptReplace);
end;

procedure OnBtnRegexClick(Sender: TObject);
const
  p = 'Use regular expression';
begin
  if _SetGsFrom(p, 'From: ') then
    if _SetGsTo(p, 'To: ') then
      _ContinueProcessing(ptRegex);
end;

procedure OnBtnPrependIfClick(Sender: TObject);
const
  p = 'Prepend word if';
begin
  if _SetGsFrom(p, 'Prepend this: ') then
    if _SetGsTo(p, 'If this word exists: ') then
      _ContinueProcessing(ptPrependIf);
end;

procedure OnBtnPrependClick(Sender: TObject);
begin
  if _SetGsFrom('Prepend word', 'Prepend this: ') then _ContinueProcessing(ptPrepend);
end;

procedure OnBtnAppendClick(Sender: TObject);
begin
  if _SetGsFrom('Append word', 'Append this: ') then _ContinueProcessing(ptAppend);
end;

procedure OnBtnMoveFrontClick(Sender: TObject);
begin
  if _SetGsFrom('Move to front', 'Move this: ') then _ContinueProcessing(ptMoveToFront);
end;

procedure OnBtnMoveTailClick(Sender: TObject);
begin
  if _SetGsFrom('Move to tail', 'Move this: ') then _ContinueProcessing(ptMoveToTail);
end;

procedure OnBtnFileExportClick(Sender: TObject);
begin
  if _SetGsFrom('Export to file', 'File name (without extension): ') then
    _ContinueProcessing(ptFileExport);
end;

procedure OnBtnFileImportClick(Sender: TObject);
begin
  if _SetGsFrom('Import from file', 'File name (without extension): ') then
    _ContinueProcessing(ptFileImport);
end;

procedure OnBtnListClick;
begin
  _ContinueProcessing(ptList);
end;

procedure OnBtnTrimFrontClick;
begin
  _ContinueProcessing(ptTrimFront);
end;

procedure OnBtnTrimAllClick;
begin
  _ContinueProcessing(ptTrimAll);
end;

procedure OnBtnTrimTailClick;
begin
  _ContinueProcessing(ptTrimTail);
end;

procedure OnBtnGetTypeClick;
begin
  _ContinueProcessing(ptGetType);
end;

procedure OnBtnAutoClick;
begin
  _ContinueProcessing(ptAuto);
end;

procedure OnBtnRestoreClick;
begin
  _ContinueProcessing(ptRestore);
end;

procedure OnBtnOverrideClick;
begin
  _ContinueProcessing(ptOverride);
end;

procedure OnBtnFromEdidClick;
begin
  _ContinueProcessing(ptFromEdid);
end;

procedure OnBtnDiagnoseClick;
begin
  _ContinueProcessing(ptDiagnose);
end;

procedure OnChkDebugClick(Sender: TObject);
begin
  gDebugMode := TCheckBox(Sender).Checked;
end;

procedure OnChkExtDebugInfoClick(Sender: TObject);
begin
  gExtDebugInfo := TCheckBox(Sender).Checked;
end;

procedure OnChkGetAllArmoTypeClick(Sender: TObject);
begin
  gGetAllArmoType := TCheckBox(Sender).Checked;
end;

function CreateButton(AParent: TControl): TButton;
begin
  Result := TButton.Create(frm);
  Result.Parent := AParent;
  Result.Left := 0;
  Result.Top := 0;
  Result.Width := btnW;
  Result.Height := btnH;
end;

// function CreateGroupbx(x, y, dx, nButtons: Integer; AFrm: TForm; AParent: TControl): TGroupBox;
function CreateGroupbx(AParent: TControl): TGroupBox;
const
  grpH = 65;
begin
    Result := TGroupBox.Create(frm);
    Result.Parent := AParent;
    Result.Left := 0;
    Result.Top := 0;
    Result.Width := btnW;
    Result.Height := btnH;
end;

function _CreateCheckbox(AParent: TControl; aChecked: Boolean): TCheckBox;
begin
  Result := TCheckBox.Create(frm);
  Result.Parent := AParent;
  Result.Checked := aChecked;
  Result.Width := btnW;
  Result.Height := btnH;
end;

// Places a control below other
procedure _Below(me, he: TControl);
begin
  me.Left := he.Left;
  me.Top := he.Top + he.Height + ctrlDY;
end;

procedure _NextTo(me, he: TControl);
begin
  me.Left := he.Left + he.Width + ctrlDX;
  me.Top := he.Top;
end;

procedure _MoveTo(aCtrl: TControl; x, y: Integer);
begin
  aCtrl.Left := x;
  aCtrl.Top := y;
end;

procedure _MoveBy(aCtrl: TControl; x, y: Integer);
begin
  aCtrl.Left := aCtrl.Left + x;
  aCtrl.Top := aCtrl.Top + y;
end;

procedure _FirstGrpBtn(aCtrl: TControl);
begin
  _MoveTo(aCtrl, ctrlDX, ctrlDY * 5);
end;

procedure _AdjustGrpSize(aGrp: TGroupBox);
var
  i, maxW, maxH: Integer;
begin
  maxW := 0;
  maxH := 0;
  for i := 0 to aGrp.ControlCount - 1 do begin
    maxW := Max(aGrp.Controls[i].Left + aGrp.Controls[i].Width, maxW);
    maxH := Max(aGrp.Controls[i].Top + aGrp.Controls[i].Height, maxH);
  end;
  aGrp.Height := maxH + ctrlDY * 3;
  aGrp.Width := maxW + ctrlDX;
end;

function ShowForm: Integer;
var
  btnExit, btnReplace, btnMoveFront, btnMoveTail, btnAppend, btnPrepend,
  btnPrependIf, btnTrimFront, btnTrimAll, btnTrimTail, btnGetType, btnDiagnose,
  btnFExport, btnFImport, btnAuto, btnRestore, btnOverride, btnFromEdid,
  btnList, btnRegex: TButton;
  grpMove, grpTrim, grpFile, grpSemi: TGroupBox;
  chkDebug, chkExtDebugInfo, chkGetAllArmoType: TCheckBox;
const
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

    btnAuto := CreateButton(frm);
    btnAuto.Caption := '&Auto';
    btnAuto.Hint := 'Process using rules defined by you';
    _MoveTo(btnAuto, btnL, btnT);

    btnReplace := CreateButton(frm);
    btnReplace.Caption := '&Replace';
    btnReplace.Hint := 'Replaces a part of the name with other';
    _Below(btnReplace, btnAuto);
    _MoveBy(btnReplace, 0, bigDY);

    btnRegex := CreateButton(frm);
    btnRegex.Caption := 'Rege&x';
    btnRegex.Hint := 'Replaces a string using a regular expression';
    _Below(btnRegex, btnReplace);

    btnPrepend := CreateButton(frm);
    btnPrepend.Caption := '&Prepend';
    btnPrepend.Hint := 'Adds some word at the start of the name';
    _Below(btnPrepend, btnRegex);

    btnPrependIf := CreateButton(frm);
    btnPrependIf.Caption := 'Prepend &if...';
    btnPrependIf.Hint := 'Adds some word at the start of the name if it contains some word';
    _Below(btnPrependIf, btnPrepend);

    btnAppend := CreateButton(frm);
    btnAppend.Caption := 'App&end';
    btnAppend.Hint := 'Adds some word at the end of the name';
    _Below(btnAppend, btnPrependIf);

    btnList := CreateButton(frm);
    btnList.Caption := 'List';
    btnList.Hint := 'Lists current selected names';
    _Below(btnList, btnAppend);

    btnDiagnose := CreateButton(frm);
    btnDiagnose.Caption := 'Diagnose';
    btnDiagnose.Hint := 'Tries to find potential problems with names in selected records.';
    _Below(btnDiagnose, btnList);
    _MoveBy(btnDiagnose, 0, bigDY);

    /////////////////////////////////////////
    grpMove := CreateGroupbx(frm);
    grpMove.Caption := 'Move to';
    _NextTo(grpMove, btnAuto);
    _MoveBy(grpMove, ctrlDX, 0);

    btnMoveFront := CreateButton(grpMove);
    btnMoveFront.Caption := '&Front';
    btnMoveFront.Hint := 'Moves some word to the beginning of the name';
    _FirstGrpBtn(btnMoveFront);

    btnMoveTail := CreateButton(grpMove);
    btnMoveTail.Caption := '&Tail';
    btnMoveTail.Hint := 'Moves some word to the end of the name';
    _NextTo(btnMoveTail, btnMoveFront);

    _AdjustGrpSize(grpMove);

    /////////////////////////////////////////
    grpTrim := CreateGroupbx(frm);
    grpTrim.Caption := 'Trim';
    _Below(grpTrim, grpMove);
    _MoveBy(grpTrim, 0, ctrlDY * 2);

    btnTrimFront := CreateButton(grpTrim);
    btnTrimFront.Caption := 'Front';
    btnTrimFront.Hint := 'Deletes leading blank spaces';
    _FirstGrpBtn(btnTrimFront);

    btnTrimAll := CreateButton(grpTrim);
    btnTrimAll.Caption := 'All';
    btnTrimAll.Hint := 'Deletes leading and trailing blank spaces';
    _NextTo(btnTrimAll, btnTrimFront);

    btnTrimTail := CreateButton(grpTrim);
    btnTrimTail.Caption := 'Tail';
    btnTrimTail.Hint := 'Deletes trailing blank spaces';
    _NextTo(btnTrimTail, btnTrimAll);

    _AdjustGrpSize(grpTrim);

    /////////////////////////////////////////
    grpFile := CreateGroupbx(frm);
    grpFile.Caption := 'File operations';
    _Below(grpFile, grpTrim);
    _MoveBy(grpFile, 0, ctrlDY * 2);

    btnFExport := CreateButton(grpFile);
    btnFExport.Caption := 'Export';
    btnFExport.Hint := 'Writes record name(s) to a file';
    _FirstGrpBtn(btnFExport);

    btnFImport := CreateButton(grpFile);
    btnFImport.Caption := 'Import';
    btnFImport.Hint := 'Reads record name(s) from a file';
    _NextTo(btnFImport, btnFExport);

    _AdjustGrpSize(grpFile);

    /////////////////////////////////////////
    grpSemi := CreateGroupbx(frm);
    grpSemi.Caption := 'Semi-automatic operations';
    _Below(grpSemi, grpFile);
    _MoveBy(grpSemi, 0, ctrlDY * 2);

    btnRestore := CreateButton(grpSemi);
    btnRestore.Caption := 'Re&store';
    btnRestore.Hint := 'Gets the name defined in the first *.esp loaded right now.';
    _FirstGrpBtn(btnRestore);

    btnOverride := CreateButton(grpSemi);
    btnOverride.Caption := '&Override';
    btnOverride.Hint := 'Copies current name to the lastest *.esp loaded right now.';
    _NextTo(btnOverride, btnRestore);

    btnFromEdid := CreateButton(grpSemi);
    btnFromEdid.Caption := 'From EDID';
    btnFromEdid.Hint := 'Copies EDID to FULL. Useful to easily translate to english.';
    _NextTo(btnFromEdid, btnOverride);

    btnGetType := CreateButton(grpSemi);
    btnGetType.Caption := 'Get t&ype';
    btnGetType.Hint := 'Prepends weapon/armor/spell type.';
    _Below(btnGetType, btnRestore);

    chkGetAllArmoType := _CreateCheckbox(grpSemi, gGetAllArmoType);
    chkGetAllArmoType.Caption := '&Get all';
    chkGetAllArmoType.Hint := 'When checked, gets all tags an armor has';
    _NextTo(chkGetAllArmoType, btnGetType);
    _MoveBy(chkGetAllArmoType, 0, btnH div 8);

    _AdjustGrpSize(grpSemi);

    /////////////////////////////////////////

    chkDebug := _CreateCheckbox(frm, gDebugMode);
    chkDebug.Caption := '&Don'#39't apply';
    chkDebug.Hint := 'Shows you the output of your operation, but doesn'#39't actually make changes on your file. Useful for testing purposes.';
    _Below(chkDebug, btnDiagnose);
    _MoveBy(chkDebug, 0, bigDY * 2);

    chkExtDebugInfo := _CreateCheckbox(frm, gExtDebugInfo);
    chkExtDebugInfo.Caption := 'Ext. Info';
    chkExtDebugInfo.Hint := 'Writes more info to xEdit Messages. Use if you aren''t getting what you wanted.';
    _Below(chkExtDebugInfo, chkDebug);
    _MoveBy(chkExtDebugInfo, 0, Round(-ctrlDY * 3/2));

    btnExit := CreateButton(frm);
    btnExit.Caption := 'Exit';
    _Below(btnExit, grpSemi);
    _MoveBy(btnExit, 0, bigDY * 2);
    btnExit.Width := 225;
    btnExit.Cancel := true;
    btnExit.ModalResult := mrCancel;

    /////////////////////////////////////////
    // OnClick events
    btnAuto.OnClick := OnBtnAutoClick;
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
    btnRestore.OnClick := OnBtnRestoreClick;
    btnOverride.OnClick := OnBtnOverrideClick;
    btnFromEdid.OnClick := OnBtnFromEdidClick;
    btnDiagnose.OnClick := OnBtnDiagnoseClick;
    btnList.OnClick := OnBtnListClick;
    btnRegex.OnClick := OnBtnRegexClick;
    chkDebug.OnClick := OnChkDebugClick;
    chkExtDebugInfo.OnClick := OnChkExtDebugInfoClick;
    chkGetAllArmoType.OnClick := OnChkGetAllArmoTypeClick;

    /////////////////////////////////////////
    // Procedurally adjust form
    frm.ClientWidth := grpTrim.Left + grpTrim.Width + btnL;
    frm.ClientHeight := btnExit.Top + btnH + bigDY;
    btnExit.Left := (frm.Width div 2) - (btnExit.Width div 2);

    Result := frm.ShowModal;
  finally
    frm.Release;
  end;
end;

end.

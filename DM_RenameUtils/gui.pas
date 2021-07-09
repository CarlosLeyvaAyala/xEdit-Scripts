unit gui;

var
  frm: TForm;                   // User input form
  chkDebug: TCheckBox;          // Don't write changes if this is checked
  chkGetAllArmoType: TCheckBox; // Get all tags for armors

const
  cancelStr = '***ThIsF0rMw4SCaNcEL1eD!!111***';  // Made to deal with strange InputQuery behavior

  // UI constants
  btnW = 119;
  btnH = 32;
  ctrlDX = 24;
  ctrlDY = 8;
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

procedure OnChkDebugClick(Sender: TObject);
begin
  gDebugMode := chkDebug.Checked;
end;

procedure OnChkGetAllArmoTypeClick(Sender: TObject);
begin
  gGetAllArmoType := chkGetAllArmoType.Checked;
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
  btnPrependIf, btnTrimFront, btnTrimAll, btnTrimTail, btnGetType,
  btnFExport, btnFImport, btnAuto: TButton;
  grpMove, grpTrim, grpFile: TGroupBox;
const
  // bigDY = 24;

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

    btnPrepend := CreateButton(frm);
    btnPrepend.Caption := '&Prepend';
    btnPrepend.Hint := 'Adds some word at the start of the name';
    _Below(btnPrepend, btnReplace);

    btnPrependIf := CreateButton(frm);
    btnPrependIf.Caption := 'Prepend &if...';
    btnPrependIf.Hint := 'Adds some word at the start of the name if it contains some word';
    _Below(btnPrependIf, btnPrepend);

    btnAppend := CreateButton(frm);
    btnAppend.Caption := 'App&end';
    btnAppend.Hint := 'Adds some word at the end of the name';
    _Below(btnAppend, btnPrependIf);

    /////////////////////////////////////////
    // grpMove := CreateGroupbx(grpL, bigDY, grpBtnDX, 2, frm, frm);
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
    // grpTrim := CreateGroupbx(grpL, grpMove.Top + grpH + grpDY, grpBtnDX, 3, frm, frm);
    grpTrim := CreateGroupbx(frm);
    grpTrim.Caption := 'Trim';
    _Below(grpTrim, grpMove);

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
    // grpFile := CreateGroupbx(grpL, grpTrim.Top + grpH + grpDY, grpBtnDX, 2, frm, frm);
    grpFile := CreateGroupbx(frm);
    grpFile.Caption := 'File operations';
    _Below(grpFile, grpTrim);

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
    btnGetType := CreateButton(frm);
    btnGetType.Caption := 'Get t&ype';
    btnGetType.Hint := 'Prepends weapon/armor/spell type.';
    _Below(btnGetType, grpFile);
    _MoveBy(btnGetType, 0, bigDY);

    chkGetAllArmoType := TCheckBox.Create(frm);
    chkGetAllArmoType.Parent := frm;
    chkGetAllArmoType.Caption := '&Get all';
    chkGetAllArmoType.Checked := gGetAllArmoType;
    chkGetAllArmoType.Hint := 'When checked, gets all tags an armor has';
    chkGetAllArmoType.Width := btnW;
    chkGetAllArmoType.Height := btnH;
    _NextTo(chkGetAllArmoType, btnGetType);
    _MoveBy(chkGetAllArmoType, 0, btnH div 8);

    /////////////////////////////////////////
    chkDebug := TCheckBox.Create(frm);
    chkDebug.Parent := frm;
    chkDebug.Caption := '&Don'#39't apply changes';
    chkDebug.Checked := gDebugMode;
    chkDebug.Width := btnW;
    chkDebug.Left := btnL;
    chkDebug.Top := btnGetType.Top + btnH +  bigDY;
    chkDebug.Height := btnH;
    chkDebug.Hint := 'Shows you the output of your operation, but doesn'#39't actually make changes on your file. Useful for testing purposes.';

    btnExit := CreateButton(frm);
    btnExit.Caption := 'Exit';
    _Below(btnExit, btnGetType);
    _MoveBy(btnExit, 0, bigDY * 3);
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
    chkDebug.OnClick := OnChkDebugClick;
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

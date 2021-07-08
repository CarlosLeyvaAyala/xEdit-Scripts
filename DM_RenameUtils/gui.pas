unit gui;

const
  cancelStr = '***ThIsF0rMw4SCaNcEL1eD!!111***';  // Made to deal with strange InputQuery behavior

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
    btnPrependIf.Caption := 'Prepend &if...';
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
    btnGetType.Hint := 'Prepends weapon/armor/spell type.';

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

end.

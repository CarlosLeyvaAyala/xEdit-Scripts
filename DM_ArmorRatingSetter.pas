unit DM_ArmorRatingSetter;
{
  Hotkey: F6
	
	Change the hotkey to your preference.
  
  Select a bunch of armors, set the total armor rating you want for them and
  this script will apply the correct armor rating for each piece.
  This is used for balancing custom armor mods to vanilla game levels.
}
interface

uses xEditApi;

implementation

var
  totalAR: Integer;
  edtAR: TEdit;
  
  // Processing regex:
  //    (\w+),?
  arHead, arHands, arLegs, arBody, arUnknown: TList;
  nHead, nHands, nLegs, nBody: Byte;

const
  desiredAR = 70;
  // Made to deal with strange InputQuery behavior
  cancelStr = '***ThIsF0rMw4SCaNcEL1eD!!111***'; 

  // Armor types
  atLight = 0; 
  atHeavy = 1;
  atCloth = 2;

  // Slots
  slHead = 1;
  slHair = 2;
  slBody = 4;
  slHands = 8;
  slForearms = 16;
  slAmulet = 32;
  slRing = 64;
  slFeet = 128;
  slCalves = 256;
  slShield = 512;
  slTail = 1024;
  slLongHair = 2048;
  slCirclet = 4096;
  slEars = 8192;
  slFace = 16384;
  slNeck = 32768;
  slChestMain = 65536;
  slBack = 131072;
  slMisc1 = 262144;
  slPelvisMain = 524288;
  slDecapitated = 1048576;
  slDecapitate = 2097152;
  slPelvisSec = 4194304;
  slLegMain = 8388608;
  slLegSec = 16777216;
  slFaceAlt = 33554432;
  slChestSec = 67108864;
  slShoulder = 134217728;
  slArmLeft = 268435456;
  slArmRight = 536870912;
  slMisc2 = 1073741824;
  slFX01 = 2147483648;

  // Armor rating multipliers
  ltBodyMult = 0.5;
  ltHeadMult = 0.25;
  ltHandMult = 0.125;
  ltLegsMult = 0.125;

  hvBodyMult = 0.45;
  hvHeadMult = 0.21;
  hvHandMult = 0.17;
  hvLegsMult = 0.17;

  invalidRating = -99999999;

// Asks the user to input a value. Made to deal with InputQuery bullshit behavior.
function PromptQuery(ACaption, APrompt: string): string;
var
  accept: Boolean;
begin
  accept := InputQuery(ACaption, APrompt, Result);
  if not accept then Result := cancelStr;
end;

function GetArmorType(e: IInterface): Integer;
begin
  Result := GetElementNativeValues(e, 'BOD2\Armor Type');
end;

// function StrIdToRecord(id: string): IInterface;
// begin
// end;

procedure ObjInit;
begin
    arHead := TList.Create;
    arHands := TList.Create;
    arLegs := TList.Create;
    arBody := TList.Create;
    arUnknown := TList.Create;
end;

procedure ObjFree;
begin
    arHead.Free;
    arHands.Free;
    arLegs.Free;
    arBody.Free;
    arUnknown.Free;
end;

function GetArmorRating(e: IInterface): Integer;
begin
  // For some reason, `GetElementNativeValues(e, 'DNAM')` gives values multiplied by 100
  Result := GetElementNativeValues(e, 'DNAM') / 100;
end;

procedure SetArmorRating(e: IInterface; newAR: Integer; optMsg: string);
var
  old: Integer;
  rName: string;
const
  fmtNoChange = '%8d = "%s" (armor rating was not changed%s)';
  fmtChanged = '%8d -> %8d = "%s" %s';
begin
  old := GetArmorRating(e);
  rName := GetElementEditValues(e, 'FULL');

  if old = newAR then begin
    AddMessage(Format(fmtNoChange, [newAR, rName, optMsg]));
    Exit;
  end;

  // Need to log before newAR is corrected
  AddMessage(Format(fmtChanged, [old, newAR, rName, optMsg]));

  newAR := newAR * 100;   // Correct weird multiplier
  SetElementNativeValues(e, 'DNAM', newAR);
end;

function IsBodyArmor(slots: Cardinal): Boolean;
begin
  Result := 
    ((slots and slBody) <> 0) or
    ((slots and slAmulet) <> 0) or
    ((slots and slTail) <> 0) or
    ((slots and slNeck) <> 0) or
    ((slots and slChestMain) <> 0) or
    ((slots and slBack) <> 0) or
    ((slots and slMisc1) <> 0) or
    ((slots and slChestSec) <> 0) or
    ((slots and slShoulder) <> 0) or
    ((slots and slMisc2) <> 0) or
    ((slots and slFX01) <> 0);
end;

function IsLegsArmor(slots: Cardinal): Boolean;
begin
  Result := 
    ((slots and slFeet) <> 0) or
    ((slots and slCalves) <> 0) or
    ((slots and slPelvisMain) <> 0) or
    ((slots and slPelvisSec) <> 0) or
    ((slots and slLegMain) <> 0) or
    ((slots and slLegSec) <> 0);
end;

function IsHandsArmor(slots: Cardinal): Boolean;
begin
  Result := 
    ((slots and slHands) <> 0) or
    ((slots and slForearms) <> 0) or
    ((slots and slRing) <> 0) or
    ((slots and slArmLeft) <> 0) or
    ((slots and slArmRight) <> 0);
end;

function IsHeadArmor(slots: Cardinal): Boolean;
begin
  Result := 
    ((slots and slHead) <> 0) or
    ((slots and slHair) <> 0) or
    ((slots and slLongHair) <> 0) or
    ((slots and slCirclet) <> 0) or
    ((slots and slEars) <> 0) or
    ((slots and slFace) <> 0) or
    ((slots and slFaceAlt) <> 0);
end;

procedure AddToArmorTypeList(e: IInterface);
var 
    slots: Cardinal;
begin
    slots := GetElementNativeValues(e, 'BOD2\First Person Flags');

    if IsBodyArmor(slots) then begin
        arBody.Add(e);
        Exit;
    end;

    if IsHeadArmor(slots) then begin
        arHead.Add(e);
        Exit;
    end;

    if IsHandsArmor(slots) then begin
        arHands.Add(e);
        Exit;
    end;

    if IsLegsArmor(slots) then begin
        arLegs.Add(e);
        Exit;
    end;

    arUnknown.Add(e);
end;

procedure SetRating(ltMult, hvMult: Real; list: TList);
var
  i, AR: Integer;
begin
    if list.count = 0 then Exit;

    AR := Round(totalAR * ltMult) div list.count;
    for i := 0 to list.count - 1 do 
        SetArmorRating(ObjectToElement(list[i]), AR, '');
end;

procedure SetBodyRating;
begin
    SetRating(ltBodyMult, hvBodyMult, arBody);
end;

procedure SetHeadRating;
begin
    SetRating(ltHeadMult, hvHeadMult, arHead);
end;

procedure SetLegsRating;
begin
    SetRating(ltLegsMult, hvLegsMult, arLegs);
end;

procedure SetHandRating;
begin
    SetRating(ltHandMult, hvHandMult, arHands);
end;

procedure SetUnknownRating;
begin
    SetRating(0, 0, arUnknown);
end;

procedure JoinLists(source, dest: TList);
var 
    i: Integer;
begin
    for i := 0 to source.count - 1 do 
        dest.Add(source[i]);
end;

procedure DivvyRemaining;
var 
    i, sumAR, divvy, currAR: Integer;
    allArmors: TList;
    armor: IInterface;
begin
    allArmors := TList.Create;
    try
        JoinLists(arBody, allArmors);
        JoinLists(arHead, allArmors);
        JoinLists(arHands, allArmors);
        JoinLists(arLegs, allArmors);
        JoinLists(arUnknown, allArmors);

        sumAR := 0;
        for i := 0 to allArmors.count - 1 do begin
            sumAR := sumAR + GetArmorRating(ObjectToElement(allArmors[i]));
        end;

        divvy := (totalAR - sumAR) div allArmors.count;
        for i := 0 to allArmors.count - 1 do begin
            armor := ObjectToElement(allArmors[i]);
            currAR := GetArmorRating(armor);
            SetArmorRating(armor, currAR + divvy, ' when correcting on last pass');
        end;
    finally
        allArmors.Free;
    end;
end;

function Initialize: Integer;
var
    s: string;
begin

    Result := 0;
    totalAR := ShowForm;

    if totalAR < 0 then begin
        AddMessage('Only positive values are allowed.');
        Result := 1;
    end;
    
    ObjInit;

    AddMessage(' ');
    AddMessage('Target armor rating: ' + IntToStr(totalAR));
    AddMessage(' ');
end;

function Finalize: Integer;
begin
    SetBodyRating;
    SetHeadRating;
    SetLegsRating;
    SetHandRating;
    SetUnknownRating;
    DivvyRemaining;
    ObjFree;
    AddMessage(' ');
end;

function Process(e: IInterface): Integer;
begin
    if(Signature(e) <> 'ARMO') then Exit;

    if GetArmorType(e) = atCloth then begin
        SetArmorRating(e, 0, ': clothes have no armor rating');
        Exit;
    end;
    AddToArmorTypeList(e);
end;

function CreateButton(AParent: TControl): TButton;
begin
  Result := TButton.Create(AParent);
  Result.Parent := AParent;
  Result.Left := 0;
  Result.Top := 0;
  Result.Width := 180;
  Result.Height := 32;
end;

function CreateARButton(AParent: TControl; caption, hint: string; value, left, top: Integer): TButton;
begin
  Result := CreateButton(AParent);
  Result.Caption := caption;
  Result.Left := left;
  Result.Top := top;
  Result.OnClick := OnArBtnClick;
  Result.Tag := value;
  Result.Hint := hint;
  Result.Width := 120;
end;

procedure OnArBtnClick(Sender: TObject);
begin
  edtAR.Text := IntToStr(TButton(Sender).Tag);
end;

procedure OnArBtnChange(Sender: TObject);
begin
  edtAR.Text := IntToStr(TButton(Sender).Tag);
end;

function ShowForm: Integer;
var
  frm: TForm;  
  btnExit, btnOk: TButton;
  pnl: TPanel;
  lbl: TLabel;
  grpLghtrmr, grpHvyrmr, grpLghtshld, grpHvyshld: TGroupBox;
begin
  frm := TForm.Create(nil);
  Result := invalidRating;

  try
    pnl := TPanel.Create(frm);
    pnl.Parent := frm;
    pnl.BevelOuter := bvNone;
    pnl.AutoSize := true;

    lbl := TLabel.Create(frm);
    lbl.Parent := pnl;
    lbl.Caption := 'New armor rating for the selected armor set:';

    edtAR := TEdit.Create(frm);
    edtAR.Parent := pnl;
    edtAR.Top := 20;
    edtAR.Width := lbl.Width;

    frm.Caption := 'Change armor rating';
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;
    frm.Height := 600;
    frm.Width := 880;
    frm.ShowHint := true;

    btnOk := CreateButton(frm);
    btnOk.Caption := '&Ok';
    btnOk.Default := true;
    btnOk.ModalResult := mrOk;

    btnExit := CreateButton(frm);
    btnExit.Caption := '&Cancel';
    btnExit.Cancel := true;
    btnExit.ModalResult := mrCancel;
    btnExit.Tag := 2;

    pnl.Left := (frm.ClientWidth div 2) - (pnl.ClientWidth div 2);

    // ==================================
    grpLghtrmr := TGroupBox.Create(frm);
    grpLghtrmr.Parent := frm;
    grpLghtrmr.Left := 15;
    grpLghtrmr.Top := 15;
    grpLghtrmr.Width := 410;
    grpLghtrmr.Height := 205;
    grpLghtrmr.Caption := 'Light Armor';

    CreateARButton(grpLghtrmr, 'Hide', 'Hide, Vampire', 40, 15, 30);
    CreateARButton(grpLghtrmr, 'Studded', 'Studded', 43, 145, 30);
    CreateARButton(grpLghtrmr, 'Fur', 'Fur, Guard', 46, 275, 30);

    CreateARButton(grpLghtrmr, 'Leather', 'Leather, Forsworn, Thalmor Armor', 52, 15, 72);
    CreateARButton(grpLghtrmr, 'Elven', 'Elven', 58, 145, 72);
    CreateARButton(grpLghtrmr, 'Chitin', 'Chitin', 60, 275, 72);

    CreateARButton(grpLghtrmr, 'Dawnguard', 'Dawnguard', 61, 15, 114);
    CreateARButton(grpLghtrmr, 'Scaled', 'Scaled, Elven Gilded', 64, 145, 114);
    CreateARButton(grpLghtrmr, 'Glass', 'Glass', 76, 275, 114);

    CreateARButton(grpLghtrmr, 'Stalhrim', 'Stalhrim', 78, 15, 156);
    CreateARButton(grpLghtrmr, 'Dragonscale', 'Dragonscale', 82, 145, 156);

    // ==================================
    grpHvyrmr := TGroupBox.Create(frm);
    grpHvyrmr.Parent := frm;
    grpHvyrmr.Left := 445;
    grpHvyrmr.Top := 15;
    grpHvyrmr.Width := 410;
    grpHvyrmr.Height := 205;
    grpHvyrmr.Caption := 'Heavy Armor';

    CreateARButton(grpHvyrmr, 'Iron', 'Iron, Ancient Nord', 60, 15, 30);
    CreateARButton(grpHvyrmr, 'Banded Iron', 'Banded Iron', 63, 145, 30);
    CreateARButton(grpHvyrmr, 'Steel', 'Steel', 72, 275, 30);

    CreateARButton(grpHvyrmr, 'Dwarven', 'Dwarven, Dawnguard', 78, 15, 72);
    CreateARButton(grpHvyrmr, 'Steel Plate', 'Steel Plate, Chitin', 87, 145, 72);
    CreateARButton(grpHvyrmr, 'Orcish', 'Orcish', 90, 275, 72);

    CreateARButton(grpHvyrmr, 'Nordic', 'Nordic', 93, 15, 114);
    CreateARButton(grpHvyrmr, 'Ebony', 'Ebony', 96, 145, 114);
    CreateARButton(grpHvyrmr, 'Dragonplate', 'Dragonplate, Stalhrim', 102, 275, 114);

    CreateARButton(grpHvyrmr, 'Daedric', 'Daedric', 108, 15, 156);

    // ==================================
    grpLghtshld := TGroupBox.Create(frm);
    grpLghtshld.Parent := frm;
    grpLghtshld.Left := 15;
    grpLghtshld.Top := grpLghtrmr.Top + grpLghtrmr.Height + 15;
    grpLghtshld.Width := 410;
    grpLghtshld.Height := 163;
    grpLghtshld.Caption := 'Light Shield';

    CreateARButton(grpLghtshld, 'Leather', 'Leather, Hide, Studded', 15, 15, 30);
    CreateARButton(grpLghtshld, 'Elven', 'Elven, Elven Gilded', 21, 145, 30);
    CreateARButton(grpLghtshld, 'Chitin', 'Chitin', 25, 275, 30);

    CreateARButton(grpLghtshld, 'Dawnguard', 'Dawnguard', 26, 15, 72);
    CreateARButton(grpLghtshld, 'Glass', 'Glass', 27, 145, 72);
    CreateARButton(grpLghtshld, 'Dragonscale', 'Dragonscale', 29, 275, 72);

    CreateARButton(grpLghtshld, 'Stalhrim', 'Stalhrim', 30, 15, 114);

    // ==================================
    grpHvyshld := TGroupBox.Create(frm);
    grpHvyshld.Parent := frm;
    grpHvyshld.Left := 445;
    grpHvyshld.Top := grpLghtshld.Top;
    grpHvyshld.Width := 410;
    grpHvyshld.Height := 163;
    grpHvyshld.Caption := 'Heavy Shield';

    CreateARButton(grpHvyshld, 'Iron', 'Iron', 20, 15, 30);
    CreateARButton(grpHvyshld, 'Banded Iron', 'Banded Iron', 22, 145, 30);
    CreateARButton(grpHvyshld, 'Steel', 'Steel, Steel Plate, Chitin', 24, 275, 30);

    CreateARButton(grpHvyshld, 'Dwarven', 'Dwarven, Dawnguard, Nordic', 26, 15, 72);
    CreateARButton(grpHvyshld, 'Stalhrim', 'Stalhrim', 29, 145, 72);
    CreateARButton(grpHvyshld, 'Orcish', 'Orcish', 30, 275, 72);

    CreateARButton(grpHvyshld, 'Ebony', 'Ebony', 32, 15, 114);
    CreateARButton(grpHvyshld, 'Dragonplate', 'Dragonplate', 34, 145, 114);
    CreateARButton(grpHvyshld, 'Daedric', 'Daedric', 36, 275, 114);

    // ==================================
    pnl.Top := grpLghtshld.Top + grpLghtshld.Height + 35;

    btnOk.Top := pnl.Top + pnl.Height + 40;
    btnExit.Top := btnOk.Top;

    btnOk.Left := frm.ClientWidth - (btnOk.Width * 2) - 20 - 10 ;
    btnExit.Left := btnOk.Left + btnOk.Width + 10;

    // ==================================
    if frm.ShowModal <> mrOk then begin
      Result := invalidRating;
    end
    else begin
      Result := StrToInt(edtAR.Text);
    end;
  finally
    frm.Release;
  end;
end;

end.

unit DM_ArmorRatingSetter;
{
  Hotkey: F6
	
	Change the hotkey to your preference.
  
  Select a bunch of armors, set the total armor rating you want for them and
  this script will apply the correct armor rating for each piece.
  This is used for balancing custom armor mods to vanilla game levels.
}

uses xEditApi;

var
  totalAR: Integer;
  
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

  // Predefined vanilla armor ratings
  arLtLeather = 52;
  arLtGuard = 46;
  arLtDragonscale = 82;
  arHvDaedric = 108;

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
            SetArmorRating(armor, currAR + divvy, 'when correcting on last pass');
        end;
    finally
        allArmors.Free;
    end;
end;

function Initialize: Integer;
var
    s: string;
begin
  // s := PromptQuery('Set Armor Rating', 'Expected **total** AR');
  // totalAR := StrToInt(s);
    totalAR := desiredAR;

    if totalAR < 0 then begin
        AddMessage('Only positive values are allowed.');
        Result := 1;
    end;
    ObjInit;
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

end.

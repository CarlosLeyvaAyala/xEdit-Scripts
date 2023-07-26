unit DM_WaedDuplicator;
{
    Hotkey: F3
}
interface

uses xEditApi;

implementation

var
    gBaseWaedFile, gOutFile: IInterface;
    distractionBattleEdid: array [1..3] of string;

const 
    waedFile = 'WAED Enchantments.esp';
    waedSummerFile = 'WAED Enchantments - Summermyst.esp';
    distractionN = 3;

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
      fx := ElementByIndex(fxs, i);
      ench := ElementByPath(fx, 'EFID');
      AddMessage(GetEditValue(ench));
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

function GetBaseEdid(e: IInterface): string;
var
  edid: string;
  r: TPerlRegex;
begin
    r := TPerlRegex.Create;
    try
        r.RegEx := '\d+';
        r.Subject := EditorID(e);
        r.Replacement := '\1';
        r.ReplaceAll;

        // CleanVanillaEdid(r);
        // CleanSummermystEdid(r);
        CleanWAEDEdid(r);

        Result := 'DM_Ench_' + r.Subject;
    finally
        r.Free;
    end;
end;

procedure CleanWAEDEdid(r: TPerlRegex);
begin
    DeleteByRegex(r, '^DM_Ench_');
    DeleteByRegex(r, '_Var$');
end;

procedure CleanVanillaEdid(r: TPerlRegex);
begin
    DeleteByRegex(r, '^EnchArmor');
    DeleteByRegex(r, '^Ench');
end;

procedure CleanSummermystEdid(r: TPerlRegex);
begin
    DeleteByRegex(r, 'Armor_\w\w\w_Ench_');
    DeleteByRegex(r, '_$');
end;

procedure DeleteByRegex(r: TPerlRegex; regex: string);
begin
    r.RegEx := regex;
    r.Replacement := '\1';
    r.ReplaceAll;
end;

procedure SetEDID(e: IInterface; edid: string; i: Integer);
var 
    edid2: string;
begin
    if(i < 1) then
        edid2 := Format('%s_Var', [edid])
    else
        edid2 := Format('%s_%.2d', [edid, i]);

    SetEditorID(e, edid2);
end;

function CopyToWaed(e: IInterface; edid: string; i: Integer): IInterface;
var
    newRecord: IInterface;
begin
    newRecord := wbCopyElementToFile(e, gOutFile, true, true);
    SetEDID(newRecord, edid, i);
    Result := newRecord;
end;

procedure CreateDistractionCopies(e: IInterface);
var 
    i: Integer;
    newRecord, newFx: IInterface;
    fxs, fx, ench: IInterface;
    edid: string;
begin
    edid := GetBaseEdid(e) + '_Distraction';

    for i := 1 to distractionN do begin
        newRecord := CopyToWaed(e, edid, i);

        // Change effect
        fxs := ElementByPath(newRecord, 'Effects');
        // fx := ElementByIndex(fxs, 0);
        fx := ElementAssign(fxs, HighInteger, nil, false);
        ench := ElementByPath(fx, 'EFID');
        SetEditValue(ench, Name(RecordByEditorID(gBaseWaedFile, distractionBattleEdid[i])));
    end;
end;

function Process(e: IInterface): Integer;
begin
    if Signature(e) = 'ENCH' then begin 
        // CopyToWaed(e, GetBaseEdid(e), 0);
        CreateDistractionCopies(e);
        // AddMessage(GetBaseEdid(e));
    end;
end;

function Initialize: Integer;
begin
    Result := ShowForm;
    if Result <> 0 then Exit;

    gBaseWaedFile := FileByName(waedFile);
    // gOutFile := FileByName(waedFile);
    // gOutFile := FileByName(waedSummerFile);
    InitArrays;
end;

function Finalize: Integer;
begin
end;

procedure InitArrays;
begin
    distractionBattleEdid[1] := 'DM_EnchFx_PerkDistraction_01';
    distractionBattleEdid[2] := 'DM_EnchFx_PerkDistraction_02';
    distractionBattleEdid[3] := 'DM_EnchFx_PerkDistraction_03';
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

function ShowForm: Integer; 
var
  frm: TForm;  
  btnExit, btnOk: TButton;
  rgpOptions: TRadioGroup;
const 
  x = 120;
  y = 30;
  dy = 40;
begin
  frm := TForm.Create(nil);

  try
    frm.Caption := 'Select destination file';
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;
    frm.Height := 290;
    frm.Width := 440;

    rgpOptions := TRadioGroup.Create(frm);
    rgpOptions.Parent := frm;
    rgpOptions.Left := x;
    rgpOptions.Top := y; 
    rgpOptions.Caption := 'WAED file';
    rgpOptions.Items.Add('&Vanilla');
    rgpOptions.Items.Add('&Summermyst');
    rgpOptions.ItemIndex := 0;

    btnExit := CreateButton(frm);
    btnExit.Caption := '&Cancel';
    btnExit.Cancel := true;
    btnExit.ModalResult := mrCancel;
    btnExit.Left := x - 85;
    btnExit.Top := y + (4 * dy);

    btnOk := CreateButton(frm);
    btnOk.Caption := '&Ok';
    btnOk.Default := true;
    btnOk.ModalResult := mrOk;
    btnOk.Left := btnExit.Left + btnExit.Width + 10;
    btnOk.Top := btnExit.Top;

    if frm.ShowModal <> mrOk then 
        Result := 1
    else begin
      case rgpOptions.ItemIndex of
      0: gOutFile := FileByName(waedFile);
      1: gOutFile := FileByName(waedSummerFile);
      end;

      Result := 0;
    end;
  finally
    frm.Release;
  end;
end;

end.

unit DM_ConvertToArmorType;
{
    Hotkey: Ctrl+Shift+A

    Converts selected armors to Clothing/Light/Heavy.
}

uses xEditApi;

var
    arType: integer;

const 
    arTypeCloth = 0;
    arTypeLight = 1;
    arTypeHeavy = 2;

    ArmorClothing = 'ArmorClothing';
    ArmorLight = 'ArmorLight';
    ArmorHeavy = 'ArmorHeavy';

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

procedure SwapKeyword(e: IInterface; fromKey, toKey: string);
var
    idx: Integer;
    key: IInterface;
begin
    idx := KeywordIndex(e, fromKey);
    if idx <> -1 then begin
        key := ElementByIndex(ElementByPath(e, 'KWDA'), idx);
        SetEditValue(key, toKey);
    end;
end;

procedure ConvertToArmorType(e: IInterface; aType: string);
begin
    SetElementEditValues(e, 'BOD2\Armor Type', aType);
end;

procedure ConvertToArmorClothes(e: IInterface);
const
    ArmorClothingL = 'ArmorClothing [KYWD:0006BBE8]';
begin
    SwapKeyword(e, ArmorHeavy, ArmorClothingL);
    SwapKeyword(e, ArmorLight, ArmorClothingL);
    SwapKeyword(e, 'ArmorCuirass', 'ClothingBody [KYWD:000A8657]');
    SwapKeyword(e, 'ArmorGauntlets', 'ClothingHands [KYWD:0010CD13]');
    SwapKeyword(e, 'ArmorHelmet ', 'ClothingHead [KYWD:0010CD11]');
    SwapKeyword(e, 'ArmorBoots', 'ClothingFeet [KYWD:0010CD12]');

    ConvertToArmorType(e, 'Clothing');
end;

procedure SwapToArmored(e: IInterface);
begin
    SwapKeyword(e, 'ClothingBody', 'ArmorCuirass [KYWD:0006C0EC]');
    SwapKeyword(e, 'ClothingHands', 'ArmorGauntlets [KYWD:0006C0EF]');
    SwapKeyword(e, 'ClothingHead', 'ArmorHelmet [KYWD:0006C0EE]');
    SwapKeyword(e, 'ClothingFeet', 'ArmorBoots [KYWD:0006C0ED]');
end;

procedure ConvertToArmorHeavy(e: IInterface);
const
    ArmorHeavyL = 'ArmorHeavy [KYWD:0006BBD2]';
begin
    SwapKeyword(e, ArmorClothing, ArmorHeavyL);
    SwapKeyword(e, ArmorLight, ArmorHeavyL);
    SwapToArmored(e);
    ConvertToArmorType(e, 'Heavy Armor');
end;

procedure ConvertToArmorLight(e: IInterface);
const
    ArmorLightL = 'ArmorLight [KYWD:0006BBD3]';
begin
    SwapKeyword(e, ArmorClothing, ArmorLightL);
    SwapKeyword(e, ArmorHeavy, ArmorLightL);
    SwapToArmored(e);
    ConvertToArmorType(e, 'Light Armor');
end;

function Process(e: IInterface): Integer;
begin
    if not (Signature(e) = 'ARMO') then Exit;
    case arType of
        arTypeCloth: ConvertToArmorClothes(e);
        arTypeLight: ConvertToArmorLight(e);
        arTypeHeavy: ConvertToArmorHeavy(e);
    end;
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
  Result := 0;

  try
    frm.Caption := 'Convert to armor type';
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;
    frm.Height := 290;
    frm.Width := 440;

    rgpOptions := TRadioGroup.Create(frm);
    rgpOptions.Parent := frm;
    rgpOptions.Left := x;
    rgpOptions.Top := y; 
    rgpOptions.Caption := 'New type';
    rgpOptions.Items.Add('&Clothing');
    rgpOptions.Items.Add('&Light');
    rgpOptions.Items.Add('&Heavy');
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

    if frm.ShowModal <> mrOk then begin
      Result := 1;
    end
    else begin
      arType := rgpOptions.ItemIndex;
    end;
  finally
    frm.Release;
  end;
end;

function Initialize: Integer;
begin
  Result := ShowForm;
  if Result <> 0 then Exit;
end;

end.
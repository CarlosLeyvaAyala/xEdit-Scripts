unit DM_Find_X_Armor;

interface

uses xEditApi;

implementation

var
  armorToFind: string;

function IsXArmor(e: IInterface): Boolean;
begin
  Result := GetElementEditValues(WinningOverride(e), 'BOD2\Armor Type') = armorToFind;
end;

function HasXArmor(f: IInterface): Boolean;
var
  armors: IInterface;
  i, n: Integer;
begin
  Result := false;
  if not HasGroup(f, 'ARMO') then Exit; 

  armors := GroupBySignature(f, 'ARMO');
  n := ElementCount(armors);
  for i := 0 to n do begin
    Result := IsXArmor(ElementByIndex(armors, i));
    if Result then Exit;
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
    frm.Caption := 'Search for armor type';
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
      case rgpOptions.ItemIndex of
      0: armorToFind := 'Clothing';
      1: armorToFind := 'Light Armor';
      2: armorToFind := 'Heavy Armor';
      end;
    end;
  finally
    frm.Release;
  end;
end;

function Initialize: Integer;
var 
  i: integer;
  f: IInterface;
begin
  Result := ShowForm;
  if Result <> 0 then Exit;

  AddMessage(#13#10#13#10);
  
  // iterate over loaded plugins
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if HasXArmor(f) then begin
      AddMessage(IntToHex(GetLoadOrder(f), 2) + ' ' + GetFileName(f));
    end;
  end;

  AddMessage(#13#10);
  AddMessage(Format('Finished searching for armor type: %s', [armorToFind]));
  AddMessage(#13#10#13#10);
end;

end.

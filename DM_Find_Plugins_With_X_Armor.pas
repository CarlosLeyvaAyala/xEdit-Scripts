unit Find_X_Armor;

interface

uses xEditApi;

implementation

const
  armorToFind = 'Light Armor';
  // armorToFind = 'Heavy Armor';

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

function Initialize: Integer;
var 
  i: integer;
  f: IInterface;
begin
  // iterate over loaded plugins
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if HasXArmor(f) then begin
      AddMessage(IntToHex(GetLoadOrder(f), 2) + ' ' + GetFileName(f));
    end;
  end;
end;

end.

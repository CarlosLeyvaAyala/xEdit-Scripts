unit DM_FixBashSmashPatch;

{
  Hotkey: Shift+F5

  Not inteneded to be used by the general public.
}
interface

uses
  xEditApi;

implementation

procedure Separate;
begin
  AddMessage(#13#10#13#10);
end;

function Initialize: Integer;
begin
  Separate;
end;

function Finalize: Integer;
begin
  Separate;
end;

function Process(e: IInterface): Integer;
var
  s: string;
begin
  if Signature(e) = 'AMMO' then
    AddMessage('Ammo')
  else if Signature(e) = 'ARMA' then
    PrArma(e)
  else if Signature(e) = 'NPC_' then
    PrNpc(e)
  else if Signature(e) = 'PERK' then
    PrPerk(e)
  else if Signature(e) = 'RACE' then
    PrRace(e)
end;

// Gets the second to last file name of the latest override
function SecondToLastOvFileName(e: IInterface): string;
var
  ov: IInterface;
  n: Integer;
begin
  e := MasterOrSelf(e);
  n := OverrideCount(e);
  if n < 2 then begin
    Result := '';
    Exit;
  end;

  ov := OverrideByIndex(e, n - 2);
  Result := GetFileName(GetFile(ov));
end;

procedure PrArma(e: IInterface);
var
  lastF: string;
begin
  lastF := SecondToLastOvFileName(e);

  if (lastF = 'BD Armor and clothes replacer.esp') or (lastF = 'HIMBO.esp') then begin
    AddMessage('Removed last override of ' + GetElementEditValues(e, 'EDID'));
    Remove(WinningOverride(e));
  end;
end;

procedure PrNpc(e: IInterface);
var
  lastF: string;
begin
  lastF := SecondToLastOvFileName(e);

  if (lastF = 'TKAA.esp') then begin
    AddMessage('Removed last override of ' + GetElementEditValues(e, 'FULL'));
    Remove(WinningOverride(e));
  end;
end;

procedure PrPerk(e: IInterface);
var
  lastF: string;
begin
  lastF := SecondToLastOvFileName(e);

  if (lastF = 'Ordinator - Perks of Skyrim.esp') then begin
    AddMessage('Removed last override of ' + GetElementEditValues(e, 'FULL'));
    Remove(WinningOverride(e));
  end;
end;

procedure PrRace(e: IInterface);
var
  lastF: string;
begin
  lastF := SecondToLastOvFileName(e);

  if (lastF = 'BeautifulVampires.esp') then begin
    AddMessage('Removed last override of ' + GetElementEditValues(e, 'FULL'));
    Remove(WinningOverride(e));
  end;
end;

end.

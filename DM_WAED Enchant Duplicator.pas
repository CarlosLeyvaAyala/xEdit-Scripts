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

        r.RegEx := '^EnchArmor';
        r.Replacement := '\1';
        r.ReplaceAll;
        
        Result := 'DM_Ench_' + r.Subject;
    finally
        r.Free;
    end;
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
    newRecord: IInterface;
    fxs, fx, ench: IInterface;
    edid: string;
begin
    edid := GetBaseEdid(e);

    for i := 2 to distractionN do begin
        // Copy record
        newRecord := wbCopyElementToFile(e, gOutFile, true, true);
        SetEDID(newRecord, edid, i);

        // edid := GetBaseEdid(EditorID(e));
        // edid := Format('DM_%s%.2d', [edid, i]);
        // SetEditorID(newRecord, edid);

        // Change effect
        fxs := ElementByPath(newRecord, 'Effects');
        fx := ElementByIndex(fxs, 0);
        ench := ElementByPath(fx, 'EFID');
        SetEditValue(ench, Name(RecordByEditorID(gBaseWaedFile, distractionBattleEdid[i])));
    end;

end;

function Process(e: IInterface): Integer;
begin
    // if Signature(e) = 'ENCH' then CreateDistractionCopies(e);
    if Signature(e) = 'ENCH' then CopyToWaed(e, GetBaseEdid(e), 0);
    // AddMessage(GetBaseEdid(e));
end;

function Initialize: Integer;
begin
    gBaseWaedFile := FileByName(waedFile);
    gOutFile := FileByName(waedFile);
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

end.

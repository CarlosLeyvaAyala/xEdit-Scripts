{
Hotkey: F10
}
unit DM_Botox_Fix_Hair;

interface
uses xEditApi
,StrUtils, SysUtils//, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Dialogs, System.Classes
;

implementation

var
  gToFixFile: TStringList;        // File with all hairstyles that need fixing.
  gFixedFile: TStringList;        // File with a list of valid hairstyles.
  gKSHairLoadOrder: string;

function Initialize: integer;
begin
  Randomize;
  gToFixFile := TStringList.Create;
  gToFixFile.LoadFromFile('Edit Scripts\DM_Botox_Fix_Hair_BadList.pas');
  gToFixFile.Sort;

  gFixedFile := TStringList.Create;
  gFixedFile.LoadFromFile('Edit Scripts\DM_Botox_Fix_Hair_GoodList.pas');
  
  // AddMessage(gToFixFile.Text);
  // AddMessage(gFixedFile.Text);

  InputQuery('Enter load order', 'Enter the **2 DIGIT** load order for KS Hairdos', gKSHairLoadOrder);
  AddMessage(gKSHairLoadOrder)
end;

// function IsFem(flags: string): Boolean;
// begin
//   Result := LeftStr(flags, 1) = '1';
// end;

// function GetFormId(e: IInterface): string;
// begin
//   Result := RightStr(IntToHex(FixedFormID(e), 1), 4)
// end;

// function GenBatchMove(e: IInterface): string;
// begin
//   Result := Format('robocopy "%%s%%" "%%d%%" *%s.* /S', [GetFormId(e)])
// end;
function HasInvalidName(aHairName: string): Boolean;
var 
  i: Integer;
begin
  Result := false;
  for i := 0 to gToFixFile.Count - 1 do begin
    if ContainsText(aHairName, gToFixFile[i]) then begin
      AddMessage(Format('Changing broken hair: %s', [gToFixFile[i]]));
      Result := true;
      Exit;
    end;
  end;
end;

function GetRandomFixedHair: string;
begin
  Result := gFixedFile[RandomRange(0, gFixedFile.Count - 1)];
end;

procedure FixHair(headPart: IInterface);
var 
  hairName, fixedHair: string;
begin
  hairName := GetEditValue(headPart);

  if HasInvalidName(hairName) then begin
    fixedHair := gKSHairLoadOrder + GetRandomFixedHair;
    // AddMessage(fixedHair);
    SetEditValue(headPart, Format('[HDPT:%s]', [fixedHair]));
  end;
end;

function Process(e: IInterface): Integer;
var
  sig: string;
  i: Integer;
  flags, li, headparts, headPart: IInterface;
begin
  sig := Signature(e);

  if sig = 'NPC_' then begin
    headparts := ElementBySignature(e, 'PNAM'); 
    if not Assigned(headparts) then begin
      AddMessage('Head not found');
      exit;
    end;

    i := 0;
    headPart := ElementByIndex(headparts, i);
    repeat
      FixHair(headPart);
      i := i + 1;
      headPart := ElementByIndex(headparts, i);
    until not assigned(headPart);

    // AddMessage(GetEditValue(ElementByIndex(headparts, 0)));
  //   flags := ElementBySignature(e, 'ACBS');
  //   if IsFem(GetEditValue(ElementByIndex(flags, 0))) then begin
  //     AddMessage( ':: ' + GetEditValue(ElementBySignature(e, 'FULL')) );
  //     AddMessage( GenBatchMove(e) );
  //   end;
  end;
end;

function Finalize: Integer;
begin
end;

end.

{
Use this script to find which armor pieces is an NPC using.

Method:
	Finds the name of the outfit used by an NPC.
	Finds the name of the armors that belong to an outfit.
	Outputs everything to clipboard
}
unit DM_Outfit_items;
interface
uses xEditApi
,StrUtils, SysUtils, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Dialogs, System.Classes
;
implementation
var
	lst: TStringList;

procedure ProcessOutfit(e: IInterface);
var
  i: Integer;
  items, li: IInterface;
begin
  items := ElementBySignature(e, 'INAM');
  if not Assigned(items) then
    exit;

  for i := 0 to ElementCount(items) - 1 do begin
    li := ElementByIndex(items, i);
    lst.add(#9 + GetEditValue(li) );
  end;
end;

procedure ProcessNPC(e: IInterface);
begin
  lst.add(#9'NPC: ' + GetEditValue(ElementBySignature(e, 'DOFT')) );
end;

function Initialize: integer;
begin
	lst := TStringList.Create;
end;

function Process(e: IInterface): Integer;
var
  sig: string;
begin
  lst.add( GetEditValue(ElementBySignature(e, 'EDID')) );
  sig := Signature(e);

  if sig = 'NPC_' then begin
    ProcessNPC(e);
  end
  else if sig = 'OTFT' then begin
    ProcessOutfit(e);
  end;
end;

function Finalize: Integer;
var
  frm: TForm;
  ed: TEdit;
begin
	frm := TForm.Create(nil);
	ed := TEdit.Create(frm);
	try
		ed.Parent := frm;
		ed.Text := Trim(lst.text);
		ed.SelectAll;
		ed.CopyToClipboard;
	finally
		frm.Free;
		lst.Free;
	end;
end;

end.


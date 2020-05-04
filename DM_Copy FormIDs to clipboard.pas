{
  Copy file FormID to clipboard (to be used with GetFormFromFile() papyrus function for example)
  Hotkey: Ctrl+I
  Mode: Silent
}
unit CopyFormIDstoClipboard;
var
	lst: TStringList;
function Initialize: integer;
begin
	lst := TStringList.Create;
end;

function Process(e: IInterface): Integer;
begin
	lst.add( IntToHex(FixedFormID(e), 8) );
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
		ed.Text := lst.text;
		ed.SelectAll;
		ed.CopyToClipboard;
	finally
		frm.Free;
		lst.Free;
	end;
end;

end.
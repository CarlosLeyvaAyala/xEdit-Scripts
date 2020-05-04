{
  This script copies FormIDs from many selected records to clipboard
}
unit CopyFormIDstoClipboard;
var
	lst: TStringList;			// Global list
	

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
	// We need a temporary TEdit to being able to copy to clipboard
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
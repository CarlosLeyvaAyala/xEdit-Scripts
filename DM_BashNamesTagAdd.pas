unit BashNamesTagAdd;
{Adds the bash:names tag to an esp file}
interface
uses xEditApi;

implementation

var
  f: IwbFile;
  gotFile: boolean;

function Process(e: IInterface): integer;
begin
  if gotFile then Exit;
  f := GetFile(e);
  gotFile := true;
end;

function Initialize: integer;
begin
  gotFile := false;  
end;

function Finalize: integer;
var
	hdr, desc: IInterface;
begin
  hdr := ElementBySignature(f, 'TES4');

  if Assigned(hdr) then begin
    desc := ElementBySignature(hdr, 'SNAM');
    if not Assigned(desc) then desc := Add(hdr, 'SNAM', false);
    SetEditValue(desc, '{{BASH:Names}}');
  end;
end;

end.
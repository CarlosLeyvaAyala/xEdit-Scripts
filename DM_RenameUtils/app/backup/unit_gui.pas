unit unit_gui;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

uses CompWriterPas;

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  Strm: TFileStream;
begin
  Strm := TFileStream.Create('new.pas', fmCreate or fmShareExclusive);
  try
    WriteComponentToPasStream(self, Strm);
  finally
    Strm.Free;
  end;
end;

end.

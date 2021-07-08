unit unit1010_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, SynEdit,
  SynHighlighterAny, SynHighlighterPas, SynHighlighterCpp, SynHighlighterIni,
  CompWriterPas;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    SynAnySyn1: TSynAnySyn;
    SynCppSyn1: TSynCppSyn;
    SynEdit1: TSynEdit;
    SynIniSyn1: TSynIniSyn;
    SynPasSyn1: TSynPasSyn;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SynEdit1Change(Sender: TObject);
    procedure SynEdit1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.SynEdit1Change(Sender: TObject);
begin

end;

procedure TForm1.SynEdit1Click(Sender: TObject);
begin
  SynEdit1.Refresh;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SynEdit1.Refresh;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  Strm:TFileStream;
begin
  Strm := TFileStream.Create('new.pas',fmCreate or fmShareExclusive);
  try
    WriteComponentToPasStream(self, Strm);
  finally
    Strm.Free;
  end ;
end;

end.


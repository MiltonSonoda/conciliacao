unit FCCNCSplash;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrSplash = class(TForm)
    Label1: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frSplash: TfrSplash;

implementation

{$R *.dfm}

procedure TfrSplash.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Action := caFree;
end;

end.

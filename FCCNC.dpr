program FCCNC;

uses
  Vcl.Forms,
  FCCNC1 in 'FCCNC1.pas' {frPrincipal};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrPrincipal, frPrincipal);
  Application.Run;
end.

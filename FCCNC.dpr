program FCCNC;

uses
  Vcl.Forms,
  FCCNC1 in 'FCCNC1.pas' {frPrincipal},
  FCCNCSplash in 'FCCNCSplash.pas' {frSplash};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  frSplash := TfrSplash.Create(nil);
  try
    frSplash.Show;
    frSplash.Update;
    Application.CreateForm(TfrPrincipal, frPrincipal);
  finally
    frSplash.Close;
  end;

  //Application.CreateForm(TfrPrincipal, frPrincipal);
  Application.Run;
end.

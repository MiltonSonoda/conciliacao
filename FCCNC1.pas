unit FCCNC1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Mask, RxToolEdit, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls,
  System.JSON,
  System.DateUtils,
  System.Generics.Collections,
  System.StrUtils,
  BRFW.Controller.Interfaces,
  BRFW.Controller,
  BRFW.Types,
  Data.DB, Vcl.Grids, vcl.wwdbigrd, vcl.wwdbgrid, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Buttons, vcl.wwcheckbox,
  System.Actions, Vcl.ActnList, Vcl.Menus;

type

  TModelIntegracaoPedidoPago = class
     class function _BancoFCerta: TEnumDbTarget;
     class function _CNPJS: TArray<String>;
  end;

  TfrPrincipal = class(TForm)
    ProgressBar1: TProgressBar;
    dsConciliacao: TDataSource;
    pg: TPageControl;
    tbFiltros: TTabSheet;
    TabSheet1: TTabSheet;
    dg: TDrawGrid;
    Button102: TButton;
    tmTransacoes: TTimer;
    GroupBox1: TGroupBox;
    Label4: TLabel;
    edDataTransacoes: TDateEdit;
    Button100: TButton;
    edInterval: TEdit;
    Label3: TLabel;
    btSalvarInterval: TBitBtn;
    ckTransacoes: TCheckBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    edtDataInicial: TDateEdit;
    edtDataFinal: TDateEdit;
    Button1: TButton;
    tbPagamentos: TTabSheet;
    gdConciliacao: TwwDBGrid;
    Panel1: TPanel;
    btnRegistrar: TButton;
    ActionList1: TActionList;
    alRegistrar: TAction;
    tbConciliacao: TFDMemTable;
    MainMenu1: TMainMenu;
    procedure Button100Click(Sender: TObject);
    procedure Button102Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure dgDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure TabSheet1Show(Sender: TObject);
    procedure _BuscarEGravarTransacoes;
    procedure ckTransacoesClick(Sender: TObject);
    procedure tmTransacoesTimer(Sender: TObject);
    procedure edIntervalChange(Sender: TObject);
    procedure _ConfigurarTimer;
    procedure btSalvarIntervalClick(Sender: TObject);
    procedure _AbrirTransacoesGravadas;
    procedure gdConciliacaoCalcCellColors(Sender: TObject; Field: TField;
      State: TGridDrawState; Highlight: Boolean; AFont: TFont; ABrush: TBrush);
    procedure alRegistrarExecute(Sender: TObject);
    procedure alRegistrarUpdate(Sender: TObject);
    procedure gdConciliacaoTitleButtonClick(Sender: TObject;
      AFieldName: string);
    procedure gdConciliacaoUpdateFooter(Sender: TObject);
    procedure gdConciliacaoAfterDrawCell(Sender: TwwCustomDBGrid;
      DrawCellInfo: TwwCustomDrawGridCellInfo);
  private
    BRFW: IController;
    VC_TotalRegistros: integer;
    VC_Interval: integer;
    VC_IbernarInicio: TTime;
    VC_IbernarFim: TTime;
    procedure _OnErroPedidoPago(vMensagem: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frPrincipal: TfrPrincipal;

const

StatusFontColor: array[0..2] of TColor = (
  $00B0ECB0,     // verde
  $008484FF,     // vermelho
  $009DF5FF   // amarelo

);

StatusCode: array[0..2] of string = (
  'K', 'C', 'D'
);

  StatusDescricao: TArray<string> = ['Registrados no caixa', 'Não cadastrada', 'Diferença de valor'];


implementation
uses BRFW.Lib;

{$R *.dfm}

procedure TfrPrincipal.alRegistrarExecute(Sender: TObject);
begin
   if MessageDlg(Format('Confirma o registro no Caixa da Solicitação %d em %s?',
       [dsConciliacao.DataSet.FieldByName('SOLICITACAO').AsInteger,
        DateToStr(Date)]), mtWarning, [mbYes, mbNo], 0, mbNo) <> mrYes then
   begin
      exit;
   end;
   BRFW.Integracao.PedidoPago.Transacoes
         .FCerta
            .Gravar
               .EstacaoId(GetEnvironmentVariable('USERDOMAIN'))
                  .Solicitacao(dsConciliacao.DataSet.FieldByName('SOLICITACAO').AsInteger)
                  .DataMovimento(Date)
                  .Event
                     .OnError(_OnErroPedidoPago)
                  .&End
                  .ExecuteHum;
   TFDMemTable(dsConciliacao.DataSet).Refresh;
   Showmessage('Registro efetuado com sucesso.');
end;

procedure TfrPrincipal.alRegistrarUpdate(Sender: TObject);
var
  A: TAction;
begin
  if not (Sender is TAction) then
    Exit;

  A := TAction(Sender);

  if (dsConciliacao <> nil) and
     (dsConciliacao.DataSet <> nil) and
     dsConciliacao.DataSet.Active and
     (not dsConciliacao.DataSet.IsEmpty)
  then
    A.Enabled := (Pos(dsConciliacao.DataSet.FieldByName('STATUS').AsString, 'K.C') = 0)
  else
    A.Enabled := False;
end;

procedure TfrPrincipal.btSalvarIntervalClick(Sender: TObject);
begin
   BRFW.Configuracao.App
       .Atributos
          .Secao('TRANSACOES')
          .Chave('INTERVALO')
          .Valor(StrToIntDef(edInterval.Text, 5))
       .&End
       .Operacoes
       .Gravar;
end;

procedure TfrPrincipal.Button100Click(Sender: TObject);
var
   VI_Transacoes: TJsonArray;
   VI_Cursor: TCursor;
begin
   if ckTransacoes.Checked then
   begin
      Showmessage('Desative o Temporizador.');
      exit;
   end;
   VI_Transacoes := TJsonArray.Create;
   VI_Cursor := Screen.Cursor;
   Screen.Cursor := crHourGlass;
   try
      BRFW.Integracao.PedidoPago
           .DataInicial(edDataTransacoes.Date)
           .Transacoes
              .Listar
                 .Lista(VI_Transacoes)
                 .Gravar;
      ShowMessage(Format('Operação efetuada com sucesso. %d transações encontradas.', [VI_Transacoes.Count]));
   finally
      VI_Transacoes.DisposeOf;
      Screen.Cursor := VI_Cursor;
   end;
end;

procedure TfrPrincipal.Button102Click(Sender: TObject);
begin
   try
      BRFW.Integracao.PedidoPago.Transacoes
         .FCerta
            .Gravar
               .EstacaoId('MiltonTeste')
               .DataMovimento(edtDataFinal.Date)             ///!!!! ACERTAR PRODUÇÃO
               .DataSource(dsConciliacao)
               .Execute;
   except
      on e: exception do
      begin
//         mmPedidoPago.Lines.Add(e.message);
      end;
   end;
end;

procedure TfrPrincipal.Button1Click(Sender: TObject);
var
   VI_Cursor: TCursor;
begin
   VI_Cursor := Screen.Cursor;
   Screen.Cursor := crHourGlass;
   try
      _AbrirTransacoesGravadas;
      pg.ActivePageIndex := 0;
   finally
      Screen.Cursor := VI_Cursor;
   end;
end;

procedure TfrPrincipal.ckTransacoesClick(Sender: TObject);
begin
   tmTransacoes.enabled := ckTransacoes.Checked;
end;

procedure TfrPrincipal.dgDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
begin
  with (Sender as TDrawGrid).Canvas do
  begin
    Brush.Color := StatusFontColor[ARow]; // array de cores
    FillRect(Rect);
    TextOut(Rect.Left + 24, Rect.Top + 4, StatusDescricao[ARow]);
  end;
end;

procedure TfrPrincipal.edIntervalChange(Sender: TObject);
begin
   ckTransacoes.Checked := false;
   tmTransacoes.Interval := StrToIntDef(edInterval.Text, 5) * 60 * 1000;
end;

procedure TfrPrincipal.FormCreate(Sender: TObject);
begin
   pg.ActivePage := tbPagamentos;
   BRFW := TController.New;
   _ConfigurarTimer;
   _AbrirTransacoesGravadas;
end;


procedure TfrPrincipal.TabSheet1Show(Sender: TObject);
begin
   dg.ColWidths[0] := dg.ClientWidth - dg.GridLineWidth;;
end;

procedure TfrPrincipal.tmTransacoesTimer(Sender: TObject);
var
  Agora, ProximoHorario: TDateTime;
begin
  Agora := Now;
  if (Time >= EncodeTime(20, 0, 0, 0)) or (Time < EncodeTime(8, 0, 0, 0)) then
  begin
    tmTransacoes.Enabled := False;
    if Time >= EncodeTime(20, 0, 0, 0) then
      ProximoHorario := (Date + 1) + EncodeTime(8,0,0,0)   // amanhã às 08:00
    else
      ProximoHorario := Date + EncodeTime(8,0,0,0);        // hoje às 08:00
    tmTransacoes.Interval :=
      MilliSecondsBetween(Agora, ProximoHorario);

    tmTransacoes.Enabled := True;

    Exit;
  end;
  _BuscarEGravarTransacoes;
  tmTransacoes.Interval := StrToIntDef(edInterval.Text, 5) * 60 * 1000;
end;

procedure TfrPrincipal.gdConciliacaoAfterDrawCell(Sender: TwwCustomDBGrid;
  DrawCellInfo: TwwCustomDrawGridCellInfo);
var
  Grid: TwwDBGrid;
begin
  Grid := Sender as TwwDBGrid;

  // Só mexe nas colunas fixas (0..FixedCols-1)
  if DrawCellInfo.DataCol < Grid.FixedCols then
  begin
    // Usa a cor de fundo do grid (ou da célula) pra "apagar" a linha inferior
    Grid.Canvas.Pen.Color := Grid.Color;   // se tiver cor de linha por status, você pode ajustar aqui
    Grid.Canvas.MoveTo(DrawCellInfo.Rect.Left, DrawCellInfo.Rect.Bottom-1);
    Grid.Canvas.LineTo(DrawCellInfo.Rect.Right, DrawCellInfo.Rect.Bottom-1);
  end;
end;

procedure TfrPrincipal.gdConciliacaoCalcCellColors(Sender: TObject; Field: TField;
  State: TGridDrawState; Highlight: Boolean; AFont: TFont; ABrush: TBrush);

var
   idx: integer;
   isCurrentRow: Boolean;
begin
//  if assigned(dsConciliacao) then
//     idx := IndexText(dsConciliacao.DataSet.FieldByName('STATUS').AsString, StatusCode)
//  else
//  begin
//     showmessage('datasource foi eliminado');
//     exit;
//  end;
//
//  if idx >= 0 then
//    ABrush.Color := StatusFontColor[idx];
//
//   if gdFocused in State then
//   begin
//      AFont.Style := [fsBold];
//      AFont.Color := clNone;     // mantém cor original da sua regra
//  end;

// ---------------------------

  isCurrentRow :=
    (gdConciliacao.GetActiveRow = gdConciliacao.DataSource.DataSet.RecNo-1);

  if isCurrentRow then
  begin
    ABrush.Color := $00FFF2C5;  // cor da linha selecionada
    AFont.Color  := clBlack;
    AFont.Style  := [fsBold];
    Exit;
  end;

  if Assigned(dsConciliacao) then
    idx := IndexText(dsConciliacao.DataSet.FieldByName('STATUS').AsString, StatusCode)
  else
  begin
    ShowMessage('datasource foi eliminado');
    Exit;
  end;

  if idx >= 0 then
    ABrush.Color := StatusFontColor[idx];

  if gdFocused in State then
  begin
    AFont.Style := [fsBold];
    AFont.Color := clNone;
  end;

end;

procedure TfrPrincipal.gdConciliacaoTitleButtonClick(Sender: TObject;
  AFieldName: string);
begin
   if AFieldName = '' then
      Exit;

  // Alterna ASC/DESC
  if TFDMemTable(dsConciliacao.Dataset).IndexFieldNames = AFieldName then
     TFDMemTable(dsConciliacao.Dataset).IndexFieldNames := AFieldName + ':D'  // Descending
  else
     TFDMemTable(dsConciliacao.Dataset).IndexFieldNames := AFieldName;       // Ascending
end;

procedure TfrPrincipal.gdConciliacaoUpdateFooter(Sender: TObject);
begin
   (Sender as TwwDBGrid).ColumnByName('Filial').FooterValue := VC_TotalRegistros.ToString;
end;

procedure TfrPrincipal._AbrirTransacoesGravadas;
var
   VI_SQL: string;
begin
   VI_SQL := 'SELECT * FROM VW_CONCILIACAO WHERE DATAPAG BETWEEN :DATAPAG1 AND :DATAPAG2 ';
//      ' OR STATUS IN (''P'', ''N'') ';
   if edtDataInicial.Date = 0 then
      VI_SQL := VI_SQL
           .Replace(':DATAPAG1', QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', IncMonth(Date, -1))))
           .Replace(':DATAPAG2', QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)))
   else
      VI_SQL := VI_SQL
           .Replace(':DATAPAG1', QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', edtDataInicial.Date)))
           .Replace(':DATAPAG2', QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', edtDataFinal.Date)));

  BRFW.Database.FCerta40.Consulta
      .Atributos
         .SQL(VI_SQL)
      .&End
      .DataSource(dsConciliacao)
      .CacheSegundos(0)
      .Open(VC_TotalRegistros);
end;

procedure TfrPrincipal._BuscarEGravarTransacoes;
var
   VI_Transacoes: TJsonArray;
begin
   VI_Transacoes := TJsonArray.Create;
   try
      BRFW.Integracao.PedidoPago
           .DataInicial(edDataTransacoes.Date)
           .Transacoes
              .Listar
                 .Lista(VI_Transacoes)
                 .Gravar;
   finally
      VI_Transacoes.DisposeOf;
   end;
end;

procedure TfrPrincipal._ConfigurarTimer;
var
   VI_Interval: integer;
begin
   tmTransacoes.Enabled := false;
   BRFW.Configuracao.App
       .Atributos
          .Secao('TRANSACOES')
          .Chave('INTERVALO')
          .Padrao(5)
       .&End
       .Operacoes
         .Ler(VI_Interval)
       .&End
       .Atributos
          .Chave('IBERNAR_INICIO')
          .Padrao(StrToTime('00:01'))
       .&End
       .Operacoes
         .Ler(VC_IbernarInicio)
       .&End
       .Atributos
          .Chave('IBERNAR_FIM')
          .Padrao(StrToTime('03:00'))
       .&End
       .Operacoes
         .Ler(VC_IbernarFim)
       .&End;

   // armazena em minutos
   // timer.interval em milisegundos.
   VC_Interval := VI_Interval * 60 * 1000;
   tmTransacoes.Interval := VC_Interval;
   //
   tmTransacoes.Enabled := true;
   //
end;

procedure TfrPrincipal._OnErroPedidoPago(vMensagem: string);
begin
   BRFW.Log.Texto.Gravar(vMensagem);
end;

{ TModelIntegracaoPedidoPago }

class function TModelIntegracaoPedidoPago._BancoFCerta: TEnumDbTarget;
begin
//   result := dbtFCerta;
   result := dbtFCerta40;
end;

class function TModelIntegracaoPedidoPago._CNPJS: TArray<String>;
begin

end;

end.

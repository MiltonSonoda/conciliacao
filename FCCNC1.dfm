object frPrincipal: TfrPrincipal
  Left = 0
  Top = 0
  Caption = 'ArtPharma - Concilia'#231#227'o Financeira - [%s a %s]'
  ClientHeight = 576
  ClientWidth = 1126
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 559
    Width = 1126
    Height = 17
    Align = alBottom
    TabOrder = 0
  end
  object pg: TPageControl
    Left = 0
    Top = 0
    Width = 1126
    Height = 559
    ActivePage = tbPagamentos
    Align = alClient
    TabOrder = 1
    object tbPagamentos: TTabSheet
      Caption = 'Pagamentos'
      ImageIndex = 4
      object gdConciliacao: TwwDBGrid
        Left = 0
        Top = 0
        Width = 1118
        Height = 490
        ControlType.Strings = (
          'CK;CheckBox;1;0'
          'IT;CustomEdit;wwExpandButton1;F')
        Selected.Strings = (
          'ID'#9'10'#9'ID'#9#9
          'FILIAL'#9'10'#9'FILIAL'#9#9
          'SOLICITACAO'#9'10'#9'SOLICITACAO'#9#9
          'CLIENTE'#9'30'#9'CLIENTE'#9#9
          'ORCAMENTO'#9'10'#9'ORCAMENTO'#9#9
          'DOCUMENTO'#9'11'#9'DOCUMENTO'#9#9
          'PEDIDO'#9'10'#9'PEDIDO'#9#9
          'FORMAPAG'#9'20'#9'FORMAPAG'#9#9
          'BANDEIRA'#9'20'#9'BANDEIRA'#9#9
          'ADQTE'#9'20'#9'ADQTE'#9#9
          'TID'#9'10'#9'TID'#9#9
          'DATACRIA'#9'18'#9'DATACRIA'#9#9
          'DATAPAG'#9'18'#9'DATAPAG'#9#9
          'VALORPAG'#9'10'#9'VALORPAG'#9#9
          'DIFVALOR'#9'10'#9'DIFVALOR'#9#9
          'STATUSPAG'#9'10'#9'STATUSPAG'#9#9
          'STATUS'#9'1'#9'STATUS'#9'T')
        IniAttributes.Delimiter = ';;'
        IniAttributes.UnicodeIniFile = False
        TitleColor = clBtnFace
        FixedCols = 4
        ShowHorzScrollBar = True
        EditControlOptions = [ecoCheckboxSingleClick, ecoSearchOwnerForm]
        Align = alClient
        DataSource = dsConciliacao
        KeyOptions = []
        Options = [dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgTabs, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgWordWrap, dgMultiSelect, dgShowFooter, dgFixedResizable, dgFixedEditable, dgFixedProportionalResize]
        TabOrder = 0
        TitleAlignment = taLeftJustify
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'Tahoma'
        TitleFont.Style = []
        TitleLines = 1
        TitleButtons = True
        UseTFields = False
        OnCalcCellColors = gdConciliacaoCalcCellColors
        OnTitleButtonClick = gdConciliacaoTitleButtonClick
        OnUpdateFooter = gdConciliacaoUpdateFooter
        FooterColor = clHighlightText
        OnAfterDrawCell = gdConciliacaoAfterDrawCell
      end
      object Panel1: TPanel
        Left = 0
        Top = 490
        Width = 1118
        Height = 41
        Align = alBottom
        TabOrder = 1
        DesignSize = (
          1118
          41)
        object btnRegistrar: TButton
          Left = 446
          Top = 8
          Width = 306
          Height = 25
          Action = alRegistrar
          Anchors = [akLeft, akTop, akRight, akBottom]
          TabOrder = 0
        end
      end
    end
    object tbFiltros: TTabSheet
      Caption = 'Filtros'
      ImageIndex = 2
      object Button102: TButton
        Left = 732
        Top = 47
        Width = 209
        Height = 33
        Caption = 'Alimentar Movimento Caixa'
        TabOrder = 0
        Visible = False
        OnClick = Button102Click
      end
      object GroupBox1: TGroupBox
        Left = 32
        Top = 176
        Width = 649
        Height = 121
        Caption = 'Buscar transa'#231#245'es'
        TabOrder = 1
        object Label4: TLabel
          Left = 24
          Top = 56
          Width = 73
          Height = 13
          Caption = 'Data espec'#237'fica'
        end
        object edDataTransacoes: TDateEdit
          Left = 124
          Top = 53
          Width = 135
          Height = 21
          NumGlyphs = 2
          TabOrder = 0
        end
        object Button100: TButton
          Left = 286
          Top = 47
          Width = 209
          Height = 33
          Caption = 'Buscar e salvar transa'#231#245'es'
          TabOrder = 1
          OnClick = Button100Click
        end
      end
      object GroupBox2: TGroupBox
        Left = 32
        Top = 16
        Width = 649
        Height = 130
        Caption = 'Carregar transa'#231#245'es gravadas'
        TabOrder = 2
        object Label1: TLabel
          Left = 24
          Top = 40
          Width = 51
          Height = 13
          Caption = 'Data inicial'
        end
        object Label2: TLabel
          Left = 24
          Top = 67
          Width = 46
          Height = 13
          Caption = 'Data final'
        end
        object edtDataInicial: TDateEdit
          Left = 124
          Top = 37
          Width = 135
          Height = 21
          NumGlyphs = 2
          TabOrder = 0
        end
        object edtDataFinal: TDateEdit
          Left = 124
          Top = 64
          Width = 135
          Height = 21
          NumGlyphs = 2
          TabOrder = 1
        end
        object Button1: TButton
          Left = 286
          Top = 47
          Width = 209
          Height = 33
          Caption = 'Carregar transa'#231#245'es'
          TabOrder = 2
          OnClick = Button1Click
        end
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'Legendas'
      ImageIndex = 3
      OnShow = TabSheet1Show
      object dg: TDrawGrid
        Left = 56
        Top = 48
        Width = 320
        Height = 137
        ColCount = 2
        FixedCols = 0
        RowCount = 4
        FixedRows = 0
        TabOrder = 0
        OnDrawCell = dgDrawCell
      end
    end
  end
  object dsConciliacao: TDataSource
    AutoEdit = False
    DataSet = tbConciliacao
    Left = 424
    Top = 128
  end
  object ActionList1: TActionList
    Left = 420
    Top = 264
    object alRegistrar: TAction
      Caption = 'Registrar venda no Caixa'
      OnExecute = alRegistrarExecute
      OnUpdate = alRegistrarUpdate
    end
  end
  object tbConciliacao: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 492
    Top = 128
    object tbConciliacaoIT: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'IT'
      Size = 1
    end
    object tbConciliacaoCK: TIntegerField
      FieldKind = fkInternalCalc
      FieldName = 'CK'
      OnChange = tbConciliacaoCKChange
    end
    object tbConciliacaoID: TIntegerField
      DisplayWidth = 10
      FieldName = 'ID'
    end
    object tbConciliacaoFILIAL: TStringField
      DisplayWidth = 10
      FieldName = 'FILIAL'
      Size = 10
    end
    object tbConciliacaoSOLICITACAO: TIntegerField
      DisplayWidth = 10
      FieldName = 'SOLICITACAO'
    end
    object tbConciliacaoCLIENTE: TStringField
      DisplayWidth = 30
      FieldName = 'CLIENTE'
      Size = 30
    end
    object tbConciliacaoORCAMENTO: TStringField
      DisplayWidth = 10
      FieldName = 'ORCAMENTO'
      Size = 10
    end
    object tbConciliacaoDOCUMENTO: TStringField
      DisplayWidth = 11
      FieldName = 'DOCUMENTO'
      Size = 11
    end
    object tbConciliacaoPEDIDO: TStringField
      DisplayWidth = 10
      FieldName = 'PEDIDO'
      Size = 10
    end
    object tbConciliacaoFORMAPAG: TStringField
      DisplayWidth = 20
      FieldName = 'FORMAPAG'
    end
    object tbConciliacaoBANDEIRA: TStringField
      DisplayWidth = 20
      FieldName = 'BANDEIRA'
    end
    object tbConciliacaoADQTE: TStringField
      DisplayWidth = 20
      FieldName = 'ADQTE'
    end
    object tbConciliacaoTID: TIntegerField
      DisplayWidth = 10
      FieldName = 'TID'
    end
    object tbConciliacaoDATACRIA: TDateTimeField
      DisplayWidth = 18
      FieldName = 'DATACRIA'
    end
    object tbConciliacaoDATAPAG: TDateTimeField
      DisplayWidth = 18
      FieldName = 'DATAPAG'
    end
    object tbConciliacaoVALORPAG: TCurrencyField
      DisplayWidth = 10
      FieldName = 'VALORPAG'
    end
    object tbConciliacaoDIFVALOR: TCurrencyField
      DisplayWidth = 10
      FieldName = 'DIFVALOR'
    end
    object tbConciliacaoSTATUSPAG: TStringField
      DisplayWidth = 10
      FieldName = 'STATUSPAG'
      Size = 10
    end
    object tbConciliacaoSTATUS: TStringField
      DisplayWidth = 1
      FieldName = 'STATUS'
      Size = 1
    end
  end
  object MainMenu1: TMainMenu
    Left = 196
    Top = 232
  end
  object tbItens: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 492
    Top = 184
    object tbItensSOLICITACAO: TIntegerField
      FieldName = 'SOLICITACAO'
    end
    object tbItensTPITM: TStringField
      FieldName = 'TPITM'
      Size = 1
    end
    object tbItensCDFIL: TIntegerField
      FieldName = 'CDFIL'
    end
    object tbItensNRORC: TIntegerField
      FieldName = 'NRORC'
    end
    object tbItensSERIEO: TStringField
      FieldName = 'SERIEO'
      Size = 1
    end
    object tbItensDESCRICAOWEB: TStringField
      FieldName = 'DESCRICAOWEB'
      Size = 50
    end
    object tbItensQUANT: TIntegerField
      FieldName = 'QUANT'
    end
    object tbItensPRUNI: TCurrencyField
      FieldName = 'PRUNI'
    end
    object tbItensVRTOT: TCurrencyField
      FieldName = 'VRTOT'
    end
    object tbItensPTDSC: TFloatField
      FieldName = 'PTDSC'
    end
    object tbItensVRDSC: TCurrencyField
      FieldName = 'VRDSC'
    end
    object tbItensVRTXA: TCurrencyField
      FieldName = 'VRTXA'
    end
    object tbItensVRLIQ: TCurrencyField
      FieldName = 'VRLIQ'
    end
  end
  object dsItens: TDataSource
    AutoEdit = False
    DataSet = tbItens
    Left = 424
    Top = 192
  end
end

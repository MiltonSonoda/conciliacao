object frPrincipal: TfrPrincipal
  Left = 0
  Top = 0
  Caption = 'ArtPharma - Concilia'#231#227'o Financeira'
  ClientHeight = 516
  ClientWidth = 1126
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 499
    Width = 1126
    Height = 17
    Align = alBottom
    TabOrder = 0
    ExplicitWidth = 989
  end
  object pg: TPageControl
    Left = 0
    Top = 0
    Width = 1126
    Height = 499
    ActivePage = tbPagamentos
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 989
    object tbPagamentos: TTabSheet
      Caption = 'Pagamentos'
      ImageIndex = 4
      ExplicitWidth = 981
      object gdConciliacao: TwwDBGrid
        Left = 0
        Top = 0
        Width = 1118
        Height = 430
        IniAttributes.Delimiter = ';;'
        IniAttributes.UnicodeIniFile = False
        TitleColor = clBtnFace
        FixedCols = 4
        ShowHorzScrollBar = True
        Align = alClient
        DataSource = dsConciliacao
        KeyOptions = []
        Options = [dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgTabs, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgWordWrap, dgShowFooter, dgFixedResizable, dgFixedEditable, dgFixedProportionalResize]
        ReadOnly = True
        TabOrder = 0
        TitleAlignment = taLeftJustify
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'Tahoma'
        TitleFont.Style = []
        TitleLines = 1
        TitleButtons = True
        OnCalcCellColors = gdConciliacaoCalcCellColors
        OnTitleButtonClick = gdConciliacaoTitleButtonClick
        OnUpdateFooter = gdConciliacaoUpdateFooter
        FooterColor = clHighlightText
        OnAfterDrawCell = gdConciliacaoAfterDrawCell
        ExplicitTop = 2
        ExplicitWidth = 981
      end
      object Panel1: TPanel
        Left = 0
        Top = 430
        Width = 1118
        Height = 41
        Align = alBottom
        TabOrder = 1
        ExplicitWidth = 981
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
      ExplicitWidth = 981
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
          Top = 33
          Width = 73
          Height = 13
          Caption = 'Data espec'#237'fica'
        end
        object Label3: TLabel
          Left = 167
          Top = 65
          Width = 37
          Height = 13
          Caption = 'minutos'
        end
        object edDataTransacoes: TDateEdit
          Left = 124
          Top = 30
          Width = 135
          Height = 21
          NumGlyphs = 2
          TabOrder = 0
        end
        object Button100: TButton
          Left = 286
          Top = 24
          Width = 209
          Height = 33
          Caption = 'Buscar e salvar transa'#231#245'es'
          TabOrder = 4
          OnClick = Button100Click
        end
        object edInterval: TEdit
          Left = 126
          Top = 62
          Width = 35
          Height = 21
          TabOrder = 1
          Text = '5'
          OnChange = edIntervalChange
        end
        object btSalvarInterval: TBitBtn
          Left = 216
          Top = 62
          Width = 41
          Height = 25
          Caption = 'Salvar'
          TabOrder = 2
          OnClick = btSalvarIntervalClick
        end
        object ckTransacoes: TCheckBox
          Left = 286
          Top = 70
          Width = 97
          Height = 17
          Caption = 'Temporizador'
          Checked = True
          State = cbChecked
          TabOrder = 3
          OnClick = ckTransacoesClick
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
      ExplicitWidth = 981
      object dg: TDrawGrid
        Left = 56
        Top = 48
        Width = 320
        Height = 137
        ColCount = 2
        FixedCols = 0
        RowCount = 3
        FixedRows = 0
        TabOrder = 0
        OnDrawCell = dgDrawCell
      end
    end
  end
  object dsConciliacao: TDataSource
    DataSet = tbConciliacao
    Left = 416
    Top = 112
  end
  object tmTransacoes: TTimer
    Enabled = False
    Interval = 300000
    OnTimer = tmTransacoesTimer
    Left = 828
    Top = 232
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
    Left = 500
    Top = 120
  end
  object MainMenu1: TMainMenu
    Left = 308
    Top = 168
  end
end

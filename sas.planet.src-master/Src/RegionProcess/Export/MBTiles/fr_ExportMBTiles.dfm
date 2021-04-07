object frExportMBTiles: TfrExportMBTiles
  Left = 0
  Top = 0
  Width = 550
  Height = 329
  Align = alClient
  Constraints.MinHeight = 230
  Constraints.MinWidth = 550
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  ExplicitHeight = 304
  object pnlCenter: TPanel
    Left = 0
    Top = 27
    Width = 550
    Height = 302
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitHeight = 277
    object pnlMain: TPanel
      Left = 0
      Top = 0
      Width = 467
      Height = 302
      Align = alClient
      BevelOuter = bvNone
      BorderWidth = 3
      TabOrder = 0
      ExplicitHeight = 277
      object lblMap: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 461
        Height = 13
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Align = alTop
        AutoSize = False
        Caption = 'Map:'
      end
      object lblOverlay: TLabel
        Left = 3
        Top = 42
        Width = 461
        Height = 13
        Align = alTop
        Caption = 'Overlay layer:'
        ExplicitWidth = 69
      end
      object lblDesc: TLabel
        Left = 3
        Top = 228
        Width = 461
        Height = 13
        Align = alTop
        Caption = 'Description:'
        ExplicitTop = 211
        ExplicitWidth = 57
      end
      object lblName: TLabel
        Left = 3
        Top = 194
        Width = 461
        Height = 13
        Align = alTop
        Caption = 'Name:'
        ExplicitTop = 177
        ExplicitWidth = 31
      end
      object lblAttr: TLabel
        Left = 3
        Top = 262
        Width = 461
        Height = 13
        Align = alTop
        Caption = 'Attribution:'
        ExplicitTop = 245
        ExplicitWidth = 55
      end
      object pnlMap: TPanel
        Left = 3
        Top = 19
        Width = 461
        Height = 23
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
      end
      object pnlOverlay: TPanel
        Left = 3
        Top = 55
        Width = 461
        Height = 23
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
      end
      object pnlImageFormat: TPanel
        Left = 3
        Top = 146
        Width = 461
        Height = 48
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 6
        ExplicitTop = 129
        object lblJpgQulity: TLabel
          Left = 156
          Top = 6
          Width = 90
          Height = 13
          Caption = 'Quality (for JPEG):'
          Layout = tlCenter
        end
        object lblImageFormat: TLabel
          Left = 0
          Top = 6
          Width = 69
          Height = 13
          Caption = 'Image format:'
          Layout = tlCenter
        end
        object lblCompression: TLabel
          Left = 312
          Top = 6
          Width = 113
          Height = 13
          Caption = 'Compression (for PNG):'
          Layout = tlCenter
        end
        object seJpgQuality: TSpinEdit
          Left = 156
          Top = 22
          Width = 150
          Height = 22
          MaxValue = 100
          MinValue = 1
          TabOrder = 1
          Value = 75
        end
        object cbbImageFormat: TComboBox
          Left = 0
          Top = 22
          Width = 150
          Height = 21
          ItemIndex = 0
          TabOrder = 0
          Text = 'Auto'
          OnChange = cbbImageFormatChange
          Items.Strings = (
            'Auto'
            'JPEG'
            'PNG (Indexed Colors)'
            'PNG (TrueColor)'
            'PNG (TrueColor + Alpha)')
        end
        object seCompression: TSpinEdit
          Left = 312
          Top = 22
          Width = 150
          Height = 22
          MaxValue = 9
          MinValue = 0
          TabOrder = 2
          Value = 2
        end
      end
      object chkUsePrevZoom: TCheckBox
        Left = 3
        Top = 95
        Width = 461
        Height = 17
        Align = alTop
        Caption = 'Use tiles from lower zooms (on unavalible tile)'
        TabOrder = 3
      end
      object chkUseXYZScheme: TCheckBox
        Left = 3
        Top = 112
        Width = 461
        Height = 17
        Align = alTop
        Caption = 'Use xyz scheme'
        TabOrder = 4
      end
      object edtDesc: TEdit
        Left = 3
        Top = 241
        Width = 461
        Height = 21
        Align = alTop
        TabOrder = 8
        ExplicitTop = 224
      end
      object edtName: TEdit
        Left = 3
        Top = 207
        Width = 461
        Height = 21
        Align = alTop
        TabOrder = 7
        ExplicitTop = 190
      end
      object edtAttr: TEdit
        Left = 3
        Top = 275
        Width = 461
        Height = 21
        Align = alTop
        TabOrder = 9
        ExplicitTop = 258
      end
      object chkAddVisibleLayers: TCheckBox
        Left = 3
        Top = 78
        Width = 461
        Height = 17
        Align = alTop
        Caption = 'Add visible Layers'
        TabOrder = 2
        OnClick = chkAddVisibleLayersClick
      end
      object chkMakeTileMillStruct: TCheckBox
        Left = 3
        Top = 129
        Width = 461
        Height = 17
        Align = alTop
        Caption = 'Make TileMill compatible structure'
        TabOrder = 5
      end
    end
    object PnlZoom: TPanel
      Left = 467
      Top = 0
      Width = 83
      Height = 302
      Align = alRight
      BevelOuter = bvNone
      BiDiMode = bdLeftToRight
      ParentBiDiMode = False
      TabOrder = 1
      ExplicitHeight = 277
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 550
    Height = 27
    Align = alTop
    BevelOuter = bvNone
    BorderWidth = 3
    TabOrder = 0
    object lblTargetFile: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 41
      Height = 18
      Margins.Left = 0
      Margins.Top = 0
      Align = alLeft
      Caption = 'Save to:'
      Layout = tlCenter
      ExplicitHeight = 13
    end
    object edtTargetFile: TEdit
      Left = 47
      Top = 3
      Width = 479
      Height = 21
      Align = alClient
      TabOrder = 0
    end
    object btnSelectTargetFile: TButton
      Left = 526
      Top = 3
      Width = 21
      Height = 21
      Align = alRight
      Caption = '...'
      TabOrder = 1
      OnClick = btnSelectTargetFileClick
    end
  end
  object dlgSaveTo: TSaveDialog
    DefaultExt = 'mbtiles'
    Filter = 'mbtiles|*.mbtiles'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 416
    Top = 272
  end
end

object frExportToJNX: TfrExportToJNX
  Left = 0
  Top = 0
  Width = 480
  Height = 220
  Align = alClient
  Anchors = [akLeft, akRight, akBottom]
  Constraints.MinHeight = 220
  Constraints.MinWidth = 480
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  Visible = False
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 480
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
      Height = 21
      Margins.Left = 0
      Margins.Top = 0
      Align = alLeft
      Alignment = taRightJustify
      Caption = 'Save to:'
      Layout = tlCenter
    end
    object edtTargetFile: TEdit
      Left = 47
      Top = 3
      Width = 409
      Height = 21
      Align = alClient
      TabOrder = 0
    end
    object btnSelectTargetFile: TButton
      Left = 456
      Top = 3
      Width = 21
      Height = 21
      Align = alRight
      Caption = '...'
      TabOrder = 1
      OnClick = btnSelectTargetFileClick
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 27
    Width = 480
    Height = 193
    ActivePage = Map
    Align = alClient
    TabOrder = 1
    OnChange = PageControl1Change
    object Map: TTabSheet
      Caption = 'Map'
      DesignSize = (
        472
        165)
      object pnlCenter: TPanel
        Left = 0
        Top = 0
        Width = 472
        Height = 165
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        object lblMap: TLabel
          AlignWithMargins = True
          Left = 27
          Top = 0
          Width = 24
          Height = 13
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Align = alCustom
          Caption = 'Map:'
        end
        object pnlMain: TPanel
          Left = 255
          Top = 0
          Width = 216
          Height = 241
          Align = alCustom
          Anchors = [akTop, akRight]
          AutoSize = True
          BevelOuter = bvNone
          BorderWidth = 3
          TabOrder = 0
          DesignSize = (
            216
            241)
          object lblCompress: TLabel
            Left = 153
            Top = 0
            Width = 65
            Height = 13
            Anchors = [akTop, akRight]
            Caption = 'Compression:'
          end
          object Label1: TLabel
            Left = 5
            Top = 0
            Width = 35
            Height = 13
            Anchors = [akTop, akRight]
            Caption = 'Zooms:'
          end
          object Label2: TLabel
            Left = 70
            Top = 0
            Width = 29
            Height = 13
            Anchors = [akTop, akRight]
            Caption = 'Scale:'
          end
          object EJpgQuality1: TSpinEdit
            Left = 154
            Top = 19
            Width = 57
            Height = 22
            Anchors = [akTop, akRight]
            Enabled = False
            MaxValue = 100
            MinValue = 10
            TabOrder = 2
            Value = 95
          end
          object CbbZoom1: TComboBox
            Left = 5
            Top = 19
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 0
            OnChange = CbbZoom1Change
          end
          object EJpgQuality2: TSpinEdit
            Left = 154
            Top = 46
            Width = 57
            Height = 22
            Anchors = [akTop, akRight]
            Enabled = False
            MaxValue = 100
            MinValue = 10
            TabOrder = 6
            Value = 95
          end
          object CbbZoom2: TComboBox
            Left = 5
            Top = 46
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 4
            OnChange = CbbZoom2Change
          end
          object EJpgQuality4: TSpinEdit
            Left = 154
            Top = 100
            Width = 57
            Height = 22
            Anchors = [akTop, akRight]
            Enabled = False
            MaxValue = 100
            MinValue = 10
            TabOrder = 14
            Value = 95
          end
          object CbbZoom4: TComboBox
            Left = 5
            Top = 100
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 12
            OnChange = CbbZoom4Change
          end
          object EJpgQuality5: TSpinEdit
            Left = 154
            Top = 127
            Width = 57
            Height = 22
            Anchors = [akTop, akRight]
            Enabled = False
            MaxValue = 100
            MinValue = 10
            TabOrder = 18
            Value = 95
          end
          object CbbZoom5: TComboBox
            Left = 5
            Top = 127
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 16
            OnChange = CbbZoom5Change
          end
          object EJpgQuality3: TSpinEdit
            Left = 154
            Top = 73
            Width = 57
            Height = 22
            Anchors = [akTop, akRight]
            Enabled = False
            MaxValue = 100
            MinValue = 10
            TabOrder = 10
            Value = 95
          end
          object CbbZoom3: TComboBox
            Left = 5
            Top = 73
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 8
            OnChange = CbbZoom3Change
          end
          object cbbscale2: TComboBox
            Left = 70
            Top = 46
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 5
          end
          object cbbscale3: TComboBox
            Left = 70
            Top = 73
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 9
          end
          object cbbscale4: TComboBox
            Left = 70
            Top = 100
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 13
          end
          object cbbscale5: TComboBox
            Left = 70
            Top = 127
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 17
          end
          object cbbscale1: TComboBox
            Left = 70
            Top = 19
            Width = 57
            Height = 21
            Align = alCustom
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Enabled = False
            ItemHeight = 13
            TabOrder = 1
            Items.Strings = (
              '800km'
              '500km'
              '300km'
              '200km'
              '120km'
              '80km'
              '50km'
              '30km'
              '20km'
              '12km'
              '8km'
              '5km'
              '3km'
              '2km'
              '1.2km'
              '800m'
              '500m'
              '300m'
              '200m'
              '120m'
              '80m'
              '50m'
              '30m'
              '20m'
              '12m'
              '8m'
              '5m')
          end
          object ChRecompress1: TCheckBox
            Left = 134
            Top = 21
            Width = 20
            Height = 17
            Hint = 
              'Re-compress JPEG tiles'#13#10'Note: Non-JPEG tiles are always recompre' +
              'ssed'
            Enabled = False
            TabOrder = 3
            OnClick = ChRecompress1Click
          end
          object ChRecompress2: TCheckBox
            Left = 134
            Top = 48
            Width = 20
            Height = 17
            Hint = 
              'Re-compress JPEG tiles'#13#10'Note: Non-JPEG tiles are always recompre' +
              'ssed'
            Enabled = False
            TabOrder = 7
            OnClick = ChRecompress2Click
          end
          object ChRecompress3: TCheckBox
            Left = 134
            Top = 75
            Width = 20
            Height = 17
            Hint = 
              'Re-compress JPEG tiles'#13#10'Note: Non-JPEG tiles are always recompre' +
              'ssed'
            Enabled = False
            TabOrder = 11
            OnClick = ChRecompress3Click
          end
          object ChRecompress4: TCheckBox
            Left = 134
            Top = 102
            Width = 20
            Height = 17
            Hint = 
              'Re-compress JPEG tiles'#13#10'Note: Non-JPEG tiles are always recompre' +
              'ssed'
            Enabled = False
            TabOrder = 15
            OnClick = ChRecompress4Click
          end
          object ChRecompress5: TCheckBox
            Left = 134
            Top = 129
            Width = 20
            Height = 17
            Hint = 
              'Re-compress JPEG tiles'#13#10'Note: Non-JPEG tiles are always recompre' +
              'ssed'
            Enabled = False
            TabOrder = 19
            OnClick = ChRecompress5Click
          end
        end
      end
      object MapsPanel: TPanel
        Left = 3
        Top = 18
        Width = 254
        Height = 147
        Anchors = [akLeft, akTop, akRight, akBottom]
        BevelOuter = bvNone
        TabOrder = 1
        DesignSize = (
          254
          147)
        object ChMap1: TCheckBox
          Left = 3
          Top = 3
          Width = 20
          Height = 17
          TabOrder = 1
          OnClick = ChMap1Click
        end
        object ChMap2: TCheckBox
          Left = 3
          Top = 30
          Width = 20
          Height = 17
          Enabled = False
          TabOrder = 3
          OnClick = ChMap2Click
        end
        object ChMap3: TCheckBox
          Left = 3
          Top = 57
          Width = 20
          Height = 17
          Enabled = False
          TabOrder = 5
          OnClick = ChMap3Click
        end
        object ChMap4: TCheckBox
          Left = 3
          Top = 84
          Width = 20
          Height = 17
          Enabled = False
          TabOrder = 7
          OnClick = ChMap4Click
        end
        object ChMap5: TCheckBox
          Left = 3
          Top = 111
          Width = 20
          Height = 17
          Enabled = False
          TabOrder = 9
          OnClick = ChMap5Click
        end
        object pnlMap1: TPanel
          Left = 23
          Top = 1
          Width = 228
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          BevelOuter = bvNone
          TabOrder = 0
        end
        object pnlMap2: TPanel
          Left = 23
          Top = 28
          Width = 228
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          BevelOuter = bvNone
          TabOrder = 2
        end
        object pnlMap4: TPanel
          Left = 23
          Top = 82
          Width = 228
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          BevelOuter = bvNone
          TabOrder = 6
        end
        object pnlMap3: TPanel
          Left = 23
          Top = 55
          Width = 228
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          BevelOuter = bvNone
          TabOrder = 4
        end
        object pnlMap5: TPanel
          Left = 23
          Top = 109
          Width = 228
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          BevelOuter = bvNone
          TabOrder = 8
        end
      end
    end
    object Info: TTabSheet
      Caption = 'Additional'
      ImageIndex = 1
      object PnlInfo: TPanel
        Left = 0
        Top = 0
        Width = 443
        Height = 249
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        object LMapName: TLabel
          Left = 4
          Top = 35
          Width = 50
          Height = 13
          Caption = 'Map Name'
        end
        object LProductID: TLabel
          Left = 3
          Top = 9
          Width = 51
          Height = 13
          Align = alCustom
          Caption = 'Product ID'
        end
        object LProductName: TLabel
          Left = 4
          Top = 60
          Width = 67
          Height = 13
          Caption = 'Product Name'
        end
        object LVersion: TLabel
          Left = 3
          Top = 88
          Width = 60
          Height = 13
          Caption = 'JNX version:'
        end
        object LZOrder: TLabel
          Left = 155
          Top = 84
          Width = 42
          Height = 13
          Caption = 'Z-Order:'
        end
        object EMapName: TEdit
          Left = 96
          Top = 31
          Width = 253
          Height = 21
          Align = alCustom
          TabOrder = 2
        end
        object EProductID: TComboBox
          Left = 96
          Top = 4
          Width = 253
          Height = 21
          Align = alCustom
          AutoDropDown = True
          ItemHeight = 0
          TabOrder = 1
          Items.Strings = (
            '0 - BirdsEye'
            '2 - BirdsEye Select EIRE'
            '3 - BirdsEye Select Deutschland'
            '4 - BirdsEye Select Great Britain'
            '5 - BirdsEye Select France'
            '6 - BirdsEye Select Kompass - Switzerland'
            '7 - BirdsEye Select Kompass - Austria + East Alps'
            '8 - USGS Quads (BirdsEye TOPO, U.S. and Canada)'
            '9 - NRC TopoRama (BirdsEye TOPO, U.S. and Canada)')
        end
        object EProductName: TEdit
          Left = 96
          Top = 57
          Width = 253
          Height = 21
          Align = alCustom
          TabOrder = 3
        end
        object EZorder: TSpinEdit
          Left = 264
          Top = 84
          Width = 85
          Height = 22
          MaxValue = 100
          MinValue = 0
          TabOrder = 5
          Value = 30
        end
        object TreeView1: TTreeView
          Left = 355
          Top = 0
          Width = 118
          Height = 161
          Align = alCustom
          Anchors = [akLeft, akTop, akRight, akBottom]
          HideSelection = False
          HotTrack = True
          Indent = 19
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
        end
        object cbbVersion: TComboBox
          Left = 96
          Top = 84
          Width = 41
          Height = 21
          Style = csDropDownList
          ItemHeight = 0
          ItemIndex = 0
          TabOrder = 4
          Text = '3'
          OnChange = cbbVersionChange
          Items.Strings = (
            '3'
            '4')
        end
        object chkUseRecolor: TCheckBox
          Left = 4
          Top = 112
          Width = 345
          Height = 17
          Align = alCustom
          Caption = 'Use postprocessing settings'
          TabOrder = 6
        end
        object chkUseMapMarks: TCheckBox
          Left = 4
          Top = 135
          Width = 345
          Height = 17
          Align = alCustom
          Caption = 'Add visible placemarks'
          Enabled = False
          TabOrder = 7
        end
      end
    end
  end
  object dlgSaveTargetFile: TSaveDialog
    DefaultExt = 'JNX'
    Filter = 'JNX |*.jnx'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 344
    Top = 200
  end
end

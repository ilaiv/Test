unit i_UseTilePrevZoomConfig;

interface

uses
  i_ConfigDataElement;

type
  IUseTilePrevZoomTileConfigStatic = interface
    function GetUsePrevZoomAtMap: Boolean;
    property UsePrevZoomAtMap: Boolean read GetUsePrevZoomAtMap;

    function GetUsePrevZoomAtLayer: Boolean;
    property UsePrevZoomAtLayer: Boolean read GetUsePrevZoomAtLayer;

    function GetUsePrevZoomAtVectorLayer: Boolean;
    property UsePrevZoomAtVectorLayer: Boolean read GetUsePrevZoomAtVectorLayer;
  end;

  IUseTilePrevZoomConfig = interface(IConfigDataElement)
    ['{FAA51B31-55AA-4F65-AA91-20F8C1174187}']
    function GetUsePrevZoomAtMap: Boolean;
    procedure SetUsePrevZoomAtMap(const AValue: Boolean);
    property UsePrevZoomAtMap: Boolean read GetUsePrevZoomAtMap write SetUsePrevZoomAtMap;

    function GetUsePrevZoomAtLayer: Boolean;
    procedure SetUsePrevZoomAtLayer(const AValue: Boolean);
    property UsePrevZoomAtLayer: Boolean read GetUsePrevZoomAtLayer write SetUsePrevZoomAtLayer;

    function GetUsePrevZoomAtVectorLayer: Boolean;
    procedure SetUsePrevZoomAtVectorLayer(const AValue: Boolean);
    property UsePrevZoomAtVectorLayer: Boolean read GetUsePrevZoomAtVectorLayer write SetUsePrevZoomAtVectorLayer;

    function GetStatic: IUseTilePrevZoomTileConfigStatic;
  end;

implementation

end.

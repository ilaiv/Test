unit u_PathDetalizeProviderBase;

interface

uses
  t_GeoTypes,
  i_NotifierOperation,
  i_InetConfig,
  i_Downloader,
  i_GeometryLonLat,
  i_GeometryLonLatFactory,
  i_PathDetalizeProvider,
  i_DoublePointsAggregator,
  u_BaseInterfacedObject;

type
  TPathDetalizeProviderBase = class(TBaseInterfacedObject, IPathDetalizeProvider)
  protected
    FBaseUrl: AnsiString;
    FDownloader: IDownloader;
    FInetConfig: IInetConfig;
    FVectorGeometryLonLatFactory: IGeometryLonLatFactory;
  protected
    function ProcessSinglePath(
      const ACancelNotifier: INotifierOperation;
      const AOperationID: Integer;
      const ASource: IGeometryLonLatSingleLine;
      const APointsAggregator: IDoublePointsAggregator;
      const ABuilder: IGeometryLonLatLineBuilder
    ): Boolean; virtual; abstract;
    procedure OnBeforeGetPath; virtual;
    procedure OnAfterGetPath; virtual;
  private
    { IPathDetalizeProvider }
    function GetPath(
      const ACancelNotifier: INotifierOperation;
      const AOperationID: Integer;
      const ASource: IGeometryLonLatLine;
      out AComment: string
    ): IGeometryLonLatLine;
  public
    constructor Create(
      const ABaseUrl: AnsiString;
      const ADownloader: IDownloader;
      const AInetConfig: IInetConfig;
      const AVectorGeometryLonLatFactory: IGeometryLonLatFactory
    );
  end;

implementation

uses
  SysUtils,
  u_DoublePointsAggregator,
  u_GeoFunc;

{ TPathDetalizeProviderBase }

constructor TPathDetalizeProviderBase.Create(
  const ABaseUrl: AnsiString;
  const ADownloader: IDownloader;
  const AInetConfig: IInetConfig;
  const AVectorGeometryLonLatFactory: IGeometryLonLatFactory
);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FDownloader := ADownloader;
  FInetConfig := AInetConfig;
  FVectorGeometryLonLatFactory := AVectorGeometryLonLatFactory;
end;

function TPathDetalizeProviderBase.GetPath(
  const ACancelNotifier: INotifierOperation;
  const AOperationID: Integer;
  const ASource: IGeometryLonLatLine;
  out AComment: string
): IGeometryLonLatLine;
var
  I: Integer;
  VIsLineProcessed: Boolean;
  VPointsAggregator: IDoublePointsAggregator;
  VSingleLine: IGeometryLonLatSingleLine;
  VMultiLine: IGeometryLonLatMultiLine;
  VBuilder: IGeometryLonLatLineBuilder;
begin
  Result := nil;
  AComment := '';

  OnBeforeGetPath;
  try
    VIsLineProcessed := False;
    VPointsAggregator := TDoublePointsAggregator.Create;
    VBuilder := FVectorGeometryLonLatFactory.MakeLineBuilder;

    if Supports(ASource, IGeometryLonLatSingleLine, VSingleLine) then begin
      VIsLineProcessed :=
        ProcessSinglePath(
          ACancelNotifier,
          AOperationID,
          VSingleLine,
          VPointsAggregator,
          VBuilder
        );
    end else if Supports(ASource, IGeometryLonLatMultiLine, VMultiLine) then begin
      for I := 0 to VMultiLine.Count - 1 do begin
        if
          ProcessSinglePath(
            ACancelNotifier,
            AOperationID,
            VMultiLine.Item[I],
            VPointsAggregator,
            VBuilder
          )
        then begin
          VIsLineProcessed := True;
          VPointsAggregator.Add(CEmptyDoublePoint);
        end else begin
          Break;
        end;
      end;
    end else begin
      Assert(False);
    end;

    if VIsLineProcessed then begin
      Result := VBuilder.MakeStaticAndClear;
    end;
  finally
    OnAfterGetPath;
  end;
end;

procedure TPathDetalizeProviderBase.OnBeforeGetPath;
begin
  // empty
end;

procedure TPathDetalizeProviderBase.OnAfterGetPath;
begin
  // empty
end;

end.


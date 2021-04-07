{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2014, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.org                                                          *}
{* info@sasgis.org                                                            *}
{******************************************************************************}

unit u_ExportProviderAbstract;

interface

uses
  Controls,
  Forms,
  i_LanguageManager,
  i_GeometryLonLat,
  i_TileIteratorFactory,
  i_RegionProcessTask,
  i_RegionProcessProgressInfo,
  i_RegionProcessProgressInfoInternalFactory,
  i_RegionProcessParamsFrame,
  i_RegionProcessProvider,
  fr_MapSelect,
  u_BaseInterfacedObject;

type
  TExportProviderAbstract = class(TBaseInterfacedObject, IRegionProcessProvider)
  private
    FFrame: TFrame;
    FLanguageManager: ILanguageManager;
    FTileIteratorFactory: ITileIteratorFactory;
    FMapSelectFrameBuilder: IMapSelectFrameBuilder;
    FProgressFactory: IRegionProcessProgressInfoInternalFactory;
    function GetParamsFrame: IRegionProcessParamsFrameBase;
    function GetTileIteratorFactory: ITileIteratorFactory;
  protected
    function GetCaption: string; virtual; abstract;
    procedure Show(
      AParent: TWinControl;
      AZoom: byte;
      const APolygon: IGeometryLonLatPolygon
    );
    procedure Hide;
    function Validate(
      const APolygon: IGeometryLonLatPolygon
    ): Boolean; virtual;
    procedure StartProcess(
      const APolygon: IGeometryLonLatPolygon
    ); virtual; abstract;
  protected
    function CreateFrame: TFrame; virtual; abstract;
    property ParamsFrame: IRegionProcessParamsFrameBase read GetParamsFrame;
    property ProgressFactory: IRegionProcessProgressInfoInternalFactory read FProgressFactory;
    property TileIteratorFactory: ITileIteratorFactory read GetTileIteratorFactory;
    property LanguageManager: ILanguageManager read FLanguageManager;
    property MapSelectFrameBuilder: IMapSelectFrameBuilder read FMapSelectFrameBuilder;
  public
    constructor Create(
      const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
      const ALanguageManager: ILanguageManager;
      const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
      const ATileIteratorFactory: ITileIteratorFactory
    );
    destructor Destroy; override;
  end;

  TExportProviderBase = class(TExportProviderAbstract)
  protected
    function PrepareTask(
      const APolygon: IGeometryLonLatPolygon;
      const AProgressInfo: IRegionProcessProgressInfoInternal
    ): IRegionProcessTask; virtual; abstract;
    procedure StartProcess(
      const APolygon: IGeometryLonLatPolygon
    ); override;
  end;

implementation

uses
  SysUtils,
  u_RegionProcessWorker;

{ TExportProviderAbstract }

constructor TExportProviderAbstract.Create(
  const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const ATileIteratorFactory: ITileIteratorFactory
);
begin
  Assert(Assigned(AProgressFactory));
  Assert(Assigned(ALanguageManager));
  Assert(Assigned(AMapSelectFrameBuilder));
  //ATileIteratorFactory can be nil here

  inherited Create;

  FProgressFactory := AProgressFactory;
  FLanguageManager := ALanguageManager;
  FMapSelectFrameBuilder := AMapSelectFrameBuilder;
  FTileIteratorFactory := ATileIteratorFactory;
end;

destructor TExportProviderAbstract.Destroy;
begin
  FreeAndNil(FFrame);
  inherited;
end;

function TExportProviderAbstract.GetParamsFrame: IRegionProcessParamsFrameBase;
begin
  if not Supports(FFrame, IRegionProcessParamsFrameBase, Result) then begin
    Result := nil;
  end;
end;

function TExportProviderAbstract.GetTileIteratorFactory: ITileIteratorFactory;
begin
  Result := FTileIteratorFactory;
  Assert(Result <> nil);
end;

procedure TExportProviderAbstract.Hide;
begin
  if FFrame <> nil then begin
    if FFrame.Visible then begin
      FFrame.Hide;
    end;
  end;
end;

procedure TExportProviderAbstract.Show(
  AParent: TWinControl;
  AZoom: byte;
  const APolygon: IGeometryLonLatPolygon
);
var
  VFrame: IRegionProcessParamsFrameBase;
begin
  if FFrame = nil then begin
    FFrame := CreateFrame;
    Assert(Supports(FFrame, IRegionProcessParamsFrameBase));
  end;
  if FFrame <> nil then begin
    FFrame.Parent := AParent;
    if not FFrame.Visible then begin
      FFrame.Show;
    end;
    VFrame := ParamsFrame;
    if VFrame <> nil then begin
      VFrame.Init(AZoom, APolygon);
    end;
  end;
end;

function TExportProviderAbstract.Validate(
  const APolygon: IGeometryLonLatPolygon
): Boolean;
begin
  Result := GetParamsFrame.Validate;
end;

{ TExportProviderBase }

procedure TExportProviderBase.StartProcess(
  const APolygon: IGeometryLonLatPolygon
);
var
  VProgressInfo: IRegionProcessProgressInfoInternal;
  VTask: IRegionProcessTask;
  VThread: TRegionProcessWorker;
begin
  VProgressInfo := ProgressFactory.Build(APolygon);

  VTask := PrepareTask(APolygon, VProgressInfo);
  if Assigned(VTask) then begin
    VThread :=
      TRegionProcessWorker.Create(
        VTask,
        VProgressInfo,
        ClassName
      );
    VThread.Start;
  end;
end;

end.

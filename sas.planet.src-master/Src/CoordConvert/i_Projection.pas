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

unit i_Projection;

interface

uses
  Types,
  t_Hash,
  t_GeoTypes,
  i_ProjectionType;

type
  IProjection = interface
    ['{1BAC7D2B-21F1-4DA7-AE3B-F9D91548E440}']
    function GetHash: THashValue;
    property Hash: THashValue read GetHash;

    function GetZoom: Byte;
    property Zoom: Byte read GetZoom;

    function GetProjectionType: IProjectionType;
    property ProjectionType: IProjectionType read GetProjectionType;

    function IsSame(const AProjection: IProjection): Boolean;

    // ���������� ������������� ������ ���������� � �������� ����
    function GetTileRect: TRect;
    // ���������� ������������� �������� ���������� � �������� ����
    function GetPixelRect: TRect;

    // ���������� ����� ���������� �������� �� �������� ����
    function GetPixelsFloat: Double;

    // ���������� ��� ���� ������� �� ����� (�� �������, ����� �������� ������������ ������ ������)
    function GetTileSplitCode: Integer;

    // ����������� ���������� ������� � ������������� ���������� �� ����� (x/PixelsAtZoom)
    function PixelPos2Relative(
      const APoint: TPoint
    ): TDoublePoint;
    // ����������� ���������� ������� � �������������� ����������
    function PixelPos2LonLat(
      const APoint: TPoint
    ): TDoublePoint;
    function PixelPos2TilePosFloat(
      const APoint: TPoint
    ): TDoublePoint;

    function PixelPosFloat2TilePosFloat(
      const APoint: TDoublePoint
    ): TDoublePoint;
    function PixelPosFloat2Relative(
      const APoint: TDoublePoint
    ): TDoublePoint;
    function PixelPosFloat2LonLat(
      const APoint: TDoublePoint
    ): TDoublePoint;

    // ��������� ������������� ������ ����������� ������������� ��������
    function PixelRect2TileRect(
      const ARect: TRect
    ): TRect;
    // ����������� ���������� �������������� �������� � ������������� ���������� �� ����� (x/PixelsAtZoom)
    function PixelRect2RelativeRect(
      const ARect: TRect
    ): TDoubleRect;
    // ����������� ���������� �������������� �������� � �������������� ���������� �� �����
    function PixelRect2LonLatRect(
      const ARect: TRect
    ): TDoubleRect;
    function PixelRect2TileRectFloat(
      const ARect: TRect
    ): TDoubleRect;

    function PixelRectFloat2TileRectFloat(
      const ARect: TDoubleRect
    ): TDoubleRect;
    function PixelRectFloat2RelativeRect(
      const ARect: TDoubleRect
    ): TDoubleRect;
    function PixelRectFloat2LonLatRect(
      const ARect: TDoubleRect
    ): TDoubleRect;

    // ����������� ������� ����� ��������� ���� � ���������� ������� ��� ������ �������� ����
    function TilePos2PixelPos(
      const APoint: TPoint
    ): TPoint;
    // ����������� ������� ����� ��������� ���� � ������ �������� ��� ����� �� �������� ����
    function TilePos2PixelRect(
      const APoint: TPoint
    ): TRect;
    function TilePos2PixelRectFloat(
      const APoint: TPoint
    ): TDoubleRect;
    // ����������� ���������� ����� � ������������� ���������� �� ����� (x/PixelsAtZoom)
    function TilePos2Relative(
      const APoint: TPoint
    ): TDoublePoint;
    // ����������� ������� ����� ��������� ���� � ������ �������� ��� ����� �� �������� ����
    function TilePos2RelativeRect(
      const APoint: TPoint
    ): TDoubleRect;
    // ����������� ���������� ����� � �������������� ����������
    function TilePos2LonLat(
      const APoint: TPoint
    ): TDoublePoint;
    // ����������� ������� ����� ��������� ���� � �������������� ���������� ��� �����
    function TilePos2LonLatRect(
      const APoint: TPoint
    ): TDoubleRect;

    function TilePosFloat2PixelPosFloat(
      const APoint: TDoublePoint
    ): TDoublePoint;
    function TilePosFloat2Relative(
      const APoint: TDoublePoint
    ): TDoublePoint;
    function TilePosFloat2LonLat(
      const APoint: TDoublePoint
    ): TDoublePoint;

    // ��������� ��������� �������� ������ �������������� ������
    function TileRect2PixelRect(
      const ARect: TRect
    ): TRect;
    // ��������� ������������� ��������� ������ �������������� ������
    function TileRect2RelativeRect(
      const ARect: TRect
    ): TDoubleRect;
    // ����������� ������������� ������ ��������� ���� � �������������� ���������� ��� �����
    function TileRect2LonLatRect(
      const ARect: TRect
    ): TDoubleRect;

    function TileRectFloat2PixelRectFloat(
      const ARect: TDoubleRect
    ): TDoubleRect;
    function TileRectFloat2RelativeRect(
      const ARect: TDoubleRect
    ): TDoubleRect;
    function TileRectFloat2LonLatRect(
      const ARect: TDoubleRect
    ): TDoubleRect;

    // ����������� ������������� ���������� �� ����� � ���������� �������
    function Relative2PixelPosFloat(
      const APoint: TDoublePoint
    ): TDoublePoint;
    // ����������� ������������� ���������� �� ����� � ���������� �����
    function Relative2TilePosFloat(
      const APoint: TDoublePoint
    ): TDoublePoint;

    // ����������� ������������� � �������������� ������������ � ������������� ��������
    function RelativeRect2PixelRectFloat(
      const ARect: TDoubleRect
    ): TDoubleRect;
    // ����������� ������������� � �������������� ������������ � ������������� ������
    function RelativeRect2TileRectFloat(
      const ARect: TDoubleRect
    ): TDoubleRect;

    // ����������� ������������� ���������� � ���������� ������� �� �������� ���� ������������ ������ ����������
    function LonLat2PixelPosFloat(
      const APoint: TDoublePoint
    ): TDoublePoint;
    // ����������� ������������� ���������� � ������� ����� �� �������� ���� ������������ ������ ����������
    function LonLat2TilePosFloat(
      const APoint: TDoublePoint
    ): TDoublePoint;

    function LonLatRect2PixelRectFloat(
      const ARect: TDoubleRect
    ): TDoubleRect;
    function LonLatRect2TileRectFloat(
      const ARect: TDoubleRect
    ): TDoubleRect;

    function GetTileSize(
      const APoint: TPoint
    ): TPoint;

    procedure ValidateTilePos(
      var APoint: TPoint;
      ACicleMap: Boolean
    );
    procedure ValidateTilePosStrict(
      var APoint: TPoint;
      ACicleMap: Boolean
    );
    procedure ValidateTileRect(
      var ARect: TRect
    );

    procedure ValidatePixelPos(
      var APoint: TPoint;
      ACicleMap: Boolean
    );
    procedure ValidatePixelPosFloat(
      var APoint: TDoublePoint;
      ACicleMap: Boolean
    );
    procedure ValidatePixelPosStrict(
      var APoint: TPoint;
      ACicleMap: Boolean
    );
    procedure ValidatePixelPosFloatStrict(
      var APoint: TDoublePoint;
      ACicleMap: Boolean
    );
    procedure ValidatePixelRect(
      var ARect: TRect
    );
    procedure ValidatePixelRectFloat(
      var ARect: TDoubleRect
    );

    function CheckTilePos(
      const APoint: TPoint
    ): boolean;
    function CheckTilePosStrict(
      const APoint: TPoint
    ): boolean;
    function CheckTileRect(
      const ARect: TRect
    ): boolean;

    function CheckPixelPos(
      const APoint: TPoint
    ): boolean;
    function CheckPixelPosFloat(
      const APoint: TDoublePoint
    ): boolean;
    function CheckPixelPosStrict(
      const APoint: TPoint
    ): boolean;
    function CheckPixelPosFloatStrict(
      const APoint: TDoublePoint
    ): boolean;
    function CheckPixelRect(
      const ARect: TRect
    ): boolean;
    function CheckPixelRectFloat(
      const ARect: TDoubleRect
    ): boolean;

  end;

implementation

end.

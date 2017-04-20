unit HelperSets;
//---------------------------------------------------------------------------
// HelperSets.pas                                       Modified: 20-Feb-2007
// Helper classes to aid the development of application logic     Version 1.0
//---------------------------------------------------------------------------
// Important Notice:
//
// If you modify/use this code or one of its parts either in original or
// modified form, you must comply with Mozilla Public License v1.1,
// specifically section 3, "Distribution Obligations". Failure to do so will
// result in the license breach, which will be resolved in the court.
// Remember that violating author's rights is considered a serious crime in
// many countries. Thank you!
//
// !! Please *read* Mozilla Public License 1.1 document located at:
//  http://www.mozilla.org/MPL/
//
// If you require any clarifications about the license, feel free to contact
// us or post your question on our forums at: http://www.afterwarp.net
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//
// The Original Code is HelperSets.pas.
//
// The Initial Developer of the Original Code is M. Sc. Yuriy Kotsarenko.
// Portions created by M. Sc. Yuriy Kotsarenko are Copyright (C) 2007,
// Afterwarp Interactive. All Rights Reserved.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Math, Vectors2px, AsphyreUtils;

//---------------------------------------------------------------------------
type
 PPointHolder = ^TPointHolder;
 TPointHolder = record
  Point: TPoint2px;
  Data : Pointer;
 end;

//---------------------------------------------------------------------------
 TIntegerList = class
 private
  Data: array of Integer;
  DataCount: Integer;

  function GetItem(Num: Integer): Integer;
  procedure SetItem(Num: Integer; const Value: Integer);
  procedure Request(Amount: Integer);
  function GetMemAddr(): Pointer;
  function GetIntAvg(): Integer;
  function GetIntSum(): Integer;
  function GetIntMax(): Integer;
  function GetIntMin(): Integer; public
  property MemAddr: Pointer read GetMemAddr;
  property Count: Integer read DataCount;
  property Items[Num: Integer]: Integer read GetItem write SetItem; default;

  property IntSum: Integer read GetIntSum;
  property IntAvg: Integer read GetIntAvg;
  property IntMax: Integer read GetIntMax;
  property IntMin: Integer read GetIntMin;

  function IndexOf(Value: Integer): Integer;
  function Insert(Value: Integer): Integer; overload;
  procedure Remove(Index: Integer);
  procedure Clear();

  procedure CopyFrom(Source: TIntegerList);
  procedure AddFrom(Source: TIntegerList);

  procedure Include(Value: Integer);
  procedure Exclude(Value: Integer);
  function Exists(Value: Integer): Boolean;
  procedure Serie(Count: Integer);
  procedure Shuffle();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TPointList = class
 private
  Data: array of TPointHolder;
  DataCount: Integer;

  function GetItem(Num: Integer): PPointHolder;
  procedure Request(Amount: Integer);
  function GetMemAddr(): Pointer;
  function GetPoint(Num: Integer): PPoint2px;
 public
  property MemAddr: Pointer read GetMemAddr;
  property Count: Integer read DataCount;

  property Item[Num: Integer]: PPointHolder read GetItem; default;
  property Point[Num: Integer]: PPoint2px read GetPoint;

  function Insert(const Point: TPoint2px; Data: Pointer = nil): Integer; overload;
  function Insert(x, y: Integer; Data: Pointer = nil): Integer; overload;
  procedure Remove(Index: Integer);
  procedure Clear();
  function IndexOf(const Point: TPoint2px): Integer;
  procedure Include(const Point: TPoint2px; Data: Pointer = nil);
  procedure Exclude(const Point: TPoint2px);

  procedure CopyFrom(Source: TPointList);
  procedure AddFrom(Source: TPointList);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TRectList = class
 private
  Data: array of TRect;
  DataCount: Integer;

  function GetItem(Num: Integer): PRect;
  procedure Request(Amount: Integer);
  function GetMemAddr(): Pointer;
 public
  property MemAddr: Pointer read GetMemAddr;
  property Count: Integer read DataCount;
  property Item[Num: Integer]: PRect read GetItem; default;

  function Add(const Rect: TRect): Integer; overload;
  function Add(x, y, Width, Height: Integer): Integer; overload;
  procedure Remove(Index: Integer);
  procedure Clear();

  procedure CopyFrom(Source: TRectList);
  procedure AddFrom(Source: TRectList);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 CacheSize = 32;

//---------------------------------------------------------------------------
constructor TIntegerList.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TIntegerList.Destroy();
begin
 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TIntegerList.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TIntegerList.GetItem(Num: Integer): Integer;
begin
 if (Num >= 0)and(Num < DataCount) then Result:= Data[Num]
  else Result:= Low(Integer);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.SetItem(Num: Integer; const Value: Integer);
begin
 if (Num >= 0)and(Num < DataCount) then
  Data[Num]:= Value;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TIntegerList.Insert(Value: Integer): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Value;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Clear();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.CopyFrom(Source: TIntegerList);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.AddFrom(Source: TIntegerList);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
function TIntegerList.IndexOf(Value: Integer): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to DataCount - 1 do
  if (Data[i] = Value) then
   begin
    Result:= i;
    Exit;
   end;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Include(Value: Integer);
begin
 if (IndexOf(Value) = -1) then Insert(Value);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Exclude(Value: Integer);
var
 Index: Integer;
begin
 Index:= IndexOf(Value);
 if (Index <> -1) then Remove(Index);
end;

//---------------------------------------------------------------------------
function TIntegerList.Exists(Value: Integer): Boolean;
begin
 Result:= (IndexOf(Value) <> -1);
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Shuffle();
var
 i, Aux, Indx: Integer;
begin
 for i:= DataCount - 1 downto 1 do
  begin
   Indx:= Random(i);

   Aux:= Data[i];
   Data[i]:= Data[Indx];
   Data[Indx]:= Aux;
  end;
end;

//---------------------------------------------------------------------------
procedure TIntegerList.Serie(Count: Integer);
var
 i: Integer;
begin
 Request(Count);
 DataCount:= Count;

 for i:= 0 to DataCount - 1 do
  Data[i]:= i;
end;


//---------------------------------------------------------------------------
function TIntegerList.GetIntSum(): Integer;
var
 i: Integer;
begin
 Result:= 0;
 for i:= 0 to DataCount - 1 do
  Inc(Result, Data[i]);
end;

//---------------------------------------------------------------------------
function TIntegerList.GetIntAvg(): Integer;
begin
 if (DataCount > 0) then
  Result:= GetIntSum() div DataCount
   else Result:= 0;
end;

//---------------------------------------------------------------------------
function TIntegerList.GetIntMax(): Integer;
var
 i: Integer;
begin
 if (DataCount < 1) then
  begin
   Result:= 0;
   Exit;
  end;

 Result:= Data[0];
 for i:= 1 to DataCount - 1 do
  Result:= Max2(Result, Data[i]);
end;

//---------------------------------------------------------------------------
function TIntegerList.GetIntMin(): Integer;
var
 i: Integer;
begin
 if (DataCount < 1) then
  begin
   Result:= 0;
   Exit;
  end;

 Result:= Data[0];
 for i:= 1 to Length(Data) - 1 do
  Result:= Min2(Result, Data[i]);
end;

//---------------------------------------------------------------------------
constructor TPointList.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TPointList.Destroy();
begin
 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TPointList.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TPointList.GetItem(Num: Integer): PPointHolder;
begin
 if (Num >= 0)and(Num < DataCount) then Result:= @Data[Num]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
function TPointList.GetPoint(Num: Integer): PPoint2px;
begin
 if (Num >= 0)and(Num < DataCount) then Result:= @Data[Num].Point
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TPointList.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TPointList.Insert(const Point: TPoint2px;
 Data: Pointer = nil): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Self.Data[Index].Point:= Point;
 Self.Data[Index].Data := Data;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPointList.Insert(x, y: Integer; Data: Pointer = nil): Integer;
begin
 Result:= Insert(Point2px(x, y), Data);
end;

//---------------------------------------------------------------------------
procedure TPointList.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
function TPointList.IndexOf(const Point: TPoint2px): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to DataCount - 1 do
  if (Data[i].Point = Point) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TPointList.Include(const Point: TPoint2px; Data: Pointer = nil);
begin
 if (IndexOf(Point) = -1) then Insert(Point, Data);
end;

//---------------------------------------------------------------------------
procedure TPointList.Exclude(const Point: TPoint2px);
begin
 Remove(IndexOf(Point));
end;

//---------------------------------------------------------------------------
procedure TPointList.Clear();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TPointList.CopyFrom(Source: TPointList);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TPointList.AddFrom(Source: TPointList);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
constructor TRectList.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TRectList.Destroy();
begin
 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TRectList.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TRectList.GetItem(Num: Integer): PRect;
begin
 if (Num >= 0)and(Num < DataCount) then Result:= @Data[Num]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TRectList.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TRectList.Add(const Rect: TRect): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Rect;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TRectList.Add(x, y, Width, Height: Integer): Integer;
begin
 Result:= Add(Bounds(x, y, Width, Height));
end;

//---------------------------------------------------------------------------
procedure TRectList.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TRectList.Clear();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TRectList.CopyFrom(Source: TRectList);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TRectList.AddFrom(Source: TRectList);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
end.

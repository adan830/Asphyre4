unit Vectors2;
//---------------------------------------------------------------------------
// Vectors2.pas                                         Modified: 02-Feb-2007
// Definitions and functions working with 2D vectors              Version 1.0
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
// The Original Code is Vectors2.pas.
//
// The Initial Developer of the Original Code is M. Sc. Yuriy Kotsarenko.
// Portions created by M. Sc. Yuriy Kotsarenko are Copyright (C) 2007,
// Afterwarp Interactive. All Rights Reserved.
//---------------------------------------------------------------------------

interface

//---------------------------------------------------------------------------
uses
 Types, Classes, Math, Vectors2px;

//---------------------------------------------------------------------------
type
 PPoint2 = ^TPoint2;
 TPoint2 = record
  x, y: Single;

  class operator Add(const a, b: TPoint2): TPoint2;
  class operator Subtract(const a, b: TPoint2): TPoint2;
  class operator Multiply(const a, b: TPoint2): TPoint2;
  class operator Divide(const a, b: TPoint2): TPoint2;

  class operator Negative(const v: TPoint2): TPoint2;
  class operator Multiply(const v: TPoint2; const k: Single): TPoint2;
  class operator Multiply(const v: TPoint2; const k: Integer): TPoint2;
  class operator Divide(const v: TPoint2; const k: Single): TPoint2;
  class operator Divide(const v: TPoint2; const k: Integer): TPoint2;
  class operator Implicit(const Point: TPoint): TPoint2;
  class operator Implicit(const Point: TPoint2): TPoint;
  class operator Explicit(const Point: TPoint): TPoint2;
  class operator Explicit(const Point: TPoint2): TPoint;

  class operator Implicit(const Point: TPoint2px): TPoint2;
  class operator Implicit(const Point: TPoint2): TPoint2px;
  class operator Explicit(const Point: TPoint2px): TPoint2;
  class operator Explicit(const Point: TPoint2): TPoint2px;
 end;

//---------------------------------------------------------------------------
 TPoints2 = class
 private
  Data: array of TPoint2;
  DataCount: Integer;

  function GetItem(Num: Integer): PPoint2;
  procedure Request(Amount: Integer);
  function GetMemAddr(): Pointer;
 public
  property MemAddr: Pointer read GetMemAddr;
  property Count: Integer read DataCount;
  property Item[Num: Integer]: PPoint2 read GetItem; default;

  function Add(const Point: TPoint2): Integer; overload;
  function Add(x, y: Single): Integer; overload;
  procedure Remove(Index: Integer);
  procedure RemoveAll();

  procedure CopyFrom(Source: TPoints2);
  procedure AddFrom(Source: TPoints2);

  procedure SaveToStream(Stream: TStream);
  procedure LoadFromStream(Stream: TStream);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
const
 ZeroVec2 : TPoint2 = (x: 0.0; y: 0.0);
 UnityVec2: TPoint2 = (x: 1.0; y: 1.0);

//---------------------------------------------------------------------------
function Point2(x, y: Single): TPoint2;
function Length2(const v: TPoint2): Single;
function Norm2(const v: TPoint2): TPoint2;
function Angle2(const v: TPoint2): Single;
function Lerp2(const v0, v1: TPoint2; Alpha: Single): TPoint2;
function Dot2(const a, b: TPoint2): Single;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 CacheSize = 512;

//---------------------------------------------------------------------------
class operator TPoint2.Add(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x + b.x;
 Result.y:= a.y + b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Subtract(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x - b.x;
 Result.y:= a.y - b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Multiply(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x * b.x;
 Result.y:= a.y * b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Divide(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x / b.x;
 Result.y:= a.y / b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Negative(const v: TPoint2): TPoint2;
begin
 Result.x:= -v.x;
 Result.y:= -v.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Multiply(const v: TPoint2;
 const k: Single): TPoint2;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Multiply(const v: TPoint2; const k: Integer): TPoint2;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Divide(const v: TPoint2;
 const k: Single): TPoint2;
begin
 Result.x:= v.x / k;
 Result.y:= v.y / k;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Divide(const v: TPoint2; const k: Integer): TPoint2;
begin
 Result.x:= v.x / k;
 Result.y:= v.y / k;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Implicit(const Point: TPoint): TPoint2;
begin
 Result.x:= Point.X;
 Result.y:= Point.Y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Implicit(const Point: TPoint2): TPoint;
begin
 Result.X:= Round(Point.x);
 Result.Y:= Round(Point.y);
end;

//---------------------------------------------------------------------------
class operator TPoint2.Explicit(const Point: TPoint): TPoint2;
begin
 Result.x:= Point.X;
 Result.y:= Point.Y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Explicit(const Point: TPoint2): TPoint;
begin
 Result.X:= Round(Point.x);
 Result.Y:= Round(Point.y);
end;

//---------------------------------------------------------------------------
class operator TPoint2.Implicit(const Point: TPoint2px): TPoint2;
begin
 Result.x:= Point.X;
 Result.y:= Point.Y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Implicit(const Point: TPoint2): TPoint2px;
begin
 Result.X:= Round(Point.x);
 Result.Y:= Round(Point.y);
end;

//---------------------------------------------------------------------------
class operator TPoint2.Explicit(const Point: TPoint2px): TPoint2;
begin
 Result.x:= Point.X;
 Result.y:= Point.Y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Explicit(const Point: TPoint2): TPoint2px;
begin
 Result.X:= Round(Point.x);
 Result.Y:= Round(Point.y);
end;

//---------------------------------------------------------------------------
function Length2(const v: TPoint2): Single;
begin
 Result:= Hypot(v.x, v.y);
end;

//---------------------------------------------------------------------------
function Norm2(const v: TPoint2): TPoint2;
var
 Amp: Single;
begin
 Amp:= Length2(v);

 if (Amp <> 0.0) then
  begin
   Result.x:= v.x / Amp;
   Result.y:= v.y / Amp;
  end else Result:= ZeroVec2;
end;

//---------------------------------------------------------------------------
function Point2(x, y: Single): TPoint2;
begin
 Result.x:= x;
 Result.y:= y;
end;

//---------------------------------------------------------------------------
function Angle2(const v: TPoint2): Single;
begin
 Result:= ArcTan2(v.y, v.x);
end;

//---------------------------------------------------------------------------
function Lerp2(const v0, v1: TPoint2; Alpha: Single): TPoint2;
begin
 Result.x:= v0.x + (v1.x - v0.x) * Alpha;
 Result.y:= v0.y + (v1.y - v0.y) * Alpha;
end;

//---------------------------------------------------------------------------
function Dot2(const a, b: TPoint2): Single;
begin
 Result:= (a.x * b.x) + (a.y * b.y);
end;

//---------------------------------------------------------------------------
constructor TPoints2.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TPoints2.Destroy();
begin
 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TPoints2.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TPoints2.GetItem(Num: Integer): PPoint2;
begin
 if (Num >= 0)and(Num < DataCount) then Result:= @Data[Num]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TPoints2.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TPoints2.Add(const Point: TPoint2): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Point;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPoints2.Add(x, y: Single): Integer;
begin
 Result:= Add(Point2(x, y));
end;

//---------------------------------------------------------------------------
procedure TPoints2.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TPoints2.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TPoints2.CopyFrom(Source: TPoints2);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TPoints2.AddFrom(Source: TPoints2);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
procedure TPoints2.SaveToStream(Stream: TStream);
begin
 Stream.WriteBuffer(DataCount, SizeOf(Integer));
 Stream.WriteBuffer(Data[0], DataCount * SizeOf(TPoint2));
end;

//---------------------------------------------------------------------------
procedure TPoints2.LoadFromStream(Stream: TStream);
begin
 Stream.ReadBuffer(DataCount, SizeOf(Integer));

 Request(DataCount);
 Stream.ReadBuffer(Data[0], DataCount * SizeOf(TPoint2));
end;

//---------------------------------------------------------------------------
end.

unit Matrices4;
//---------------------------------------------------------------------------
// Matrices4.pas                                        Modified: 02-Apr-2007
// Definitions and functions working with 3D 4x4 matrices         Version 1.0
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
// The Original Code is Matrices4.pas.
//
// The Initial Developer of the Original Code is M. Sc. Yuriy Kotsarenko.
// Portions created by M. Sc. Yuriy Kotsarenko are Copyright (C) 2007,
// M. Sc. Yuriy Kotsarenko. All Rights Reserved.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
// Enable the following option to take advantage of mathematical routines
// from D3DX interface.
//---------------------------------------------------------------------------
{.$define SupportD3DX}

//---------------------------------------------------------------------------
uses
 {$ifdef SupportD3DX}
   {$IFDEF AsphyreUseDx8}
    D3DX8,
   {$ELSE}
    D3DX9,
   {$ENDIF}
 {$endif}
 SysUtils, Math, Vectors3;

//---------------------------------------------------------------------------
type
 PMatrix4 = ^TMatrix4;
 TMatrix4 = record
  Data: array[0..3, 0..3] of Single;

  class operator Add(const a, b: TMatrix4): TMatrix4;
  class operator Subtract(const a, b: TMatrix4): TMatrix4;
  class operator Multiply(const a, b: TMatrix4): TMatrix4;
  class operator Multiply(const Mtx: TMatrix4; Theta: Single): TMatrix4;
  class operator Multiply(const v: TVector3; const m: TMatrix4): TVector3;
  class operator Divide(const Mtx: TMatrix4; Theta: Single): TMatrix4;

  function GetPos(): TVector3;
 end;

//---------------------------------------------------------------------------
const
 IdentityMtx4: TMatrix4 = (Data: ((1.0, 0.0, 0.0, 0.0), (0.0, 1.0, 0.0, 0.0),
  (0.0, 0.0, 1.0, 0.0), (0.0, 0.0, 0.0, 1.0)));

 ZeroMtx4: TMatrix4 = (Data: ((0.0, 0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 0.0),
  (0.0, 0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 0.0)));

//---------------------------------------------------------------------------
// Matrix Transposition
//---------------------------------------------------------------------------
function TransposeMtx4(const Mtx: TMatrix4): TMatrix4;

//---------------------------------------------------------------------------
// Inverse of the Matrix
//---------------------------------------------------------------------------
function InvertMtx4(const m: TMatrix4): TMatrix4;

//---------------------------------------------------------------------------
// Translation Matrix
//---------------------------------------------------------------------------
function TranslateMtx4(const Offset: TVector3): TMatrix4;

//---------------------------------------------------------------------------
// Scaling Matrix
//---------------------------------------------------------------------------
function ScaleMtx4(const Coef: TVector3): TMatrix4;

//---------------------------------------------------------------------------
// String Representation of Matrix
//---------------------------------------------------------------------------
function StringMtx4(const m: TMatrix4): string;

//---------------------------------------------------------------------------
// Rotation Matrix around X-axis
//---------------------------------------------------------------------------
function RotateXMtx4(Angle: Single): TMatrix4;

//---------------------------------------------------------------------------
// Rotation Matrix around Y-axis
//---------------------------------------------------------------------------
function RotateYMtx4(Angle: Single): TMatrix4;

//---------------------------------------------------------------------------
// Rotation Matrix around Z-axis
//---------------------------------------------------------------------------
function RotateZMtx4(Angle: Single): TMatrix4;

//---------------------------------------------------------------------------
// Rotation Matrix around an arbitrary axis
//---------------------------------------------------------------------------
function RotateMtx4(const Axis: TVector3; Angle: Single): TMatrix4;

//---------------------------------------------------------------------------
// Reflection Matrix
//---------------------------------------------------------------------------
function ReflectMtx4(const Axis: TVector3): TMatrix4;

//---------------------------------------------------------------------------
// Look at given point Matrix (left-handed coordinates)
//---------------------------------------------------------------------------
function LookAtMtx4(const Origin, Target, Roof: TVector3): TMatrix4;

//---------------------------------------------------------------------------
// Perspective Projection with Field of View in Y-axis
//---------------------------------------------------------------------------
function PerspectiveFOVYMtx4(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
// Perspective Projection with Field of View in X-axis
//---------------------------------------------------------------------------
function PerspectiveFOVXMtx4(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
// Perspective Projection with View Volume
//---------------------------------------------------------------------------
function PerspectiveVOLMtx4(Width, Height, MinRange, MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
// Perspective Projection with Axis Boundaries
//---------------------------------------------------------------------------
function PerspectiveBDSMtx4(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
// Orthogonal Projection with View Volume
//---------------------------------------------------------------------------
function OrthogonalVOLMtx4(Width, Height, MinRange, MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
// Orthogonal Projection with Axis Boundaries
//---------------------------------------------------------------------------
function OrthogonalBDSMtx4(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
// Euler rotation matrix with respective heading, pitch and bank.
//---------------------------------------------------------------------------
function HeadingPitchBankMtx4(Heading, Pitch,
 Bank: Single): TMatrix4; overload;
function HeadingPitchBankMtx4(const v: TVector3): TMatrix4; overload;

//---------------------------------------------------------------------------
{$ifdef SupportD3DX}
function YawPitchRollMtx4(Yaw, Pitch, Roll: Single): TMatrix4; overload;
function YawPitchRollMtx4(const v: TVector3): TMatrix4; overload;
{$endif}

//---------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
type
 PLMatrix4 = ^TLMatrix4;
 TLMatrix4 = array[0..15] of Single;

//---------------------------------------------------------------------------
function TMatrix4.GetPos(): TVector3;
var
 View: PLMatrix4;
begin
 View:= @Data[0, 0];

 Result.x:= -View[0] * View[12] - View[1] * View[13] - View[2] * View[14];
 Result.y:= -View[4] * View[12] - View[5] * View[13] - View[6] * View[14];
 Result.z:= -View[8] * View[12] - View[9] * View[13] - View[10] * View[14];
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Add(const a, b: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= a.Data[j, i] + b.Data[j, i];
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Subtract(const a, b: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= a.Data[j, i] - b.Data[j, i];
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Multiply(const a, b: TMatrix4): TMatrix4;
{$ifndef SupportD3DX}
var
 i, j: Integer;
{$endif}
begin
 {$ifdef SupportD3DX}
 D3DXMatrixMultiply(TD3DXMatrix(Result), TD3DXMatrix(a), TD3DXMatrix(b));
 {$else}
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= (a.Data[j, 0] * b.Data[0, i]) +
    (a.Data[j, 1] * b.Data[1, i]) +
    (a.Data[j, 2] * b.Data[2, i]) +
    (a.Data[j, 3] * b.Data[3, i]);
 {$endif}   
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Multiply(const Mtx: TMatrix4; Theta: Single): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= Mtx.Data[j, i] * Theta;
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Divide(const Mtx: TMatrix4; Theta: Single): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= Mtx.Data[j, i] / Theta;
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Multiply(const v: TVector3;
 const m: TMatrix4): TVector3;
begin
 Result.x:= (v.x * m.Data[0, 0]) + (v.y * m.Data[1, 0]) +
  (v.z * m.Data[2, 0]) + (1.0 * m.Data[3, 0]);
 Result.y:= (v.x * m.Data[0, 1]) + (v.y * m.Data[1, 1]) +
  (v.z * m.Data[2, 1]) + (1.0 * m.Data[3, 1]);
 Result.z:= (v.x * m.Data[0, 2]) + (v.y * m.Data[1, 2]) +
 (v.z * m.Data[2, 2]) + (1.0 * m.Data[3, 2]);
end;

//---------------------------------------------------------------------------
function StringMtx4(const m: TMatrix4): string;
var
 s: string;
 i, j: Integer;
begin
 s:= '{';
 for i:= 0 to 3 do
  begin
   s:= s + '(';
   for j:= 0 to 3 do
    begin
     s:= s + Format('%1.2f', [m.Data[i, j]]);
     if (j < 3) then s:= s + ', ';
    end;
   s:= s + ')';
   if (i < 3) then s:= s + #13#10;
  end;
 Result:= s + '}';
end;

//--------------------------------------------------------------------------
function TransposeMtx4(const Mtx: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for i:= 0 to 3 do
  for j:= 0 to 3 do
   Result.Data[i, j]:= Mtx.Data[j, i];
end;

//---------------------------------------------------------------------------
function TranslateMtx4(const Offset: TVector3): TMatrix4;
begin
 Result:= IdentityMtx4;
 Result.Data[3, 0]:= Offset.x;
 Result.Data[3, 1]:= Offset.y;
 Result.Data[3, 2]:= Offset.z;
end;

//--------------------------------------------------------------------------
function ScaleMtx4(const Coef: TVector3): TMatrix4;
begin
 Result:= IdentityMtx4;
 Result.Data[0, 0]:= Coef.x;
 Result.Data[1, 1]:= Coef.y;
 Result.Data[2, 2]:= Coef.z;
end;

//---------------------------------------------------------------------------
function DetMtx3(a1, a2, a3, b1, b2, b3, c1, c2, c3: Single): Single;
begin// 求行列式的值
 Result:= a1 * (b2 * c3 - b3 * c2) - b1 * (a2 * c3 - a3 * c2) +
  c1 * (a2 * b3 - a3 * b2);
end;

//---------------------------------------------------------------------------
function AdjointMtx4(const m: TMatrix4): TMatrix4;
begin// 计算标准伴随矩阵
 Result.Data[0, 0]:=  DetMtx3(m.Data[1, 1], m.Data[2, 1], m.Data[3, 1],
  m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[1, 0]:= -DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[2, 0]:=  DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[1, 1], m.Data[2, 1], m.Data[3, 1], m.Data[1, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[3, 0]:= -DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[1, 1], m.Data[2, 1], m.Data[3, 1], m.Data[1, 2], m.Data[2, 2],
  m.Data[3, 2]);

 Result.Data[0, 1]:= -DetMtx3(m.Data[0, 1], m.Data[2, 1], m.Data[3, 1],
  m.Data[0, 2], m.Data[2, 2], m.Data[3, 2], m.Data[0, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[1, 1]:=  DetMtx3(m.Data[0, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[0, 2], m.Data[2, 2], m.Data[3, 2], m.Data[0, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[2, 1]:= -DetMtx3(m.Data[0, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[0, 1], m.Data[2, 1], m.Data[3, 1], m.Data[0, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[3, 1]:=  DetMtx3(m.Data[0, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[0, 1], m.Data[2, 1], m.Data[3, 1], m.Data[0, 2], m.Data[2, 2],
  m.Data[3, 2]);

 Result.Data[0, 2]:=  DetMtx3(m.Data[0, 1], m.Data[1, 1], m.Data[3, 1],
  m.Data[0, 2], m.Data[1, 2], m.Data[3, 2], m.Data[0, 3], m.Data[1, 3],
  m.Data[3, 3]);
 Result.Data[1, 2]:= -DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[3, 0],
  m.Data[0, 2], m.Data[1, 2], m.Data[3, 2], m.Data[0, 3], m.Data[1, 3],
  m.Data[3, 3]);
 Result.Data[2, 2]:=  DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[3, 0],
  m.Data[0, 1], m.Data[1, 1], m.Data[3, 1], m.Data[0, 3], m.Data[1, 3],
  m.Data[3, 3]);
 Result.Data[3, 2]:= -DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[3, 0],
  m.Data[0, 1], m.Data[1, 1], m.Data[3, 1], m.Data[0, 2], m.Data[1, 2],
  m.Data[3, 2]);

 Result.Data[0, 3]:= -DetMtx3(m.Data[0, 1], m.Data[1, 1], m.Data[2, 1],
  m.Data[0, 2], m.Data[1, 2], m.Data[2, 2], m.Data[0, 3], m.Data[1, 3],
  m.Data[2, 3]);
 Result.Data[1, 3]:=  DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[2, 0],
  m.Data[0, 2], m.Data[1, 2], m.Data[2, 2], m.Data[0, 3], m.Data[1, 3],
  m.Data[2, 3]);
 Result.Data[2, 3]:= -DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[2, 0],
  m.Data[0, 1], m.Data[1, 1], m.Data[2, 1], m.Data[0, 3], m.Data[1, 3],
  m.Data[2, 3]);
 Result.Data[3, 3]:=  DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[2, 0],
  m.Data[0, 1], m.Data[1, 1], m.Data[2, 1], m.Data[0, 2], m.Data[1, 2],
  m.Data[2, 2]);
end;

//---------------------------------------------------------------------------
function DetMtx4(const m: TMatrix4): Single;
begin
 {$ifdef SupportD3DX}
   {$IFDEF AsphyreUseDx8}
     Result:= m.Data[0, 0] * DetMtx3(m.Data[1, 1], m.Data[2, 1], m.Data[3, 1],
      m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3], m.Data[2, 3],
      m.Data[3, 3]) - m.Data[0, 1] * DetMtx3(m.Data[1, 0], m.Data[2, 0],
      m.Data[3, 0], m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3],
      m.Data[2, 3], m.Data[3, 3]) + m.Data[0, 2] * DetMtx3(m.Data[1, 0],
      m.Data[2, 0], m.Data[3, 0], m.Data[1, 1], m.Data[2, 1], m.Data[3, 1],
      m.Data[1, 3], m.Data[2, 3], m.Data[3, 3]) - m.Data[0, 3] *
      DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0], m.Data[1, 1],
      m.Data[2, 1], m.Data[3, 1], m.Data[1, 2], m.Data[2, 2], m.Data[3, 2]);

   {$ELSE}
     Result:= D3DXMatrixDeterminant(TD3DXMatrix(m));
   {$ENDIF}
 {$else}
 Result:= m.Data[0, 0] * DetMtx3(m.Data[1, 1], m.Data[2, 1], m.Data[3, 1],
  m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3], m.Data[2, 3],
  m.Data[3, 3]) - m.Data[0, 1] * DetMtx3(m.Data[1, 0], m.Data[2, 0],
  m.Data[3, 0], m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3],
  m.Data[2, 3], m.Data[3, 3]) + m.Data[0, 2] * DetMtx3(m.Data[1, 0],
  m.Data[2, 0], m.Data[3, 0], m.Data[1, 1], m.Data[2, 1], m.Data[3, 1],
  m.Data[1, 3], m.Data[2, 3], m.Data[3, 3]) - m.Data[0, 3] *
  DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0], m.Data[1, 1],
  m.Data[2, 1], m.Data[3, 1], m.Data[1, 2], m.Data[2, 2], m.Data[3, 2]);
 {$endif}
end;

//---------------------------------------------------------------------------
function InvertMtx4(const m: TMatrix4): TMatrix4;
{$ifndef SupportD3DX}
var
 Det: Single;
{$endif}
begin
 {$ifdef SupportD3DX}
 D3DXMatrixInverse(TD3DXMatrix(Result), nil, TD3DXMatrix(m));
 {$else}
 Det:= DetMtx4(m);
 if (Det <> 0.0) then
  begin
   Result:= AdjointMtx4(m) / Det;
  end else Result:= IdentityMtx4
 {$endif} 
end;

//--------------------------------------------------------------------------
function RotateXMtx4(Angle: Single): TMatrix4;
begin
 {$ifdef SupportD3DX}
 D3DXMatrixRotationX(TD3DXMatrix(Result), Angle);
 {$else}
 Result:= IdentityMtx4;

 Result.Data[1, 1]:=  Cos(Angle);
 Result.Data[1, 2]:=  Sin(Angle);
 Result.Data[2, 1]:= -Result.Data[1, 2];
 Result.Data[2, 2]:=  Result.Data[1, 1];
 {$endif}
end;

//--------------------------------------------------------------------------
function RotateYMtx4(Angle: Single): TMatrix4;
begin
 {$ifdef SupportD3DX}
 D3DXMatrixRotationY(TD3DXMatrix(Result), Angle);
 {$else}
 Result:= IdentityMtx4;

 Result.Data[0, 0]:=  Cos(Angle);
 Result.Data[0, 2]:= -Sin(Angle);
 Result.Data[2, 0]:= -Result.Data[0, 2];
 Result.Data[2, 2]:=  Result.Data[0, 0];
 {$endif}
end;

//--------------------------------------------------------------------------
function RotateZMtx4(Angle: Single): TMatrix4;
begin
 {$ifdef SupportD3DX}
 D3DXMatrixRotationZ(TD3DXMatrix(Result), Angle);
 {$else}
 Result:= IdentityMtx4;

 Result.Data[0, 0]:=  Cos(Angle);
 Result.Data[0, 1]:=  Sin(Angle);
 Result.Data[1, 0]:= -Result.Data[0, 1];
 Result.Data[1, 1]:=  Result.Data[0, 0];
 {$endif}
end;

//--------------------------------------------------------------------------
function RotateMtx4(const Axis: TVector3; Angle: Single): TMatrix4;
{$ifndef SupportD3DX}
var
 CosTh, iCosTh, SinTh: Single;
 xy, xz, yz, xSin, ySin, zSin: Single;
{$endif}
begin
 {$ifdef SupportD3DX}
 D3DXMatrixRotationAxis(TD3DXMatrix(Result), TD3DXVector3(Axis), Angle);
 {$else}
 CosTh := Cos(Angle);
 iCosTh:= 1.0 - CosTh;
 SinTh := Sin(Angle);
 xy    := Axis.x * Axis.y * iCosTh;
 xz    := Axis.x * Axis.z * iCosTh;
 yz    := Axis.y * Axis.z * iCosTh;
 xSin  := Axis.x * SinTh;
 ySin  := Axis.y * SinTh;
 zSin  := Axis.z * SinTh;

 Result:= IdentityMtx4;
 Result.Data[0, 0]:= (Sqr(Axis.x) * iCosTh) + CosTh;
 Result.Data[0, 1]:= xy + zSin;
 Result.Data[0, 2]:= xz - ySin;
 Result.Data[1, 0]:= xy - zSin;
 Result.Data[1, 1]:= (Sqr(Axis.y) * iCosTh) + CosTh;
 Result.Data[1, 2]:= yz + xSin;
 Result.Data[2, 0]:= xz + ySin;
 Result.Data[2, 1]:= yz - xSin;
 Result.Data[2, 2]:= (Sqr(Axis.z) * iCosTh) + CosTh;
 {$endif}
end;

//---------------------------------------------------------------------------
function ReflectMtx4(const Axis: TVector3): TMatrix4;
var
 xy, yz, xz: Single;
begin
 xy:= -2.0 * Axis.x * Axis.y;
 xz:= -2.0 * Axis.x * Axis.z;
 yz:= -2.0 * Axis.y * Axis.z;

 Result:= IdentityMtx4;
 Result.Data[0, 0]:= 1.0 - (2.0 * Sqr(Axis.x));
 Result.Data[0, 1]:= xy;
 Result.Data[0, 2]:= xz;
 Result.Data[1, 0]:= xy;
 Result.Data[1, 1]:= 1.0 - (2.0 * Sqr(Axis.y));
 Result.Data[1, 2]:= yz;
 Result.Data[2, 0]:= xz;
 Result.Data[2, 1]:= yz;
 Result.Data[2, 2]:= 1.0 - (2.0 * Sqr(Axis.z));
end;

//---------------------------------------------------------------------------
function LookAtMtx4(const Origin, Target, Roof: TVector3): TMatrix4;
{$ifndef SupportD3DX}
var
 xAxis, yAxis, zAxis: TVector3;
{$endif}
begin
 {$ifdef SupportD3DX}
 D3DXMatrixLookAtLH(TD3DXMatrix(Result), TD3DXVector3(Origin),
  TD3DXVector3(Target), TD3DXVector3(Roof));
 {$else}
 zAxis:= Norm3(Target - Origin);
 xAxis:= Norm3(Cross3(Roof, zAxis));
 yAxis:= Cross3(zAxis, xAxis);

 Result.Data[0, 0]:= xAxis.x;
 Result.Data[0, 1]:= yAxis.x;
 Result.Data[0, 2]:= zAxis.x;
 Result.Data[0, 3]:= 0.0;

 Result.Data[1, 0]:= xAxis.y;
 Result.Data[1, 1]:= yAxis.y;
 Result.Data[1, 2]:= zAxis.y;
 Result.Data[1, 3]:= 0.0;

 Result.Data[2, 0]:= xAxis.z;
 Result.Data[2, 1]:= yAxis.z;
 Result.Data[2, 2]:= zAxis.z;
 Result.Data[2, 3]:= 0.0;

 Result.Data[3, 0]:= -Dot3(xAxis, Origin);
 Result.Data[3, 1]:= -Dot3(yAxis, Origin);
 Result.Data[3, 2]:= -Dot3(zAxis, Origin);
 Result.Data[3, 3]:= 1.0;
 {$endif}
end;

//---------------------------------------------------------------------------
function PerspectiveFOVYMtx4(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single): TMatrix4;
var
 xScale, yScale, zCoef: Single;
begin
 yScale:= Cot(FieldOfView * 0.5);
 xScale:= yScale / AspectRatio;
 zCoef := MaxRange / (MaxRange - MinRange);

 Result:= ZeroMtx4;

 Result.Data[0, 0]:= xScale;
 Result.Data[1, 1]:= yScale;
 Result.Data[2, 2]:= zCoef;
 Result.Data[2, 3]:= 1.0;
 Result.Data[3, 2]:= -MinRange * zCoef;
end;

//---------------------------------------------------------------------------
function PerspectiveFOVXMtx4(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single): TMatrix4;
var
 xScale, yScale, zCoef: Single;
begin
 xScale:= Cot(FieldOfView * 0.5);
 yScale:= xScale / AspectRatio;
 zCoef := MaxRange / (MaxRange - MinRange);

 Result:= ZeroMtx4;

 Result.Data[0, 0]:= xScale;
 Result.Data[1, 1]:= yScale;
 Result.Data[2, 2]:= zCoef;
 Result.Data[2, 3]:= 1.0;
 Result.Data[3, 2]:= -MinRange * zCoef;
end;

//---------------------------------------------------------------------------
function PerspectiveVOLMtx4(Width, Height, MinRange, MaxRange: Single): TMatrix4;
begin
 Result:= ZeroMtx4;

 Result.Data[0, 0]:= (2.0 * MinRange) / Width;
 Result.Data[1, 1]:= (2.0 * MinRange) / Height;
 Result.Data[2, 2]:= MaxRange / (MaxRange - MinRange);
 Result.Data[2, 3]:= 1.0;
 Result.Data[3, 2]:= MinRange * MaxRange / (MinRange - MaxRange);
end;

//---------------------------------------------------------------------------
function PerspectiveBDSMtx4(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single): TMatrix4;
begin
 Result:= ZeroMtx4;

 Result.Data[0, 0]:= (2.0 * MinRange) / (Right - Left);
 Result.Data[1, 1]:= (2.0 * MinRange) / (Top - Bottom);

 Result.Data[2, 0]:= (Left + Right) / (Left - Right);
 Result.Data[2, 1]:= (Top + Bottom) / (Bottom - Top);
 Result.Data[2, 2]:= MaxRange / (MaxRange - MinRange);
 Result.Data[2, 3]:= 1.0;
 Result.Data[3, 2]:= MinRange * MaxRange / (MinRange - MaxRange);
end;

//---------------------------------------------------------------------------
function OrthogonalVOLMtx4(Width, Height, MinRange, MaxRange: Single): TMatrix4;
begin
 Result:= ZeroMtx4;

 Result.Data[0, 0]:= 2.0 / Width;
 Result.Data[1, 1]:= 2.0 / Height;
 Result.Data[2, 2]:= 1.0 / (MaxRange - MinRange);
 Result.Data[2, 3]:= MinRange / (MinRange - MaxRange);
 Result.Data[3, 3]:= 1.0;
end;

//---------------------------------------------------------------------------
function OrthogonalBDSMtx4(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single): TMatrix4;
begin
 Result:= ZeroMtx4;

 Result.Data[0, 0]:= 2.0 / (Right - Left);
 Result.Data[1, 1]:= 2.0 / (Top - Bottom);
 Result.Data[2, 2]:= 1.0 / (MaxRange - MinRange);
 Result.Data[2, 3]:= MinRange / (MinRange - MaxRange);
 Result.Data[3, 0]:= (Left + Right) / (Left - Right);
 Result.Data[3, 1]:= (Top + Bottom) / (Bottom - Top);
 Result.Data[3, 2]:= MinRange / (MinRange - MaxRange);
 Result.Data[3, 3]:= 1.0;
end;

//--------------------------------------------------------------------------
function HeadingPitchBankMtx4(Heading, Pitch, Bank: Single): TMatrix4;
var
 CosH, SinH: Single;
 CosP, SinP: Single;
 CosB, SinB: Single;
begin
 Result:= IdentityMtx4;

 CosH:= Cos(Heading);
 SinH:= Sin(Heading);
 CosP:= Cos(Pitch);
 SinP:= Sin(Pitch);
 CosB:= Cos(Bank);
 SinB:= Sin(Bank);

 Result.Data[0, 0]:= (CosH * CosB) + (SinH * SinP * SinB);
 Result.Data[0, 1]:= (-CosH * SinB) + (SinH * SinP * CosB);
 Result.Data[0, 2]:= SinH * CosP;
 Result.Data[1, 0]:= SinB * CosP;
 Result.Data[1, 1]:= CosB * CosP;
 Result.Data[1, 2]:= -SinP;
 Result.Data[2, 0]:= (-SinH * CosB) + (CosH * SinP * SinB);
 Result.Data[2, 1]:= (SinB * SinH) + (CosH * SinP * CosB);
 Result.Data[2, 2]:= CosH * CosP;
end;

//---------------------------------------------------------------------------
function HeadingPitchBankMtx4(const v: TVector3): TMatrix4; overload;
begin
 Result:= HeadingPitchBankMtx4(v.y, v.x, v.z);
end;

//---------------------------------------------------------------------------
{$ifdef SupportD3DX}
function YawPitchRollMtx4(Yaw, Pitch, Roll: Single): TMatrix4; overload;
begin
 D3DXMatrixRotationYawPitchRoll(TD3DXMatrix(Result), Yaw, Pitch, Roll);
end;

//---------------------------------------------------------------------------
function YawPitchRollMtx4(const v: TVector3): TMatrix4; overload;
begin
 D3DXMatrixRotationYawPitchRoll(TD3DXMatrix(Result), v.y, v.x, v.z);
end;
{$endif}

//---------------------------------------------------------------------------
end.

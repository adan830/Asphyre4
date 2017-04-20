{******************************************************************************}
{��Ԫ���ƣ�AsphyreFontCache.pas                                                }
{�������������һ���������뻺���֧ࣨ��Asphyre410��                            }
{������Ա��Piao40993470 (xbpiao@msn.com)                                       }
{����ʱ�䣺2007-07-07 21:44                                                    }
{ʹ��˵����                                                                    }
{�޸���ʷ��                                                                    }
{     2007-07-08 20:16 Add by Piao40993470 ���ڻ��峬��ʱ��ʧ��������          }
{******************************************************************************}

unit AsphyreFontCache;

interface

uses
  Types, Classes, Windows, SysUtils, Vectors2px,
  AsphyreTypes, AsphyreImages, AsphyreDevices;

type
  { ���������С��λ }
  PFontCacheData = ^TFontCacheData;
  TFontCacheData = record
    FID: Cardinal;           // ע���ID���Ǵ�1��ʼ��0������Ϊ��ЧID
    FTimeTick: Cardinal;     // �ϴ�ʹ��ʱ���
    FRect: TRect;            // �ڻ��������е�λ��
    FFontIndex: integer;     // ��������
    FText: WideString;       // ������Ƶ�����
    FColor: Cardinal;        // ��ɫ
    FRepaint: Boolean;       // �Ƿ���Ҫ�ػ�
    FSafeguard: Boolean;     // ��֤������Ϊ��ʱ����ɾ��
  end;// TFontCacheData

  { 2007-07-07 23:12 Add by Piao40993470
    ע��ʼ��ʹ��TAsphyreDevice.SysFont
  }
  TAsphyreFontCache = class(TObject)
  private
    FDevice: TAsphyreDevice;
    FActiveFontName: string;
    FCacheTimeOut: Cardinal; // ���ݿ����ʱ��
    FLastID: Cardinal;      // �������ID��
    FCacheData: TList;
    FImageIndex: integer;   // ȷ���пɻ��Ƶı���
    FImageName: string;
    FImage: TAsphyreCustomImage;

    FNeedRender: boolean;    // �ж��Ƿ���Ҫ�ػ�
    FNeedRenderAll: Boolean; // �Ƿ���Ҫ�ػ�ȫ��
    FMaxHeight: integer;
    FMaxWidth: integer;
    FRemainArea: integer;

    { ����Ⱦ��Ҫ�ػ�Ĳ��� }
    procedure RenderNeedUpdateText(Sender: TAsphyreDevice; Tag: TObject);
    function HasValidArea(X, Y: integer; var Area: TRect): boolean;

    procedure OnDeviceReset(Sender: TObject; EventParam: Pointer;
      var Success: Boolean);
    procedure OnDeviceLost(Sender: TObject; EventParam: Pointer;
      var Success: Boolean);
    procedure OnDeviceDestroy(Sender: TObject; EventParam: Pointer;
      var Success: Boolean); virtual;
    function GetIsNeedRender: Boolean;

  protected

  public
    constructor Create(const ADevice: TAsphyreDevice; ImageName: string);
    destructor Destroy; override;

    procedure Clear;
    procedure Render();
    procedure NeedReRenderAll();


    { ����AFontName�����ı�AText, �õ�FontCacheID��֮��ɿ���ͨ��FontCacheID���� }
    function GetFontCacheID(const AFontName: string; const AText: WideString;
      Color: Cardinal): Cardinal;
    function GetFontCacheData(const AFontName: string; const AText: WideString;
      Color: Cardinal): PFontCacheData;

    { ����ID�жϸû����Ƿ񻹴���, =-1������ >=0 ���� }
    function Exist(const CacheID: Cardinal): Integer;
    { ��������������� }
    procedure Dirty(const CacheID: Cardinal);

    { ����������ݿ� }
    procedure DirtyTimeOut();

    { ֱ��ʹ��FontCacheID���� begin }
    function TextOut(const CacheID: Cardinal; x, y: Integer;
      const Colors: TColor2): boolean; overload;
    function TextOut(const CacheID: Cardinal;  x, y: Integer;
      Color: Cardinal): boolean; overload;
    function TextRect(const CacheID: Cardinal; const Rect: TRect;
      HorizontalAlign: THorizontalAlign; VerticalAlign: TVerticalAlign;
      const Colors: TColor2): Boolean; overload;

    function TextExtent(const CacheID: Cardinal): TPoint2px;overload;
    function TextWidth(const CacheID: Cardinal): Integer;overload;
    function TextHeight(const CacheID: Cardinal): Integer;overload;
    { ֱ��ʹ��FontCacheID���� End }

    { ʹ��PFontCacheData���ƴ������ begin }
    // �ɽ�Լÿ�μ����Ч�Բ�������ʱ��(����Ϸ���������Ҳ���൱�ɹ۵�)�������Զ������������
    function TextOut(const FontCacheData: PFontCacheData; x, y: Integer;
      const Colors: TColor2): boolean; overload;
    function TextOut(const FontCacheData: PFontCacheData;  x, y: Integer;
      Color: Cardinal): boolean; overload;
    function TextRect(const FontCacheData: PFontCacheData; const Rect: TRect;
      HorizontalAlign: THorizontalAlign; VerticalAlign: TVerticalAlign;
      const Colors: TColor2): Boolean; overload;

    function TextExtent(const FontCacheData: PFontCacheData): TPoint2px; overload;
    function TextWidth(const FontCacheData: PFontCacheData): Integer; overload;
    function TextHeight(const FontCacheData: PFontCacheData): Integer; overload;
    { ʹ��PFontCacheData���ƴ������ end }

    function CacheText(const CacheID: Cardinal): WideString;
    function CacheData(const CacheID: Cardinal): PFontCacheData;

    procedure UseFontImage(const TexRect: TRect);

    property ImageIndex: integer read FImageIndex;
    property IsNeedRender: Boolean read GetIsNeedRender; 
  published
    property CacheTimeOut: Cardinal read FCacheTimeOut write FCacheTimeOut;
  end;


var
   GuiFontCache: TAsphyreFontCache = nil;
implementation

uses AsphyreEvents, AsphyreSystemFonts, AsphyreEffects, AsphyreUtils,
 {$IFDEF AsphyreUseDx8}
 Direct3D8
 {$ELSE}
 Direct3D9
 {$ENDIF} ;

{ TAsphyreFontCache }

function TAsphyreFontCache.CacheData(const CacheID: Cardinal): PFontCacheData;
var t: integer;
begin
  Result := nil;
  t := Exist(CacheID);
  if (t >= 0) and Assigned(FDevice) and Assigned(FImage) then
  begin
    Result := FCacheData.Items[t];
    { �������ȡ���ݺ��򲻼�����ƹ����У���Ҫ�ֶ�TAsphyreFontCache.Dirty�ͷ� }
    Result.FSafeguard := True;
  end;// if
end;

function TAsphyreFontCache.CacheText(const CacheID: Cardinal): WideString;
var t: integer;
    tmpData: PFontCacheData;
begin
  Result := '';
  t := Exist(CacheID);
  if (t >= 0) and Assigned(FDevice) and Assigned(FImage) then
  begin
    tmpData := FCacheData.Items[t];
    Result := tmpData^.FText;
  end;// if
end;

procedure TAsphyreFontCache.Clear;
var i: integer;
    tmpData: PFontCacheData;
begin
  for i := 0 to FCacheData.Count - 1 do
  begin
    tmpData := FCacheData.Items[i];
    tmpData^.FText := '';
    Dispose(tmpData);
  end;// for i
  FCacheData.Clear;
  FRemainArea := FMaxHeight * FMaxWidth;
end;

constructor TAsphyreFontCache.Create(const ADevice: TAsphyreDevice;
  ImageName: string);
begin
  FDevice := ADevice;
  FCacheTimeOut := 3000; // 5����û��ʹ�õ����Զ���������
  FLastID := 0;
  FImageIndex := -1;
  FImageName := ImageName;
  FImage := nil;

  FMaxHeight := 0;
  FMaxWidth := 0;
  FRemainArea := 0;

  FCacheData := TList.Create;
  FNeedRender := False;
  FNeedRenderAll := True;// ��֤��һ��ȫ����Ҫ�ػ�
  { �����¼� }
//  EventDeviceReset.Subscribe(OnDeviceReset, ADevice);
//  EventDeviceLost.Subscribe(OnDeviceLost, ADevice);
//  EventDeviceDestroy.Subscribe(OnDeviceDestroy, ADevice);
  EventDeviceReset.Subscribe(OnDeviceReset, DefDevice);
  EventDeviceLost.Subscribe(OnDeviceLost, DefDevice);
  EventDeviceDestroy.Subscribe(OnDeviceDestroy, DefDevice);

end;

destructor TAsphyreFontCache.Destroy;
begin
  Clear();
  FreeAndNil(FCacheData);
  inherited;
end;

procedure TAsphyreFontCache.Dirty(const CacheID: Cardinal);
var tmpIndex: integer;
    tmpData: PFontCacheData;
begin
  tmpIndex := Exist(CacheID);
  if tmpIndex >= 0 then
  begin{ ֱ��ɾ�� }


    tmpData := FCacheData.Items[tmpIndex];
    tmpData^.FText := '';
    FRemainArea := FRemainArea + (tmpData^.FRect.Right - tmpData^.FRect.Left) *
      (tmpData^.FRect.Bottom - tmpData^.FRect.Top);

    {$IFDEF UseOutputDebugString}
      OutputDebugString(PAnsiChar('TAsphyreFontCache.Dirty[' +
        IntToStr(tmpData^.FID) + ']FRemainArea=' + IntToStr(FRemainArea)));
    {$ENDIF}
    Dispose(tmpData);
    FCacheData.Delete(tmpIndex);
    FNeedRender := True;
  end;// if
end;

procedure TAsphyreFontCache.DirtyTimeOut;
var i: integer;
    CurTick: Cardinal;
    tmpData: PFontCacheData;
begin
  CurTick := GetTickCount;
  for i := 0 to FCacheData.Count - 1 do
  begin
    tmpData := FCacheData.Items[i];
    if (not tmpData^.FSafeguard) and
     ((CurTick - tmpData^.FTimeTick) >= FCacheTimeOut) then
    begin
      tmpData^.FText := '';
      FRemainArea := FRemainArea + (tmpData^.FRect.Right - tmpData^.FRect.Left) *
        (tmpData^.FRect.Bottom - tmpData^.FRect.Top);
      Dispose(tmpData);
      FCacheData.Items[i] := nil;
    end;// if
  end;// for i
  FCacheData.Pack;
end;

function TAsphyreFontCache.Exist(const CacheID: Cardinal): integer;
var
  L, H, I, C: Integer;
begin{ ID���Ǵ�С����������˿�ֱ��ʹ���۰���� }
  Result := -1;
  if CacheID = 0 then Exit;
  L := 0;
  H := FCacheData.Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := PFontCacheData(FCacheData[i])^.FID - CacheID;
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := I;
        { ��¼��ʹ��ʱ�� }
        PFontCacheData(FCacheData[i])^.FTimeTick := GetTickCount;
        Break; // �ҵ�����
      end;// if
    end;// if
  end;// while
end;

function TAsphyreFontCache.GetFontCacheData(const AFontName: string;
  const AText: WideString; Color: Cardinal): PFontCacheData;
begin
  Result := CacheData(GetFontCacheID(AFontName, AText, Color));
end;

function TAsphyreFontCache.GetFontCacheID(const AFontName: string;
  const AText: WideString; Color: Cardinal): Cardinal;
var Font: TAsphyreSystemFont;
    CacheFontData: PFontCacheData;
    ATextExtent: TPoint2px;    
begin
  Result := 0;
  Font := FDevice.SysFonts.Font[AFontName];
  if FImageIndex < 0 then
  begin{ ��ȡ���������С }
    FImageIndex := FDevice.Images.ResolveImage(FImageName);
    FImage := FDevice.Images.Items[FImageIndex];
    FMaxHeight := 0;
    FMaxWidth := 0;
    FRemainArea := 0;
    if FImage.TextureCount > 0 then
    begin
      FMaxHeight := FImage.Texture[0].Size.Y;
      FMaxWidth := FImage.Texture[0].Size.X;
      FRemainArea := FMaxHeight * FMaxWidth;
    end;// if
  end;// if
  if (FImageIndex >=0) and Assigned(Font) and (AText <> '') then
  begin
    FNeedRender := True;  // ��Ҫ����

    New(CacheFontData);
    Inc(FLastID);
    CacheFontData^.FID := FLastID;
    CacheFontData^.FTimeTick := GetTickCount;

    CacheFontData^.FText := AText;
    CacheFontData^.FFontIndex := Font.FontIndex;
    CacheFontData^.FColor := Color;
    CacheFontData^.FRepaint := True;
    CacheFontData^.FSafeguard := False;
    { ��ο��ٸ�Ч�ķ���һ����ȷ�ľ������ڻ��� }
    ATextExtent := Font.TextExtent(AText);
    if HasValidArea(ATextExtent.x , ATextExtent.y, CacheFontData^.FRect) then
    begin// �ҵ�����λ��
      Result := CacheFontData^.FID;
      FCacheData.Add(CacheFontData);
      FRemainArea := FRemainArea - ATextExtent.x * ATextExtent.y;
    end
    else
    begin{ ��������û�к���ʱ��������ڵ� }
      DirtyTimeOut(); // ����������ݿ�
      if HasValidArea(ATextExtent.x , ATextExtent.y, CacheFontData^.FRect) then
      begin// �ҵ�����λ��
        Result := CacheFontData^.FID;
        FCacheData.Add(CacheFontData);
        FRemainArea := FRemainArea - ATextExtent.x * ATextExtent.y;
      end
      else
      begin{ ��Ȼû������򲻴��� }
        CacheFontData^.FText := '';
        Dispose(CacheFontData);
        {$IFDEF UseOutputDebugString}
          OutputDebugString('TAsphyreFontCache.GetFontCacheID û����ռ�');
        {$ENDIF}

      end;// if
    end;// if
    { ��ʱΪ���� }
    //CacheFontData^.FRect := Rect(0, 0, ATextExtent.x, ATextExtent.y);

  end;// if
end;



function TAsphyreFontCache.GetIsNeedRender: Boolean;
begin
  Result := FNeedRender or FNeedRenderAll;
end;

function TAsphyreFontCache.HasValidArea(X, Y: integer;
  var Area: TRect): boolean;
var AddArea: integer;
    DataLen: integer;
    i, j: integer;
    t: array[0..3] of TPoint;
    tmpArea{, IntersectArea}: TRect;
    CacheFontData, tmpData: PFontCacheData;
    
    function ValidArea(const AValue: TRect): boolean;
    begin
      with AValue do
      Result := (Left >= 0) and (Left < FMaxWidth) and
        (Top >= 0) and (Top < FMaxHeight) and
        (Right >= 0) and (Right < FMaxWidth) and
        (Bottom >= 0) and (Bottom < FMaxHeight);
    end;

    function CheckArea(const AValue: TRect; CurPos: Integer): Boolean;
    var k: integer;
    begin
      Result := False;
      for k := CurPos to DataLen - 1 do
      begin{ ���ȴӵ�ǰλ�ø������ }
        tmpData := FCacheData.Items[k];
        //if IntersectRect(IntersectArea, AValue, tmpData^.FRect) then Exit;
        if OverlapRect(AValue, tmpData^.FRect) then Exit;
      end;// for k

      for k := 0 to CurPos - 1 do
      begin{ ������� }
        tmpData := FCacheData.Items[k];
        //if IntersectRect(IntersectArea, AValue, tmpData^.FRect) then Exit;
        if OverlapRect(AValue, tmpData^.FRect) then Exit;
      end;// for k
      Result := True;
    end;
begin{ ���㷨Ч��δ������(������������ȷ��)����ʹ����ֱ�ӵ���ٷ�Ч�ʿ϶��д��Ż� }
  Result := False;
  AddArea := X * Y;
  if (AddArea <= 0) or (AddArea > FRemainArea) then Exit; // û���㹻���������
  DataLen := FCacheData.Count;
  
  if (DataLen = 0) and (X <= FMaxWidth) and (Y <= FMaxHeight) then
  begin{ ֱ�ӷ��� }
    Area := Rect(0, 0, X, Y);

    Result := True;
    Exit;
  end;// if
  for i := DataLen - 1 downto 0 do
  begin{ ��� }
    CacheFontData := FCacheData.Items[i];

    with CacheFontData^.FRect do
    begin{ �趨�ĸ��� }
      t[0].X := Left;
      t[0].Y := Top;
      t[1].X := Right;
      t[1].Y := Top;
      t[2].X := Left;
      t[2].Y := Bottom;
      t[3].X := Right;
      t[3].Y := Bottom;
    end;// with

    for j := 0 to 3 do
    begin { ÿ�������ĸ�����������˳ʱ�� }
      {1. }
      tmpArea.TopLeft := t[j];
      tmpArea.Right := tmpArea.Left + X;
      tmpArea.Bottom := tmpArea.Top + Y;
      if ValidArea(tmpArea) and CheckArea(tmpArea, i) then
      begin
        Result := True;
        Break;
      end;// if

      {2.��}
      tmpArea.Left := t[j].X - X;
      tmpArea.Top := t[j].Y;
      tmpArea.Right := t[j].X;
      tmpArea.Bottom := t[j].Y + Y;
      if ValidArea(tmpArea) and CheckArea(tmpArea, i) then
      begin
        Result := True;
        Break;
      end;// if

      {3. }
      tmpArea.Left := t[j].X - X;
      tmpArea.Top := t[j].Y - Y;
      tmpArea.BottomRight := t[j];
      if ValidArea(tmpArea) and CheckArea(tmpArea, i) then
      begin
        Result := True;
        Break;
      end;// if

      {4. }
      tmpArea.Left := t[j].X;
      tmpArea.Top := t[j].Y - Y;
      tmpArea.Right := t[j].X + X;
      tmpArea.Bottom := t[j].Y;
      if ValidArea(tmpArea) and CheckArea(tmpArea, i) then
      begin
        Result := True;
        Break;
      end;// if

    end;// for j
    
    if Result then Break;
  end;// for i

  if Result then
  begin{�ҵ�}
    Area := tmpArea;
    
  end;// if
end;


procedure TAsphyreFontCache.NeedReRenderAll;
begin
  FNeedRenderAll := True;
  FNeedRender := True;
end;

procedure TAsphyreFontCache.OnDeviceDestroy(Sender: TObject;
  EventParam: Pointer; var Success: Boolean);
begin

end;

procedure TAsphyreFontCache.OnDeviceLost(Sender: TObject; EventParam: Pointer;
  var Success: Boolean);
begin
  FImage := nil;
end;

procedure TAsphyreFontCache.OnDeviceReset(Sender: TObject; EventParam: Pointer;
  var Success: Boolean);
begin
  if FImageIndex < 0 then
  begin{ ��ȡ���������С }
    FImageIndex := FDevice.Images.ResolveImage(FImageName);
    FImage := FDevice.Images.Items[FImageIndex];
    FMaxHeight := 0;
    FMaxWidth := 0;
    FRemainArea := 0;
    if FImage.TextureCount > 0 then
    begin
      FMaxHeight := FImage.Texture[0].Size.Y;
      FMaxWidth := FImage.Texture[0].Size.X;
      FRemainArea := FMaxHeight * FMaxWidth;
    end;// if
  end
  else
  begin
    FImageIndex := FDevice.Images.ResolveImage(FImageName);
    FImage := FDevice.Images.Items[FImageIndex];
    FMaxHeight := 0;
    FMaxWidth := 0;
    if FImage.TextureCount > 0 then
    begin
      FMaxHeight := FImage.Texture[0].Size.Y;
      FMaxWidth := FImage.Texture[0].Size.X;
      //FRemainArea := FMaxHeight * FMaxWidth;
    end;// if

  end;// if
  FNeedRenderAll := True;
  FNeedRender := True;

end;

procedure TAsphyreFontCache.Render;
begin
  if FNeedRender and (FImageIndex >= 0) and (FCacheData.Count > 0)
    and (FDevice <> nil) then
  begin
    //FDevice.RenderTo(FImageIndex, RenderNeedUpdateText, Self, 0, 0.0, 0);
    FDevice.RenderTo(FImageIndex, RenderNeedUpdateText, Self);
  end;// if
end;

procedure TAsphyreFontCache.RenderNeedUpdateText(Sender: TAsphyreDevice;
  Tag: TObject);
var i, t: integer;
    CurTick: Cardinal;
    CachFontData: PFontCacheData;
    Font: TAsphyreSystemFont;
begin
  CurTick := GetTickCount;
  t := 0;
  if FNeedRenderAll then
  begin
    {$IFDEF AsphyreUseDx8}
    Sender.Dev8.Clear(0, nil, D3DCLEAR_TARGET, 0, 0.0, 0);
    {$ELSE}
    Sender.Dev9.Clear(0, nil, D3DCLEAR_TARGET, 0, 0.0, 0);
    {$ENDIF}
  end;// if
  for i := 0 to FCacheData.Count - 1 do
  begin
    CachFontData := FCacheData.Items[i];
    if CachFontData^.FRepaint or FNeedRenderAll then
    begin{ ����ָ���� }
      if not FNeedRenderAll then
      begin
        {$IFDEF AsphyreUseDx8}
        Sender.Dev8.Clear(1, PD3DRect(@CachFontData^.FRect), D3DCLEAR_TARGET, 0, 0.0, 0);
        {$ELSE}
        Sender.Dev9.Clear(1, PD3DRect(@CachFontData^.FRect), D3DCLEAR_TARGET, 0, 0.0, 0);
        {$ENDIF}
      end;// if
      Font := Sender.SysFonts.Items[CachFontData^.FFontIndex];
      Font.TextOut(CachFontData^.FText, CachFontData^.FRect,
        [fftTop, fftLeft, fftSingleLine], CachFontData^.FColor);
      CachFontData^.FRepaint := False;
    end
    else
    begin{ �Զ����չ��ڲ��õĵ��� }
      if (not CachFontData^.FSafeguard) and
         ((CurTick - CachFontData^.FTimeTick) > FCacheTimeOut) then
      begin
        FRemainArea := FRemainArea + (CachFontData^.FRect.Right -
          CachFontData^.FRect.Left) *
          (CachFontData^.FRect.Bottom - CachFontData^.FRect.Top);

//        {$IFDEF UseOutputDebugString}
//          OutputDebugString(PAnsiChar('TAsphyreFontCache.RenderNeedUpdateText '+
//            'Dispose=' + IntToStr(CachFontData^.FID) + ' FRemainArea=' + IntToStr(FRemainArea)));
//        {$ENDIF}

        Dispose(CachFontData);
        FCacheData.Items[i] := nil;
        Inc(t);
      end;// if
    end;// if
  end;// for i
  FNeedRender := False;
  FNeedRenderAll := False;
  if t > 0 then
  begin
    {$IFDEF UseOutputDebugString}
      OutputDebugString(PAnsiChar('TAsphyreFontCache.RenderNeedUpdateText Dirty=' +
        IntToStr(t)+ ' FRemainArea=' + IntToStr(FRemainArea)));
    {$ENDIF}
    FCacheData.Pack;
  end;// if  
end;

function TAsphyreFontCache.TextExtent(const CacheID: Cardinal): TPoint2px;
var t: integer;
    tmpData: PFontCacheData;
begin
  t := Exist(CacheID);
  if (t >= 0) and Assigned(FDevice) and Assigned(FImage) then
  begin
    tmpData := FCacheData.Items[t];
    Result.x := tmpData^.FRect.Right - tmpData^.FRect.Left;
    Result.y := tmpData^.FRect.Bottom - tmpData^.FRect.Top;
  end;// if
end;

function TAsphyreFontCache.TextHeight(const CacheID: Cardinal): Integer;
begin
  Result := TextExtent(CacheID).y;
end;

function TAsphyreFontCache.TextOut(const CacheID: Cardinal; x, y: Integer;
  const Colors: TColor2): Boolean;
var t: integer;
    tmpData: PFontCacheData;
begin
  Result := False;
  t := Exist(CacheID);
  if (t >= 0) and Assigned(FDevice) and Assigned(FImage) then
  begin
    tmpData := FCacheData.Items[t];
    Result := TextOut(tmpData, x, y, Colors);
//    FDevice.Canvas.UseImage(FImage, 0, tmpData^.FRect);
//    FDevice.Canvas.TexMap(pRect4(Rect(x, y,
//      x + (tmpData^.FRect.Right - tmpData^.FRect.Left),
//      y + (tmpData^.FRect.Bottom - tmpData^.FRect.Top))),
//      cColor4(Colors[0], Colors[0], Colors[1], Colors[1]), fxFullBlend);
    Result := True;
  end;// if
end;

function TAsphyreFontCache.TextOut(const CacheID: Cardinal; x, y: Integer;
  Color: Cardinal): Boolean;
begin
  Result := TextOut(CacheID, x, y, cColor2(Color));
end;

function TAsphyreFontCache.TextRect(const CacheID: Cardinal; const Rect: TRect;
  HorizontalAlign: THorizontalAlign; VerticalAlign: TVerticalAlign;
  const Colors: TColor2): Boolean;
var t: integer;
    tmpData: PFontCacheData;
    tmpRect: TRect;
    x, y: integer;
begin
  Result := False;
  t := Exist(CacheID);
  if (t >= 0) and Assigned(FDevice) and Assigned(FImage) then
  begin
    tmpData := FCacheData.Items[t];
    tmpRect := Rect;
    x := tmpData^.FRect.Right - tmpData^.FRect.Left;
    y := tmpData^.FRect.Bottom - tmpData^.FRect.Top;

    case HorizontalAlign of
      haRight:
       tmpRect.Left := Rect.Right - x;

      haCenter:
       tmpRect.Left := Rect.Left + ((Rect.Right - (Rect.Left + x)) div 2);

      else
        tmpRect.Left := Rect.Left;
    end;// case

    case VerticalAlign of
      vaBottom:
       tmpRect.Top := Rect.Bottom - y;

      vaCenter:
       tmpRect.Top := Rect.Top + ((Rect.Bottom - (Rect.Top + y)) div 2);

      else
        tmpRect.Top := Rect.Left;
    end;// case
    tmpRect.Right := tmpRect.Left + x;
    tmpRect.Bottom := tmpRect.Top + y;

    FDevice.Canvas.UseImage(FImage, 0, tmpData^.FRect);
    FDevice.Canvas.TexMap(pRect4(tmpRect),
      cColor4(Colors[0], Colors[0], Colors[1], Colors[1]), fxFullBlend);
    Result := True;
  end;// if
end;

function TAsphyreFontCache.TextWidth(const CacheID: Cardinal): Integer;
begin
  Result := TextExtent(CacheID).x;
end;

procedure TAsphyreFontCache.UseFontImage(const TexRect: TRect);
begin
  FDevice.Canvas.UseImage(FImage, 0, TexRect);
end;

function TAsphyreFontCache.TextOut(const FontCacheData: PFontCacheData; x,
  y: Integer; const Colors: TColor2): boolean;
begin
  Result := False;
  if (FontCacheData = nil) or (not Assigned(FDevice)) then Exit;
  FDevice.Canvas.UseImage(FImage, 0, FontCacheData^.FRect);
  FDevice.Canvas.TexMap(pRect4(Rect(x, y,
      x + (FontCacheData^.FRect.Right - FontCacheData^.FRect.Left),
      y + (FontCacheData^.FRect.Bottom - FontCacheData^.FRect.Top))),
      cColor4(Colors[0], Colors[0], Colors[1], Colors[1]), fxFullBlend);
  Result := True;
end;

function TAsphyreFontCache.TextOut(const FontCacheData: PFontCacheData; x,
  y: Integer; Color: Cardinal): boolean;
begin
  Result := TextOut(FontCacheData, x, y, cColor2(Color));
end;

function TAsphyreFontCache.TextRect(const FontCacheData: PFontCacheData;
  const Rect: TRect; HorizontalAlign: THorizontalAlign;
  VerticalAlign: TVerticalAlign; const Colors: TColor2): Boolean;
var
    tmpRect: TRect;
    x, y: integer;
begin
  Result := False;
  if (FontCacheData = nil) or (not Assigned(FDevice)) then Exit;
  tmpRect := Rect;
  x := FontCacheData^.FRect.Right - FontCacheData^.FRect.Left;
  y := FontCacheData^.FRect.Bottom - FontCacheData^.FRect.Top;

  case HorizontalAlign of
    haRight:
     tmpRect.Left := Rect.Right - x;

    haCenter:
     tmpRect.Left := Rect.Left + ((Rect.Right - (Rect.Left + x)) div 2);

    else
      tmpRect.Left := Rect.Left;
  end;// case

  case VerticalAlign of
    vaBottom:
     tmpRect.Top := Rect.Bottom - y;

    vaCenter:
     tmpRect.Top := Rect.Top + ((Rect.Bottom - (Rect.Top + y)) div 2);

    else
      tmpRect.Top := Rect.Left;
  end;// case
  tmpRect.Right := tmpRect.Left + x;
  tmpRect.Bottom := tmpRect.Top + y;

  FDevice.Canvas.UseImage(FImage, 0, FontCacheData^.FRect);
  FDevice.Canvas.TexMap(pRect4(tmpRect),
    cColor4(Colors[0], Colors[0], Colors[1], Colors[1]), fxFullBlend);
  Result := True;
end;

function TAsphyreFontCache.TextExtent(
  const FontCacheData: PFontCacheData): TPoint2px;
begin

  if (FontCacheData = nil) or (not Assigned(FDevice)) then Exit;
  Result.x := FontCacheData^.FRect.Right - FontCacheData^.FRect.Left;
  Result.y := FontCacheData^.FRect.Bottom - FontCacheData^.FRect.Top;
end;

function TAsphyreFontCache.TextHeight(
  const FontCacheData: PFontCacheData): Integer;
begin
  Result := TextExtent(FontCacheData).y;
end;

function TAsphyreFontCache.TextWidth(
  const FontCacheData: PFontCacheData): Integer;
begin
  Result := TextExtent(FontCacheData).x;
end;

end.

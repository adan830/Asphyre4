{******************************************************************************}
{��Ԫ���ƣ�GuiCnWebForms.pas                                                   }
{����������ʵ��֧��WideString��GuiForm (�ο�GuiForms.pas)                      }
{������Ա��Piao40993470 (xbpiao@msn.com)                                       }
{����ʱ�䣺2007-07-07 16:27                                                    }
{ʹ��˵����                                                                    }
{�޸���ʷ��
          Add 2007-7-26 11:23:59 by Xiebin ����Щ��������Ϊ������չӦ��
                                                                               }
{                                                                              }
{******************************************************************************}

unit GuiCnWebForms;

interface

uses
  Types, Vectors2px, AsphyreTypes, GuiShapeRep, GuiTypes, GuiUtils,
  GuiObjects, GuiControls, GuiSkins;


type
  
//  TOnMouseEvent = procedure (const Pos: TPoint2px; Event: TMouseEventType;
//      Button: TMouseButtonType; SpecialKeys: TSpecialKeyState) of object;
  TOnFindCtrlAtEvent = procedure (const Point: TPoint2px;
    var FctCtrl: TGuiControl) of object;

  TGuiCnWebForm = class(TGuiControl)
  private
    FDragShape : string;
    FDragClick  : TPoint2px;
    FDragInit   : TPoint2px;
    FDragging: boolean;

    FCaption: WideString;
    FCaptRect: TRect;
    FCaptColor: TColor2;
    FCaptFont: string;
    FCaptionFontColor: Cardinal;

    FAlphaValue: Byte;
    FCaptVAlign: TVerticalAlign;
    FCaptHAlign: THorizontalAlign;

    // ��չ����
    FExtControlName: string;
    FExtData: Pointer;
    FExtRect: TRect;
    FExtParams: string;
    FExtTag: integer;
    FExtShape: string;            // �����������ѡ�е�
    FExtMiniStyle: string;        // ��С��ʱ�Ľ�����

    FFontCacheID: Cardinal;
    FOnDrawEvent: TOnDrawEvent;
    FOnFindCtrlAtEvent: TOnFindCtrlAtEvent;

    procedure DrawText(const DrawPos: TPoint2px);
    procedure SetCaption(const Value: WideString);
    function HasMouseOverChild(): boolean;
  protected
    function GetSkinDrawType(): TSkinDrawType; override;
    procedure DoMouseEvent(const Pos: TPoint2px; Event: TMouseEventType;
      Button: TMouseButtonType; SpecialKeys: TSpecialKeyState); override;
    procedure DoDraw(const DrawPos: TPoint2px); override;

    procedure DoDescribe(); override;
    procedure WriteProperty(Code: Cardinal; Source: Pointer); override;
  public
    constructor Create(AOwner: TGuiObject); override;
    destructor Destroy(); override;

    function FindCtrlAt(const Point: TPoint2px): TGuiControl; override;

    property DragShape : string read FDragShape write FDragShape;
    { Caption ��� }
    property Caption   : WideString read FCaption write SetCaption;
    property CaptRect  : TRect read FCaptRect write FCaptRect;
    property CaptColor : TColor2 read FCaptColor write FCaptColor;
    property CaptFont  : string read FCaptFont write FCaptFont;
    property CaptHAlign: THorizontalAlign read FCaptHAlign write FCaptHAlign;
    property CaptVAlign: TVerticalAlign read FCaptVAlign write FCaptVAlign;
    
    property AlphaValue: Byte read FAlphaValue write FAlphaValue;

    // ��չ����
    property ExtControlName: string read FExtControlName;
    property ExtData: Pointer read FExtData write FExtData;
    property ExtRect: TRect read FExtRect write FExtRect;
    property ExtParams: string read FExtParams write FExtParams;
    property ExtTag: integer read FExtTag write FExtTag;
    property ExtShape: string read FExtShape write FExtShape;
    property ExtMiniStyle: string read FExtMiniStyle write FExtMiniStyle;

    property OnFindCtrlAtEvent: TOnFindCtrlAtEvent read FOnFindCtrlAtEvent write FOnFindCtrlAtEvent;

    procedure SetFocus(); override;
  end;


implementation

uses AsphyreFontCache, GuiCnForms;

const
  cPropBase = $1000;

{ TGuiCnWebForm }

constructor TGuiCnWebForm.Create(AOwner: TGuiObject);
begin
  inherited;
  FDragging := False;
  FCaptHAlign := haCenter;
  FCaptVAlign := vaCenter;
  FAlphaValue := 255;
  FCaptionFontColor := $FF000000;
  FExtData := nil;
  FOnDrawEvent := nil;
end;

destructor TGuiCnWebForm.Destroy;
begin
  if (FFontCacheID > 0) and Assigned(GuiFontCache) then
    GuiFontCache.Dirty(FFontCacheID);
  inherited;
end;

procedure TGuiCnWebForm.DoDescribe;
begin
  inherited;
  Describe(cPropBase + $0, 'Caption',    gdtWideString);
  Describe(cPropBase + $1, 'CaptFont',   gdtString);
  Describe(cPropBase + $2, 'CaptColor',  gdtColor2);
  Describe(cPropBase + $3, 'CaptRect',   gdtRect);
  Describe(cPropBase + $4, 'CaptHAlign', gdtHAlign);
  Describe(cPropBase + $5, 'CaptVAlign', gdtVAlign);
  Describe(cPropBase + $6, 'DragShape',  gdtString);
  Describe(cPropBase + $7, 'AlphaValue',  gdtCardinal);
  Describe(cPropBase + $8, 'CaptionFontColor',  gdtColor);

  { Ϊ���⴦����� }
  Describe(cPropBase + $9, 'ExtControlName',  gdtString);
  Describe(cPropBase + $A, 'ExtRect',         gdtRect);
  Describe(cPropBase + $B, 'ExtParams',       gdtString);
  Describe(cPropBase + $C, 'ExtShape',        gdtString);
  Describe(cPropBase + $D, 'ExtMiniStyle',    gdtString);

end;

procedure TGuiCnWebForm.DoDraw(const DrawPos: TPoint2px);
begin
//  if Assigned(FOnDrawEvent) then
//    FOnDrawEvent(DrawPos);// ��Ӧ�ⲿ�����¼�

  if (FCaptFont <> '')and(FCaption <> '') then DrawText(DrawPos);
  inherited;
end;

procedure TGuiCnWebForm.DoMouseEvent(const Pos: TPoint2px; Event: TMouseEventType;
  Button: TMouseButtonType; SpecialKeys: TSpecialKeyState);
begin
  if (Event = metDown)and(Button = mbtLeft)and
    (PointInside(FDragShape, Pos))and(not FDragging) then
  begin
    FDragInit := Origin;
    FDragClick:= Pos;
    FDragging := True;
  end;

  if (FDragging) and (Button = mbtLeft) and (Event = metUp) then
    FDragging:= False;
    
  if (FDragging)and(Event = metMove) then
    Origin:= FDragInit + Pos - FDragClick;
end;

procedure TGuiCnWebForm.DrawText(const DrawPos: TPoint2px);
begin
  if GuiFontCache = nil then Exit;
  if not GuiFontCache.TextRect(FFontCacheID, MoveRect(FCaptRect, DrawPos),
      FCaptHAlign, FCaptVAlign, FCaptColor) then
  begin
    FFontCacheID := GuiFontCache.GetFontCacheID(FCaptFont, FCaption, FCaptionFontColor);
    GuiFontCache.TextRect(FFontCacheID, MoveRect(FCaptRect, DrawPos),
      FCaptHAlign, FCaptVAlign, FCaptColor);
  end;// if
end;

function TGuiCnWebForm.FindCtrlAt(const Point: TPoint2px): TGuiControl;
begin
  Result := inherited FindCtrlAt(Point);
  if (Result <> nil) and Assigned(FOnFindCtrlAtEvent) then
  begin{ �����¼����������ѡ����� }
    FOnFindCtrlAtEvent(Point, Result);
  end;// if
end;

function TGuiCnWebForm.GetSkinDrawType: TSkinDrawType;
begin
 Result:= sdtNormal;

 if (not Enabled) then
   Result:= sdtDisabled
 else
 begin
 if (Focused) then
   Result:= sdtFocused
 else
   if HasMouseOverChild() then Result:= sdtOver;
 end;// if

// if (FMouseDown) then Result:= sdtDown;
end;

function TGuiCnWebForm.HasMouseOverChild: boolean;
var i: integer;
    Temp : TGuiControl;
begin{ �����MouseOver���� }
  Result := MouseOver;
  if Result then Exit;
  for i := 0 to ChildCount - 1 do
  begin
    if (Child[i] is TGuiControl) then
    begin
      Temp := TGuiControl(Child[i]);
      if Temp.MouseOver then
      begin
        Result := True;
        Break;
      end;// if
    end;// if
  end;// for i

end;

procedure TGuiCnWebForm.SetCaption(const Value: WideString);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    // ���ڵĻᱻ�Զ�����
    if (FFontCacheID > 0) then
      GuiFontCache.Dirty(FFontCacheID);
    FFontCacheID := 0;
  end;// if
end;

procedure TGuiCnWebForm.SetFocus;
begin
  inherited;
  BringToFront();
end;

procedure TGuiCnWebForm.WriteProperty(Code: Cardinal; Source: Pointer);
begin
  case Code of
    cPropBase + $0:
      FCaption:= PWideChar(Source);

    cPropBase + $1:
      FCaptFont:= PChar(Source);

    cPropBase + $2:
      FCaptColor:= PColor2(Source)^;

    cPropBase + $3:
      FCaptRect:= PRect(Source)^;

    cPropBase + $4:
      FCaptHAlign:= THorizontalAlign(Source^);

    cPropBase + $5:
      FCaptVAlign:= TVerticalAlign(Source^);

    cPropBase + $6:
      FDragShape:= PChar(Source);

    cPropBase + $7:
      if PCardinal(Source)^ > 255 then
        FAlphaValue := 255
      else
        FAlphaValue := PCardinal(Source)^;
        
    cPropBase + $8:
       FCaptionFontColor := PCardinal(Source)^;

  { Ϊ���⴦����� }
    cPropBase + $9:
      FExtControlName := PChar(Source);     // ��Ƕ�ؼ����Ʊ�ʶ
    cPropBase + $A:
      FExtRect := PRect(Source)^;           // ����λ��
    cPropBase + $B:
      FExtParams := PChar(Source);          // ��ز���
    cPropBase + $C:
      FExtShape := PChar(Source);           // �����������
    cPropBase + $D:
      FExtMiniStyle := PChar(Source);       // ��С��ʱ����Ĳ���
    else inherited WriteProperty(Code, Source);
  end;// case

end;

end.

{******************************************************************************}
{��Ԫ���ƣ�GuiCnEdit.pas                                                       }
{����������                                                                    }
{������Ա��Piao40993470 (xbpiao@msn.com)                                       }
{����ʱ�䣺2007-07-08 22:58                                                    }
{ʹ��˵����                                                                    }
{�޸���ʷ��                                                                    }
{          ע���ı�������TAsphyreFontCache�����Ļ������������Ƽ�ʹ���������
         2007-07-22 15:49 ������ɣ�û�д��������������Сʱ����ʾ����
         2007-07-22 16:23 todo �Ƿ����µ�������ʱ��ʹ�ñ༭���С�������أ�
                                                                               }
{******************************************************************************}

unit GuiCnEdit;

interface

uses
  Windows, SysUtils, Types, Classes, Clipbrd, Vectors2px, HelperSets,
  AsphyreTypes,
  AsphyreUtils, AsphyreEffects, AsphyreFonts, GuiSkins, GuiTypes, GuiUtils,
  GuiShapeRep, GuiObjects, GuiControls,
  TntClipBrd{ ʹ��֧��Unicode��ճ�� };

type

  TEditKeyEvent = procedure(Sender: TObject; var Key: Integer;
    Event: TKeyEventType; SpecialKeys: TSpecialKeyState) of object;

type
  TGuiCnEdit = class(TGuiControl)
  private
    FTextOpt : TFontOptions;
    FTextFont: string;
    FTextFontColor: Cardinal;
    FTextRect: TRect;
    FText    : WideString;
    FOnChange: TNotifyEvent;
    FMaxLength: Integer;
    FReadOnly: Boolean;
    FSideSpace: Integer;
    FCaretPos: Integer;

    FScrollPos: Integer;
    FCaretColor: Cardinal;
    FCaretAlpha: Integer;
    FSelectColor: Cardinal;
    FSelectAlpha: Integer;
    FTextCol: TGuiFontCol;
    FFontCacheID: Cardinal;
    FSelectedPos: integer;
    FMaxScrollPos: Integer;   // ��ǰ������ƶ��Ҳ���Ҫ����λ�õ�����

    FFontTexRect: TRect;     // ��Ҫ���Ƶ��ı��������꣨��AsphyreFontCache�У�
    FDrawTextRect: TRect;    // ��ʵ��������

    FDrawScrollPos: Integer; // ��ǰ�Ѿ����Ƶ��ı�λ��
    FPrevDrawPos: TPoint2px; // �ϴλ���ʱ��λ��
    FTextLen: integer;       // �ı�����ÿ�λ������¼���
    FLastLeftTexPos: Integer;// ���һ�μ������������
    FTextFitWidth: Integer;  // �ʺ���ʾ���ı����
    FShowWidth: Integer;     // ��ʾ�Ŀ��
    FShowHeight: Integer;    // ��ʾ�ĸ߶�
    FCaretRect: TRect;           // ���λ�õ�Rect
    FTextWidth: Integer;
    FTextHeight: integer;
    FFontTexRight: Integer; // �����������������ڼ��Խ������
    FLastCaretFix: integer; // �����λ��������

    FHoverCaret: TRect;

    { ���ֽ����� }
    FKeyByteCount: integer;
    FInputStr: Cardinal;
    FInputAnsiStr: string;
    FIsDoubleByte: Boolean;
    FIsUnicode: boolean;
    FLastMouseDownTick: Cardinal;


    // �Ƿ���TIntegerList?  in HelperSets.pas
    FCharWidth: TIntegerList; // ���ڼ�¼ÿ���ַ����

    FOnEditKeyEvent: TEditKeyEvent;
    procedure SetText(const Value: WideString);
    procedure SetMaxLength(const Value: Integer);
    procedure SetScrollPos(const Value: Integer);
    function GetTextOpt: PFontOptions;
    function UpdateTextRects(): Boolean;

    function ScrollRightCaretPos(ACaretPos: integer): Integer;
    function CharAtPos(const Pos: TPoint2px): integer;
  protected
    procedure DoDestroy(); override;
    procedure DoDraw(const DrawPos: TPoint2px); override;
    procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
      SpecialKeys: TSpecialKeyState); override;
    procedure DoMouseEvent(const Pos: TPoint2px; Event: TMouseEventType;
      Button: TMouseButtonType; SpecialKeys: TSpecialKeyState); override;

    procedure DoDescribe(); override;
    procedure WriteProperty(Code: Cardinal; Source: Pointer); override;

    function GetSkinDrawType(): TSkinDrawType; override;

  public
    constructor Create(AOwner: TGuiObject); override;
    destructor Destroy; override;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Text: WideString read FText write SetText;
    property ReadOnly : Boolean read FReadOnly write FReadOnly;
    property MaxLength: Integer read FMaxLength write SetMaxLength;

    property SideSpace: Integer read FSideSpace write FSideSpace;
    property ScrollPos: Integer read FScrollPos write SetScrollPos;
    property CaretPos : Integer read FCaretPos write FCaretPos;

    property CaretColor : Cardinal read FCaretColor write FCaretColor;
    property CaretAlpha : Integer read FCaretAlpha write FCaretAlpha;
    property SelectColor: Cardinal read FSelectColor write FSelectColor;
    property SelectAlpha: Integer read FSelectAlpha write FSelectAlpha;

    property TextOpt : PFontOptions read GetTextOpt;
    property TextCol : TGuiFontCol read FTextCol;
    property TextFont: string read FTextFont write FTextFont;
    property TextRect: TRect read FTextRect write FTextRect;

    property MaxScrollPos: integer read FMaxScrollPos;
    property OnEditKeyEvent: TEditKeyEvent read FOnEditKeyEvent write FOnEditKeyEvent;
  published

  end;

implementation

uses AsphyreFontCache, AsphyreSystemFonts;

const
  cPropBase = $1000;
  { ���ڼ��ո�ò������ֿ���� }
  csCheckChar = 'a';
  cCaretDrawSpeed = 1.0; // �����˸�ٶ�
  cMouseDownDelayScroll = 700; // �������800ms���Զ�����

{ TGuiCnEdit }

function TGuiCnEdit.CharAtPos(const Pos: TPoint2px): integer;
var
  i: integer;
  tmpRect: TRect;
begin{ ʹ��������� }
  Result := -1;
  tmpRect.Top := FDrawTextRect.Top;
  tmpRect.Bottom := FDrawTextRect.Bottom;
  tmpRect.Left := 0 - FLastCaretFix;
  tmpRect.Right := FCharWidth[0] - FLastCaretFix;
  tmpRect.Left := tmpRect.Left + FDrawTextRect.Left;
  tmpRect.Right := tmpRect.Right + FDrawTextRect.Left;
  if PointInRect(Pos, tmpRect) then
  begin
    FHoverCaret := tmpRect;
    Result := FScrollPos;
    Exit;
  end;// if

  for i := 1 to FCharWidth.Count - 1 do
  begin
    tmpRect.Left := FCharWidth[i - 1] - FLastCaretFix;
    tmpRect.Right := FCharWidth[i] - FLastCaretFix;
    tmpRect.Left := tmpRect.Left + FDrawTextRect.Left;
    tmpRect.Right := tmpRect.Right + FDrawTextRect.Left;

    if PointInRect(Pos, tmpRect) then
    begin
      FHoverCaret := tmpRect;
      Result := FScrollPos + i;
      Break;
    end;// if
  end;// for i
end;

constructor TGuiCnEdit.Create(AOwner: TGuiObject);
begin
  inherited;
  FTextCol   := TGuiFontCol.Create();

  FCharWidth := TIntegerList.Create;

  FSideSpace := 2;
  FScrollPos := 0;
  FMaxScrollPos := 0;
  FReadOnly  := False;
  FMaxLength := 0;

  FSelectedPos := -1;
  FCaretAlpha := 96;
  FSelectAlpha:= 32;

  FText:= '';
  FTextFontColor := $FF000000;
  FTextOpt.Reset();

  FTextLen := 0;
  FLastLeftTexPos := 0;
  { ���ֽ����� }
  FKeyByteCount := 0;
  FInputStr := 0;
  FInputAnsiStr := '';
  FIsDoubleByte := False;
  FOnEditKeyEvent := nil;
  FIsUnicode := IsWindowUnicode(GuiDevice.Params.hDeviceWindow);
end;

destructor TGuiCnEdit.Destroy;
begin
  FreeAndNil(FCharWidth);
  inherited;
end;

procedure TGuiCnEdit.DoDescribe;
begin
  inherited;
  Describe(cPropBase + $0, 'TextOpt',     gdtFontOpt);
  Describe(cPropBase + $1, 'TextCol',     gdtFontColor);
  Describe(cPropBase + $2, 'TextFont',    gdtString);
  Describe(cPropBase + $3, 'TextRect',    gdtRect);
  Describe(cPropBase + $4, 'SideSpace',   gdtInteger);
  Describe(cPropBase + $5, 'ReadOnly',    gdtBoolean);
  Describe(cPropBase + $6, 'MaxLength',   gdtInteger);
  Describe(cPropBase + $7, 'CaretColor',  gdtColor);
  Describe(cPropBase + $8, 'CaretAlpha',  gdtInteger);
  Describe(cPropBase + $9, 'SelectColor', gdtColor);
  Describe(cPropBase + $A, 'SelectAlpha', gdtInteger);
  Describe(cPropBase + $B, 'Text',        gdtWideString);
  Describe(cPropBase + $C, 'TextFontColor', gdtColor);

end;

procedure TGuiCnEdit.DoDestroy;
begin
  if (FFontCacheID > 0) and Assigned(GuiFontCache) then
    GuiFontCache.Dirty(FFontCacheID);
  FTextCol.Free;
  inherited;
end;

procedure TGuiCnEdit.DoDraw(const DrawPos: TPoint2px);
var ClientTextRect: TRect;
  Theta: Real;
  Alpha: Integer;
  PrevClipRect: TRect;
begin
  FPrevDrawPos := DrawPos;
  PrevClipRect:= GuiCanvas.ClipRect;
  GuiCanvas.ClipRect:= MoveRect(FTextRect, DrawPos);

  if UpdateTextRects() then
  begin
    ClientTextRect := MoveRect(FDrawTextRect, DrawPos);
    GuiFontCache.UseFontImage(FFontTexRect);
    GuiCanvas.TexMap(pRect4(ClientTextRect),
      cColor4(FTextFontColor), fxFullBlend);
  end;// if

  if Focused and ((FCaretRect.Right - FCaretRect.Left) > 0) then
  begin { ���ƹ�� }
    Theta:= (Sin(GetTickCount() * cCaretDrawSpeed / 100.0) + 1.0) * 0.5;
    Theta:= 0.5 + (Theta * 0.5);
    Alpha:= Round(Theta * FCaretAlpha);

    ClientTextRect := MoveRect(FCaretRect, DrawPos);
    GuiCanvas.FillQuad(pRect4(ClientTextRect), cColorAlpha4(FCaretColor,
      Alpha), fxuBlend);
    GuiCanvas.WireQuadHw(pRect4(ClientTextRect), cColorAlpha4(FCaretColor,
      Alpha), fxuBlend);


    if ((FHoverCaret.Right - FHoverCaret.Left) > 0) then
    begin

      ClientTextRect := MoveRect(FHoverCaret, DrawPos);
      GuiCanvas.FillQuad(pRect4(ClientTextRect), cColorAlpha4(FCaretColor,
        Alpha), fxuBlend);
      GuiCanvas.WireQuadHw(pRect4(ClientTextRect), cColorAlpha4(FCaretColor,
        Alpha), fxuBlend);
    end;// if

  end;// if
  
  GuiCanvas.ClipRect:= PrevClipRect;
end;

procedure TGuiCnEdit.DoKeyEvent(Key: Integer; Event: TKeyEventType;
  SpecialKeys: TSpecialKeyState);
var
  Ch: Char;
  tmpWideStr: WideString;
begin

  if Assigned(FOnEditKeyEvent) then
    FOnEditKeyEvent(Self, Key, Event, SpecialKeys);

  if Key = 0 then Exit;

  case Event of
    ketDown:
      begin
        case Key of
          VK_RIGHT:
            begin
              if FCaretPos <= FTextLen then
                Inc(FCaretPos);
            end;// VK_RIGHT
          VK_LEFT:
            begin
              if FCaretPos > 1 then
                Dec(FCaretPos);
            end;// VK_LEFT
          VK_HOME:
            begin
              FCaretPos := 1;
              FScrollPos := 1;
              FMaxScrollPos := 1;
            end;// VK_HOME
          VK_END:
            begin
              if FMaxScrollPos = (FTextLen + 1) then
                FCaretPos := FMaxScrollPos
              else
              begin // ������ʵ�λ��
                FMaxScrollPos := (FTextLen + 1);
                FCaretPos := FMaxScrollPos;
                FScrollPos := FMaxScrollPos;
              end;// if
            end;// VK_END
          VK_BACK:
            begin
              if (not FReadOnly) and (FTextLen > 0) and (FCaretPos > 1) then
              begin
                Dec(FCaretPos);
                Delete(FText, FCaretPos, 1);
                { �ͷžɵ����� }
                if (FFontCacheID > 0) and Assigned(GuiFontCache) then
                begin
                  GuiFontCache.Dirty(FFontCacheID);
                  FFontCacheID := 0;
                end;// if
                if (FCaretPos <= FScrollPos) and
                  (FCaretPos = (Length(FText) + 1)) then
                begin // ����Ҫ���¼���ʱ�� ������ʵ�λ��
                  FMaxScrollPos := (Length(FText) + 1);
                  FCaretPos := FMaxScrollPos;
                  FScrollPos := FMaxScrollPos;
                end;// if

                if (Assigned(FOnChange)) then FOnChange(Self);
              end;// if
            end;// VK_BACK
          VK_DELETE:
            begin
              if (not FReadOnly) and (FTextLen > 0) then
              begin
                Delete(FText, FCaretPos, 1);
                { �ͷžɵ����� }
                if (FFontCacheID > 0) and Assigned(GuiFontCache) then
                begin
                  GuiFontCache.Dirty(FFontCacheID);
                  FFontCacheID := 0;
                end;// if
                if (Assigned(FOnChange)) then FOnChange(Self);
              end;// if
            end;// VK_DELETE
        end;// case
        if ((Key = Ord('v')) or (Key = Ord('V'))) and
          (SpecialKeys = [sksCtrl]) then
        begin
          tmpWideStr := TntClipboard.AsText;
          if Length(tmpWideStr) > 0 then
          begin
            if (FText = '') or (FCaretPos > Length(FText)) then
            begin
              FText:= FText + tmpWideStr;
              FScrollPos := ScrollRightCaretPos(Length(FText) + 1);
              FCaretPos := FTextLen + 1;
            end
            else
            begin
              Insert(tmpWideStr, FText, FCaretPos);
              FScrollPos := ScrollRightCaretPos(FCaretPos + Length(tmpWideStr));
              FCaretPos := FCaretPos + Length(tmpWideStr);
            end;// if

            { �ͷžɵ����� }
            if (FFontCacheID > 0) and Assigned(GuiFontCache) then
            begin
              GuiFontCache.Dirty(FFontCacheID);
              FFontCacheID := 0;
            end;// if
            if (Assigned(FOnChange)) then FOnChange(Self);

          end;// if
          Exit;
        end;// if
        
      end;// ketDown
    ketPress:
      begin
        if FReadOnly then Exit; // ֻ�����˳�

        if (not FIsDoubleByte) and (Key < 32) then Exit;
        if Key = 255 then
        begin{ ��Unicodeģʽ�Ļ������±�֤������ȷ }
          FIsDoubleByte := True;
          Exit;
        end;// if
        Ch := Char(Key);

        if FIsDoubleByte or IsDBCSLeadByte(Key) then
        begin{ ���ֽ� }
          FIsDoubleByte := True;
          Inc(FKeyByteCount);
          case FKeyByteCount of
            1:
              FInputStr := Byte(ch) shl 8;
            2:
              FInputStr := FInputStr + Byte(ch);
          end;// case;
          FInputAnsiStr := FInputAnsiStr + ch;
          if FKeyByteCount < 2 then
            Exit;
        end
        else
        begin
          FInputStr := Byte(Ch);
          FInputAnsiStr := Ch;
        end;// if

        if (FText = '') or (FCaretPos > Length(FText)) then
        begin
          if FIsUnicode then
            FText:= FText + WideChar(FInputStr)
          else
            FText:= FText + FInputAnsiStr;

          FCaretPos := Length(FText) + 1;
          FMaxScrollPos := FCaretPos;
        end
        else
        begin
          if FIsUnicode then
            Insert(WideChar(FInputStr), FText, FCaretPos)
          else
            Insert(FInputAnsiStr, FText, FCaretPos);

          Inc(FCaretPos);
        end;// if
        FKeyByteCount := 0;
        FInputStr := 0;
        FIsDoubleByte := False;
        FInputAnsiStr := '';
        //FIsDoubleByte := False;
        { �ͷžɵ����� }
        if (FFontCacheID > 0) and Assigned(GuiFontCache) then
        begin
          GuiFontCache.Dirty(FFontCacheID);
          FFontCacheID := 0;
        end;// if
        if (Assigned(FOnChange)) then FOnChange(Self);
      end;// ketPress
  end;// case
end;

procedure TGuiCnEdit.DoMouseEvent(const Pos: TPoint2px; Event: TMouseEventType;
  Button: TMouseButtonType; SpecialKeys: TSpecialKeyState);
var
  LocalPos: TPoint2px;
  t: integer;
  tmpRect: TRect;
begin

  LocalPos := ScreenToLocal(Pos);
  FHoverCaret := Rect(0, 0, 0, 0);
  if (FCharWidth.Count = 0) or
     (not PointInRect(LocalPos, FDrawTextRect)) then Exit;
  t := CharAtPos(LocalPos);


  if (t > 0) and (Button = mbtLeft) then
  begin
    if (Event = metUp) and (FCaretPos >= FScrollPos) and (FCaretPos <= FMaxScrollPos) then
      FCaretPos := t;
    if (Event = metDown) then
    begin
      tmpRect := FDrawTextRect;
      tmpRect.Right := tmpRect.Left + 3;
      if (t = FScrollPos) and (t > 1) and (PointInRect(LocalPos, tmpRect)) then
      begin
        Dec(t);
        FCaretPos := t;
      end;// if
      tmpRect := FDrawTextRect;
      tmpRect.Left := tmpRect.Right - 3;
      if (t = FMaxScrollPos) and (t <= FTextLen) and (PointInRect(LocalPos, tmpRect)) then
      begin
        Inc(t);
        FCaretPos := t;
      end;// if

      if Assigned(Self.OnClick) then
        Self.OnClick(Self);

    end;// if
  end;// if
end;

function TGuiCnEdit.GetSkinDrawType: TSkinDrawType;
begin
  Result:= sdtNormal;

  if (MouseOver) then Result:= sdtOver;
  if (MouseDown) then Result:= sdtDown;
  if (Focused) then Result:= sdtFocused;
  if (not Enabled) then Result:= sdtDisabled;
end;

function TGuiCnEdit.GetTextOpt: PFontOptions;
begin

end;

function TGuiCnEdit.ScrollRightCaretPos(ACaretPos: integer): Integer;
var TexFitWidth, i, t, tmpScrPos: Integer;
    Font: TAsphyreSystemFont;
begin{ �����λ�ü����ʺϵ�����λ�� }
  Result := FScrollPos;
  FTextLen := Length(FText);
  if (ACaretPos > (FTextLen + 1)) or (ACaretPos <= 0) then exit;

  Font := GuiDevice.SysFonts.Font[FTextFont];
  if Font = nil then Exit; // �Ҳ����ʺϵ������˳�
  if ACaretPos = (FTextLen + 1) then
  begin
    TexFitWidth := Font.TextWidth(FText[ACaretPos]);
    ACaretPos := FTextLen;
  end
  else
    TexFitWidth := 0;

  tmpScrPos := 0;
  for i := ACaretPos downto 1 do
  begin
    t := Font.TextWidth(FText[i]);
    if t = 0 then
    begin{ �����ո�ͱȽ�������ֻ����ʱ�����㶨 }
      t := Font.TextWidth(FText[i] + csCheckChar);
      t := t - Font.TextWidth(csCheckChar);
    end;// if
    TexFitWidth := TexFitWidth + t;
    Inc(tmpScrPos);
    if TexFitWidth > FShowWidth then Break;
  end;// for i
  if ((FCaretPos - FScrollPos) > tmpScrPos) or (ACaretPos > (FMaxScrollPos + 1)) then
    Result := ACaretPos - tmpScrPos;
end;

procedure TGuiCnEdit.SetMaxLength(const Value: Integer);
begin
  FMaxLength := Value;
end;

procedure TGuiCnEdit.SetScrollPos(const Value: Integer);
begin
  FScrollPos := Value;
end;

procedure TGuiCnEdit.SetText(const Value: WideString);
begin
  FText := Value;
  { �ͷžɵ����� }
  if (FFontCacheID > 0) and Assigned(GuiFontCache) then
  begin
    GuiFontCache.Dirty(FFontCacheID);
    FFontCacheID := 0;
  end;// if
  { ʹ�����ػ� }
  FCaretPos := 1;
  FScrollPos := 1;
  FMaxScrollPos := 1;
end;

function TGuiCnEdit.UpdateTextRects: Boolean;
var tmpLetfPosStr: WideString;
    FontCacheData: PFontCacheData;
    Font: TAsphyreSystemFont;
    i, t, FDrawFixTop, LeftTextFitWidth: integer;
begin
  Result := False;
  { ����Ƿ���Ҫ���¼���λ�� }
  if (FFontCacheID > 0) and (FScrollPos < FMaxScrollPos) and
    (FScrollPos <= FCaretPos) and (FCaretPos <= FMaxScrollPos) then
  begin{ ����Ҫ���¼�������������ݣ�ֻ��Ҫ��������������뼴�� }
    { �������뻹������ }
    if (FCaretPos = FMaxScrollPos) and (FTextFitWidth > FShowWidth) then
    begin//����
      FFontTexRect.Left := FLastLeftTexPos; // ����Ϊ����λ��
      FFontTexRect.Right := FFontTexRect.Left + FTextFitWidth;
      FFontTexRect.Left := FFontTexRect.Right - FShowWidth;
      t := 0;
      if (FFontTexRect.Right > FFontTexRight) then
      begin
        t := FFontTexRect.Right - FFontTexRight;
        FFontTexRect.Right := FFontTexRight;
      end;// if
      FDrawTextRect.Right := FDrawTextRect.Left + FShowWidth - t;
      { �������λ���� }
      FLastCaretFix := FTextFitWidth - FShowWidth;
    end;

    if (FCaretPos = FScrollPos) then 
    begin// ����
      FFontTexRect.Left := FLastLeftTexPos; // ����Ϊ����λ��
      LeftTextFitWidth := FTextFitWidth;
      if FTextFitWidth > FShowWidth then
        LeftTextFitWidth := FShowWidth;
      FFontTexRect.Right := FFontTexRect.Left + LeftTextFitWidth;

      t := 0;
      if (FFontTexRect.Right > FFontTexRight) then
      begin
        t := FFontTexRect.Right - FFontTexRight;
        FFontTexRect.Right := FFontTexRight;
      end;// if
      FDrawTextRect.Right := FDrawTextRect.Left + LeftTextFitWidth - t;
      FLastCaretFix := 0;
    end;// if

    { ������λ�� }
    t := FCaretPos - FScrollPos - 1;
    if (t < 0) or (t >= FCharWidth.Count) then
    begin
      FCaretRect.Left := 0;
    end
    else
      FCaretRect.Left := FCharWidth[t];
    inc(t);
    if (t < 0) or (t >= FCharWidth.Count) then
      t := 0;
    FCaretRect.Right := FCharWidth[t];
    FCaretRect.Left := FCaretRect.Left - FLastCaretFix;
    FCaretRect.Right := FCaretRect.Right - FLastCaretFix;
    FCaretRect.Left := FCaretRect.Left + FDrawTextRect.Left;
    FCaretRect.Right := FCaretRect.Right + FDrawTextRect.Left;

    Result := True;
    Exit;
  end;// if

  FTextLen := Length(FText);
  if FTextLen = 0 then
  begin { ���ı�����ʾ�ͺ� }
    FScrollPos := 0;
    FMaxScrollPos := 0;
    FCaretPos := 0;
    FCharWidth.Clear;
    FDrawTextRect := FTextRect;
    InflateRect(FDrawTextRect, -FSideSpace * 2, -FSideSpace * 2);// �ճ��߿�λ��

    FCaretRect.Top := FDrawTextRect.Top;
    FCaretRect.Bottom := FDrawTextRect.Bottom;
    FCaretRect.Left := FDrawTextRect.Left + 1;
    FCaretRect.Right := FCaretRect.Left + 8;
    Exit;
  end;// if
  { ��ȡ������������ }
  FontCacheData := GuiFontCache.CacheData(FFontCacheID);
  if FontCacheData = nil then
  begin
    FFontCacheID := GuiFontCache.GetFontCacheID(FTextFont, FText, FTextFontColor);
    FontCacheData := GuiFontCache.CacheData(FFontCacheID);
    FDrawScrollPos := -1;
  end;// if
  if FontCacheData = nil then
    Exit;// ��ȡ�������建��ʱ�˳�
  FontCacheData^.FSafeguard := True; // �������Զ����ջ���
  Font := GuiDevice.SysFonts.Items[FontCacheData^.FFontIndex];
  if Font = nil then
    Exit;// ��ȡ������Ϣʧ��ʱ�˳�

  FDrawTextRect := FTextRect;
  InflateRect(FDrawTextRect, -FSideSpace * 2, -FSideSpace * 2);// �ճ��߿�λ��

  FShowWidth := FDrawTextRect.Right - FDrawTextRect.Left;
  FShowHeight := FDrawTextRect.Bottom - FDrawTextRect.Top;

  FFontTexRect := FontCacheData^.FRect;
  FTextWidth := FFontTexRect.Right - FFontTexRect.Left;
  FTextHeight := FFontTexRect.Bottom - FFontTexRect.Top;
  FFontTexRight := FFontTexRect.Right;

  if (FCaretPos = (FTextLen + 1)) and (FCaretPos = FScrollPos)
    and (FMaxScrollPos = FScrollPos) then
  begin{ ��End���Ĵ���������ʵ�ScrollPos }
    FTextFitWidth := Font.TextWidth(FText[FTextLen]);
    FScrollPos := 0;
    for i := FTextLen downto 1 do
    begin
      t := Font.TextWidth(FText[i]);
      if t = 0 then
      begin{ �����ո�ͱȽ�������ֻ����ʱ�����㶨 }
        t := Font.TextWidth(FText[i] + csCheckChar);
        t := t - Font.TextWidth(csCheckChar);
      end;// if
      FTextFitWidth := FTextFitWidth + t;
      Inc(FScrollPos);
      if FTextFitWidth > FShowWidth then Break;
    end;// for i
    FScrollPos := FTextLen - FScrollPos;
  end
  else
  begin
    { ���ݺϷ��Լ�� }
    if (FCaretPos < FScrollPos) and (FCaretPos >= 1) then
      FScrollPos := FCaretPos;
    if (FCaretPos > FMaxScrollPos) and (FCaretPos <= (FTextLen + 1)) then
      Inc(FScrollPos);
  end;// if

  if FCaretPos <= 0 then
    FCaretPos := 1;
  if FScrollPos <= 0 then
    FScrollPos := 1;

  // �������Ȱ��������
  if FScrollPos > 1 then
  begin
    tmpLetfPosStr := Copy(FText, 1, FScrollPos - 1);
    FFontTexRect.Left := FFontTexRect.Left + Font.TextWidth(tmpLetfPosStr);
//    for i := Length(tmpLetfPosStr) downto 1 do
//    begin{ ��������ʱ���Ȼ�ܻ�ȡ�����ո��λ�ã��ΰ� }
//      t := Font.TextWidth(tmpLetfPosStr[i]);
//      if t <> 0 then break;
//      { �����Ŀո�����ȡ���㣬���� }
//      t := Font.TextWidth(tmpLetfPosStr[i] + csCheckChar);
//      t := t - Font.TextWidth(csCheckChar);
//      FFontTexRect.Left := FFontTexRect.Left + t;
//    end;// for i
  end;// if
  
  FLastLeftTexPos := FFontTexRect.Left;// �����������λ��
  // �����ʺϵ���ʾ���ֿ��
  FTextFitWidth := 0;
  FMaxScrollPos := FScrollPos - 1;
  FCharWidth.Clear;
  for i := FScrollPos to FTextLen do
  begin
    t := Font.TextWidth(FText[i]);
    if t = 0 then
    begin{ �����ո�ͱȽ�������ֻ����ʱ�����㶨 }
      t := Font.TextWidth(FText[i] + csCheckChar);
      t := t - Font.TextWidth(csCheckChar);
    end;// if
    FTextFitWidth := FTextFitWidth + t;
    FCharWidth.Insert(FTextFitWidth);
    Inc(FMaxScrollPos);
    if FTextFitWidth >= FShowWidth then Break;
  end;// for i
  if FTextFitWidth < FShowWidth then
  begin{ ��֤���ı�ĩ����һ��λ�� }
    FTextFitWidth := FTextFitWidth + t;
    FCharWidth.Insert(FTextFitWidth);
    Inc(FMaxScrollPos);
  end;// if

  { �߶Ⱦ��� }
  t := (FShowHeight - FTextHeight) div 2;
  FDrawFixTop := 0;
  if t > 0 then
  begin
    FDrawFixTop := t;
  end;// if
  FDrawTextRect.Top := FDrawTextRect.Top + FDrawFixTop;
  FDrawTextRect.Bottom := FDrawTextRect.Top + FTextHeight;
  FCaretRect.Top := FDrawTextRect.Top;
  FCaretRect.Bottom := FDrawTextRect.Bottom;

  { �������뻹������ }
  if (FCaretPos = FMaxScrollPos) and (FTextFitWidth > FShowWidth) then
  begin//����
    FFontTexRect.Left := FLastLeftTexPos; // ����Ϊ����λ��
    FFontTexRect.Right := FFontTexRect.Left + FTextFitWidth;
    FFontTexRect.Left := FFontTexRect.Right - FShowWidth;
    t := 0;
    if (FFontTexRect.Right > FFontTexRight) then
    begin
      t := FFontTexRect.Right - FFontTexRight;
      FFontTexRect.Right := FFontTexRight;
    end;// if
    FDrawTextRect.Right := FDrawTextRect.Left + FShowWidth - t;
    { �������λ���� }
    FLastCaretFix := FTextFitWidth - FShowWidth;

  end
  else
  begin// ����
    FFontTexRect.Left := FLastLeftTexPos; // ����Ϊ����λ��
    LeftTextFitWidth := FTextFitWidth;
    if FTextFitWidth > FShowWidth then
      LeftTextFitWidth := FShowWidth;
    FFontTexRect.Right := FFontTexRect.Left + LeftTextFitWidth;

    t := 0;
    if (FFontTexRect.Right > FFontTexRight) then
    begin
      t := FFontTexRect.Right - FFontTexRight;
      FFontTexRect.Right := FFontTexRight;
    end;// if
    FDrawTextRect.Right := FDrawTextRect.Left + LeftTextFitWidth - t;
    FLastCaretFix := 0;
  end;// if

  { ������λ�� }
  t := FCaretPos - FScrollPos - 1;
  if (t < 0) or (t >= FCharWidth.Count) then
  begin
    FCaretRect.Left := 0;
  end
  else
    FCaretRect.Left := FCharWidth[t];
  inc(t);
  if (t < 0) or (t >= FCharWidth.Count) then
    t := 0;
  FCaretRect.Right := FCharWidth[t];
  FCaretRect.Left := FCaretRect.Left - FLastCaretFix;
  FCaretRect.Right := FCaretRect.Right - FLastCaretFix;
  FCaretRect.Left := FCaretRect.Left + FDrawTextRect.Left;
  FCaretRect.Right := FCaretRect.Right + FDrawTextRect.Left;
  
  Result := True;
end;

procedure TGuiCnEdit.WriteProperty(Code: Cardinal; Source: Pointer);
begin
  case Code of
    cPropBase + $0:
     FTextOpt:= PFontOptions(Source)^;

    cPropBase + $1:
     FTextCol.Assign(TGuiFontCol(Source));

    cPropBase + $2:
     FTextFont:= PChar(Source);

    cPropBase + $3:
     FTextRect:= PRect(Source)^;

    cPropBase + $4:
     FSideSpace:= PInteger(Source)^;

    cPropBase + $5:
     FReadOnly:= PBoolean(Source)^;

    cPropBase + $6:
     FMaxLength:= PInteger(Source)^;

    cPropBase + $7:
     FCaretColor:= PCardinal(Source)^;

    cPropBase + $8:
     FCaretAlpha:= PInteger(Source)^;

    cPropBase + $9:
     FSelectColor:= PCardinal(Source)^;

    cPropBase + $A:
     FSelectAlpha:= PInteger(Source)^;

    cPropBase + $B:
     FText:= PWideChar(Source);

    cPropBase + $C:
      FTextFontColor := PCardinal(Source)^;

  else
    inherited WriteProperty(Code, Source);
  end;// case
end;

end.

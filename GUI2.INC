{кФФФC.I.A.ФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФverze 2.00ФФФП
 ГS timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymiГ
 Гv dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.Г
 РФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФй}

var guiD: PDialog;      { GUI dialog, vnitrne pouzite pro objekty }
    guiActive,          { aktivni a posledne aktivni objekt v GUI dialogu }
    guiOldActive:word;
    guiRedrawFlag: boolean; { ma se prekreslit GUI dialog ? }

constructor TGuiObject.Init;
begin
  inherited Init;
  CanActive := True;
end;
procedure TGuiObject.Draw;
begin
  guiRedrawFlag := True;
end;
procedure TGuiObject.HandleEvent(var Event: TEvent);
begin
  if OldActive <> Active then begin
    guiRedrawFlag := True;
    OldActive := Active;
  end;
end;
procedure TGuiObject.GetData(var Data); begin end;
procedure TGuiObject.SetData(var Data); begin end;
function TGuiObject.DataSize: Word; begin DataSize := 0 end;

{ллллллллллллллллл TGuiText ллллллллллллллллл}

constructor TGuiText.Init(aX,aY: Integer; S: String; aAttr: Byte);
begin
  inherited Init;
  X := aX;  { preda parametry }
  Y := aY;
  Txt := S;
  Attr := aAttr;
  CanActive := False; { nemuze byt aktivovan }
end;
procedure TGuiText.Draw;
begin
  inherited Draw;
  { vycentrovani textu }
  if X = -1 then X := guiD^.chrX shr 1 - Length(Txt) shr 1;
  if Y = -1 then Y := guiD^.chrY shr 1;
  guiD^.wrixy(Attr,X,Y,Txt);
end;

{ллллллллллллллллл TGuiCheck лллллллллллллллл}

constructor TGuiCheck.Init(aX,aY: Integer; S: String; aChecked: Boolean);
begin
  inherited Init;
  X := aX;
  Y := aY;
  Txt := S;
  Checked := aChecked;
end;
procedure TGuiCheck.Draw;
begin
  inherited Draw;
  guiD^.wrixy(either(active,$3f,$30),x+4,y,Txt);
  guiD^.wrixy(either(active,$3f,$31),x,y,'[ ]');
  if Checked then guiD^.wrixy($3e,x+1,y,'X');
end;
procedure TGuiCheck.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Active then begin
    case Code(Event) of
      kSpace: begin
                Checked := not Checked;
                guiRedrawFlag := True;
              end;
    end;
  end;
  case Code(Event) of
    mcLeftPressed:
            if (guiD^.press.X >= x) and (guiD^.press.X <= x+4+length(txt)) and
               (guiD^.press.Y = y) then begin
              Checked := not Checked;
              guiActive := Id;
              Active := True;
              guiRedrawFlag := True;
            end;
  end;
end;
procedure TGuiCheck.GetData(var Data);
begin
  Boolean(Data) := Checked;
end;
procedure TGuiCheck.SetData(var Data);
begin
  Checked := Boolean(Data);
end;
function TGuiCheck.DataSize: Word;
begin
  DataSize := SizeOf(Boolean);
end;

{ллллллллллллллллл TGuiHorizScroll лллллллллллллллл}

constructor TGuiHorizScroll.Init(aX,aY,aSirka: Byte; aValue: Byte);
begin
  inherited Init;
  X := aX;
  Y := aY;
  Sirka := aSirka;
  Value := aValue;
end;
procedure TGuiHorizScroll.Draw;
var
 xx: byte;
begin
  inherited Draw;
  guiD^.wrixy(either(active,$1e,$16),x,y,rep('-',sirka));
  guiD^.wrixy(either(active,$1f,$17),x+value-1,y,'ў');
end;
procedure TGuiHorizScroll.HandleEvent(var Event: TEvent);
var
 Krok: Integer;
begin
  inherited HandleEvent(Event);
  if Active then begin
    case Code(Event) of
      kRight: begin
                guiRedrawFlag := Value<>Sirka;
                Krok := 1+either(kPressed[kLShift] or kPressed[kRShift],1,0);
                if Value+Krok <= Sirka then Inc(Value,Krok) else Value := Sirka;
              end;
      kLeft: begin
               guiRedrawFlag := Value<>1;
               Krok := 1+either(kPressed[kLShift] or kPressed[kRShift],1,0);
               if Value-Krok >= 1 then Dec(Value,Krok) else Value := 1;
             end;
      kHome: begin
               guiRedrawFlag :=  Value<>1;
               Value:=1;
             end;
      kEnd: begin
              guiRedrawFlag :=  Value<>Sirka;
              Value:=Sirka;
            end;
    end;
  end;
  case Code(Event) of
    mcLeftPressed,
    mcLeftHold:
            if (guiD^.EventPos.X >= X) and (guiD^.EventPos.X <= (X+Sirka-1)) and
               (guiD^.EventPos.Y = Y) then begin
              guiActive := ID;
              Value := guiD^.EventPos.X-X+1;
              guiRedrawFlag := True;
            end;
  end;
end;
procedure TGuiHorizScroll.GetData(var Data);
begin
  Byte(Data) := Value;
end;
procedure TGuiHorizScroll.SetData(var Data);
begin
  Value := Byte(Data);
end;
function TGuiHorizScroll.DataSize: Word;
begin
  DataSize := SizeOf(Byte);
end;

{ллллллллллллллллл TGuiButton лллллллллллллллл}

constructor TGuiButton.Init(aX,aY,aSirka: Byte; S: String; aEvent: TEvent; aCommand: Word);
begin
  inherited Init;
  X := aX;
  Y := aY;
  Sirka := aSirka;
  Txt := S;
  Ev := aEvent;
  Command := aCommand;
  Downed := False;
end;
procedure TGuiButton.Draw;
begin
  with guiD^ do begin
    WriXY($0,X,Y,Rep(' ',Sirka));
    WriXY(either(active,$f,$7),X+Sirka div 2-Length(Txt) div 2,Y,Txt);
    if not Downed then begin
      WriXY($f,X,Y,'');
      WriXY($f,X+Sirka-1,Y,'');
    end else begin
      WriXY($f,X+1,Y,'');
      WriXY($f,X+Sirka-2,Y,'');
    end;
  end;
end;
procedure TGuiButton.HandleEvent(var Event: TEvent);
var Old: Longint;
begin
  inherited HandleEvent(Event);
  if Active then begin
    case Code(Event) of
      kEnter,kSpace: begin
                       Downed := True;
                       guiRedrawFlag := True;
                       Draw;
                       if Ev <> 0 then
                         guiD^.s^.PushEvent(Ev);
                       guiCommand := Command;
                       Downed := False;
                     end;
    end;
  end;
  case Code(Event) of
    mcLeftPressed:
            if (guiD^.Press.X >= X) and (guiD^.Press.X <= X+Sirka-1) and
               (guiD^.Press.Y = Y) then begin
              Downed := True;
              guiActive := ID;
              guiRedrawFlag := True;
              Draw;
            end;
    mcLeftHold: ;
    mcLeftReleased:
            if Downed then begin
              if Ev <> 0 then
                guiD^.s^.PushEvent(Ev); { vlozim pozadovany event pri stisku }
              guiCommand := Command; { nastavim prikaz }
              Downed := False;
              guiRedrawFlag := True;
              Draw;
            end;
  end;
end;

{ллллллллллллллллл TGuiPicture лллллллллллллллл}

constructor TGuiPicture.Init(aX,aY: Byte; aResizeX,aResizeY: Integer; aPic: PBitMap);
begin
  inherited Init;
  X := aX;
  Y := aY;
  ResizeX := aResizeX;
  ResizeY := aResizeY;
  Pic := aPic;
  CanActive := False;
end;
procedure TGuiPicture.Draw;
begin
  if guiD^.S^.mapModel <> model_text then with guiD^ do
    if (ResizeX = -1) and (ResizeY = -1) then
      BtF2Box(Pic,X*mulX,Y*mulY)
    else
      ResizeBtF2Box(0,Pic,X*mulX,Y*mulY,ResizeX,ResizeY);
end;

{ллллллллллллллллл TGuiInputLine лллллллллллллллл}

constructor TGuiInputLine.Init(aX,aY,aSirka,aMaxSirka: Byte; aTxt: String; aPrvni: Boolean);
begin
  inherited Init;
  X := aX;
  Y := aY;
  Sirka := aSirka;
  MaxSirka := aMaxSirka;
  Txt := aTxt;
  Cursor := Length(Txt);
  Scroll := 0;
  Prvni := aPrvni;
end;
procedure TGuiInputLine.Draw;
begin
  with guiD^ do begin
    WriXY($10,x,y,Rep(' ',Sirka+2));
    if scroll > 0 then WriXY($12,x,y,'');
    if scroll < length(txt)-sirka then WriXY($12,x+sirka+1,y,'');
    WriXY(either(active,$1f,$17),x+1,y,Copy(txt,1+scroll,sirka));
    if not Active then begin if Prvni then kurzorOn := false; end
    else GotoXY(x+1+Cursor-scroll,y);
  end;
end;
procedure TGuiInputLine.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Code(Event) = mcLeftPressed then
    if (guiD^.press.X >= x) and (guiD^.press.X <= x+sirka+1) and
       (guiD^.press.Y = y) then begin
      guiActive := Id;
      Active := True;
      guiRedrawFlag := True;
    end;
  if Active then begin
    case Char(Event) of
      #32..#255: if not ((Length(Txt) = MaxSirka) and (Cursor=Sirka+Scroll)) then begin
                   Insert(csAutoDecodedChar(Char(Event)),Txt,Cursor+1);
                   Inc(Cursor);
                   if (Cursor >= Sirka+Scroll+1){ and
                      (Scroll < length(txt)-sirka)} then Inc(Scroll);
                   guiRedrawFlag := True;
                 end;
    end;
    case Code(Event) of
      kBackspace: if (Cursor > 0) and (Length(Txt) > 0) then begin
                    Delete(Txt,Cursor,1);
                    Dec(Cursor);
                    guiRedrawFlag := True;
                  end;
      kDelete   : if (Cursor < Length(Txt)) and (Length(Txt) > 0) then begin
                    Delete(Txt,Cursor+1,1);
                    guiRedrawFlag := True;
                  end;
      kLeft     : if Cursor > 0 then begin
                    Dec(Cursor);
                    guiRedrawFlag := True;
                  end;
      kRight    : if Cursor < Length(Txt) then begin
                    Inc(Cursor);
                    guiRedrawFlag := True;
                  end;
      kHome     : begin
                    Scroll := 0;
                    Cursor := 0;
                    guiRedrawFlag := True;
                  end;
      kEnd      : begin
                    if Length(Txt) > Sirka then
                      Scroll := Length(Txt)-Sirka
                    else Scroll := 0;
                    Cursor := Length(txt);
                    guiRedrawFlag := True;
                  end;
    end;
    if Length(Txt) > MaxSirka then Txt := Copy(Txt,1,MaxSirka);
    if (Cursor = Sirka+Scroll+1) and
       (Scroll < length(txt)-sirka) then Inc(Scroll);
    if (Cursor = -1+Scroll) and (Scroll > 0) then Dec(Scroll);
  end;
end;
procedure TGuiInputLine.GetData(var Data);
begin
  String(Data) := Txt;
end;
procedure TGuiInputLine.SetData(var Data);
begin
  Txt := String(Data);
  Cursor := Length(Txt);
  Scroll := MaxI(0,integer(Cursor)-integer(Sirka));
end;
function TGuiInputLine.DataSize: Word;
begin
  DataSize := SizeOf(String);
end;

{лллллллллллллллллл dlgGUI лллллллллллллллллл}

function dlgGUI(Sirka,Vyska: Byte; var P: PCollection; var Data; IdleProc: TProc):word;
var   guiIdlePtr: Pointer absolute guiIdle;
      event:TEvent;
      pos:TPoint;
      d:PDialog;
      ch:char;
      i: word;
{ nastavi aktivni objekt; pokud nemuze byt aktivni jde na radu az dalsi,
  ktery muze }
procedure SetActive(Id: Word);
var I: Word;
begin
  for I := 0 to P^.Count-1 do
    PGuiObject(P^.Items^[I])^.Active := False; { vsechny objekty deaktivuju }
  I := Id;
  while (not PGuiObject(P^.Items^[I])^.CanActive) do begin
    I := (I+1) mod p^.count;                        { najdu si prvni vhodny }
    if i = id then exit;
  end;
  PGuiObject(P^.Items^[I])^.OldActive := False;
  PGuiObject(P^.Items^[I])^.Active := True;            { a aktivuju objekt }
  guiActive := I;
end;
procedure GoForward;
begin
  SetActive((guiActive+1) mod p^.count);
end;
procedure GoBack;
var I,Id: Word;
begin
  Id := (guiActive-1) mod p^.count;
  for I := 0 to P^.Count-1 do
    PGuiObject(P^.Items^[I])^.Active := False;
  I := Id;
  while (not PGuiObject(P^.Items^[I])^.CanActive) do begin
    if I > 1 then I := I-1 else I := p^.count-1;
    if i = id then exit;
  end;
  PGuiObject(P^.Items^[I])^.OldActive := False;
  PGuiObject(P^.Items^[I])^.Active := True;
  guiActive := I;
end;
{ zobrazi objekty do bitmapy dialogu }
procedure Draw;
var I: Word;
begin
  for I := 0 to P^.Count-1 do begin
    PGuiObject(P^.Items^[I])^.Draw;
    PGuiObject(P^.Items^[I])^.Id := I;
  end;
end;
{ zavola hlavni obsluzne metody objektu }
procedure HandleEvent(var Ev: TEvent);
var I: Word;
begin
  for I := 0 to P^.Count-1 do begin
    PGuiObject(P^.Items^[I])^.HandleEvent(Ev);
    if guiActive <> guiOldActive then begin
      SetActive(guiActive mod p^.count);
      guiOldActive := guiActive;
    end;
  end;
end;
{ nastavi data objektu }
procedure SetData;
var I: Byte;
    DataPtr: Pointer;
    Citac: Word;
type Pole = Array [0..65534] of Byte;
begin
  Citac := 0;
  for I := 0 to P^.Count-1 do begin
    PGuiObject(P^.Items^[I])^.SetData(Pole(Data)[Citac]);
    Inc(Citac, PGuiObject(P^.Items^[I])^.DataSize);
  end;
end;
{ zjisti data objektu }
procedure GetData;
var I: Byte;
    DataPtr: Pointer;
    Citac: Word;
type Pole = Array [0..65534] of Byte;
begin
  Citac := 0;
  for I := 0 to P^.Count-1 do begin
    PGuiObject(P^.Items^[I])^.GetData(Pole(Data)[Citac]);
    Inc(Citac, PGuiObject(P^.Items^[I])^.DataSize);
  end;
end;

var _D: PDialog;
    _Active,
    _OldActive: word;
    _RedrawFlag: boolean;
    _Idle: TProc;
    _Command: Word;
begin
  dlgGUI:=0;
  { Je-li kolekce prazdna nebo nealokovana, tak skonci: }
  if (P^.Count=0) or (P=nil) then Exit;

  if NewDialog(d,Sirka,Vyska,nil) then begin
    { Ulozeni globalnich promennych: }
    _D := guiD;
    _Active := guiActive;
    _OldActive := guiOldActive;
    _RedrawFlag := guiRedrawFlag;
    _Idle := guiIdle;
    _Command := guiCommand;

    guiIdle := IdleProc;
    guiCommand := 0;
    guiD := d;      { nastavime dialog pro pouziti v objektech }
    SetActive(0);   { zativuje se prvni objekt, ktery jde aktivovat }
    d^.Frame;       { zobrazi se ramecek }
    SetData;        { nastavi data objektum }
    guiRedrawFlag := True; { musi se nakreslit }
    if guiIdlePtr <> nil then begin
      GetData;
      guiIdle;
    end;
    repeat
      { nakresleni: }
      if guiRedrawFlag then begin
        Draw;
        guiRedrawFlag := false;
        d^.FreshFull;
      end;

      { eventy: }
      event:=d^.GetEvent;
      ch:=UpCase(char(event));
      case code(event) of
        vcEndGui:Break;
        kEsc    :begin guiCommand:=0;Break;end;
        kTab    :if p^.count>1 then begin
                  if char(event)=#9 then GoForward else GoBack;
                  guiRedrawFlag := True;
                 end;
      end;
      HandleEvent(Event);

      { idle proc: }
      if guiIdlePtr <> nil then begin
        GetData;
        guiEvent := Event;
        guiPos := Pos;
        guiIdle;
      end;
    until False;
    GetData;
    d^.Free;
    guiEvent := 0;

    dlgGUI:=guiCommand;

    { Vraceni globalnich promennych: }
    guiD := _D;
    guiActive := _Active;
    guiOldActive := _OldActive;
    guiRedrawFlag := _RedrawFlag;
    guiIdle := _Idle;
    guiCommand := _Command;
  end;
end;


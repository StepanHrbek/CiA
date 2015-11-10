{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: klavesnice - low level hratky, veskera informace je dostupna

}

{$m 10000,0,20000}

Uses Key,Sys;

{par rutinek zkopirovanych z vga.pas}
Procedure GotoXY(x,y:byte);assembler;
 asm mov dl,x;mov dh,y;mov ah,2;mov bh,0;int 10h;end;
function vga_HideCursor:boolean;assembler;
 asm mov dx,3d4h;mov al,0ah;out dx,al;inc dx;in al,dx;
     mov ah,al;or al,00010000b;out dx,al
     shl ah,3;shr ax,15;dec ax;end;
function vga_ShowCursor:boolean;assembler;
 asm mov dx,3d4h;mov al,0ah;out dx,al;inc dx;in al,dx;
     mov ah,al;and al,11101111b;out dx,al
     shl ah,3;shr ax,15;dec ax;end;

Var  i:integer;

Begin
 {smazeme obrazovku a schovame kurzor}
 asm mov ax,3;int 10h;end;
 vga_HideCursor;

 {zapneme keyboard handler}
 kSetHandler(true);

 repeat
  {vypiseme rady}
  GotoXY(0,0);
  write('Zkus drzet ruzne klavesy a sleduj.');

  {vypiseme stav vsech klaves: #=stisknuta, .=nestisknuta}
  GotoXY(0,2);
  write('Pole vsech klaves: ');
  for i:=0 to 255 do if kPressed[i] then write('#') else write('.');

  {vypiseme zvlast stav shiftu, altu atd.}
  GotoXY(0,7);
  write('Z toho nektere zajimave stiskle: ');
  if kPressed[kLShift] then write('levy_shift ');
  if kPressed[kRShift] then write('pravy_shift ');
  if kPressed[kLAlt] then write('levy_alt ');
  if kPressed[kRAlt] then write('pravy_alt ');
  if kPressed[kLCtrl] then write('levy_ctrl ');
  if kPressed[kRCtrl] then write('pravy_ctrl ');
  if kPressed[kWin1] then write('levy_win ');
  if kPressed[kWin2] then write('pravy_win ');
  if kPressed[kWin3] then write('win_menu ');
  if kPressed[kScrol] then write('scroll_lock ');
  if kPressed[kCaps] then write('caps_lock ');
  if kPressed[kkNum] then write('num_lock ');
  if kPressed[kSpace] then write('mezernik ');
  if kPressed[kEnter] then write('levy_enter ');
  if kPressed[kkEnter] then write('pravy_enter ');
  if kPressed[kLeft] then write('doleva ');
  if kPressed[kRight] then write('doprava ');
  if kPressed[kUp] then write('nahoru ');
  if kPressed[kDown] then write('dolu ');
  write('                            ');

  {vypiseme stav locku}
  GotoXY(0,9);
  write('Locknute locky: ');
  if kPressed[kPause] then write('pause ');
  if num    then write('num ');
  if caps   then write('caps ');
  if scroll then write('scroll ');
  write('          ');

  {odeberem pripadne stisky biosu z bufferu}
  while Keypressed do Readkey;

 until kPressed[kEsc];

 vga_ShowCursor;
End.
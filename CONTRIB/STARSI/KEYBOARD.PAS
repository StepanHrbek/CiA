unit keyboard;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
 INTERFACE
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 KeybIntr=9;
 KeybPort=$60;
 scnkey:array[0..255] of string[12]=('NUL',
  'Esc','1','2','3','4','5','6','7','8','9',
  '0','-','= or +','BackSpace','TAB','Q','W','E','R','T',
  'Y','U','I','O','P','[ or {','] or }','Enter','Left_CTRL','A',
  'S','D','F','G','H','J','K','L','; or :',#39' or "',
  '` or ~','Left_Shift','','Z','X','C','V','B','N','M',
  ', or <','. or >','/ or ?','Right_Shift','Pause/Break','Left_Alt','Space','CapsLock','F1','F2',
  'F3','F4','F5','F6','F7','F8','F9','F10','NumLock','ScrollLock',
  'KeyPad 7','KeyPad 8','KeyPad 9','KeyPad -','KeyPad 4','KeyPad 5','KeyPad 6','KeyPad +','KeyPad 1','KeyPad 2',
  'KeyPad 3','KeyPad 0','KeyPad .','Sys.Request','','','F11','F12','','',
  '','','','','','','','','','',
  '','','','','','','','','','',
  '','','','','','','','','','',
  '','','','','','','','',{128}'','',
  '','','','','','','','','','',
  '','','','','','','','','','',
  '','','','','','KeyPad Enter','Right CTRL','','','',
  '','','','','','','','','','PtrScreen',
  '','','','','','','','','','',
  'KeyPad /','','PrtScreen','Right Alt','','','','','','',
  '','','','','','','','','Home','Arrow Up',
  'Page Up','','Arrow Left','','Arrow Right','','End','Arrow Down','Page Down','Insert',
  'Delete','','','','','','','','','',
  '','','','','','','','','','',
  '','','','','','','','','Macro','',
  '','','','','','','','','','',
  '','','','','');
 KeyEsc=1;
 KeyEscape=KeyEsc;
 Key1=2;
 Key2=3;
 Key3=4;
 Key4=5;
 Key5=6;
 Key6=7;
 Key7=8;
 Key8=9;
 Key9=10;
 Key0=11;
 Key_=12;
 KeyPodtrzitko=Key_;
 KeyMinus=Key_;
 KeyPlus=13;
 KeyBackSpace=14;
 KeyTab=15;
 KeyQ=16;
 KeyW=17;
 KeyE=18;
 KeyR=19;
 KeyT=20;
 KeyY=21;
 KeyU=22;
 KeyI=23;
 KeyO=24;
 KeyP=25;
 KeyZacatekHranatyZavorky=26;
 KeyZacatekHranaty=KeyZacatekHranatyZavorky;
 KeyKonecHranatyZavorky=27;
 KeyKonecHranaty=KeyKonecHranatyZavorky;
 KeyEnter=28;
 KeyReturn=KeyEnter;
 KeyCR=KeyEnter;
 KeyEOL=KeyEnter;
 KeyCTRL=29;
 KeyControl=KeyCTRL;
 KeyLeftCTRL=KeyCTRL;
 KeyLeftControl=KeyCTRL;
 KeyA=30;
 KeyS=31;
 KeyD=32;
 KeyF=33;
 KeyG=34;
 KeyH=35;
 KeyJ=36;
 KeyK=37;
 KeyL=38;
 KeyStrednik=39;
 KeyDvojtecka=KeyStrednik;
 KeyColon=KeyStrednik;
 KeySemiColon=KeyStrednik;
 KeyApostrof=40;
 KeyUvozovky=KeyApostrof;
 KeyVlnka=41;
 KeyLeftShift=42;
 KeyBackSlash=43;
 KeyZ=44;
 KeyX=45;
 KeyC=46;
 KeyV=47;
 KeyB=48;
 KeyN=49;
 KeyM=50;
 KeyCarka=51;
 KeyTecka=52;
 KeyOtaznik=53;
 KeyLomitko=KeyOtaznik;
 KeyRightShift=54;
 KeyAlt=56;
 KeyLeftAlt=56;
 KeySpace=57;
 KeySpaceBar=KeySpace;
 KeyMezernik=KeySpace;
 KeyMezera=KeySpace;
 KeyCapsLock=58;
 KeyCaps=KeyCapsLock;
 KeyF1=59;
 KeyF2=60;
 KeyF3=61;
 KeyF4=62;
 KeyF5=63;
 KeyF6=64;
 KeyF7=65;
 KeyF8=66;
 KeyF9=67;
 KeyF10=68;
 KeyF11=133;
 KeyF12=134;
 KeyNumLock=69;
 KeyNum=KeyNumLock;
 KeyScrLock=70;
 KeyScrollLock=KeyScrLock;
 KeyPad7=71;
 KeyPad8=72;
 KeyPad9=73;
 KeyPadMinus=74;
 KeyGrayMinus=KeyPadMinus;
 KeySedeMinus=KeyPadMinus;
 KeyPad4=75;
 KeyPad5=76;
 KeyCenter=KeyPad5;
 KeyPad6=77;
 KeyPadPlus=78;
 KeyGrayPlus=KeyPadPlus;
 KeySedePlus=KeyPadPlus;
 KeyPad1=79;
 KeyPad2=80;
 KeyPad3=81;
 KeyPad0=82;
 KeyPadInsert=KeyPad0;
 KeyPadIns=KeyPadInsert;
 KeyPadDelete=83;
 KeyPadDel=KeyPadDelete;
 KeyWinLeft=91;
 KeyWinRight=92;
 KeyWinMenu=93;
 {A teÔ rozç¡ýen‚ kl vesy, kter‚ do portu vracej¡ k¢d 224 ($E0) a teprve
  potom svuj scan-k¢d. To, §e jsou rozç¡ýen‚, indikuje sedmì bit.}
 KeyExtend=1 shl 7;
 KeyPadEnter=KeyExtend+KeyEnter;
 KeyRightCTRL=KeyExtend+KeyLeftCTRL;
 KeyRightControl=KeyExtend+KeyControl;
 KeyPrintScreen=KeyExtend+55;
 KeyPrtScr=KeyPrintScreen;
 KeyPrtScr2=KeyExtend+1;
 KeyPadLomitko=KeyExtend+KeyLomitko;
 KeyRightAlt=KeyExtend+KeyAlt;
 KeyAltGr=KeyExtend+KeyAlt;
 KeyHome=KeyExtend+KeyPad7;
 KeyUp=KeyExtend+KeyPad8;
 KeyPageUp=KeyExtend+KeyPad9;
 KeyLeft=KeyExtend+KeyPad4;
 KeyRight=KeyExtend+KeyPad6;
 KeyEnd=KeyExtend+KeyPad1;
 KeyDown=KeyExtend+KeyPad2;
 KeyPageDown=KeyExtend+KeyPad3;
 KeyInsert=KeyExtend+KeyPad0;
 KeyDelete=KeyExtend+KeyPadDel;
 KeyMacro=KeyExtend+111;
 {Nasledujici konstanty neodpovidaji skutecnym scan-kodum:}
 KeyPause=254;
 KeyBreak=255;
 KeyCTRLBreak=KeyBreak;
 KeyControlBreak=KeyBreak;
 c_stiskni=100;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 p_Keyb=^o_Keyb;
 o_Keyb=
  object
   constructor Init;
   destructor  Done;
   procedure   Start;
   procedure   Stop;
   procedure   ClearKeybBuffer;
   function    keypr(KeyCode:byte):boolean;
  end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 KeybHist:string[6]; {sest poslednich klaves}
 KeybMap:array[-1..255] of byte;
    {KeybMap[-1]=false, kdyz ma klavesnici zpracovavat BIOS
     KeybMmap[-1]=true, kdyz ma klavesnici zpracovavat uzivatelsky handler}
 KeybBIOSProc:procedure;
 CTRLBreakPressed:boolean;
 PKeyb:p_Keyb; {pointer na objekt}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
 IMPLEMENTATION
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
uses Dos;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{$F+,S-,W-}
procedure KeybHandler(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP:Word); interrupt;
var
 key,key2:byte;
begin {KeybHandler}
 fillchar(KeybHist[1],0,6);
 key:=Port[KeybPort];
 KeybHist:=Concat(chr(key),KeybHist);
 if key in [224,225]
 then keybmap[KeyExtend]:=key-222
 else
    begin
     if keybmap[KeyExtend]>0
     then dec(keybmap[KeyExtend]);
     case keybmap[KeyExtend] of
     1: begin
         if key>127 then KeybMap[KeyExtend+key and 127]:=0 else
         if key<127 then KeybMap[KeyExtend+key and 127]:=c_stiskni;
         if key=70 then CTRLBreakPressed:=true
        end;
     0: if key>127 then KeybMap[key and 127]:=0 else
        if key<127 then KeybMap[key and 127]:=c_stiskni
     end
    end;
 KeybMap[KeyPause]:=c_stiskni*byte(KeybHist=#197#157#225#69#29#225);
 KeybMap[KeyPrtScr2]:=c_stiskni*byte(KeybHist[1]+KeybHist[2]=#55#224);
 if KeybMap[-1]=0
 then
  begin
   inline($9C); {pushf}
   if KeybMap[KeyPause]*KeybMap[KeyCTRLBreak]=0
   then KeybBIOSProc
  end
 else
  begin
   if KeybMap[KeyPause]*KeybMap[KeyCTRLBreak]=0
   then KeybBIOSProc;
   inline($B0/$20/$E6/$20) {Port[$20]:=$20}
  end
end;  {KeybHandler}
{$F-,S+}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
constructor o_keyb.Init;
begin {o_keyb.Init}
 if MaxAvail<=SizeOf(o_keyb)
 then Fail;
 fillchar(KeybMap[0],256,0);
 KeybMap[-1]:=0;
 KeybBIOSProc:=nil
end;  {o_keyb.Init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
destructor o_keyb.Done;
begin {o_keyb.Done}
 fillchar(KeybMap[0],256,0);
 KeybMap[-1]:=0;
 KeybBIOSProc:=nil
end;  {o_keyb.Done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure o_keyb.Start;
begin {o_keyb.Start}
 GetIntVec(KeybIntr,@KeybBIOSProc);
 SetIntVec(KeybIntr,Addr(KeybHandler));
 fillchar(KeybMap[0],256,0);
 KeybHist:=#0#0#0#0#0#0;
 KeybMap[-1]:=1
end;  {o_keyb.Start}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure o_keyb.Stop;
begin {o_keyb.Stop}
 SetIntVec(KeybIntr,@KeybBIOSProc);
 fillchar(KeybMap[0],256,0);
 KeybMap[-1]:=0
end;  {o_keyb.Stop}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure o_keyb.ClearKeybBuffer; assembler;
{memw[seg0040:$1c]:=memw[seg0040:$1a] - vycisti bufer klavesnice}
asm {o_keyb.ClearKeybBuffer}
 push ds
 push es
 mov  es,seg0040
 mov  di,01Ch
 mov  ds,seg0040
 mov  si,01Ah
 movsw
 pop  es
 pop  ds
end;{o_keyb.ClearKeybBuffer}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function o_keyb.keypr(KeyCode:byte):boolean;
begin {o_keyb.keypr}
 keypr:=KeybMap[KeyCode]=c_stiskni
end;  {o_keyb.keypr}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin {unit}
 CTRLBreakPressed:=false
end.  {unit}

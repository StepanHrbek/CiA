{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 AutoPressSpeed:byte=2;
type
 string20=string[20];
 Pbutton=^Tbutton;
 Tbutton=
  object
   x,y:byte;         {pozice leveho krajniho bodu}
   w,h,d:byte;       {sirka,vyska,hloubka tlacitka}
   c1,c2,c3,c4:byte; {barvy tlacitka a textu}
   e:word;
   napis:string20;   {napis}
   pressed:boolean;  {stav tlacitka (zapnuto/vypnuto)}
   locked:boolean;   {neni mozne zmenit jeho stav}
   auto:boolean;     {nemusi se cekat na pusteni tlacitka mysi}
   constructor init(_napis:string20; _x,_y,_w,_h:byte; _pressed:boolean);
   destructor  done;
   procedure show(mode:boolean);
   function  pointed:boolean;
   function  clicked:boolean;
   function  press:boolean;
  end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
constructor Tbutton.init(_napis:string20; _x,_y,_w,_h:byte; _pressed:boolean);
begin {Tbutton.init}
 napis:=_napis;
 e:=_stde;
 x:=_x;
 y:=_y;
 d:=2;
 if _w=0 then w:=length(napis)*(e and 127)+(d+1) shl 1 else w:=_w;
 if _h=0 then h:=e shr 8+(d+1) shl 1 else h:=_h;
 pressed:=_pressed;
 c1:=28;
 c2:=26;
 c3:=24;
 c4:=31;
 e:=_stde or $80;
 locked:=false;
 auto:=false;
end;  {Tbutton.init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
destructor Tbutton.done;
begin
end;  {Tbutton.done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure Tbutton.show(mode:boolean);
var n:byte;
begin {Tbutton.show}
 butt(x,y,w,h,either(mode,c3,c1),c2,either(mode,c1,c3),d,SegA000);
 n:=(w-d shl 1) div (e and 127);
 if n=0 then inc(n);
 fw(Copy(napis,1,n),x+d+1,y+either(h>=e shr 8+d shl 1,d,0)+byte(mode),c2 shl 8+c4,e,SegA000,font4x6);
end;  {Tbutton.show}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function Tbutton.pointed:boolean;
var mx,my:word;
begin {Tbutton.pointed}
 mx:=mysx;
 my:=mysy;
 pointed:=IsIn(mx,x,x+w-1) and IsIn(my,y,y+h-1);
end;  {Tbutton.pointed}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function Tbutton.clicked:boolean;
var mx,my:word;
begin {Tbutton.clicked}
 mx:=mysx;
 my:=mysy;
 clicked:=IsIn(mx,x,x+w-1) and IsIn(my,y,y+h-1) and mysn;
end;  {Tbutton.clicked}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function Tbutton.press:boolean;
var
 mx,my:word;
 point:boolean;
begin {Tbutton.press}
 press:=false;
 if not clicked then exit;
 show(false);
 waitticks(1);
 point:=pointed;
 show(point);
 repeat
  if point<>pointed then
   begin
    point:=pointed;
    show(point);
   end;
  mx:=mysx;
  my:=mysy;
  if auto and (mem[Seg0040:$6C] mod AutoPressSpeed=0) then break;
  getbitmap(mbk,mx,my,minw(8,scrwidth-mx),minw(sizeof(mbk) shr 3,scrheight-my),SegA000);
  putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,1,SegA000);
  repeat
   waitticks(1);
  until (mx<>mysx) or (my<>mysy) or (auto and pointed) or not(mysn);
  putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,0,SegA000);
 until not mysn;
 show(false);
 press:=point;
end;  {Tbutton.press}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}

unit button;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
interface
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 AutoPressSpeed:byte=2;
type
 string20=string[20];
 Tbuf=
  record
   d:pointer;
   s:word;
  end;
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

function  volba(s:string; b0,b1:string20):boolean;
procedure hlaska(s:string);
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
implementation
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
uses syst,vgax256,maus;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
constructor Tbutton.init(_napis:string20; _x,_y,_w,_h:byte; _pressed:boolean);
begin {Tbutton.init}
 napis:=_napis;
 e:=_stde;
 d:=2;
 if _w=0 then w:=length(napis)*(e and 127)+(d+1) shl 1 else w:=_w;
 if _h=0 then h:=e shr 8+(d+1) shl 1 else h:=_h;
 if _x=$FF then x:=(scrwidth-w) shr 1 else x:=_x;
 y:=_y;
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
  getbitmap(mbk,mx,my,minw(_mysw,scrwidth-mx),minw(_mysh,scrheight-my),SegA000);
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
function  volba(s:string; b0,b1:string20):boolean;
{Zobrazi hlasku a dve tlacitka. Vrati true, jestli bylo stisknuto leve tlacitko nebo klavesa Enter}
var
 bak:Tbuf;
 radka:array[0..11] of string[31];
 i,maxx,maxy:byte;
 b:array[0..1] of TButton;
 keys:string[2];
 mx,my:word;
begin {volba}
 i:=0;
 maxx:=0;
 if s[length(s)]<>'\' then s:=s+#13;
 while pos(#13,s)>0 do
  begin
   if pos(#13,s)<=1 then radka[i]:='' else radka[i]:=copy(s,1,minW(pos(#13,s)-1,38));
   if length(radka[i]) shl 3+4>maxx then maxx:=length(radka[i]) shl 3+4;
   delete(s,1,pos(#13,s));
   if i>=24 then break;
   inc(i);
  end;
 if length(b0) shl 2+12>maxx then maxx:=length(b0) shl 2+12;
 if length(b1) shl 2+12>maxx then maxx:=length(b1) shl 2+12;
 maxy:=i shl 3+32;
 with bak do
 begin
  d:=nil;
  s:=maxx*maxy;
  getmem(d,s);
  if d<>nil then getbitmap(d^,(scrwidth-maxx) shr 1,(scrheight-maxy) shr 1,maxx,maxy,SegA000);
 end;
 butt((scrwidth-maxx) shr 1,(scrheight-maxy) shr 1,maxx,maxy,28,26,24,2,SegA000);
 for i:=1 to (maxy-28) shr 3 do
  fw(radka[i-1],(scrwidth-maxx) shr 1+3,(scrheight-maxy) shr 1+2+(i-1) shl 3,$1A1F,$0888,SegA000,font8x8);
 for i:=0 to 1 do
  with b[i] do
  begin
   Init(eitherS(i=0,b0,b1),$FF,(scrheight-maxy) shr 1+maxy-28+i*13,0,12,false);
   show(false);
  end;
 repeat
  mx:=mysx;
  my:=mysy;
  getbitmap(mbk,mx,my,_mysw,_mysh,SegA000);
  putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,17,SegA000);
  repeat
   keys:=inkeys;
  until (keys<>'') or (mx<>mysx) or (my<>mysy) or b[0].clicked or b[1].clicked;
  putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,16,SegA000);
  if b[0].press or (keys=#13) then
   begin
    volba:=true;
    b[0].show(true);
    if keys=#13 then waitticks(5);
    break;
   end;
  if b[1].press or (keys=#27) then
   begin
    volba:=false;
    b[1].show(true);
    if keys=#27 then waitticks(5);
    break;
   end;
 until false;
 keys:='';
 with bak do
 if d<>nil then
  begin
   putbitmap(d^,(scrwidth-maxx) shr 1,(scrheight-maxy) shr 1,maxx,maxy,0,maxx,16,SegA000);
   freemem(d,s);
  end;
end;  {volba}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure hlaska(s:string);
var
 bak:Tbuf;
 radka:array[0..11] of string[31];
 i,maxx,maxy:byte;
 keys:string[2];
 mx,my:word;
begin {hlaska}
 i:=0;
 maxx:=0;
 if s[length(s)]<>'\' then s:=s+#13;
 while pos(#13,s)>0 do
  begin
   if pos(#13,s)<=1 then radka[i]:='' else radka[i]:=copy(s,1,minW(pos(#13,s)-1,38));
   if length(radka[i]) shl 3+4>maxx then maxx:=length(radka[i]) shl 3+4;
   delete(s,1,pos(#13,s));
   if i>=24 then break;
   inc(i);
  end;
 maxy:=i shl 3+16;
 with bak do
 begin
  d:=nil;
  s:=maxx*maxy;
  getmem(d,s);
  if d<>nil then getbitmap(d^,(scrwidth-maxx) shr 1,(scrheight-maxy) shr 1,maxx,maxy,SegA000);
 end;
 butt((scrwidth-maxx) shr 1,(scrheight-maxy) shr 1,maxx,maxy,28,26,24,2,SegA000);
 for i:=1 to (maxy-16) shr 3 do
  fw(radka[i-1],(scrwidth-maxx) shr 1+3,(scrheight-maxy) shr 1+2+(i-1) shl 3,$1A1F,$0888,SegA000,font8x8);
 repeat
  if mysInit then
   begin
    mx:=mysx;
    my:=mysy;
    getbitmap(mbk,mx,my,_mysw,_mysh,SegA000);
    putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,17,SegA000);
    repeat keys:=inkeys
    until (keys<>'') or (mx<>mysx) or (my<>mysy) or mysn;
    putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysh,16,SegA000);
   end
  else
   repeat keys:=inkeys until keys<>'';
 until (keys<>'') or mysn;
 with bak do
 if d<>nil then
  begin
   putbitmap(d^,(scrwidth-maxx) shr 1,(scrheight-maxy) shr 1,maxx,maxy,0,maxx,16,SegA000);
   freemem(d,s);
  end;
end;  {hlaska}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin {unit button}
end.  {unit button}
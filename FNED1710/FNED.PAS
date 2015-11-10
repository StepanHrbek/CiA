{$G+,I-,X+,T+,V+,D+,L+,S+,Y+,R+,Q+}
{$M 16384,0,262144}
uses dos,maus,fajls,syst,button,sele,xvga,vgax256;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 _exesize=37069;
 _fnhead='ëmÕonç ';
 _verze='16.10.1999';
 _hlpfile='fned.hlp';
 _temfile='fned.tem';
 _inBlock=1;
 _saved=2;
 _blk=1;
 _chr=2;
 _row=4;
 _col=8;
 _menuw=44;
 homedir:string[67]='';
 sklon:byte=4; {pro kurz¡vu}
 xorbyte:byte=32;
 clrPod:byte=19;
 clrDot:byte=20;
 clrWhite:word=$000F;
 clrBorder:byte=$C6;
 clrEmp:word=$202E;
 aply:byte=_chr;
 menuoffsets=10;
 _mnHlavni =0;
 _mnSoubor =1;
 _mnEdituj =2;
 _mnBlok   =3;
 _mnZoom   =4;
 _mnPreklop=5;
 _mnRotuj  =6;
 _mnZaklon =7;
 _mnSpecial=8;
 _mnOdrizni=9;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 shortint=-128..127;
 TFNChrInfo=
  record
   relx,rely:shortint; {relativni souradnice vzhledem ke kurzoru}
   sirb,vysb:byte;     {sirka a vyska bitmapy}
   shift    :shortint; {posun kurzoru doprava}
   ofsb     :word;     {offset bitmapy od zacatku souboru}
  end;
 TClip=
  record
   d:pointer;
   s:word;
   w,h:byte;
   paste:boolean;
  end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 first,last,c,z:char;
 over,under:shortint;
 addspace,future:shortint;
 tablo:array[#0..#255] of TFNChrInfo;
 letter:array[#0..#255] of Tbuf;
 count,mx,my,blokv,i,j:word;
 k,blokz,maxsirb,maxvysb:byte;
 f:file;
 jmeno:string;
 keys:string[2];
 zmena:boolean;
 row,column:byte;
 scrl:array[0..3] of TButton;
 menubutt:array[0..3] of TButton;
 blok:array[0..255] of byte;
 clip:TClip;
 cliptablo:TFNChrInfo;
 menunr:byte;
 menuposun:byte;
 menuoffset:array[0..menuoffsets-1] of word; {menuoffsets jsou na DS:xx ale menudata na CS:xx !}
const
 zoomx:byte=1;
 zoomy:byte=1;
 ofsx:byte=0;
 ofsy:byte=0;
 winx:byte=8;
 winy:byte=8;
 winw:byte=180;
 winh:byte=212;
 wind:byte=2;
 autozoom:boolean=false;
 quadzoom:boolean=true;
 modified:boolean=false;
 pakuj:boolean=false;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure unloadfn;
var z:char;
begin {unloadfn}
 for z:=#0 to #255 do
  with letter[z] do
  if d<>nil then freemem(d,s);
end;  {unloadfn}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure blitz(napis:string);
begin {blitz}
 setmode(3);
 unloadfn;
 bioswrite(napis+#13#10);
 halt(0);
end;  {blitz}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure minimizechar(c:char); forward;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  loadfn(filename:string):boolean;
var
 fn:Tbuf;
 z:char;
 magic:string[length(_fnhead)];
 ofs0:word;
begin {loadfn}
 loadfn:=false;
 if (filename='') or (modified and not volba('File'#13'"'+filename
    +'"'#13'was modified.'#13'Lost changes?','Yes, go ahead','No, please don''t')) then exit;
 assign(f,filename);
 filemode:=0;
 reset(f,1);
 if IOResult<>0 then
  begin
   hlaska('Can''t open file'#13'"'+filename+'".');
   exit;
  end;
 blockread(f,magic[1],length(_fnhead),count);
 magic[0]:=chr(length(_fnhead));
 if magic<>_fnhead then
  begin
   hlaska('File'#13'is not a'#13'FN file.');
   close(f);
   exit;
  end;
 jmeno:='';
 repeat
  blockread(f,z,1,count);
  jmeno:=jmeno+z;
 until z=#0;
 fillchar(tablo,sizeof(tablo),0);
 blockread(f,first,sizeof(first),count);
 blockread(f,last,sizeof(last),count);
 blockread(f,over,sizeof(over),count);
 blockread(f,under,sizeof(under),count);
 blockread(f,addspace,sizeof(addspace),count);
 blockread(f,future,sizeof(future),count);
 blockread(f,tablo[first],(ord(last)-ord(first)+1)*sizeof(TFNChrInfo),count);
 ofs0:=filepos(f);
 with fn do
 begin
  s:=system.filesize(f)-filepos(f);
  getmem(d,s);
  if d=nil then
   begin
    close(f);
    exit;
   end
  else blockread(f,d^,s,count);
 end;
 close(f);
 unloadfn;
 for z:=first to last do
  with letter[z] do
  begin
   s:=tablo[z].vysb*bi2by(tablo[z].sirb);
   if s<>0 then
    begin
     getmem(d,s);
     if d=nil then
      s:=0
     else
      move(ptr(seg(fn.d^),word(longint(ofs(fn.d^))+longint(tablo[z].ofsb)+longint(-ofs0)))^,d^,s);
    end
   else d:=nil
  end;
 with fn do freemem(d,s);
 maxsirb:=0;
 maxvysb:=0;
 for z:=first to last do
  with tablo[z] do
  begin
   if sirb>maxsirb then maxsirb:=sirb;
   if vysb>maxvysb then maxvysb:=vysb;
  end;
 if not autozoom then
  begin
   if maxsirb=0 then zoomx:=1 else zoomx:=bounded(winw div maxsirb,1,winw);
   if maxvysb=0 then zoomy:=1 else zoomy:=bounded(winh div maxvysb,1,winh);
  end;
 modified:=false;
 loadfn:=true;
end;  {loadfn}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  loadfnt(filename:string; fc,lc:char; w:byte):boolean;
var
 z:char;
 h:byte;
begin {loadfnt}
 loadfnt:=false;
 if fc>lc then xchg(fc,lc,sizeof(char));
 h:=fajls.filesize(filename) div (ord(lc)-ord(fc)+1) div bi2by(w);
 if w*h=0 then exit;
 if (filename='') or (modified and not volba('File'#13'"'+filename
    +'"'#13'was modified.'#13'Lost changes?','Yes, go ahead','No, please don''t')) then exit;
 assign(f,filename);
 filemode:=0;
 reset(f,1);
 if IOResult<>0 then
  begin
   hlaska('Can''t open file'#13'"'+filename+'".');
   exit;
  end;
 count:=h*bi2by(w);
 for z:=fc to lc do
  begin
   with letter[z] do
   begin
    if d<>nil then freemem(d,s);
    d:=nil;
    s:=h*bi2by(w);
    getmem(d,s);
    if (d=nil) or (count<>s) or (IOResult<>0) then
     begin
      close(f);
      hlaska('Loading error');
      exit;
     end;
    blockread(f,d^,s,count);
   end;
   with tablo[z] do
   begin
    sirb:=w;
    vysb:=h;
    shift:=w;
    relx:=0;
    rely:=-h;
   end;
  end;
 close(f);
 first:=fc;
 last:=lc;
 modified:=false;
 loadfnt:=true;
end;  {loadfnt}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  savefn(filename:string):boolean;
var
 fn:Tbuf;
 z,y,minpos:char;
 ofs0,ofs1,reals:word;
 l:longint;
 fnhead:string[length(_fnhead)];
 sorted:array[#0..#255] of char;
 min:word;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 function nalezeno(var buf1; s1:word; var buf2; s2:word):word;
 var                   {co nalezeno}    {v cem nalezeno}
  v:boolean;
  i,j:word;
 begin {nalezeno}
  nalezeno:=$FFFF;
  if (s1=0) or (s2=0) or (s2<s1) then exit;
  for i:=0 to s2-s1 do
   begin
    nalezeno:=i;
    for j:=0 to s1-1 do
     if mem[seg(buf1):ofs(buf1)+j]<>mem[seg(buf2):ofs(buf2)+i] then break;
    if (j=s1-1) and (mem[seg(buf1):ofs(buf1)+j]=mem[seg(buf2):ofs(buf2)+i+j]) then exit;
   end;
  nalezeno:=$FFFF;
 end;  {nalezeno}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin {savefn}
 savefn:=false;
 if (filename='') or (fileExists(filename) and not volba('This file,'#13'"'+filename
    +'"'#13'already exists.'#13'Do you wish to'#13'overwrite it?','Yes, go ahead','No! Cancel it!')) then exit;
 l:=0;
 for z:=first to last do {vypocita velikost hromady bitmap, kdyby se zadne neprekryvaly}
  begin
   minimizechar(z);
   inc(l,letter[z].s);
  end;
 if l>$FFFF then
  begin
   hlaska('The font won''t'#13'fit to 64kB'#13'limit.');
   exit;
  end;
 assign(f,filename);
 filemode:=1;
 rewrite(f,1);
 if IOResult<>0 then exit;
 fnhead:=_fnhead;
 blockwrite(f,fnhead[1],length(_fnhead),count);
 blockwrite(f,jmeno[1],length(jmeno),count);
 blockwrite(f,first,sizeof(first),count);
 blockwrite(f,last,sizeof(last),count);
 blockwrite(f,over,sizeof(over),count);
 blockwrite(f,under,sizeof(under),count);
 blockwrite(f,addspace,sizeof(addspace),count);
 blockwrite(f,future,sizeof(future),count);
 with fn do
 begin
  s:=l;
  d:=nil;
  getmem(d,s);
  if d=nil then
   begin
    close(f);
    exit;
   end;
 end;
 ofs0:=filepos(f)+(ord(last)-ord(first)+1)*sizeof(TFNChrInfo);
 reals:=0; {skutecna velikost hromady bitmap, kterou ulozim (ukazuje do fn.d^)}
 case pakuj of
 true: {pokus o pakov n¡}
  begin
   {seradi znaky podle velikosti od nejvetsiho do nejmensiho}
   for z:=first to last do
    begin
     sorted[z]:=z;
     blok[ord(z)]:=blok[ord(z)] and not(_saved);
    end;
   if abs(ord(first)-ord(last))>1 then
    for z:=first to chr(ord(last)-1) do
     if letter[z].s>0 then
      begin
       min:=tablo[z].sirb*tablo[z].vysb;
       minpos:=z;
       for y:=chr(ord(z)+1) to last do
        if (tablo[y].sirb*tablo[y].vysb>min) and (blok[ord(y)] and _saved=0) then
         begin
          min:=tablo[y].sirb*tablo[y].vysb;
          minpos:=y;
         end;
       xchg(sorted[z],sorted[minpos],sizeof(sorted[minpos]));
       blok[ord(minpos)]:=blok[ord(minpos)] or _saved;
      end;
   pset((ord(last)-ord(first)) shr 1+1,255,31,SegA000);
   for z:=first to last do
    begin
     pset((ord(z)-ord(first)) shr 1,255,40,SegA000);
     if letter[sorted[z]].s<>0 then
      begin {pokus¡ se naj¡t bitmapu znaku v prozat¡mn¡m buferu}
       ofs1:=nalezeno(letter[sorted[z]].d^,letter[sorted[z]].s,fn.d^,reals);
       if ofs1=$FFFF then {kdy‘ ho nenajde..}
        begin             {..p©ilep¡ znak na konec hromady bitmap}
         move(letter[sorted[z]].d^,ptr(seg(fn.d^),ofs(fn.d^)+reals)^,letter[sorted[z]].s);
         tablo[sorted[z]].ofsb:=reals+ofs0;
         inc(reals,letter[sorted[z]].s);
        end
       else
        tablo[sorted[z]].ofsb:=ofs1-ofs(letter[sorted[z]].d^);
      end
     else tablo[sorted[z]].ofsb:=0;
    end;
  end;
 false: {jen za©ad¡ bitmapy za sebe}
  for z:=first to last do
   if letter[z].s<>0 then
    begin
     move(letter[z].d^,ptr(seg(fn.d^),ofs(fn.d^)+reals)^,letter[z].s);
     tablo[z].ofsb:=reals+ofs0;
     inc(reals,letter[z].s);
    end
   else tablo[z].ofsb:=ofs0;
 end;
 blockwrite(f,tablo[first],(ord(last)-ord(first)+1)*sizeof(TFNChrInfo),count);
 blockwrite(f,fn.d^,reals,count);
 with fn do freemem(d,s);
 close(f);
 quad(0,255,129,1,0,SegA000);
 modified:=false;
 savefn:=true;
end;  {savefn}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure drawchars;
var c:byte;
begin {drawchars}
 for c:=0 to 255 do
  fw(chr(c),winx+winw+wind+2+(c and 7) shl 3,c and $F8
  ,$1E+byte((c>=ord(first)) and (c<=ord(last)))+$0400*(blok[c] and _inBlock)
  ,$0808,SegA000,font8x8);
end;  {drawchars}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure drawcur(white:boolean);
begin {drawcur}
 case white of
 true:
  fw(c,winx+winw+wind+2+(ord(c) and 7) shl 3,ord(c) and $F8,
  $0400*(blok[ord(c)] and _inBlock)+30+byte((ord(c)>=ord(first)) and (ord(c)<=ord(last))),$0808,SegA000,font8x8);
 false:
  fw(c,winx+winw+wind+2+(ord(c) and 7) shl 3,ord(c) and $F8,
  either(blok[ord(c)] and _inBlock=0,clrEmp and $FF00,$0C00)+$1E+byte((ord(c)>=ord(first)) and (ord(c)<=ord(last)))
  ,$0808,SegA000,font8x8);
 end;
end;  {drawcur}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure drawchar;
begin {drawchar}
 with tablo[c] do
 begin
  if (sirb>0) and (ofsx>=sirb) then ofsx:=sirb-1;
  if (vysb>0) and (ofsy>=vysb) then ofsy:=vysb-1;
 end;
 {nakresli okraj okna a vybarvi ho}
 for i:=1 to wind do
  quadb(winx-i,winy-i,winw+i shl 1,winh+i shl 1,24,28,SegA000);
 quad(winx,winy,winw,winh,clrPod,SegA000);
 drawcur(false);
 {pripadne upravi zoom podle aktualniho znaku}
 if autozoom then
  begin
   if tablo[c].sirb=0 then zoomx:=1 else zoomx:=bounded(winw div tablo[c].sirb,1,8);
   if tablo[c].vysb=0 then zoomy:=1 else zoomy:=bounded(winh div tablo[c].vysb,1,8);
  end;
 if quadzoom and (zoomx<>zoomy) then
  if zoomx>zoomy then zoomx:=zoomy else if zoomy>zoomx then zoomy:=zoomx;
 {nakresli okraje znaku}
 with tablo[c] do
 repeat
  if sirb*vysb=0 then break;
  row:=bounded(row,0,vysb-1);
  column:=bounded(column,0,sirb-1);
  if (sirb-ofsx)*zoomx<winw then quad(winx+(sirb-ofsx)*zoomx,winy,1,minw((vysb-ofsy)*zoomy,winh),23,SegA000);
  if (vysb-ofsy)*zoomy<winh then quad(winx,winy+(vysb-ofsy)*zoomy,minw((sirb-ofsx)*zoomx,winw),1,23,SegA000);
  if (winx>=1) and (ofsx=0) then quad(winx-1,winy,1,minw((vysb-ofsy)*zoomy,winh),23,SegA000);
  if (winy>=1) and (ofsy=0) then quad(winx,winy-1,minw((sirb-ofsx)*zoomx,winw),1,23,SegA000);
  if (zoomx>1) and (zoomy>1) then
   for j:=0 to minI(vysb-ofsy-1,winh div zoomy-1) do
    for i:=0 to minI(sirb-ofsx-1,winw div zoomx-1) do
     pset(winx+i*zoomx,winy+j*zoomy,clrDot,SegA000);
  if (column>=ofsx) and ((column-ofsx)*zoomx<=winw) and ((vysb-ofsy)*zoomy<=winh) then
   quad(winx+(column-ofsx)*zoomx,winy+(vysb-ofsy)*zoomy,zoomx,1,3,SegA000);
  if (row>=ofsy) and ((row-ofsy)*zoomy<=winh) and ((sirb-ofsx)*zoomx<=winw) then
   quad(winx+(sirb-ofsx)*zoomx,winy+(row-ofsy)*zoomy,1,zoomy,3,SegA000);
 until true;
 waitfortrace;
 {nakresli samotny znak (nebo jeho vyrez)}
 if (letter[c].d<>nil) and (tablo[c].sirb*tablo[c].vysb<>0) and
    (ofsx<tablo[c].sirb) and (ofsy<tablo[c].vysb) then
  for i:=0 to bounded(maxi(tablo[c].vysb-ofsy-1,0),0,winh div zoomy-1) do
   for j:=0 to bounded(maxi(tablo[c].sirb-ofsx-1,0),0,winw div zoomx-1) do
    if mem[seg(letter[c].d^):ofs(letter[c].d^)+(i+ofsy)*bi2by(tablo[c].sirb)+(j+ofsx) shr 3]
       and ($80 shr ((j+ofsx) and 7))<>0 then
     quad(winx+j*zoomx,winy+i*zoomy,zoomx,zoomy,clrWhite,SegA000);
 {vypise parametry znaku}
 fw(left(stri(ord(c)),4),        28+0*_menuw,winy+winh+wind+2+0*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(tablo[c].sirb),4), 28+0*_menuw,winy+winh+wind+2+1*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(tablo[c].vysb),4), 28+0*_menuw,winy+winh+wind+2+2*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(memavail shr 10)+'k',6),16,winy+winh+wind+2+3*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(tablo[c].shift),4),28+1*_menuw,winy+winh+wind+2+0*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(tablo[c].relx),4), 28+1*_menuw,winy+winh+wind+2+1*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(tablo[c].rely),4), 28+1*_menuw,winy+winh+wind+2+2*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(addspace),4),      28+1*_menuw,winy+winh+wind+2+3*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(ord(first)),4),    28+2*_menuw,winy+winh+wind+2+0*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(ord(last)),4),     28+2*_menuw,winy+winh+wind+2+1*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(over),4),          28+2*_menuw,winy+winh+wind+2+2*8,clrWhite,_stde,SegA000,font4x6);
 fw(left(stri(under),4),         28+2*_menuw,winy+winh+wind+2+3*8,clrWhite,_stde,SegA000,font4x6);
 zmena:=false;
end;  {drawchar}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure Initialize;
const
 _napis:string[4]=#27#26#24#25;
 _menunapis:array[0..3] of char=('','X','?','');
begin {Initialize}
 x256x256;
 setbordercolor(clrBorder);
 pal(clrBorder,0,0,10);
 pal(3,16,36,36);
 pal(255,59,61,63);
 pal(99,63,50,50);
 with clip do
 begin
  d:=nil;
  s:=0;
  paste:=false;
 end;
 if not mysInit then
  begin
   hlaska('Mouse driver is'#13'not installed.');
   blitz('FNED.exe: Cannot continue without mouse.');
  end;
 mysoff;
 mysrange(0,0,scrwidth shl 2-1,scrheight-1);
 fw('CHAR:',  0*_menuw,winy+winh+wind+2+0*8,clrWhite,_stde,SegA000,font4x6);
 fw('WIDTH:', 0*_menuw,winy+winh+wind+2+1*8,clrWhite,_stde,SegA000,font4x6);
 fw('HEIGHT:',0*_menuw,winy+winh+wind+2+2*8,clrWhite,_stde,SegA000,font4x6);
 fw('MEM:',   0*_menuw,winy+winh+wind+2+3*8,clrWhite,_stde,SegA000,font4x6);
 fw('SHIFT:', 1*_menuw,winy+winh+wind+2+0*8,clrWhite,_stde,SegA000,font4x6);
 fw('RELX:',  1*_menuw,winy+winh+wind+2+1*8,clrWhite,_stde,SegA000,font4x6);
 fw('RELY:',  1*_menuw,winy+winh+wind+2+2*8,clrWhite,_stde,SegA000,font4x6);
 fw('ADDSPC:',1*_menuw,winy+winh+wind+2+3*8,clrWhite,_stde,SegA000,font4x6);
 fw('FIRST:', 2*_menuw,winy+winh+wind+2+0*8,clrWhite,_stde,SegA000,font4x6);
 fw('LAST:',  2*_menuw,winy+winh+wind+2+1*8,clrWhite,_stde,SegA000,font4x6);
 fw('OVER:',  2*_menuw,winy+winh+wind+2+2*8,clrWhite,_stde,SegA000,font4x6);
 fw('UNDER:', 2*_menuw,winy+winh+wind+2+3*8,clrWhite,_stde,SegA000,font4x6);
 fw('BLK',winx+winw+wind-12,winy+winh+wind+2+0*8,$681A+5*byte(aply and _blk<>0),_stde,SegA000,font4x6);
 fw('CHR',winx+winw+wind-12,winy+winh+wind+2+1*8,$681A+5*byte(aply and _chr<>0),_stde,SegA000,font4x6);
 fw('ROW',winx+winw+wind-12,winy+winh+wind+2+2*8,$681A+5*byte(aply and _row<>0),_stde,SegA000,font4x6);
 fw('CLM',winx+winw+wind-12,winy+winh+wind+2+3*8,$681A+5*byte(aply and _col<>0),_stde,SegA000,font4x6);
 fw('[ MENU ]', 3*_menuw,winy+winh+wind+2+0*8,$0208,_stde,SegA000,font4x6);
 for i:=0 to 3 do
  scrl[i].Init(_napis[i+1],(winx-wind)*byte(i<2),(winy-wind)*byte(i>1),minw(8,winx-wind),mini(8,winy-wind),false);
 scrl[1].x:=winx+winw+wind-scrl[1].w;
 scrl[3].y:=winy+winh+wind-scrl[3].h;
 for i:=0 to 3 do
  with scrl[i] do
  begin
   d:=1;
   auto:=true;
   show(false);
  end;
 for i:=0 to 3 do
  with menubutt[i] do
  begin
   init(_menunapis[i],3*_menuw+9*4+1,winy+winh+wind+2+i shl 3,8,8,false);
   show(false);
  end;
 for i:=1 to wind do
  quadb(winx-i,winy-i,winw+i shl 1,winh+i shl 1,24,28,SegA000);
 quadG(winx-wind+scrl[0].w,0,winw+wind shl 1-scrl[0].w-scrl[1].w,scrl[0].h,23,22,SegA000);
 quadG(0,winy-wind+scrl[2].h,scrl[2].w,winh+wind shl 1-scrl[2].h-scrl[3].h,23,22,SegA000);
 quad(winx,winy,winw,winh,clrPod,SegA000);
 jmeno:=#0;
 zmena:=true;
end;  {Initialize}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure rolhorizontal(c:char; doleva:boolean);
begin {rolhorizontal}
 with letter[c] do
 if (d<>nil) and (tablo[c].sirb*tablo[c].sirb<>0) then
  if (aply and _row<>0) and (row<=tablo[c].vysb) then
   rolbits(mem[seg(d^):ofs(d^)+row*bi2by(tablo[c].sirb)],tablo[c].sirb,doleva) else
  if aply and (_row+_col)=0 then
   for j:=0 to tablo[c].vysb-1 do
    rolbits(mem[seg(d^):ofs(d^)+j*bi2by(tablo[c].sirb)],tablo[c].sirb,doleva);
end;  {rolhorizontal}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure rolvertical(c:char; nahoru:boolean);
var
 i:byte;
 bak:array[0..31] of byte;
begin {rolvertical}
 if (letter[c].d=nil) or (tablo[c].vysb<2) then exit;
 with letter[c] do
 case nahoru of
 false:
  begin
   move(mem[seg(d^):ofs(d^)+(tablo[c].vysb-1)*bi2by(tablo[c].sirb)],bak[0],bi2by(tablo[c].sirb));
   for i:=tablo[c].vysb-2 downto 0 do
    move(mem[seg(d^):ofs(d^)+ i   *bi2by(tablo[c].sirb)],
         mem[seg(d^):ofs(d^)+(i+1)*bi2by(tablo[c].sirb)],bi2by(tablo[c].sirb));
   move(bak[0],d^,bi2by(tablo[c].sirb));
  end;
 true:
  begin
   move(d^,bak[0],bi2by(tablo[c].sirb));
   for i:=1 to tablo[c].vysb-1 do
    move(mem[seg(d^):ofs(d^)+ i   *bi2by(tablo[c].sirb)],
         mem[seg(d^):ofs(d^)+(i-1)*bi2by(tablo[c].sirb)],bi2by(tablo[c].sirb));
   move(bak[0],mem[seg(d^):ofs(d^)+(tablo[c].vysb-1)*bi2by(tablo[c].sirb)],bi2by(tablo[c].sirb));
  end;
 end;
end;   {rolvertical}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{$I pieces.inc}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin {main}
 setmode(3);
 fillword(mem[SegB800:0],80,$1E20);
 memw[Seg0040:$50]:=0;
 writeln(Left(' FN EDitor v '+_verze,mem[Seg0040:$4A]));
 if fileSize(paramstr(0))<>_exesize then
  begin
   bioswrite('Size of this file has changed!'#13#10);
   bioswrite('Original size: '+stri(_exesize)+#13#10);
   bioswrite('Current  size: '+stri(fileSize(paramstr(0)))+#13#10);
{   repeat keys:=inkeys until keys[1] in [#13,#27,#32];
   if keys[1]=#27 then halt;}
  end;
 feasts;
 if not diskwriteable then bioswrite('You are trying to run FNED on write-protected disk ('+dskCur+':).'#13#10);
 homedir:=paramstr(0);
 while (homedir>'') and (homedir[length(homedir)]<>'\') do dec(homedir[0]);
 if homedir='' then getdir(0,homedir);
 if homedir[length(homedir)]='\' then
  if homedir[0]+homedir[2]+homedir[3]<>#3':\' then dec(homedir[0]);
 fillchar(letter[#0],sizeof(letter),0);
 fillchar(blok[0],sizeof(blok),0);
 Initialize; menudata; runmenu;
 if fileExists(paramstr(1)) then filename:=paramstr(1) else filename:=selectfile('*.fn');
 loadfn(filename);
 drawchars;
 c:=first;
 repeat
  if zmena then drawchar;
  repeat
   mx:=mysx;
   my:=mysy;
   getbitmap(mbk,mx,my,_mysw,_mysh,SegA000);
   putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,17,SegA000);
   repeat
    keys:=inkeys;
    for i:=0 to 3 do if scrl[i].clicked then break;
   until (keys<>'') or (mx<>mysx) or (my<>mysy) or mysn;
   putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,16,SegA000);
   {kdyz je stisknuto tlacitko v bitmape znaku}
   paintchar;
   {kdyz je stisknuto tlacitko v poli znakove sady}
   choosechar;
   {kdyz je stisknuto tlacitko na liste}
   with tablo[c] do
   begin
    if scrl[0].press and (letter[c].d<>nil) then if ofsx>0      then begin dec(ofsx); drawchar; end;
    if scrl[1].press and (letter[c].d<>nil) then if ofsx<sirb-1 then begin inc(ofsx); drawchar; end;
    if scrl[2].press and (letter[c].d<>nil) then if ofsy>0      then begin dec(ofsy); drawchar; end;
    if scrl[3].press and (letter[c].d<>nil) then if ofsy<vysb-1 then begin inc(ofsy); drawchar; end;
   end;
   CheckAttributs;
   {kdyz je stisknuto tlacitko v menu}
   runmenu;
   if (mx=0) and (my=0) and mysn then keys:=#27;
  until keys<>'';
  if ((keys[0]+keys[1]=#2#0) and (pos(keys[2],'jKMHPGORS012/#&%$-'#5#17#19#22#23#16#30#31#32#131)>0)) or
     ((length(keys)=1) and (pos(keys[1],'+-'#18#27#127)>0)) then zmena:=true;
  if ((keys[0]+keys[1]=#2#0) and (pos(keys[2],'jRS012&%$#/-'#5#17#19#22#23#25#32#16#30#31#131)>0)) or
     ((length(keys)=1) and (pos(keys[1],#127)>0)) then modified:=true;
  drawcur(true);
  mem[SegA000:$FFFF]:=32+8*byte(modified);
  case keys[1] of
  #127: {CTRL-Backspace}
   begin
    if aply and _blk<>0 then
     for z:=#0 to #255 do
      if blok[ord(z)] and _inBlock<>0 then
       with letter[z] do
       if (d<>nil) and (tablo[z].sirb*tablo[z].sirb<>0) then
        begin
         if (aply and _row<>0) and (row<=tablo[z].vysb) then
          fillchar(mem[seg(d^):ofs(d^)+row*bi2by(tablo[z].sirb)],bi2by(tablo[z].sirb),0);
         if aply and _col<>0 then
          for j:=0 to tablo[z].vysb-1 do
           mem[seg(d^):ofs(d^)+j*bi2by(tablo[z].sirb)+column shr 3]:=
           mem[seg(d^):ofs(d^)+j*bi2by(tablo[z].sirb)+column shr 3] and not($80 shr (column and 7));
         if aply and (_row+_col)=0 then fillchar(d^,s,0);
        end;
    if aply and _chr<>0 then
     with letter[c] do
     if (d<>nil) and (tablo[c].sirb*tablo[c].sirb<>0) then
      begin
       if (aply and _row<>0) and (row<=tablo[c].vysb) then
        fillchar(mem[seg(d^):ofs(d^)+row*bi2by(tablo[c].sirb)],bi2by(tablo[c].sirb),0);
       if (aply and _col<>0) and (column<=tablo[c].sirb) then
        for j:=0 to tablo[c].vysb-1 do
         mem[seg(d^):ofs(d^)+j*bi2by(tablo[c].sirb)+column shr 3]:=
         mem[seg(d^):ofs(d^)+j*bi2by(tablo[c].sirb)+column shr 3] and not($80 shr (column and 7));
       if aply and (_row+_col)=0 then fillchar(d^,s,0);
      end;
   end;
  '+':
   if (zoomx<winw) or (zoomy<winh) then
    begin
     zoomx:=bounded(zoomx+1,1,winw);
     zoomy:=bounded(zoomy+1,1,winh);
     drawchar;
    end;
  '-':
   if (zoomx>1) or (zoomy>1) then
    begin
     zoomx:=bounded(zoomx-1,1,winw);
     zoomy:=bounded(zoomy-1,1,winh);
     drawchar;
    end;
  #32:
   begin
    blok[ord(c)]:=blok[ord(c)] xor _inBlock;
    drawcur(false);
   end;
  #13: fwx;
  #18: zmena:=true;
  #4: {CTRL-D}
   begin
    asm
     mov  ax,3h
     int  10h
    end;
    {$M 16384,0,0}
    SwapVectors;
    Exec('','');
    SwapVectors;
    {$M 16384,0,262144}
    x256x256;
    fillword(ptr(SegA000,0)^,$8000,0);
    Initialize;
    drawchars;
    drawcur(false);
    if DosError<>0
    then hlaska('DosError number :'+stri(DosError)+#13+DosErrorMsg(DosError))
    else hlaska('DosExitCode number:'#13+stri(DosExitCode));
    keys:='';
   end;
  #0:
   case keys[2] of
   'K': if mem[Seg0040:$17] and 3<>0 then
         if letter[c].d<>nil then
          begin
           resizebitmap(c,tablo[c].sirb-1,tablo[c].vysb);
           dec(tablo[c].shift);
           modified:=true;
          end else
        else c:=chr(wrapped(longint(ord(c)-1),ord(first),ord(last)));
   'M': if mem[Seg0040:$17] and 3<>0 then
         if letter[c].d<>nil then
          begin
           resizebitmap(c,tablo[c].sirb+1,tablo[c].vysb);
           inc(tablo[c].shift);
           keys:=#0#19;
           modified:=true;
          end else
        else c:=chr(wrapped(longint(ord(c)+1),ord(first),ord(last)));
   'H': if mem[Seg0040:$17] and 3<>0 then
         if letter[c].d<>nil then
          begin
           rolvertical(c,true);
           resizebitmap(c,tablo[c].sirb,tablo[c].vysb-1);
           modified:=true;
          end else
        else c:=chr(wrapped(longint(ord(c)-8),ord(first),ord(last)));
   'P': if mem[Seg0040:$17] and 3<>0 then
         if letter[c].d<>nil then
          begin
           resizebitmap(c,tablo[c].sirb,tablo[c].vysb+1);
           rolvertical(c,false);
           dec(tablo[c].rely);
           modified:=true;
          end else
        else c:=chr(wrapped(longint(ord(c)+8),ord(first),ord(last)));
   'G': c:=first;
   'O': c:=last;
   ';': help;
   '<': {F2}
    begin
     filename:=selectfile('*.fn');
     {$R-N-}
     if (filename<>'') and not savefn(filename) then hlaska('The font'#13'was not'#13'saved!');
     {$R+N+}
     drawchars;
     drawcur(false);
     zmena:=true;
    end;
   '-': keys:=#27; {Alt-X}
   '=': {F3}
    begin
     filename:=selectfile('*.fn');
     if (filename<>'') and not loadfn(filename) then hlaska('The font'#13'was not'#13'loaded!');
     drawchars;
     c:=chr(bounded(ord(c),ord(first),ord(last)));
     drawcur(false);
     zmena:=true;
    end;
   'A': {F7}
    if (blokz=ord(c)) and (blokv=0) then
     begin
      blokz:=0;
      blokv:=256;
      for i:=blokz to blokz+blokv-1 do blok[byte(i)]:=blok[byte(i)] or 1;
      drawchars;
      drawcur(false);
     end
    else
     begin
      blokz:=ord(c);
      blokv:=0;
      for i:=0 to sizeof(blok)-1 do blok[byte(i)]:=blok[byte(i)] and $FE;
      drawchars;
      drawcur(false);
     end;
   'B': {F8}
    begin
     if blokv>0 then for i:=blokz to blokz+blokv-1 do blok[byte(i)]:=blok[byte(i)] xor _inBlock;
     blokv:=ord(c)+byte(blokz>ord(c)) shl 8-blokz+1;
     if blokv>0 then for i:=blokz to blokz+blokv-1 do blok[byte(i)]:=blok[byte(i)] xor _inBlock;
     drawchars;
     drawcur(false);
    end;
   'S': {Del}
    with letter[c] do
    begin
     if aply and _blk<>0 then {s blokem, clipboard se neuplatnuje}
      begin
       if (aply and (_row or _col)=0) and volba('Delete all characters'#13'in block?','Yes, go ahead','No, cancel it!') then
        begin
         for z:=#0 to #255 do
          if blok[ord(z)] and _inBlock<>0 then
           with letter[z] do
           begin
            if d<>nil then freemem(d,s);
            d:=nil;
            s:=0;
            tablo[z].sirb:=0;
            tablo[z].vysb:=0;
           end;
         drawchar;
        end;
       if (aply and _row<>0) and
          volba('Delete marked row of every'#13'character in block?','Yes, go ahead','No, cancel it!') then
        for z:=#0 to #255 do
         if blok[ord(z)] and _inBlock<>0 then
          with tablo[z] do
          if letter[z].d<>nil then
           begin
            for i:=row+1 to vysb-1 do
             move(mem[seg(letter[z].d^):ofs(letter[z].d^)+i*bi2by(sirb)]
             ,mem[seg(letter[z].d^):ofs(letter[z].d^)+(i-1)*bi2by(sirb)],bi2by(sirb));
            resizebitmap(z,sirb,vysb-1);
           end;
      end;
     if aply=_chr then {bez bloku}
      begin
       if d<>nil then freemem(d,s);
       d:=nil;
       s:=0;
       tablo[c].sirb:=0;
       tablo[c].vysb:=0;
      end;
     if aply and _row<>0 then
      with tablo[c] do
      if letter[c].d<>nil then
       begin
        for i:=row+1 to vysb-1 do
         move(mem[seg(letter[c].d^):ofs(letter[c].d^)+i*bi2by(sirb)]
         ,mem[seg(letter[c].d^):ofs(letter[c].d^)+(i-1)*bi2by(sirb)],bi2by(sirb));
        resizebitmap(c,sirb,vysb-1);
       end;
    end;
   #7: {Shift-Del}
    with letter[c] do
    begin
     if clip.d<>nil then freemem(clip.d,clip.s);
     clip.d:=nil;
     if aply=_chr then
      begin
       clip.s:=letter[c].s;
       if s>0 then getmem(clip.d,clip.s);
       if (d<>nil) and (clip.d<>nil) then move(letter[c].d^,clip.d^,s) else clip.s:=0;
       clip.paste:=false;
       if d<>nil then freemem(d,s);
       d:=nil;
       s:=0;
       clip.w:=tablo[c].sirb;
       clip.h:=tablo[c].vysb;
       tablo[c].sirb:=0;
       tablo[c].vysb:=0;
      end;
     if aply and _row<>0 then
      begin
       with clip do
       begin
        w:=tablo[c].sirb;
        h:=1;
        s:=bi2by(tablo[c].sirb);
        if s>0 then getmem(d,s);
        if (letter[c].d<>nil) and (d<>nil) then
         move(mem[seg(letter[c].d^):ofs(letter[c].d^)+row*bi2by(tablo[c].sirb)],clip.d^,clip.s);
        paste:=true;
       end;
       with tablo[c] do
       if letter[c].d<>nil then
        begin
         for i:=row+1 to vysb-1 do
          move(mem[seg(letter[c].d^):ofs(letter[c].d^)+i*bi2by(sirb)]
          ,mem[seg(letter[c].d^):ofs(letter[c].d^)+(i-1)*bi2by(sirb)],bi2by(sirb));
         resizebitmap(c,sirb,vysb-1);
        end;
      end;
     drawchar;
    end;
   'R',#5: {Ins}
    if mem[Seg0040:$17] and 3<>0 then
     with clip do
     begin {Shift-Ins}
      if d<>nil then freemem(d,s);
      s:=letter[c].s;
      w:=tablo[c].sirb;
      h:=tablo[c].vysb;
      paste:=false;
      getmem(d,s);
      if d<>nil then
       begin
        move(letter[c].d^,d^,s);
        move(tablo[c],cliptablo,sizeof(tablo[c]));
       end
      else s:=0;
     end
    else
     with letter[c] do
     case clip.paste of
     false:
      begin
       if d<>nil then freemem(d,s);
       d:=nil;
       s:=clip.s;
       if s>0 then getmem(d,s);
       if d=nil then s:=0 else
        if clip.d<>nil then
         begin
          move(clip.d^,letter[c].d^,s);
          move(cliptablo,tablo[c],sizeof(tablo[c]));
         end;
       tablo[c].sirb:=clip.w;
       tablo[c].vysb:=clip.h;
       drawchar;
      end;
     true:
      begin
       paste;
       drawchar;
       keys:='';
      end;
     end;
   #19,'&': {alt-r, alt-l}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if blok[ord(z)] and _inBlock<>0 then
        rolhorizontal(z,keys[2]='&');
     if aply and _chr<>0 then rolhorizontal(c,keys[2]='&');
    end;
   '#': {alt-h}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if blok[ord(z)] and _inBlock<>0 then
        with letter[z] do
        if (d<>nil) and (tablo[z].sirb*tablo[z].sirb<>0) then
         if (aply and _row<>0) and (row<=tablo[z].vysb)  then
          for i:=0 to (tablo[z].sirb-1) shr 1 do
           xchgbit(mem[seg(d^):ofs(d^)+row*bi2by(tablo[z].sirb)+i shr 3],7-i and 7
           ,mem[seg(d^):ofs(d^)+row*bi2by(tablo[z].sirb)+(tablo[z].sirb-1-i) shr 3]
           ,7-(tablo[z].sirb-1-i) and 7)
         else if aply and (_row+_col)=0 then
          for j:=0 to tablo[z].vysb-1 do
           for i:=0 to (tablo[z].sirb-1) shr 1 do
            xchgbit(mem[seg(d^):ofs(d^)+j*bi2by(tablo[z].sirb)+i shr 3],7-i and 7
            ,mem[seg(d^):ofs(d^)+j*bi2by(tablo[z].sirb)+(tablo[z].sirb-1-i) shr 3]
            ,7-(tablo[z].sirb-1-i) and 7);
     if aply and _chr<>0 then
      with letter[c] do
      if (d<>nil) and (tablo[c].sirb*tablo[c].sirb<>0) then
       if (aply and _row<>0) and (row<=tablo[z].vysb)  then
        for i:=0 to (tablo[c].sirb-1) shr 1 do
         xchgbit(mem[seg(d^):ofs(d^)+row*bi2by(tablo[c].sirb)+i shr 3],7-i and 7
         ,mem[seg(d^):ofs(d^)+row*bi2by(tablo[c].sirb)+(tablo[c].sirb-1-i) shr 3],7-(tablo[c].sirb-1-i) and 7)
       else if aply and (_row+_col)=0 then
         for j:=0 to tablo[c].vysb-1 do
          for i:=0 to (tablo[c].sirb-1) shr 1 do
           xchgbit(mem[seg(d^):ofs(d^)+j*bi2by(tablo[c].sirb)+i shr 3],7-i and 7
           ,mem[seg(d^):ofs(d^)+j*bi2by(tablo[c].sirb)+(tablo[c].sirb-1-i) shr 3],7-(tablo[c].sirb-1-i) and 7);
    end;
   '/': {alt-v}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if blok[ord(z)] and _inBlock<>0 then
        with letter[z] do
        if (d<>nil) and (tablo[z].sirb*tablo[z].sirb<>0) then
         begin
          if (aply and _col<>0) and (column<=tablo[z].sirb) then
           for i:=0 to (tablo[z].vysb-1) shr 1 do
            xchgbit(mem[seg(d^):ofs(d^)+i*bi2by(tablo[z].sirb)+column shr 3],7-column and 7
            ,mem[seg(d^):ofs(d^)+(tablo[z].vysb-1-i)*bi2by(tablo[z].sirb)+column shr 3],7-column and 7);
          if aply and (_row+_col)=0 then
           for i:=0 to (tablo[z].vysb-1) shr 1 do
            xchg(mem[seg(d^):ofs(d^)+i*bi2by(tablo[z].sirb)]
            ,mem[seg(d^):ofs(d^)+(tablo[z].vysb-1-i)*bi2by(tablo[z].sirb)]
            ,bi2by(tablo[z].sirb));
         end;
     if aply and _chr<>0 then
       with letter[c] do
       if (d<>nil) and (tablo[c].sirb*tablo[c].sirb<>0) then
        begin
         if (aply and _col<>0) and (column<=tablo[c].sirb) then
          for i:=0 to (tablo[c].vysb-1) shr 1 do
           xchgbit(mem[seg(d^):ofs(d^)+i*bi2by(tablo[c].sirb)+column shr 3],7-column and 7
           ,mem[seg(d^):ofs(d^)+(tablo[c].vysb-1-i)*bi2by(tablo[c].sirb)+column shr 3],7-column and 7);
         if aply and (_row+_col)=0 then
          for i:=0 to (tablo[c].vysb-1) shr 1 do
           xchg(mem[seg(d^):ofs(d^)+i*bi2by(tablo[c].sirb)]
           ,mem[seg(d^):ofs(d^)+(tablo[c].vysb-1-i)*bi2by(tablo[c].sirb)]
           ,bi2by(tablo[c].sirb));
        end;
    end;
   #22,#32: {alt-u, alt-d}
    begin
     keys[1]:=upcase(keys[1]);
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if blok[ord(z)] and _inBlock<>0 then
        with letter[z] do
        if (d<>nil) and (tablo[z].vysb>1) then
         rolvertical(z,keys[2]=#22);
     if aply and _chr<>0 then
      with letter[c] do
      if (d<>nil) and (tablo[c].vysb>1) then
       rolvertical(c,keys[2]=#22);
    end;
   #23: {alt-i}
    begin
     if aply and _blk<>0 then
       for z:=#0 to #255 do
        if blok[ord(z)] and _inBlock<>0 then
         with letter[z] do
         if (d<>nil) and (tablo[z].sirb*tablo[z].sirb<>0) then
          begin
           if (aply and _row<>0) and (row<=tablo[z].vysb) then
            invbitmap(mem[seg(d^):ofs(d^)+row*bi2by(tablo[z].sirb)],bi2by(tablo[z].sirb));
           if (aply and _col<>0) and (column<=tablo[z].sirb) then
            for j:=0 to tablo[z].vysb-1 do
             mem[seg(d^):ofs(d^)+j*bi2by(tablo[z].sirb)+column shr 3]:=
             mem[seg(d^):ofs(d^)+j*bi2by(tablo[z].sirb)+column shr 3] xor ($80 shr (column and 7));
           if aply and (_row+_col)=0 then invbitmap(d^,s);
          end;
     if aply and _chr<>0 then
      with letter[c] do
      if (d<>nil) and (tablo[c].sirb*tablo[c].sirb<>0) then
       begin
        if (aply and _row<>0) and (row<=tablo[c].vysb)  then
         invbitmap(mem[seg(d^):ofs(d^)+row*bi2by(tablo[c].sirb)],bi2by(tablo[c].sirb));
        if (aply and _col<>0) and (column<=tablo[c].sirb) then
         for j:=0 to tablo[c].vysb-1 do
          mem[seg(d^):ofs(d^)+j*bi2by(tablo[c].sirb)+column shr 3]:=
          mem[seg(d^):ofs(d^)+j*bi2by(tablo[c].sirb)+column shr 3] xor ($80 shr (column and 7));
        if aply and (_row+_col)=0 then invbitmap(d^,s);
       end;
    end;
   #17: {alt-w}
    sWapchars;
   '2': {alt-m}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if blok[ord(z)] and _inBlock<>0 then minimizechar(z);
     if aply and _chr<>0 then minimizechar(c);
    end;
   '$','%': {alt-j, alt-k, (nakloneni)}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if blok[ord(z)] and _inBlock<>0 then
         torsechar(z,keys[2]='$');
     if aply and _chr<>0 then torsechar(c,keys[2]='$');
    end;
   '0','1': {alt-b, alt-n, (tlustsi/tenci)}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if blok[ord(z)] and _inBlock<>0 then
         tloustkaznaku(z,keys[2]='0');
     if aply and _chr<>0 then tloustkaznaku(c,keys[2]='0');
    end;
   #25: {alt-p}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if blok[ord(z)] and _inBlock<>0 then
        with tablo[z] do if sirb<>0 then shift:=sirb;
     if aply and _chr<>0 then
      with tablo[c] do if sirb<>0 then shift:=sirb;
     fw(left(stri(tablo[c].shift),4),28+_menuw,winy+winh+wind+2+0*8,clrWhite,_stde,SegA000,font4x6);
    end;
   #20: {alt-t}
    rotatechar(c);
   #16: {alt-q}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if (blok[ord(z)] and _inBlock<>0) and (letter[z].d<>nil) then
        with tablo[z] do
        begin
         rolvertical(z,true);
         resizebitmap(z,sirb,vysb-1);
         inc(rely);
        end;
     if aply and _chr<>0 then
      if letter[c].d<>nil then
       with tablo[c] do
       begin
        rolvertical(c,true);
        resizebitmap(c,sirb,vysb-1);
        inc(rely);
       end;
     zmena:=true;
    end;
   #30: {alt-a; urizne jednu radku zezdola}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if (blok[ord(z)] and _inBlock<>0) and (letter[z].d<>nil) then
        with tablo[z] do resizebitmap(z,sirb,vysb-1);
     if aply and _chr<>0 then
      if letter[c].d<>nil then
       with tablo[c] do resizebitmap(c,sirb,vysb-1);
     zmena:=true;
    end;
   #31: {alt-s; urizne jeden sloupec zprava}
    begin
     if aply and _blk<>0 then
      for z:=#0 to #255 do
       if (blok[ord(z)] and _inBlock<>0) and (letter[z].d<>nil) then
        with tablo[z] do
        begin
         resizebitmap(z,sirb-1,vysb);
         dec(shift);
        end;
     if aply and _chr<>0 then
      if letter[c].d<>nil then
       with tablo[c] do
       begin
        resizebitmap(c,sirb-1,vysb);
        dec(shift);
       end;
     zmena:=true;
    end;
   'i': {alt-F2}
    savechain(mem[Seg0040:$17] and 3<>0);
   'j': {alt-F3}
    loadchain;
   'C': {F9}
    begin
     if aply and _blk<>0 then
      begin
       aply:=aply and not(_blk);
       aply:=aply or _chr
      end else
     if aply and _chr<>0 then
      begin
       aply:=aply and not(_chr);
       aply:=aply or _blk
      end;
     fw('BLK',winx+winw+wind-12,winy+winh+wind+2+0*8,$681A+5*byte(aply and _blk<>0),_stde,SegA000,font4x6);
     fw('CHR',winx+winw+wind-12,winy+winh+wind+2+1*8,$681A+5*byte(aply and _chr<>0),_stde,SegA000,font4x6);
     drawcur(false);
    end;
   'V': {shift-F3}
    repeat
     filename:=selectfile('*.fnt');
     if (filename='') then break;
     if GotFNTparams(k) then loadfnt(filename,first,last,k) else filename:='';
     {*nastavit sizeover a sizeunder}
    until true;
   #131: {alt-=, czmakro}
    czechmacro;
   end;
  #2:
   begin
    menunr:=ord(keys[2]);
    menuposun:=0;
    runmenu;
   end;
  else
   begin
    c:=chr(bounded(ord(keys[1]),ord(first),ord(last)));
    zmena:=true;
   end;
  end;
  if keys=#27 then
   begin
    case modified of
    false:
     if volba('Do you wish'#13'to quit?','Yes, please','Not yet') then break;
    true:
     if volba('You have unsaved'#13'changes. Do you'#13'wish to quit'
      +#13'and lost them?','Yes, exactly','No!') then break;
    end;
    keys:='';
   end;
 until false;
 chdir(homedir);
end.  {main}

 TO_DO:
PRI COPY/PASTE VYREZU NEPOCITAM S POSUNEM
 rotace bitu vertikalne pro sloupec
 sikla by se taky moznost smazat jediny sloupec a posunout zbytek
 stejne tak by melo byt mozno tam jeden radek nebo sloupec pridat
*naky menu
 DOSS Hell (to mi nejde, snad mi s tim pomuze Dement)
 scrollery
 bugfixies v protektu (pri ukladani obcas upadne)
 funkce na uchovani a vpusteni videopameti
 autozoom
*rotace o 90 stupnu nebo transponace {alt-t}
 shrink a expand
 options page
 naky efekty jako je
  nahodne ubrani/pridani par bodu, bloody-efekt, zvetsovani apod.
 vic x-modu (tech neni nikdy d0st :-))

POSTREHY:
 - kazda operace se znakem pujde i pro blok, radku ci sloupec
 - meneni pixelu je dost ubohy, mys ma malou frekvenci
 - na nektery veci se vypina kurzor mysi (ach, ta lenost :-))
 - nemalo znaku je symetrickych nebo skoro symetrickych,
   sikly by se funkce, ktere by toho vyuzivaly.
   napr. presun + prevraceni jedne poloviny znaku na druhou
 - helpfile uz hleda v adresari, ve kterem byl spusten
 - nakonec se vrati do adresare, ve kterem byl spusten
 - mam line! muzu ji pouzit do delani hacku a carek

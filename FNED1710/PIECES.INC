const
 _ff:array[0..7] of byte=($FF,$80,$C0,$E0,$F0,$F8,$FC,$FE);
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure paintchar;
var
 mode:boolean;
 sx,sy,nx,ny:word;
 i,j:byte;
{ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ }
 procedure pixor(i,j:byte);
 var rx,ry:byte;
 begin
  if (zoomx=1) or (zoomy=1) then
   begin
    pset(winx+i*zoomx,winy+j*zoomy
    ,pget(winx+i*zoomx,winy+j*zoomy,SegA000) xor xorbyte,SegA000);
    exit;
   end;
  for ry:=0 to zoomy-zoomy shr 2 do
   for rx:=0 to zoomx-zoomx shr 2 do
    pset(winx+i*zoomx+zoomx shr 3+rx,winy+j*zoomy+zoomy shr 3+ry
    ,pget(winx+i*zoomx+zoomx shr 3+rx,winy+j*zoomy+zoomy shr 3+ry,SegA000) xor xorbyte,SegA000);
 end;
{ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ }
 procedure markquad;
 var i,j:byte;
 begin {markquad}
  for j:=maxI(minW(ny,sy),0) to minW(maxW(ny,sy),tablo[c].vysb-1) do
   for i:=maxI(minW(nx,sx),0) to minW(maxW(nx,sx),tablo[c].sirb-1) do
    if ((i=minW(nx,sx)) or (i=maxW(nx,sx))) or
       ((j=minW(ny,sy)) or (j=maxW(ny,sy))) then pixor(i-ofsx,j-ofsy);
 end;  {markquad}
{ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ }
begin {paintchar}
 if tablo[c].vysb*tablo[c].sirb=0 then exit;
 if isin(mx,winx+longint(tablo[c].sirb-ofsx)*zoomx,winx+longint(tablo[c].sirb-ofsx)*(zoomx+1)) and
    (longint(tablo[c].sirb-ofsx)*zoomx<=winw) and
    isin(my,winy,winy+minI(longint(tablo[c].vysb-ofsy)*zoomy-1,winh-1)) and mysl then
  begin
   row:=ofsy+(my-winy) div zoomy;
   with tablo[c] do
   begin
    if (sirb-ofsx)*zoomx<winw then quad(winx+(sirb-ofsx)*zoomx,winy,1,minw((vysb-ofsy)*zoomy,winh),23,SegA000);
    if ((sirb-ofsx)*zoomx<winw) and (row>=ofsy) and ((row-ofsy+1)*zoomy<winh) then
     quad(winx+(sirb-ofsx)*zoomx,winy+(row-ofsy)*zoomy,1,zoomy,3,SegA000);
   end;
  end;
 if isin(my,winy+(tablo[c].vysb-ofsy)*zoomy,winy+(tablo[c].vysb-ofsy)*(zoomy+1)) and
    ((tablo[c].vysb-ofsy)*zoomy<=winh) and
    isin(mx,winx,winx+minI((tablo[c].sirb-ofsx)*zoomx-1,winw-1)) and mysl then
  begin
   column:=ofsx+(mx-winx) div zoomx;
   with tablo[c] do
   begin
    if (vysb-ofsy)*zoomy<winh then quad(winx,winy+(vysb-ofsy)*zoomy,minw((sirb-ofsx)*zoomx,winw),1,23,SegA000);
    if ((vysb-ofsy)*zoomy<winh) and (column>=ofsx) and ((column-ofsx+1)*zoomx<winw) then
     quad(winx+(column-ofsy)*zoomx,winy+(vysb-ofsy)*zoomy,zoomx,1,3,SegA000);
   end;
  end;
 if isin(mx,winx,winx+minI((tablo[c].sirb-ofsx)*zoomx-1,winw-1)) and
    isin(my,winy,winy+minI((tablo[c].vysb-ofsy)*zoomy-1,winh-1)) and mysn then
  begin {kurzor je v editacnim poli a je stisknuto nejake tlacitko}
   modified:=true;
   mode:=mem[seg(letter[c].d^):ofs(letter[c].d^)+((my-winy) div zoomy+ofsy)*bi2by(tablo[c].sirb)
             +((mx-winx) div zoomx+ofsx) shr 3]
         and ($80 shr (((mx-winx) div zoomx+ofsx) and 7))=0;
   if mysl then {stisk leveho tlacitka}
    if mem[Seg0040:$17] and 3=0 then
     repeat {bez shiftu}
      getbitmap(mbk,mx,my,minw(_mysw,scrwidth-mx),minw(_mysh,scrheight-my),SegA000);
      putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,17,SegA000);
      waitticks(1);
      putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,16,SegA000);
      if isin(mx,winx,winx+minI((tablo[c].sirb-ofsx)*zoomx-1,winw-1)) and
         isin(my,winy,winy+minI((tablo[c].vysb-ofsy)*zoomy-1,winh-1)) and mysn then
       if mode then
        begin
         bitset(7-((mx-winx) div zoomx+ofsx) and 7
         ,mem[seg(letter[c].d^):ofs(letter[c].d^)+((my-winy) div zoomy+ofsy)*bi2by(tablo[c].sirb)
          +((mx-winx) div zoomx+ofsx) shr 3]);
         quad(winx+((mx-winx) div zoomx)*zoomx,winy+((my-winy) div zoomy)*zoomy,zoomx,zoomy,clrWhite,SegA000)
        end
       else
        begin
         bitdel(7-((mx-winx) div zoomx+ofsx) and 7
         ,mem[seg(letter[c].d^):ofs(letter[c].d^)+((my-winy) div zoomy+ofsy)*bi2by(tablo[c].sirb)
          +((mx-winx) div zoomx+ofsx) shr 3]);
         quad(winx+((mx-winx) div zoomx)*zoomx,winy+((my-winy) div zoomy)*zoomy,zoomx,zoomy,clrPod,SegA000);
         pset(winx+((mx-winx) div zoomx)*zoomx,winy+((my-winy) div zoomy)*zoomy,clrDot,SegA000);
        end;
      mx:=mysx;
      my:=mysy;
     until (not mysn) or (inkeys=#27)
    else {..leve tlacitko se shiftem}
     begin
      nx:=ofsx+(mx-winx) div zoomx;
      ny:=ofsy+(my-winy) div zoomy;
      repeat
       mx:=bounded(mysx,winx,winx+winw);
       my:=bounded(mysy,winy,winy+winh);
       sx:=ofsx+(mx-winx) div zoomx;
       sy:=ofsy+(my-winy) div zoomy;
       markquad;
       getbitmap(mbk,mx,my,minw(_mysw,scrwidth-mx),minw(_mysh,scrheight-my),SegA000);
       putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,17,SegA000);
       repeat keys:=inkeys
       until (mysx<>mx) or (keys=#27) or (mysy<>my) or not mysn;
       putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,16,SegA000);
       markquad;
       if isin(mx,winx,winx+minI((tablo[c].sirb-ofsx)*zoomx-1,winw-1)) and
          isin(my,winy,winy+minI((tablo[c].vysb-ofsy)*zoomy-1,winh-1)) and mysn then
        begin
         sx:=ofsx+(mx-winx) div zoomx;
         sy:=ofsy+(my-winy) div zoomy;
        end;
      until (not mysn) or (keys=#27);
      if keys=#27 then exit;
      with clip do
      begin
       if d<>nil then freemem(d,s);
       d:=nil;
       w:=maxW(nx,sx)-minW(nx,sx)+1;
       h:=maxW(ny,sy)-minW(ny,sy)+1;
       s:=bi2by(w)*h;
       paste:=true;
       getmem(d,s);
       if d=nil then
        begin
         hlaska('Cannot copy'#13'the range into'#13'clipboard.');
         exit;
        end;
       fillchar(d^,s,0);
      end;
      with clip do
      for j:=minW(ny,sy) to maxW(ny,sy) do
       for i:=minW(nx,sx) to maxW(nx,sx) do
        if mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(tablo[c].sirb)+i shr 3] and ($80 shr (i and 7))<>0 then
         inc(mem[seg(d^):ofs(d^)+(j-minW(ny,sy))*bi2by(w)+(i-minW(nx,sx)) shr 3],$80 shr ((i-minW(nx,sx)) and 7));
     end
   else {stisk praveho tlacitka}
    begin
     sx:=mx;
     sy:=my;
     repeat
      getbitmap(mbk,mx,my,minw(_mysw,scrwidth-mx),minw(_mysh,scrheight-my),SegA000);
      putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,17,SegA000);
      repeat until (mx<>mysx) or (my<>mysy) or not(mysn);
      putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,16,SegA000);
      mx:=mysx;
      my:=mysy;
     until not mysr;
     if isin(mx,winx,winx+minI((tablo[c].sirb-ofsx)*zoomx-1,winw-1)) and
        isin(my,winy,winy+minI((tablo[c].vysb-ofsy)*zoomy-1,winh-1)) then
      begin
       mx:=ofsx+(mx-winx) div zoomx;
       my:=ofsy+(my-winy) div zoomy;
       sx:=ofsx+(sx-winx) div zoomx;
       sy:=ofsy+(sy-winy) div zoomy;
       if mx<sx then xchg(mx,sx,sizeof(mx));
       if my<sy then xchg(my,sy,sizeof(my));
       if mode then
        for j:=sy to my do
         for i:=sx to mx do
          begin
           bitset(7-i and 7,mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(tablo[c].sirb)+i shr 3]);
           quad(winx+(i-ofsx)*zoomx,winy+(j-ofsy)*zoomy,zoomx,zoomy,clrWhite,SegA000);
          end
       else
        for j:=sy to my do
         for i:=sx to mx do
          begin
           bitdel(7-i and 7,mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(tablo[c].sirb)+i shr 3]);
           quad(winx+(i-ofsx)*zoomx,winy+(j-ofsy)*zoomy,zoomx,zoomy,clrPod,SegA000);
           if (zoomx*zoomy<>1) then pset(winx+(i-ofsx)*zoomx,winy+(j-ofsy)*zoomy,clrDot,SegA000);
          end;
      end;
    end;
  end;
end;  {paintchar}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure choosechar;
var mode:boolean;
begin {choosechar}
 if isin(mx,winx+winw+wind+2,winx+winw+wind+65) then
  if mysl then
   begin
    drawcur(true);
    c:=chr(my and $F8+(mx-(winx+winw+wind+1)) shr 3);
    drawchar;
    repeat
     mx:=mysx;
     my:=mysy;
     drawcur(false);
     getbitmap(mbk,mx,my,_mysw,_mysh,SegA000);
     putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,1,SegA000);
     repeat until (mx<>mysx) or (my<>mysy) or not(mysn);
     putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,0,SegA000);
     drawcur(true);
     if isin(mx,winx+winw+wind+2,winx+winw+wind+65) then
      if ord(c)<>my and $F8+(mx-(winx+winw+wind+2)) shr 3 then
       begin
        c:=chr(my and $F8+(mx-(winx+winw+wind+2)) shr 3);
        drawchar;
       end;
    until (not mysn) or (inkeys=#27);
    drawcur(false);
   end else
  if mysr then
   begin
    drawcur(true);
    blokz:=my and $F8+(mx-(winx+winw+wind+1)) shr 3;
    mode:=boolean(blok[blokz] and 1=0);
    repeat
     mx:=mysx;
     my:=mysy;
     if isin(mx,winx+winw+wind+2,winx+winw+wind+65) then
      c:=char(my and $F8+(mx-(winx+winw+wind+2)) shr 3);
     getbitmap(mbk,mx,my,_mysw,_mysh,SegA000);
     putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,1,SegA000);
     repeat until (mx<>mysx) or (my<>mysy) or not(mysn);
     putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,0,SegA000);
    until (not mysn) or (inkeys=#27);
    if isin(mx,winx+winw+wind+2,winx+winw+wind+65) then
     begin
      blokv:=ord(c)+byte(blokz>ord(c)) shl 8-blokz+1;
      if mode then
       for i:=0 to blokv-1 do blok[byte(blokz+i)]:=blok[byte(blokz+i)] or 1
      else
       for i:=0 to blokv-1 do blok[byte(blokz+i)]:=blok[byte(blokz+i)] and $FE;
     end;
    drawchars;
    drawchar;
    drawcur(false);
   end;
end;  {choosechar}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure resizebitmap(c:char; w,h:byte);
var
 pom:Tbuf;
 i:byte;
begin {resizebitmap}
 if ((tablo[c].sirb=w) and (tablo[c].vysb=h)) or (w or h=$FF) then exit;
{ if (bi2by(w)=bi2by(tablo[c].sirb)) and (tablo[c].vysb=h) then
  begin
   tablo[c].sirb:=w;
   for i:=0 to tablo[c].vysb-1 do
    mem[seg(letter[c].d^):ofs(letter[c].d^)+(i+1)*bi2by(tablo[c].sirb)-1]:=
    mem[seg(letter[c].d^):ofs(letter[c].d^)+(i+1)*bi2by(tablo[c].sirb)-1] and _ff[w and 7];
   exit;
  end;}
 if (w=0) or (h=0) then
  with letter[c] do
  begin
   if d<>nil then freemem(d,s); d:=nil;
   tablo[c].sirb:=w;
   tablo[c].vysb:=h;
   exit;
  end;
 with pom do
 begin
  d:=nil;
  s:=bi2by(w)*h;
  getmem(d,s);
  if (s<>0) and (d=nil) then exit;
  fillchar(d^,s,0);
 end;
 if letter[c].d<>nil then
  for i:=0 to minW(tablo[c].vysb,h)-1 do
   begin
    move(mem[seg(letter[c].d^):ofs(letter[c].d^)+i*bi2by(tablo[c].sirb)]
    ,mem[seg(pom.d^):ofs(pom.d^)+i*bi2by(w)],bi2by(w));
   end;
 xchg(letter[c],pom,sizeof(pom));
 with pom do if d<>nil then freemem(d,s);
 tablo[c].sirb:=w;
 tablo[c].vysb:=h;
end;  {resizebitmap}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure CheckAttributs;
begin {CheckAttributs}
 if IsIn(mx,0*_menuw,_menuw-1) and IsIn(my,winy+winh+wind+2,winy+winh+wind+7+0*8) and mysn then
  begin
   modified:=true;
   drawcur(true);
   s:=input(stri(ord(c)),28,winy+winh+wind+2+0*8,3,clrWhite,1,_stde,SegA000,font4x6);
   if (length(s)=1) and not(s[1] in ['0'..'9']) then c:=s[1] else c:=chr(valu(s));
   drawcur(false);
   drawchar;
  end;
 if IsIn(mx,0*_menuw,_menuw-1) and IsIn(my,winy+winh+wind+2+1*8,winy+winh+wind+7+1*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(tablo[c].sirb),28,winy+winh+wind+2+1*8,3,clrWhite,1,_stde,SegA000,font4x6);
   if aply and _blk<>0 then
    if volba('Set this property for:'#13,'All marked chars','Current character') then
     for z:=#0 to #255 do
      if (blok[ord(z)] and _inBlock<>0) and (letter[z].d<>nil) then
       with tablo[z] do resizebitmap(z,valu(s),tablo[c].vysb) else
    else
     with tablo[c] do resizebitmap(z,valu(s),tablo[c].vysb);
   if aply and _chr<>0 then resizebitmap(c,valu(s),tablo[c].vysb);
   drawchar;
  end;
 if IsIn(mx,0*_menuw,_menuw-1) and IsIn(my,winy+winh+wind+2+2*8,winy+winh+wind+7+2*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(tablo[c].vysb),28,winy+winh+wind+2+2*8,3,clrWhite,1,_stde,SegA000,font4x6);
   if aply and _blk<>0 then
    if volba('Set this property for:','All marked chars','Current character') then
     for z:=#0 to #255 do
      if (blok[ord(z)] and _inBlock<>0) and (letter[z].d<>nil) then
       with tablo[z] do resizebitmap(z,tablo[c].sirb,valu(s)) else
    else
     with tablo[c] do resizebitmap(z,tablo[c].sirb,valu(s));
   if aply and _chr<>0 then resizebitmap(c,tablo[c].sirb,valu(s));
   drawchar;
  end;
 if IsIn(mx,1*_menuw,2*_menuw-1) and IsIn(my,winy+winh+wind+2+0*8,winy+winh+wind+7+0*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(tablo[c].shift),28+1*_menuw,winy+winh+wind+2+0*8,4,clrWhite,1,_stde,SegA000,font4x6);
   if aply and _blk<>0 then
    if volba('Set this property for:','All marked chars','Current character') then
     for z:=#0 to #255 do
      if blok[ord(z)] and _inBlock<>0 then
      with tablo[z] do tablo[z].shift:=valu(s) else
    else
     with tablo[c] do tablo[z].shift:=valu(s);
   if aply and _chr<>0 then tablo[c].shift:=valu(s);
  end;
 if IsIn(mx,1*_menuw,2*_menuw-1) and IsIn(my,winy+winh+wind+2+1*8,winy+winh+wind+7+1*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(tablo[c].relx),28+1*_menuw,winy+winh+wind+2+1*8,4,clrWhite,1,_stde,SegA000,font4x6);
   if aply and _blk<>0 then
    if volba('Set this property for:','All marked chars','Current character') then
     for z:=#0 to #255 do
      if blok[ord(z)] and _inBlock<>0 then
      with tablo[z] do tablo[z].relx:=valu(s) else
    else
     with tablo[c] do tablo[z].relx:=valu(s);
   if aply and _chr<>0 then tablo[c].relx:=valu(s);
  end;
 if IsIn(mx,1*_menuw,2*_menuw-1) and IsIn(my,winy+winh+wind+2+2*8,winy+winh+wind+7+2*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(tablo[c].rely),28+1*_menuw,winy+winh+wind+2+2*8,4,clrWhite,1,_stde,SegA000,font4x6);
   if aply and _blk<>0 then
    if volba('Set this property for:','All marked chars','Current character') then
     for z:=#0 to #255 do
      if blok[ord(z)] and _inBlock<>0 then
      with tablo[z] do tablo[z].rely:=valu(s) else
    else
     with tablo[c] do tablo[z].rely:=valu(s);
   if aply and _chr<>0 then tablo[c].rely:=valu(s);
  end;
 if IsIn(mx,1*_menuw,2*_menuw-1) and IsIn(my,winy+winh+wind+2+3*8,winy+winh+wind+7+3*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(addspace),28+1*_menuw,winy+winh+wind+2+3*8,4,clrWhite,1,_stde,SegA000,font4x6);
   addspace:=valu(s);
  end;
 if IsIn(mx,2*_menuw,3*_menuw-1) and IsIn(my,winy+winh+wind+2+0*8,winy+winh+wind+7+0*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(ord(first)),28+2*_menuw,winy+winh+wind+2+0*8,3,clrWhite,1,_stde,SegA000,font4x6);
   first:=chr(valu(s));
   drawchars;
   drawcur(false);
  end;
 if IsIn(mx,2*_menuw,3*_menuw-1) and IsIn(my,winy+winh+wind+2+1*8,winy+winh+wind+7+1*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(ord(last)),28+2*_menuw,winy+winh+wind+2+1*8,3,clrWhite,1,_stde,SegA000,font4x6);
   last:=chr(valu(s));
   drawchars;
   drawcur(false);
  end;
 if IsIn(mx,2*_menuw,3*_menuw-1) and IsIn(my,winy+winh+wind+2+2*8,winy+winh+wind+7+2*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(over),28+2*_menuw,winy+winh+wind+2+2*8,4,clrWhite,1,_stde,SegA000,font4x6);
   over:=valu(s);
  end;
 if IsIn(mx,2*_menuw,3*_menuw-1) and IsIn(my,winy+winh+wind+2+3*8,winy+winh+wind+7+3*8) and mysn then
  begin
   modified:=true;
   s:=input(stri(under),28+2*_menuw,winy+winh+wind+2+3*8,4,clrWhite,1,_stde,SegA000,font4x6);
   under:=valu(s);
  end;
 {bity}
 if IsIn(mx,winx+winw+wind-12,winx+winw+wind-1) and IsIn(my,winy+winh+wind+2,winy+winh+wind+34) and mysn then
  begin
   if 1 shl ((my-winy-winh-wind-2) shr 3) in [_blk,_chr] then aply:=aply and not(_blk+_chr);
   aply:=aply xor (1 shl ((my-winy-winh-wind-2) shr 3));
   fw('BLK',winx+winw+wind-12,winy+winh+wind+2+0*8,$681A+5*byte(aply and _blk<>0),_stde,SegA000,font4x6);
   fw('CHR',winx+winw+wind-12,winy+winh+wind+2+1*8,$681A+5*byte(aply and _chr<>0),_stde,SegA000,font4x6);
   fw('ROW',winx+winw+wind-12,winy+winh+wind+2+2*8,$681A+5*byte(aply and _row<>0),_stde,SegA000,font4x6);
   fw('CLM',winx+winw+wind-12,winy+winh+wind+2+3*8,$681A+5*byte(aply and _col<>0),_stde,SegA000,font4x6);
   repeat until not mysn;
  end;
end;  {CheckAttributs}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure fwx;
var
 test:string[180];
 x,i,j,k,mx,my:word;
begin {fwx}
 x360x480;
 test:='';
 mysrange(0,0,360 shl 2-1,480-1);
 for k:=1 to length(filename) do
  for j:=0 to 7 do
   for i:=0 to 7 do
    putpixel((k-1) shl 3+i,j+((k-1) div 45) shl 3,byte(font8x8[ord(filename[k]) shl 3+j] and ($80 shr i)<>0)*26);
 repeat
  x:=1;
  if keys=#25 {CTRL-Y} then test:='';
  for k:=1 to length(test) do
   with tablo[test[k]] do
   begin
    if (letter[test[k]].d<>nil) and (sirb*vysb<>0) then
      for j:=0 to vysb-1 do
       for i:=0 to minW(sirb-1,359-x) do
        if mem[seg(letter[test[k]].d^):ofs(letter[test[k]].d^)+j*bi2by(sirb)+i shr 3] and ($80 shr (i and 7))<>0 then
         putpixel(x+relx+i,scrheight shr 1+28+j+rely,15);
    inc(x,shift+addspace);
    if x>359 then
     begin
      test:=copy(test,1,k);
      break;
     end;
   end;
  repeat
   mx:=mysx;
   my:=mysy;
   cursorget(mx,my);
   cursorset(mx,my);
   repeat
    keys:=inkeys
   until (mx<>mysx) or (my<>mysy) or mysn or (keys<>'');
   if mysn then
    begin
     cursorret(mx,my);
     repeat
      j:=mysx;
      k:=mysy;
      WaitForTrace;
      for i:=0 to 480 shr 1-1 do putpixel(j,i shl 1,getpixel(j,i shl 1) xor (32+i mod 72));
      for i:=0 to 360 shr 1-1 do putpixel(i shl 1,k,getpixel(i shl 1,k) xor (32+i mod 72));
      while (j=mysx) and (k=mysy) and (keys='') and mysn do keys:=inkeys;
      for i:=0 to 480 shr 1-1 do putpixel(j,i shl 1,getpixel(j,i shl 1) xor (32+i mod 72));
      for i:=0 to 360 shr 1-1 do putpixel(i shl 1,k,getpixel(i shl 1,k) xor (32+i mod 72));
     until not mysn;
    end;
   cursorret(mx,my);
  until keys<>'';
  clearscreen;
  if keys[1] in [#13,#27] then break else
  if keys[1]=#8 then
   if length(test)>0 then dec(test[0]) else
  else if length(keys)=1 then test:=test+keys[1];
 until false;
 x256x256;
 Initialize;
 drawchars;
 drawcur(false);
 keys:='';
end;  {fwx}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure czechmacro;
const
 _chrs=44;
 ca:array[0.._chrs-1] of char=
 ('à','®','á','©','ë','ò','†','°','Ç','£','ñ','ü','§','É','¢','Ñ','å','ç','ì','™','Å','î',
  'â','õ','Ä','û','í','ù','è','ã','ê','ó','¶','Ü','•','Ö','ï','é','ú','ä','ß','´','ö','ô');
 cb:array[0.._chrs-1] of char=
 ('e','s','c','r','z','y','a','i','e','u','u','t','n','d','o','a','l','l','o','r','u','o',
  'E','S','C','R','Z','Y','A','I','E','U','U','T','N','D','O','A','L','L','O','R','U','O');
 cc:array[0.._chrs shr 1-1] of byte=
 ( 2 , 2 , 2 , 2 , 2 , 1 , 1 , 1 , 1 , 1 , 3 , 5 , 2 , 5 , 1 , 4 , 2 , 5 , 6 , 6 , 4 , 4);
 cp:array[1..6] of byte=(25,30,34,20,8,28);
 {1=carka, 2=hacek, 3=krouzek, 4=prehlaska, 5=apostrof, 6=striska}
begin {czechmacro}
 for i:=0 to _chrs-1 do
  if letter[cb[i]].d<>nil then {je co kopirovat}
   with letter[ca[i]] do
   begin
    if d<>nil then freemem(d,s);
    d:=nil;
    s:=bi2by(tablo[cb[i]].sirb)*(tablo[cb[i]].vysb+tablo[cb[i]].vysb*cp[cc[i mod (_chrs shr 1)]] div 100);
    getmem(d,s);
    if d<>nil then
     begin
      fillchar(d^,s,0);
      move(letter[cb[i]].d^,d^,letter[cb[i]].s);
      move(tablo[cb[i]],tablo[ca[i]],sizeof(tablo[ca[i]]));
      tablo[ca[i]].vysb:=s div bi2by(tablo[ca[i]].sirb);
      dec(tablo[ca[i]].rely,tablo[cb[i]].vysb*cp[cc[i mod (_chrs shr 1)]] div 100);
      for j:=1 to tablo[cb[i]].vysb*cp[cc[i mod (_chrs shr 1)]] div 100 do rolvertical(ca[i],false);
     end;
   end;
end;  {czechmacro}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
function nalevoNic(c:char):boolean;
var i:byte;
begin {nalevoNic}
 nalevoNic:=false;
 if letter[c].d=nil then exit;
 with tablo[c] do
 for i:=0 to vysb-1 do
  if mem[seg(letter[c].d^):ofs(letter[c].d^)+i*bi2by(sirb)] and $80<>0 then exit;
 nalevoNic:=true;
end;  {nalevoNic}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
function napravoNic(c:char):boolean;
const
 _bit:array[0..7] of byte=($01,$80,$40,$20,$10,$08,$04,$02);
var i:byte;
begin {napravoNic}
 napravoNic:=false;
 if letter[c].d=nil then exit;
 with tablo[c] do
 for i:=0 to vysb-1 do
  if mem[seg(letter[c].d^):ofs(letter[c].d^)+(i+1)*bi2by(sirb)-1] and _bit[sirb and 7]<>0 then exit;
 napravoNic:=true;
end;  {napravoNic}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
function nahoreNic(c:char):boolean;
begin {nahoreNic}
 nahoreNic:=false;
 if letter[c].d=nil then exit;
 with letter[c] do
 begin
  mem[seg(d^):ofs(d^)+bi2by(tablo[c].sirb)-1]:=
  mem[seg(d^):ofs(d^)+bi2by(tablo[c].sirb)-1] and _ff[tablo[c].sirb and 7];
  nahoreNic:=cmpbyte(ptr(seg(d^),ofs(d^)),0,bi2by(tablo[c].sirb));
 end;
end;  {nahoreNic}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
function doleNic(c:char):boolean;
begin {doleNic}
 doleNic:=false;
 if letter[c].d=nil then exit;
 with letter[c] do
 begin
  mem[seg(d^):ofs(d^)+s-1]:=mem[seg(d^):ofs(d^)+s-1] and _ff[tablo[c].sirb and 7];
  doleNic:=cmpbyte(ptr(seg(d^),ofs(d^)+(tablo[c].vysb-1)*bi2by(tablo[c].sirb)),0,bi2by(tablo[c].sirb));
 end;
end;  {doleNic}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure minimizechar(c:char);
var i:byte;
begin {minimizechar}
 if letter[c].d=nil then exit;
 with tablo[c] do
 begin
  while nahorenic(c) do
   begin
    rolvertical(c,true);
    resizebitmap(c,sirb,vysb-1);
    rely:=bounded(rely+1,-128,127);
   end;
  while dolenic(c) do resizebitmap(c,sirb,vysb-1);
  while nalevonic(c) do
   begin
    for i:=0 to vysb-1 do
     rolbits(mem[seg(letter[c].d^):ofs(letter[c].d^)+i*bi2by(sirb)],sirb,true);
    resizebitmap(c,sirb-1,vysb);
    relx:=bounded(relx+1,-128,127);
{    shift:=bounded(shift-1,-128,127);}
   end;
  while napravonic(c) do
   begin
    resizebitmap(c,sirb-1,vysb);
{    shift:=bounded(shift-1,-128,127);}
   end;
 end;
end;  {minimizechar}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure swapchars;
var
 i:byte;
 n:word;
begin {swapchars}
 n:=0;
 for i:=0 to 255 do
  n:=n+blok[i] and 1;
 if n<>1 then exit;
 for i:=0 to 255 do
  if blok[i] and 1<>0 then break;
 if chr(i)=c then exit;
 xchg(tablo[chr(i)],tablo[c],sizeof(tablo[c]));
 xchg(letter[chr(i)],letter[c],sizeof(letter[c]));
end;  {swapchars}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure torsechar(c:char; doleva:boolean);
var i,j:byte;
begin {torsechar}
 if letter[c].d=nil then exit;
 with tablo[c] do
 begin
  resizebitmap(c,sirb+(vysb-1) div sklon,vysb);
  inc(shift,(vysb-1) div sklon);
  for i:=0 to vysb-1 do
   for j:=1 to (vysb-1-i) div sklon do
    rolbits(mem[seg(letter[c].d^):ofs(letter[c].d^)+i*bi2by(sirb)],sirb,doleva);
 end;
 minimizechar(c);
end;  {torsechar}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure tloustkaznaku(c:char; vetsi:boolean);
const _fb:array [0..7] of byte=($40,$20,$10,8,4,2,1,$80);
var i,j:byte;
begin {tloustkaznaku}
 with tablo[c] do
 begin
  if (letter[c].d=nil) or (sirb in [0,255]) then exit;
  case vetsi of
  false:
   begin
    dec(shift);
    for j:=0 to vysb-1 do
     begin
      {najdi prvni 1, tu zrus, dec, najdi prvni nulu}
      i:=sirb-1;
      repeat
       while (mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(sirb)+i shr 3]
        and ($80 shr (i and 7))=0) and (i>0) do dec(i);
       if i=0 then break;
       mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(sirb)+i shr 3]:=
       mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(sirb)+i shr 3] and not($80 shr (i and 7));
       if i=0 then break else dec(i);
       while (mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(sirb)+i shr 3]
        and ($80 shr (i and 7))<>0) and (i>0) do dec(i);
      until false;
     end;
    minimizechar(c);
   end;
  true:
   begin
    resizebitmap(c,sirb+1,vysb);
    inc(shift);
    for j:=0 to vysb-1 do
     for i:=sirb-2 downto 0 do
      if mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(sirb)+i shr 3] and ($80 shr (i and 7))<>0 then
      mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(sirb)+(i+1) shr 3]:=
      mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(sirb)+(i+1) shr 3] or _fb[i and 7];
   end; {case true}
  end; {case}
 end; {with}
end;  {tloustkaznaku}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure help;
const
 _rows=31;
var
 g:text;
 r:string[61];
begin {help}
 assign(g,homedir+eitherS(homedir[length(homedir)]='\','','\')+_hlpfile);
 filemode:=0;
 reset(g);
 if IOResult<>0 then
  begin
   hlaska('Cannot open help file'#13'('+_hlpfile+')');
   exit;
  end;
 butt(4,4,scrWidth-8,scrHeight-8,30,28,26,2,SegA000);
 for i:=0 to _rows-1 do
  begin
   readln(g,r); r:=Copy(r,1,61);
   fw(r,8,8+i shl 3,28 shl 8+clrWhite,_stde,SegA000,font4x6);
  end;
 repeat keys:=inkeys until (keys<>'') or mysn;
 close(g);
 fillword(ptr(SegA000,0)^,$8000,0);
 Initialize;
 drawchars;
 drawcur(false);
 keys:='';
end;  {help}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
function  loadchain:boolean;
begin {loadchain}
 loadchain:=false;
 assign(f,_temfile);
 filemode:=0;
 reset(f,1);
 if IOResult<>0 then
  begin
   hlaska('Can''t load'#13'a chain of chars');
   exit;
  end;
 for z:=#0 to #255 do
  if (filepos(f)<system.filesize(f)) and (blok[ord(z)] and _inBlock<>0) then
   begin
    with letter[z] do
    begin
     if d<>nil then
      begin
       freemem(d,s);
       d:=nil;
      end;
    end;
    with tablo[z] do
    begin
     blockread(f,i,1,count);
     blockread(f,tablo[z],sizeof(tablo[z]),count);
     letter[z].s:=bi2by(sirb)*vysb;
    end;
    with letter[z] do
    begin
     getmem(d,s);
     if d=nil then
      begin
       tablo[z].sirb:=0;
       tablo[z].vysb:=0;
      end
     else
      blockread(f,letter[z].d^,letter[z].s,count);
    end;
   end;
 close(f);
 loadchain:=true;
end;  {loadchain}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
function  savechain(add:boolean):boolean;
begin {savechain}
 savechain:=false;
 assign(f,_temfile);
 filemode:=1;
 if add and fileExists(_temfile) then reset(f,1) else rewrite(f,1);
 if IOResult<>0 then
  begin
   hlaska('Can''t save'#13'a chain of chars');
   exit;
  end;
 if add then seek(f,system.filesize(f));
 for z:=#0 to #255 do
  if blok[ord(z)] and _inBlock<>0 then
   begin
    blockwrite(f,z,sizeof(z),count);
    blockwrite(f,tablo[z],sizeof(tablo[z]),count);
    blockwrite(f,letter[z].d^,letter[z].s,count);
   end;
 close(f);
 savechain:=true;
end;  {savechain}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure paste;
const             {pismeno}   {clipboard} {pruhlednost}
 colortable:array[false..true,false..true,false..true] of byte=(
 ((18,20),(29, 26)),
 ((17,30),(31,100)));
var
 ox,oy,i,j:integer;
 pruhlednost:boolean;
begin {paste}
 if (letter[c].d=nil) or (clip.d=nil) then exit;
 pal(clrBorder,0,0,30);
 pruhlednost:=true;
 ox:=0;
 oy:=0;
 repeat
  drawchar;
  for j:=maxI(oy,0) to minI(oy+clip.h-1,tablo[c].vysb-1) do
   for i:=maxI(ox,0) to minI(ox+clip.w-1,tablo[c].sirb-1) do
     quad(winX+(i{-ofsx})*zoomx,winY+(j{-ofsy})*zoomy,zoomx,zoomy,
     colortable
     [mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(tablo[c].sirb)+i shr 3] and ($80 shr (i and 7))<>0
     ,mem[seg(clip.d^):ofs(clip.d^)+(j-maxI(oy,0)-minI(oy,0))*bi2by(clip.w)+(i-maxI(ox,0)-minI(ox,0)) shr 3]
       and ($80 shr ((i-maxI(ox,0)-minI(ox,0)) and 7))<>0
     ,pruhlednost],SegA000);
  repeat keys:=inkeys until keys<>'';
  if keys[0]=#2 then
   case keys[2] of
   'H': oy:=bounded(oy-1,-clip.h+1,tablo[c].vysb-1);
   'P': oy:=bounded(oy+1,-clip.h+1,tablo[c].vysb-1);
   'K': ox:=bounded(ox-1,-clip.w+1,tablo[c].sirb-1);
   'M': ox:=bounded(ox+1,-clip.w+1,tablo[c].sirb-1);
   'G': ox:=0;
   'O': ox:=tablo[c].sirb-clip.w;
   'I': oy:=0;
   'Q': oy:=tablo[c].vysb-clip.h;
   'R': pruhlednost:=not pruhlednost;
   '#': {alt-h}
    with clip do
    for j:=0 to h-1 do
     for i:=0 to (w-1) shr 1 do
      xchgbit(mem[seg(d^):ofs(d^)+j*bi2by(w)+i shr 3],7-i and 7
      ,mem[seg(d^):ofs(d^)+j*bi2by(w)+(w-1-i) shr 3],7-(w-1-i) and 7);
   '/': {alt-v}
    with clip do
    for i:=0 to (h-1) shr 1 do
     xchg(mem[seg(d^):ofs(d^)+i*bi2by(w)]
     ,mem[seg(d^):ofs(d^)+(h-1-i)*bi2by(w)]
     ,bi2by(w));
   #23: {alt-i}
    with clip do invbitmap(d^,s);
   end;
 until (keys[0]=#1) and (keys[1] in [#13,#27,#32]);
 pal(clrBorder,0,0,10);
 if keys=#27 then exit;
 for j:=maxI(oy,0) to minI(oy+clip.h-1,tablo[c].vysb-1) do
  for i:=maxI(ox,0) to minI(ox+clip.w-1,tablo[c].sirb-1) do
   case pruhlednost of
   true:
    if mem[seg(clip.d^):ofs(clip.d^)+(j-maxI(oy,0)-minI(oy,0))*bi2by(clip.w)+(i-maxI(ox,0)-minI(ox,0)) shr 3]
       and ($80 shr ((i-maxI(ox,0)-minI(ox,0)) and 7))<>0 then
     mem[seg(letter[c].d^):ofs(letter[c].d^)+(j+ofsY)*bi2by(tablo[c].sirb)+(i+ofsX) shr 3]:=
     mem[seg(letter[c].d^):ofs(letter[c].d^)+(j+ofsY)*bi2by(tablo[c].sirb)+(i+ofsX) shr 3]
     or ($80 shr ((i+ofsX) and 7));
   false:
    if mem[seg(clip.d^):ofs(clip.d^)+(j-maxI(oy,0)-minI(oy,0))*bi2by(clip.w)+(i-maxI(ox,0)-minI(ox,0)) shr 3]
       and ($80 shr ((i-maxI(ox,0)-minI(ox,0)) and 7))<>0 then
     mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(tablo[c].sirb)+i shr 3]:=
     mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(tablo[c].sirb)+i shr 3]
     or ($80 shr (i and 7))
    else
     mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(tablo[c].sirb)+i shr 3]:=
     mem[seg(letter[c].d^):ofs(letter[c].d^)+j*bi2by(tablo[c].sirb)+i shr 3]
     and not($80 shr (i and 7));
   end;
end;  {paste}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure menudata; assembler;
asm   {menudata}
 jmp  @kod
@Hlavni:
 db   6
 db   8,'(main)  '
 db   8,'File    '
 db   8,'Edit    '
 db   8,'Block   '
 db   8,'Zoom    '
 db   8,'(main)  '
@Soubor:
 db   8
 db   8,'(file)  '
 db   8,'New     '
 db   8,'Open FN '
 db   8,'Open FNT'
 db   8,'Save    '
 db   8,'DOSShell'
 db   8,'Exit    '
 db   8,'(back)  '
@Edituj:
 db   8
 db   8,'(edit)  '
 db   8,'Flip    '
 db   8,'Rotate  '
 db   8,'Invert  '
 db   8,'Italic  '
 db   8,'Special '
 db   8,'Cut at..'
 db   8,'(back)  '
@Blok:
 db   9
 db   8,'(blok)  '
 db   8,'Begin   '
 db   8,'End     '
 db   8,'Char+/- '
 db   8,'Copy    '
 db   8,'Paste   '
 db   8,'blk>file'
 db   8,'file>blk'
 db   8,'(back)  '
@Zoom:
 db   5
 db   8,'(zoom)  '
 db   8,'Zoom+   '
 db   8,'Zoom-   '
 db   8,'Hi-res. '
 db   8,'(back)  '
@Preklop:
 db   4
 db   8,'(Flip)  '
 db   8,'Horiz.  '
 db   8,'Vertic. '
 db   8,'(back)  '
@Rotuj:
 db   6
 db   8,'(rotate)'
 db   8,'Up      '
 db   8,'Down    '
 db   8,'Left    '
 db   8,'Right   '
 db   8,'(back)  '
@Zaklon:
 db   4
 db   8,'(/talic)'
 db   8,'Left    '
 db   8,'Right   '
 db   8,'(back)  '
@Special:
 db   7
 db   8,'(spec.) '
 db   8,'Bolder  '
 db   8,'Slimmer '
 db   8,'Minimal '
 db   8,'Swap    '
 db   8,'CZmacro '
 db   8,'(back)  '
@Odrizni:
 db   5
 db   8,'(Cut at)'
 db   8,'Top     '
 db   8,'Bottom  '
 db   8,'Right s.'
 db   8,'(back)  '
@kod:
 lea  di,menuoffset
 mov  ax,offset @Hlavni
 stosw
 mov  ax,offset @Soubor
 stosw
 mov  ax,offset @Edituj
 stosw
 mov  ax,offset @Blok
 stosw
 mov  ax,offset @Zoom
 stosw
 mov  ax,offset @Preklop
 stosw
 mov  ax,offset @Rotuj
 stosw
 mov  ax,offset @Zaklon
 stosw
 mov  ax,offset @Special
 stosw
 mov  ax,offset @Odrizni
 stosw
end;  {menudata}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure runmenu;
const
 _nejdelsi=9;
 zpet:array[0..menuoffsets-1] of byte=(0,0,0,0,0,2,2,2,2,2);
{Soubor
  Novò
  Otev©i
  Uloë
  DOSShell
  Konec
 Edituj
  P©eklop
   vodorov
   svisle
  Rotuj
   nahoru
   dolu
   doleva
   doprava
  Inverze
  Z†klon
   doleva
   doprava
  Speci†l
   tlust®°
   tenái
   minimal
   z†màna
   czmakro
  Od©°zni
   zezdola
   zeshora
   zprava
 Blok
  zaá†tek
  konec
  znak+/-
  kop°ruj
  p©ilep
  blok->f
  f->blok
 Zoom
  zvàt®i
  zmen®i
  zkou®ka}
var
 menu:array[0.._nejdelsi-1] of string[8];
 i,items,c1max,c2max:byte;
begin {runmenu}
 if keys[0]+keys[1]<>#2#2 then
  if IsIn(mx,3*_menuw,3*_menuw+9*4+8) and IsIn(my,winy+winh+wind+2,winy+winh+wind+2+4*8-1) and mysn then else exit;
 quad(3*_menuw,winy+winh+wind+2,8*4,4*4,2,SegA000);
 if menunr>9 then exit;
 items:=mem[CSeg:menuoffset[menunr]];
 move(mem[CSeg:menuoffset[menunr]+1],menu,items*9);
 c1max:=MinW(items-1,3);
 c2max:=MaxI(items-4,0);
 for i:=0 to c1max do
  fw(menu[menuposun+i],3*_menuw,winy+winh+wind+2+i*8,$0200+either(menuposun+i in [1..items-2],14,8),_stde,SegA000,font4x6);
 if keys[0]+keys[1]=#2#2 then exit;
 if menubutt[0].press then menuposun:=bounded(menuposun-1,0,c2max);
 if menubutt[1].press then menunr:=zpet[menunr];
 if menubutt[2].press then help;
 if menubutt[3].press then menuposun:=bounded(menuposun+1,0,c2max);
 if IsIn(mx,3*_menuw,3*_menuw+8*4-1) and IsIn(my,winy+winh+wind+2,winy+winh+wind+2+4*8-1) then
  if mysl then
   begin
    i:=menuposun+(my-(winy+winh+wind+2)) shr 3;
    fw(menu[i],3*_menuw,winy+winh+wind+2+(i-menuposun)*8,$0220+either(menuposun+i in [1..items-2],14,8),_stde,SegA000,font4x6);
    case menunr of
    _mnHlavni:
     case i of
     1: keys:=#2+chr(_mnSoubor);
     2: keys:=#2+chr(_mnEdituj);
     3: keys:=#2+chr(_mnBlok);
     4: keys:=#2+chr(_mnZoom);
     end;
    _mnSoubor:
     case i of
     {*1: Novy}
     2: keys:=#0'='; {F3}
     3: keys:=#0'D';
     4: keys:=#0'='; {F2}
     5: keys:=#4;
     6: keys:=#27;
     end;
    _mnEdituj:
     case i of
     1: keys:=#2+chr(_mnPreklop);
     2: keys:=#2+chr(_mnRotuj);
     3: keys:=#0#23; {alt-i}
     4: keys:=#2+chr(_mnZaklon);
     5: keys:=#2+chr(_mnSpecial);
     6: keys:=#2+chr(_mnOdrizni);
     end;
    _mnBlok:
     case i of
     1: keys:=#0'A'; {F7}
     2: keys:=#0'B'; {F8}
     3: keys:=' ';
     {*4: musim emulovat shift nebo to napsat primo sem}
     5: keys:=#0'R'; {Ins}
     6: keys:=#0'i'; {alt-F2}
     7: keys:=#0'j'; {alt-F3}
     end;
    _mnZoom:
     case i of
     1: keys:='+';
     2: keys:='-';
     3: keys:=#13;
     end;
    _mnPreklop:
     case i of
     1: keys:=#0'#';
     2: keys:=#0'/';
     end;
    _mnRotuj:
     case i of
     1: keys:=#0#22;
     2: keys:=#0#32;
     3: keys:=#0'&';
     4: keys:=#0#19;
     end;
    _mnZaklon:
     case i of
     1: keys:=#0'$';
     2: keys:=#0'%';
     end;
    _mnSpecial:
     case i of
     1: keys:=#0'0';
     2: keys:=#0'1';
     3: keys:=#0'2';
     4: keys:=#0#17;
     5: keys:=#0#131;
     end;
    _mnOdrizni:
     case i of
     1: keys:=#0#32;
     2: keys:=#0#22;
     3: keys:=#0'&';
     end;
    end;
    if (i=items-1) and (menunr<>_mnHlavni) then
     keys:=#2+chr(zpet[menunr]);
   end
  else keys:=#2+chr(zpet[menunr]);
 while mysn do ;
 if menunr>8 then exit;
 items:=mem[CSeg:menuoffset[menunr]];
 move(mem[CSeg:menuoffset[menunr]+1],menu,items*9);
 c1max:=MinW(items-1,3);
 c2max:=MaxI(items-4,0);
 for i:=0 to c1max do
  fw(menu[menuposun+i],3*_menuw,winy+winh+wind+2+i*8,$0200+either(menuposun+i in [1..items-2],14,8),_stde,SegA000,font4x6);
 waitticks(1);
end;  {runmenu}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
FUNCTION  GotFNTParams(var width:byte):boolean;
var
 sz,_hm:word;
 _first,_last,_w,_h:byte;
 button:array[0..1] of TButton;
begin {GotFNTParams}
 GotFNTParams:=false;
 sz:=fajls.fileSize(filename);
 butt(36,50,112,126,20,22,24,2,SegA000);
 fw('Getting FNT variables',41,      7*8-1,$0,_stde or $80,SegA000,font4x6);
 fw('Getting FNT variables',40,      7*8,$1F,_stde or $80,SegA000,font4x6);
 fw('File size:',40,                 8*8,$1C,_stde or $80,SegA000,font4x6);
 fw(stri(sz)+' bytes',40,            9*8,$1C,_stde or $80,SegA000,font4x6);
 fw('First char ascii code:',40,    10*8,$1C,_stde or $80,SegA000,font4x6);
 fw('Last char ascii code:',40,     12*8,$1C,_stde or $80,SegA000,font4x6);
 fw('Characters in font:',40,       14*8,$1C,_stde or $80,SegA000,font4x6);
 fw('Character width (in dots):',40,16*8,$1C,_stde or $80,SegA000,font4x6);
 fw('Character height:',40,         18*8,$1C,_stde or $80,SegA000,font4x6);
 for i:=0 to 1 do
  with button[i] do
  begin
   init(eitherS(i=0,'Ok','Cancel'),40*(1+i),162,32,10,false);
   d:=1;
   show(pressed);
  end;
 _first:=0;
 _last:=255;
 _w:=8;
 repeat
  if _first>_last then xchg(_first,_last,sizeof(_last));
  _hm:=_last-_first+1;
  _h:=sz div (_hm*bi2by(_w));
  fw(left(stri(_first),3),40,11*8,$1C,_stde,SegA000,font4x6);
  fw(left(stri(_last),3),40, 13*8,$1C,_stde,SegA000,font4x6);
  fw(left(stri(_hm),3),40,   15*8,$1C,_stde,SegA000,font4x6);
  fw(left(stri(_w),3),40,    17*8,$1C,_stde,SegA000,font4x6);
  fw(left(stri(_h),3),40,    19*8,$1C,_stde,SegA000,font4x6);
  mx:=mysx;
  my:=mysy;
  getbitmap(mbk,mx,my,_mysw,_mysh,SegA000);
  putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,17,SegA000);
  repeat
   keys:=inkeys;
  until (keys<>'') or (mx<>mysx) or (my<>mysy) or button[0].clicked or button[1].clicked or mysn;
  case keys[1] of
  #13:
   begin
    button[0].show(true); waitticks(4);
    first:=chr(_first);
    last:=chr(_last);
    width:=_w;
    GotFNTParams:=true;
    break;
   end;
  #27:
   begin
    button[1].show(true); waitticks(4);
    break;
   end;
  end;
  if mysl and isin(mx,36,147) and isin(my,50,19*8+7) then
   case my shr 3 of
   11: _first:=valu(input(stri(_first),40,11*8,3,$1C,0,_stde,SegA000,font4x6));
   13: _last:=valu(input(stri(_last),40,  13*8,3,$1C,0,_stde,SegA000,font4x6));
   15:
    begin
     _hm:=bounded(valu(input(stri(_hm),40,15*8,3,$1C,0,_stde,SegA000,font4x6)),0,255);
     _last:=byte(_first+_hm);
    end;
   17: _w:=valu(input(stri(_w),40,        17*8,3,$1C,0,_stde,SegA000,font4x6));
   19:
    begin
     _h:=valu(input(stri(_h),40,          19*8,3,$1C,0,_stde,SegA000,font4x6));
     _w:=trunc(sz/(_hm*_h));
    end;
   end;
  if button[0].press then
   begin
    first:=chr(_first);
    last:=chr(_last);
    width:=_w;
    GotFNTParams:=true;
    break;
   end;
  if button[1].press then break;
  putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,16,SegA000);
 until false;
 drawchars;
 drawchar;
 keys:='';
end;  {GotFNTParams}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
procedure rotatechar(c:char);
{$DEFINE _transponace}
var
 pom:TBuf;
 j,i:byte;
begin {rotatechar}
 if letter[c].d=nil then exit;
 with pom do
 begin
  d:=nil;
  s:=bi2by(tablo[c].vysb)*tablo[c].sirb;
  getmem(d,s);
  if d=nil then exit;
  fillchar(d^,s,0);
  for j:=0 to tablo[c].vysb-1 do
   for i:=0 to tablo[c].sirb-1 do
    mem[seg(d^):ofs(d^)+i*bi2by(tablo[c].vysb)+j shr 3]:=
    mem[seg(d^):ofs(d^)+i*bi2by(tablo[c].vysb)+j shr 3] or ($80 shr (j and 7))*
    byte(mem[seg(letter[c].d^):ofs(letter[c].d^)+
    ({$IFDEF transponace}j{$ELSE}tablo[c].vysb-1-j{$ENDIF})*bi2by(tablo[c].sirb)+i shr 3] and ($80 shr (i and 7))<>0);
  xchg(tablo[c].sirb,tablo[c].vysb,sizeof(tablo[c].vysb));
  xchg(letter[c],pom,sizeof(pom));
  freemem(d,s);
 end;
 zmena:=true;
end;  {rotatechar}
{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

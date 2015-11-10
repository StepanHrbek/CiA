unit sele;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
interface
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 filename,s:string[80];
function  selectfile(maska:string):string;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
implementation
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
uses dos,syst,fajls,vgax256,maus,button;
const
 _sezmax=1024;
type
 string12=string[12];
 TFileRec=
  record
   name:string12;
   size:longint;
   attr:byte;
  end;
 PFileRec=^TFileRec;
 PFileSelector=^TFileSelector;
 TFileSelector=
 object
  masc:string[22];
  count:word;
  c1,c1max:byte;
  c2,c2max:word;
  sez:array[0.._sezmax-1] of PFileRec;
  constructor Init;
  destructor  Done;
  procedure cleanup;
  function  PreSelektni(fn:string12):boolean;
  procedure nacti;
  procedure serad;
  function  vyber(x,y,h:byte):string;
 end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 ParentDir='..          ';
 CharsInFile  :set of char=['!'..')','-','.','0'..'9','<'..'>','@'..'[',']'..#255,#8];
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  AdjustName(fn:string12; lowcase:boolean):string; assembler;
asm   {AdjustName}
 push ds
 push es
 xor  ch,ch
 lds  si,fn
 lodsb
 mov  bh,al  {BH - puvodni delka stringu}
 or   bh,bh
 jz   @nic
 mov  ah,lowcase
 cmp  bh,12
 jae  @case
 mov  al,ds:[si]
 cmp  al,'.'
 je   @tecka
 les  di,fn
 inc  di
 mov  al,'.'
 mov  cl,bh
 repne scasb
 or   cl,cl
 jz   @nopoint
 mov  bl,cl
 neg  bl
 add  bl,bh  {BL - pozice tecky ve stringu}
 les  di,@result
 mov  al,12
 stosb
 mov  cl,bl
 dec  cl
 cmp  ah,true
 je   @3
@1:
 lodsb
 cmp  al,'a'
 jb   @2
 cmp  al,'z'
 ja   @2
 sub  al,'a'-'A'
@2:
 stosb
 loop @1
 jmp  @5
@3:
 lodsb
 cmp  al,'A'
 jb   @4
 cmp  al,'Z'
 ja   @4
 add  al,'a'-'A'
@4:
 stosb
 loop @3
@5:
 mov  al,' '
 mov  cl,9
 sub  cl,bl
 rep  stosb
 mov  cl,bh
 sub  cl,bl
 inc  cl
 cmp  ah,true
 je   @8
@6:
 lodsb
 cmp  al,'a'
 jb   @7
 cmp  al,'z'
 ja   @7
 sub  al,'a'-'A'
@7:
 stosb
 loop @6
 jmp  @10
@8:
 lodsb
 cmp  al,'A'
 jb   @9
 cmp  al,'Z'
 ja   @9
 add  al,'a'-'A'
@9:
 stosb
 loop @8
@10:
 mov  cl,3
 sub  cl,bh
 add  cl,bl
 or   cl,cl
 jz   @end
 mov  al,' '
 rep  stosb
 jmp  @end
@nic:
 les  di,@result
 mov  al,12
 stosb
 mov  al,' '
 mov  cl,8
 rep  stosb
 mov  al,'.'
 stosb
 mov  al,' '
 mov  cl,3
 rep  stosb
 jmp  @end
@tecka:
 les  di,@result
 mov  al,12
 stosb
 mov  cl,al
 xor  al,al
 rep  stosb
 jmp  @end
@case:
 les  di,@result
 mov  al,12
 stosb
 mov  cl,al
 cmp  ah,true
 je   @case4
@case2:
 lodsb
 cmp  al,'a'
 jb   @case3
 cmp  al,'z'
 ja   @case3
 sub  al,'a'-'A'
@case3:
 stosb
 loop @case2
 jmp  @end
@case4:
 lodsb
 cmp  al,'A'
 jb   @case5
 cmp  al,'Z'
 ja   @case5
 add  al,'a'-'A'
@case5:
 stosb
 loop @case4
 jmp  @end
@nopoint:
 les  di,@result
 mov  al,12
 stosb
 mov  cl,bh
 cmp  ah,true
 je   @nopoint4
@nopoint2:
 lodsb
 cmp  al,'a'
 jb   @nopoint3
 cmp  al,'z'
 ja   @nopoint3
 sub  al,'a'-'A'
@nopoint3:
 stosb
 loop @nopoint2
 jmp  @nopoint6
@nopoint4:
 lodsb
 cmp  al,'A'
 jb   @nopoint5
 cmp  al,'Z'
 ja   @nopoint5
 add  al,'a'-'A'
@nopoint5:
 stosb
 loop @nopoint4
@nopoint6:
 mov  al,' '
 mov  cl,12
 sub  cl,bh
 rep  stosb
 jmp  @end
@end:
 pop  es
 pop  ds
end;  {AdjustName}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
constructor TFileSelector.Init;
var i:word;
begin {TFileSelector.Init}
 for i:=0 to _sezmax-1 do sez[i]:=nil;
 count:=0;
 masc:='';
end;  {TFileSelector.Init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
destructor TFileSelector.Done;
begin {TFileSelector.Done}
 cleanup;
end;  {TFileSelector.Done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure TFileSelector.cleanup;
var i:word;
begin {TFileSelector.cleanup}
 for i:=0 to _sezmax-1 do
  begin
   if sez[i]<>nil then dispose(sez[i]);
   sez[i]:=nil;
  end;
 count:=0;
end;  {TFileSelector.cleanup}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TFileSelector.PreSelektni(fn:string12):boolean;
var j:word;
begin {TFileSelector.PreSelektni}
 Preselektni:=false;
 c1:=0; c2:=0;
 fn:=AdjustName(fn,true);
 if (fn='') or (count<1) then exit;
 for j:=0 to count-1 do
  with sez[j]^ do
  if lcased(name)=fn then
   begin
    c2:=0;
    c1:=j;
    while (c1>c1max) and (c1>0) do
     begin
      dec(c1);
      inc(c2);
     end;
    while (c2>c2max) and (c2>0) do
     begin
      inc(c1);
      dec(c2);
     end;
    Preselektni:=true;
    break;
   end;
end;  {TFileSelector.PreSelektni}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure TFileSelector.nacti;
var
 di:SearchRec;
 p:PFileRec;
begin {TFileSelector.nacti}
 cleanup;
 New(p);
 if p=nil then exit;
 findfirst(masc,AnyFile-VolumeID-Directory,di);
 repeat
  while (di.attr and directory<>0) and (doserror=0) do findnext(di);
  if doserror<>0 then break;
  with p^ do
  begin
   name:=adjustname(di.name,true);
   attr:=byte(di.attr);
   size:=di.size;
  end;
  if count>=_sezmax-1 then exit;
  new(sez[count]);
  if sez[count]=nil then exit;
  sez[count]^:=p^;
  inc(count);
  findnext(di);
 until false;
 findfirst('*.*',AnyFile-VolumeID,di);
 if (doserror=0) and (di.name='.') then findnext(di);
 repeat
  while (di.attr and directory=0) and (doserror=0) do findnext(di);
  if doserror<>0 then break;
  with p^ do
  begin
   name:=adjustname(di.name,false);
   attr:=byte(di.attr);
   size:=0;
  end;
  if count>=_sezmax-1 then exit;
  new(sez[count]);
  if sez[count]=nil then exit;
  sez[count]^:=p^;
  inc(count);
  findnext(di);
 until false;
 if not preselektni('..') and (length(dirCurAt('@'))>3) and (count<_sezmax-1) then
  begin
   with p^ do
   begin
    name:=ParentDir;
    attr:=Directory;
    size:=0;
   end;
   new(sez[count]);
   if sez[count]<>nil then
    begin
     sez[count]^:=p^;
     inc(count);
    end;
  end;
 Dispose(p);
end;  {TFileSelector.nacti}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure TFileSelector.serad;
var
 a,b,minpos:word;
begin {TFileSelector.serad}
 if count>0 then
  for a:=0 to count-1 do
   with sez[a]^ do if name[1]=#0 then name:=ParentDir;
 if count<2 then exit;
 for a:=0 to count-2 do
  begin
   minpos:=a;
   for b:=a+1 to count-1 do
    if (sez[b]^.attr and Directory>sez[minpos]^.attr and Directory) or
       ((sez[b]^.attr and Directory=sez[minpos]^.attr and Directory) and (sez[b]^.name<sez[minpos]^.name)) then
     minpos:=b;
   xchg(sez[a],sez[minpos],sizeof(sez[minpos]));
  end;
end;  {TFileSelector.serad}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TFileSelector.vyber(x,y,h:byte):string;
var
 i,mx,my:word;
 keys:string[2];
 qfind:string[12];
 parent:string[80];
begin {TFileSelector.vyber}
 nacti;
 serad;
 c1:=0;
 c2:=0;
 qfind:='';
 if count>=h then c1max:=h-1 else if count=0 then c1max:=0 else c1max:=count-1;
 if count<h+1 then c2max:=0 else c2max:=count-h-1;
 Preselektni(getfilename(filename));
 quad(x,y,22*8,h shl 3,0,SegA000);
 quad(x,y-12,23*8,8,1,SegA000);
 repeat
  if count>0 then
   for i:=0 to c1max do
    with sez[c2+i]^ do
    fw(name+eitherS(attr and Directory<>0,' <ADRESž>',right(stri(size),10))
    ,x,y+i shl 3,either(i=c1,$010F,$000F),$0808,SegA000,font8x8);
  fw(#30,x+176,y,$0708,$0808,SegA000,font8x8);
  fw(#31,x+176,y+(h-1) shl 3,$0708,$0808,SegA000,font8x8);
  for i:=1 to h-2 do
   fw(#176,x+176,y+i shl 3,$0708,$0808,SegA000,font8x8);
  if (h>2) and (count>h) then
   fw(#254,x+176,y+8+((h-2)*(c1+c2) div (count-1)) shl 3,$0708,$0808,SegA000,font8x8);
  if sez[c1+c2]<>nil then
   begin
    fw(sez[c1+c2]^.name,x,y-12,$012C,$0808,SegA000,font8x8);
    {*zjisti sizeover, sizeunder a zobraz je}
   end;
  repeat
   mx:=mysx;
   my:=mysy;
   getbitmap(mbk,mx,my,_mysw,_mysh,SegA000);
   putbitmap(mys,mx,my,_mysw,_mysh,0,_mysw,17,SegA000);
   repeat
    keys:=inkeys;
   until (keys<>'') or (mx<>mysx) or (my<>mysy) or mysn;
   if mysn then
    begin
     if isin(mx,x,x+23 shl 3-1) and isin(my,y-12,y-4) then keys:=#9;
     if isin(mx,x+22 shl 3,x+22 shl 3+7) and isin(my,y,y+7) then begin waitticks(1); keys:=#0'H'; end;
     if isin(mx,x+22 shl 3,x+22 shl 3+7) and isin(my,y+(h-1) shl 3,y+h shl 3-1) then begin waitticks(1); keys:=#0'P'; end;
     if isin(mx,x,x+22 shl 3-1) and isin(my,y,y+h shl 3-1) then
      if (my-y) shr 3<=c1max then
       begin
        c1:=(my-y) shr 3;
        keys:=#13;
       end;
     if isin(mx,x+22 shl 3,x+22 shl 3+7) and isin(my,y+8,y+(h-1) shl 3-1) then
      if (count>1) and (h>1) then
       begin
        c1:=0;
        c2:=((my-y-8) shr 3)*count div (h-2);
        while (c2>c2max) and (c1<=c1max) do
         begin
          dec(c2);
          inc(c1);
         end;
        keys:=#0;
       end;
    end;
   putbitmap(mbk,mx,my,_mysw,_mysh,0,_mysw,16,SegA000);
  until keys<>'';
  if (length(keys)=1) and (keys[1] in charsinfile) then else qfind:='';
  if (keys=#0'„') and (count>0) and (sez[0]^.name=ParentDir) then begin c1:=0; c2:=0; keys:=#13; end;
  if (keys=#0'v') and (count>0) and (sez[c1+c2]^.attr and Directory<>0) then keys:=#13;
  case keys[0] of
  #1:
   case keys[1] of
   #9:
    repeat
     if sez[c1+c2]<>nil then parent:=withoutchar(' ',sez[c1+c2]^.name) else parent:='';
     parent:=input(parent,x,y-12,23,$010F,1,$0808,SegA000,font8x8);
     quad(x,y-12,23*8,8,1,SegA000);
     if parent[length(parent)]=#9 then break;
     parent:=ucased(getcore(parent));
     if (length(parent)=1) and (pos(parent[1],dskList)>0) then
      begin
       if dskChanged(parent[1])>1 then {*reporterror};
       keys:=#18;
       break;
      end;
     if pos('*',parent)+pos('?',parent)>0 then
      begin
       masc:=getfilename(parent);
       keys:=#18;
       while (length(parent)>0) and not(parent[length(parent)] in [':','\']) do dec(parent[0]);
       if parent[length(parent)]='\' then dec(parent[0]);
       if pos(':',parent)+pos('\',parent)=0 then break;
      end;
     if dirExists(parent) then
      begin
       chDir(parent);
       if IOResult=0 then keys:=#18;
       break;
      end;
     vyber:=parent;
     exit;
    until true;
   #8:
    repeat
     if qfind='' then break else dec(qfind[0]);
     qfind:=lcased(qfind);
     for i:=c2 to count-1 do
      if lcased(Copy(WithoutChar(' ',sez[i]^.name),1,length(qfind)))=qfind then
       begin {nasel soubor zacinajici na qfind}
        c1:=0;
        c2:=i;
        for i:=1 to h shr 1 do
         if (c2>0) and (c1<c1max)
         then begin dec(c2); inc(c1) end
         else break;
        while (c2>c2max) and (c1<=c1max) do
         begin
          dec(c2);
          inc(c1);
         end;
        i:=$FFFF;
        break;
       end;
    until true;
   #13:
    if sez[c1+c2]<>nil then
     if sez[c1+c2]^.attr and Directory<>0 then
      begin
       parent:=getfilename(dirCurAt('@'));
       chdir(withoutchar(' ',sez[c1+c2]^.name));
       i:=byte((sez[c1+c2]^.name<>ParentDir) or (IOResult<>0));
       nacti;
       serad;
       c1:=0;
       c2:=0;
       if i=0 then Preselektni(parent);
       if count>=h then c1max:=h-1 else if count=0 then c1max:=0 else c1max:=count-1;
       if count<h+1 then c2max:=0 else c2max:=count-h-1;
       quad(x,y,22*8,h shl 3,0,SegA000);
      end
     else
      begin
       vyber:=dirCurAt('@')+withoutchar(' ',sez[c1+c2]^.name);
       break;
      end;
   #27:
    begin
     vyber:='';
     break;
    end;
   else
    if (keys[1] in charsinfile) and (count>0) then
     begin
      if qfind[0]<#12
      then qfind:=qfind+keys[1];
      qfind:=lcased(qfind);
      for i:=c2 to count-1 do
       if lcased(Copy(WithoutChar(' ',sez[i]^.name),1,length(qfind)))=qfind then
        begin {nasel string zacinajici na qfind}
         c1:=0;
         c2:=i;
         for i:=1 to h shr 1 do
          if (c2>0) and (c1<c1max) then
           begin
            dec(c2);
            inc(c1)
           end
          else break;
         while (c2>c2max) and (c1<=c1max) do
          begin
           dec(c2);
           inc(c1);
          end;
         i:=$FFFF;
         break;
        end;
      if i<>$FFFF then dec(qfind[0]); {kdyz byl stisknut spatny znak, vymaze ho, aby qfind neukazoval na neexistujici jmeno}
     end;
   end;
  #2:
   case keys[2] of
   'H': if c1>0 then dec(c1) else if c2>0 then dec(c2);
   'P': if c1<c1max then inc(c1) else c2:=minW(c2+1,c2max);
   'G': begin c1:=0; c2:=0; end;
   'O': begin c1:=c1max; c2:=c2max; end;
   'I': if c2=0 then c1:=0 else if c2>h then dec(c2,h) else c2:=0;
   'Q': if c2=c2max then c1:=c1max else c2:=bounded(c2+h,0,c2max);
   #23: if (count>0) and (c2>0) then dec(c2);
   #24: if (count>0) and (c2<c2max) then inc(c2);
   'w': c1:=0;
   'u': c1:=c1max;
   'S':
    if sez[c1+c2]<>nil then
      with sez[c1+c2]^ do
      if (attr and Directory=0) and volba('Delete'#13'"'+withoutchar(' ',name)+'"?','Yes','No') then
       begin
        fileDelete(withoutchar(' ',name));
        keys:=#18;
       end;
   end;
  end;
  if keys=#18 then
   begin
    nacti;
    serad;
    if i=0 then Preselektni(parent);
    if count>=h then c1max:=h-1 else if count=0 then c1max:=0 else c1max:=count-1;
    if count<h+1 then c2max:=0 else c2max:=count-h-1;
    c1:=bounded(c1,0,c1max);
    c2:=bounded(c2,0,c2max);
    quad(x,y,22*8,h shl 3,0,SegA000);
   end;
 until false;
end;  {TFileSelector.vyber}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  selectfile(maska:string):string;
var
 fs:PFileSelector;
 bak:Tbuf;
begin {selectfile}
 selectfile:='';
 new(fs,init);
 if fs=nil then exit;
 fs^.masc:=maska;
 with bak do
 begin
  s:=192*180;
  getmem(d,s);
  if d<>nil then getbitmap(d^,scrwidth shr 1-24*4,30,192,180,SegA000);
 end;
 butt(scrwidth shr 1-24*4,30,192,180,30,28,26,2,SegA000);
 selectfile:=fs^.vyber(scrwidth shr 1-23*4,46,20);
 dispose(fs,done);
 with bak do
 if d<>nil then
  begin
   putbitmap(d^,scrwidth shr 1-24*4,30,192,180,0,192,0,SegA000);
   freemem(d,s);
  end
 else quad(scrwidth shr 1-24*4,30,192,180,0,SegA000);
end;  {selectfile}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin
end.
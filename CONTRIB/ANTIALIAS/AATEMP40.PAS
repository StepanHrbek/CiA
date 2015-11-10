uses syst,vga13h;
const
 p:array[0..23] of byte=(
 0,0,0,
 16,24,10,
 18,29,0,
 18,32,0,
 22,33,0,
 27,40,0,
 31,44,13,
 32,45,15);
type
  TChrInfo=record
    w,h:byte;
    relx,rely:shortint;
    shift:byte;
    d:pointer;
  end;
var
  tablo:array[char] of TChrInfo;
  f:file;
  c,key:char;
  i,j:integer;
begin
  if paramcount<1 then exit;
  assign(f,paramstr(1));
  filemode:=0;
  reset(f,1);
  if IOResult<>0 then exit;
  fillchar(tablo,sizeof(tablo),0);
  c:=' ';
  setmode($13);
  for i:=0 to 15 do pal(i,i*4,i*4,i*4);
{  for i:=0 to 4 do pal(i,i*12,i*12,i*12);
  for i:=0 to 7 do pal(i,p[i*3],p[i*3+1],p[i*3+2]);}
  repeat
    blockread(f,tablo[c],sizeof(tablo[c])-sizeof(pointer));
    with tablo[c] do
    if w*h<>0 then begin
      getmem(d,w*h);
      blockread(f,d^,w*h,i);
      if i<>w*h then break;
    end;
    inc(c);
  until eof(f) or (port[$60]=1);
  close(f);
  c:=' ';
  repeat
    quad(0,59,48,48,8,SegA000);
    with tablo[c] do begin
      if w*h<>0 then
        for j:=0 to h-1 do
          for i:=0 to w-1 do
            mem[SegA000:(rely+j+60)*320+relx+i+1]:=mem[seg(d^):ofs(d^)+j*w+i];
      fw8('"'+c+'"',128,60,31,0,SegA000);                fw4(stri(ord(c))+' ',128,70,31,0,SegA000);
      fw4('w='+stri(w)+' ',160,60,31,0,SegA000);         fw4('h='+stri(h)+' ',200,60,31,0,SegA000);
      fw4('relx='+stri(relx)+' ',160,70,31,0,SegA000);   fw4('rely='+stri(rely)+' ',200,70,31,0,SegA000);
      fw4('shift='+stri(shift)+' ',160,80,31,0,SegA000);
    end;
    key:=readkey;
    case key of
    #27: break;
    #0:
     case readkey of
     'K': dec(c);
     'M': inc(c);
     end;
    end;
  until false;
end.
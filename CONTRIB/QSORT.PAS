uses crt;
type
 TComparePointers=function(p1,p2:pointer):boolean;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE Xchg(var a,b;bytes:word); assembler;
asm   {Xchg}
 push ds
 lds  si,a
 les  di,b
 mov  cx,bytes
@1:
 mov  al,[es:di]
 xchg al,[si]
 stosb
 inc  si
 loop @1
 pop  ds
end;  {Xchg}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function ComparePointers2(p1,p2:pointer):boolean; far;
begin {ComparePointers}
 ComparePointers2:=word(p1^)>word(p2^);
end;  {ComparePointers}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  QSort(pole:pointer; itemsize,count:word; ComparePointers:TComparePointers):boolean;
type
 TZasobnik=
  record
   zac,kon:word;
  end;
 PStack=^TStack;
 TStack=array[0..$FFF8 div sizeof(TZasobnik)-1] of TZasobnik;
var
 stack:Pstack;
 stacksize:word;
 sp:integer;
 zac,kon,levy,pravy:word;
 prostredni:pointer;
begin {QSort}
 QSort:=false;
 if (count*itemsize=0) or (addr(ComparePointers)=nil) then exit; {*chyba: spatne zadane hodnoty}
 stacksize:=(count shr 1+1)*itemsize;
 getmem(stack,stacksize);
 if stack=nil then exit; {*chyba: stack se nevejde do pameti}
 sp:=1;
 stack^[1].zac:=0;
 stack^[1].kon:=count-1;
 repeat
  zac:=stack^[sp].zac;
  kon:=stack^[sp].kon;
  dec(sp);
  repeat
   levy:=zac;
   pravy:=kon;
   prostredni:=ptr(seg(pole^),ofs(pole^)+((zac+kon) shr 1)*itemsize);
   repeat
    while ComparePointers(prostredni,ptr(seg(pole^),ofs(pole^)+levy*itemsize)) do inc(levy);
    while ComparePointers(ptr(seg(pole^),ofs(pole^)+pravy*itemsize),prostredni) do dec(pravy);
    if (levy>=count) or (integer(pravy)<0) then halt;
    if levy<=pravy then {vymena}
     begin
      if prostredni=ptr(seg(pole^),ofs(pole^)+levy*itemsize) then
       prostredni:=ptr(seg(pole^),ofs(pole^)+pravy*itemsize) else
      if prostredni=ptr(seg(pole^),ofs(pole^)+pravy*itemsize) then
       prostredni:=ptr(seg(pole^),ofs(pole^)+levy*itemsize);
      xchg(ptr(seg(pole^),ofs(pole^)+levy*itemsize)^,ptr(seg(pole^),ofs(pole^)+pravy*itemsize)^,itemsize);
      inc(levy);
      dec(pravy);
     end;
   until levy>pravy;
   if levy<kon then
    begin
     inc(sp);
     stack^[sp].zac:=levy;
     stack^[sp].kon:=kon;
    end;
   kon:=pravy;
  until zac>=kon;
 until sp=0;
 freemem(stack,stacksize);
 QSort:=true;
end;  {QSort}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 KLIC:array[0..7] of integer=(65,85,34,30,47,91,72,41);
var
 i:byte;
begin
 clrscr;
 qsort(addr(KLIC),sizeof(word),sizeof(KLIC) div sizeof(word),ComparePointers2);
 for i:=0 to 7 do writeln(KLIC[i]);
end.

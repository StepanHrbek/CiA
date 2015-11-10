type
 PAGreaterThanB=^TAGreaterThanB;
 TAGreaterThanB=function(a,b:pointer):boolean;
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
function ComparePointers(a,b:pointer):boolean;
begin {ComparePointers}
 ComparePointers:=byte(a^)>byte(b^);
end;  {ComparePointers}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  QSort(pole:pointer; itemsize,n:word{; AGreaterThanB:TAGreaterThanB}):boolean;
type
 TZasobnik=
  record
   zac,kon:word;
  end;
 PStack=^TStack;
 TStack=array[0..$FFF8 div sizeof(TZasobnik)-1] of TZasobnik;
var
 stack:Pstack;
 stacksize,sp:word;
 zac,kon,levy,pravy:word;
 prostredni:pointer;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure qsPush(_zac,_kon:word);
 begin {qsPush}
  if _zac=_kon then exit;
  if sp=stacksize then exit; {*chyba: preteceni interniho stacku}
  with stack^[sp] do
  begin
   zac:=_zac;
   kon:=_kon;
  end;
  inc(sp);
 end;  {qsPush}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure qsPop(var _zac,_kon:word);
 begin {qsPop}
  if sp=0 then exit; {*chyba: podteceni interniho stacku}
  dec(sp);
  with stack^[sp] do
  begin
   _zac:=zac;
   _kon:=kon;
  end;
 end;  {qsPop}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 function qsStackEmpty:boolean;
 begin {qsStackEmpty}
  qsStackEmpty:=sp=0;
 end;  {qsStackEmpty}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin {QSort}
 QSort:=false;
 if (n*itemsize=0) {or (@AGreaterThanB=nil) }then exit; {*chyba: spatne zadane hodnoty}
 stacksize:=n shr 1;
 getmem(stack,stacksize);
 if stack=nil then exit; {*chyba: stack se nevejde do pameti}
 sp:=0;
 qsPush(0,n-1);
 repeat
  qsPop(zac,kon);
  repeat
   levy:=zac;
   pravy:=kon;
   prostredni:=ptr(seg(pole^),ofs(pole^)+((zac+kon) shr 1)*itemsize);
   repeat
    while {AGreaterThanB}ComparePointers(prostredni,ptr(seg(pole^),ofs(pole^)+levy*itemsize)) do inc(levy);
    while {AGreaterThanB}ComparePointers(ptr(seg(pole^),ofs(pole^)+pravy*itemsize),prostredni) do dec(pravy);
    if levy<>pravy then {vymena}
     xchg(ptr(seg(pole^),ofs(pole^)+levy*itemsize)^,ptr(seg(pole^),ofs(pole^)+pravy*itemsize)^,itemsize);
    inc(levy);
    dec(pravy);
   until levy>pravy;
   if zac<pravy then qsPush(zac,pravy);
   if kon>levy then qsPush(levy,kon);
  until levy>=pravy;
 until qsStackEmpty;
 freemem(stack,stacksize);
 QSort:=true;
end;  {QSort}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 polep:array[0..7] of word;
 i:byte;
begin
 for i:=0 to sizeof(polep)-1 do polep[i]:=random(100);
 qsort(addr(polep),2,8{,TAGreaterThanB(ComparePointers)});
end.

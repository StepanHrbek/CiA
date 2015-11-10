uses crt;
type
 TPole=array[0..7] of word;
 TComparePointers=function(p1,p2:pointer):boolean;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE Xchg(var a,b;bytes:word);assembler;
asm
 PUSH DS
 lds  si,a
 les  di,b
 mov  cx,bytes
@1:
 mov  al,[es:di]
 xchg al,[si]
 stosb
 inc  si
 loop @1
 POP  DS
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  ComparePointers2(p1,p2:pointer):boolean; far;
begin
 ComparePointers2:=byte(p1^)>byte(p2^);
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure heapsort(pole:pointer; itemsize,count:integer; ComparePointers:TComparePointers);
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure probublej;
 var i,j,p:word;
 begin
  for j:=count shr 1 downto 1 do
   begin
    i:=j;
    while i shl 1<=count do
     begin
      p:=word(ComparePointers(ptr(seg(pole^),ofs(pole^)+(i shl 1)*itemsize),ptr(seg(pole^),ofs(pole^)+(i shl 1-1)*itemsize)));
      p:=p and word(i shl 1<>count);
      if ComparePointers(ptr(seg(pole^),ofs(pole^)+(i shl 1+p-1)*itemsize),ptr(seg(pole^),ofs(pole^)+(i-1)*itemsize)) then
       begin
        xchg(ptr(seg(pole^),ofs(pole^)+(i shl 1+p-1)*itemsize)^,ptr(seg(pole^),ofs(pole^)+(i-1)*itemsize)^,itemsize);
        i:=i shl 1+p;
       end
      else
       break;
     end;
   end;
 end;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin
 if (pole=nil) or (addr(ComparePointers)=nil) or (itemsize=0) or (count<2) then exit;
 for count:=count downto 2 do
  begin
   probublej;
   xchg(pole^,ptr(seg(pole^),ofs(pole^)+(count-1)*itemsize)^,itemsize);
  end;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 pole:TPole=(5,1,3,9,2,8,7,4);
var
 i:word;
begin
 clrscr;
 heapsort(@pole,sizeof(pole[0]),sizeof(pole) div sizeof(pole[0]),ComparePointers2);
 for i:=0 to 7 do
  writeln(pole[i]);
end.
